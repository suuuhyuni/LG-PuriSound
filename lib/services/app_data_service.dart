part of hrgg_app;

final AppDataService appDataService = AppDataService();

class AppDataService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User get _user {
    final user = _auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    return user;
  }

  String get primaryDeviceId => '${_user.uid}_primary';

  DocumentReference<Map<String, dynamic>> get _userRef =>
      _firestore.collection('users').doc(_user.uid);

  DocumentReference<Map<String, dynamic>> get _deviceRef =>
      _firestore.collection('devices').doc(primaryDeviceId);

  Future<void> ensureUserWorkspace() async {
    final settingsRef = _userRef.collection('settings').doc('app');
    final settings = await settingsRef.get();
    final batch = _firestore.batch();
    if (!settings.exists) {
      batch.set(settingsRef, {
        'themeMode': 'system',
        'autoMasking': true,
        'puriSoundEnabled': true,
        'noiseType': 'auto',
        'noiseVersion': 1,
        'noiseVersions': {'brown': 1, 'pink': 1, 'white': 1},
        'volume': 42,
        'fadeSpeed': 'normal',
        'sensitivity': 'normal',
        'adaptiveEnabled': true,
        'ledMode': 'auto',
        'ledColor': '#C97B3A',
        'ledBrightness': 35,
        'notifications': {
          'quietHoursNoise': true,
          'thresholdExceeded': true,
          'deviceDisconnected': true,
          'weeklyReportReady': false,
        },
        'updatedAt': FieldValue.serverTimestamp(),
        'autoNoiseSelection': FieldValue.delete(),
      });
    }
    for (final mode in _systemModes) {
      final modeRef = _userRef.collection('modes').doc(mode['id'] as String);
      final existing = await modeRef.get();
      if (!existing.exists) {
        batch.set(modeRef, {...mode, 'updatedAt': FieldValue.serverTimestamp()});
      }
    }
    final powerRef = _userRef.collection('modes').doc('_system_state');
    final powerDoc = await powerRef.get();
    if (!powerDoc.exists) {
      batch.set(powerRef, {
        'modeId': '_system_state',
        'name': '_system_state',
        'type': 'system_state',
        'puriSoundEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await _reconcileLegacySettings();
  }

  Future<void> _reconcileLegacySettings() async {
    final current = await getSettings();
    if (current.isEmpty) return;
    final autoMasking = current['autoMasking'] as bool? ?? true;
    final updates = <String, dynamic>{};
    final currentLedMode = current['ledMode'] as String?;

    if (autoMasking) {
      if (currentLedMode != 'auto') {
        updates['ledMode'] = 'auto';
      }
      if (current['ledColor'] != '#C97B3A') {
        updates['ledColor'] = '#C97B3A';
      }
    } else {
      if (currentLedMode != 'manual' && currentLedMode != 'off') {
        updates['ledMode'] = 'off';
      }
      if (currentLedMode == 'mode') {
        updates['ledMode'] = 'off';
      }
      if ((updates['ledMode'] ?? currentLedMode) == 'off') {
        updates['ledColor'] = '#FFFFFF';
        updates['ledBrightness'] = 0;
      }
    }

    if (updates.isEmpty) return;
    await _userRef.collection('settings').doc('app').set(
      {
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> registerPrimaryDevice({
    String zone = '침실',
    String noiseType = 'brown',
    int volume = 42,
    String sensitivity = 'normal',
    bool applyInitialSettings = false,
  }) async {
    final batch = _firestore.batch();
    batch.set(
      _deviceRef,
      {
        'deviceId': primaryDeviceId,
        'ownerId': _user.uid,
        'deviceName': 'PuriSound Speaker 001',
        'model': 'H-01',
        'firmwareVersion': 'v1.2.3',
        'localZone': zone,
        'connectionStatus': 'connected',
        'registeredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    if (applyInitialSettings) {
      batch.set(
        _userRef.collection('settings').doc('app'),
        {
        'puriSoundEnabled': true,
        'autoMasking': false,
        'noiseType': noiseType,
        'volume': volume,
        'sensitivity': sensitivity,
        'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  Future<Map<String, dynamic>> getSettings() async =>
      (await _userRef.collection('settings').doc('app').get()).data() ?? {};

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchSettings() =>
      _userRef.collection('settings').doc('app').snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchModes() =>
      _userRef.collection('modes').orderBy('name').snapshots();

  Future<Map<String, dynamic>?> getMode(String modeId) async =>
      (await _userRef.collection('modes').doc(modeId).get()).data();

  Stream<QuerySnapshot<Map<String, dynamic>>> watchSchedules() =>
      _userRef.collection('schedules').orderBy('createdAt', descending: true).snapshots();

  Future<void> deleteSchedule(String scheduleId) =>
      _userRef.collection('schedules').doc(scheduleId).delete();

  Future<void> saveSettings(Map<String, dynamic> values) async {
    final normalized = await _normalizeSettings(values);
    return _userRef.collection('settings').doc('app').set(
      {...normalized, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> setPuriSoundEnabled(bool enabled) async {
    final settingsRef = _userRef.collection('settings').doc('app');
    final powerRef = _userRef.collection('modes').doc('_system_state');
    final normalized = await _normalizeSettings({
      'puriSoundEnabled': enabled,
      'autoMasking': enabled,
      'noiseType': enabled ? 'auto' : 'off',
    });
    final batch = _firestore.batch();
    batch.set(
      settingsRef,
      {...normalized, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    batch.set(
      powerRef,
      {
        'modeId': '_system_state',
        'name': '_system_state',
        'type': 'system_state',
        'puriSoundEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> saveMode({
    String? modeId,
    required String name,
    required String noiseType,
    required int volume,
    required String sensitivity,
    String ledColor = '#E6007E',
    bool isSystemMode = false,
  }) async {
    final ref = modeId == null
        ? _userRef.collection('modes').doc()
        : _userRef.collection('modes').doc(modeId);
    await ref.set({
      'modeId': ref.id,
      'name': name,
      'noiseType': noiseType,
      'volume': volume,
      'sensitivity': sensitivity,
      'ledColor': ledColor,
      'isSystemMode': isSystemMode,
      'updatedAt': FieldValue.serverTimestamp(),
      if (modeId == null) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setActiveMode(
    String modeId,
    String modeName, {
    bool autoMasking = false,
  }) async {
    final mode = (await _userRef.collection('modes').doc(modeId).get()).data();
    await saveSettings({
      'activeModeId': modeId,
      'activeModeName': modeName,
      'autoMasking': autoMasking,
      'autoNoiseSelection': FieldValue.delete(),
      if (mode != null) ...{
        'noiseType': mode['noiseType'],
        'volume': mode['volume'],
        'sensitivity': mode['sensitivity'],
        'ledColor': mode['ledColor'],
      },
    });
  }

  Future<Map<String, dynamic>> _normalizeSettings(
      Map<String, dynamic> values) async {
    final current = await getSettings();
    final merged = <String, dynamic>{...current, ...values};
    final hasPowerOverride = values.containsKey('puriSoundEnabled');
    final hasAutoOverride = values.containsKey('autoMasking');
    final hasNoiseTypeOverride = values.containsKey('noiseType');
    final requestedPower = merged['puriSoundEnabled'] as bool?;
    final requestedAuto = merged['autoMasking'] as bool?;
    final requestedNoiseType = merged['noiseType'] as String?;

    if (hasPowerOverride && requestedPower == false) {
      merged['puriSoundEnabled'] = false;
      merged['autoMasking'] = false;
      merged['noiseType'] = 'off';
      merged['ledMode'] = 'off';
      merged['ledColor'] = '#FFFFFF';
      merged['ledBrightness'] = 0;
      return merged;
    }

    merged['puriSoundEnabled'] =
        requestedPower ?? (current['puriSoundEnabled'] as bool? ?? true);
    final hasLedModeOverride = values.containsKey('ledMode');
    final requestedLedMode = merged['ledMode'] as String?;

    if (hasAutoOverride && requestedAuto == true) {
      merged['autoMasking'] = true;
      merged['noiseType'] = 'auto';
      merged['ledMode'] = 'auto';
      merged['ledColor'] = '#C97B3A';
    } else if (hasAutoOverride && requestedAuto == false) {
      merged['autoMasking'] = false;
      if (!hasNoiseTypeOverride || requestedNoiseType == 'auto') {
        merged['noiseType'] = 'off';
      }
      if (!hasLedModeOverride ||
          requestedLedMode == null ||
          requestedLedMode == 'auto' ||
          requestedLedMode == 'mode') {
        merged['ledMode'] = 'off';
        merged['ledColor'] = '#FFFFFF';
        merged['ledBrightness'] = 0;
      }
    } else if (hasNoiseTypeOverride && requestedNoiseType == 'auto') {
      merged['autoMasking'] = true;
      merged['noiseType'] = 'auto';
      merged['ledMode'] = 'auto';
      merged['ledColor'] = '#C97B3A';
    } else if (hasNoiseTypeOverride &&
        requestedNoiseType != null &&
        requestedNoiseType != 'auto') {
      merged['autoMasking'] = false;
    }

    final effectiveNoiseType = merged['noiseType'] as String?;
    if (effectiveNoiseType == 'off') {
      merged['noiseVersion'] = null;
      merged['volume'] = 0;
    }

    final effectiveAutoMasking = merged['autoMasking'] as bool? ?? false;
    if (effectiveAutoMasking) {
      merged['ledMode'] = 'auto';
      merged['ledColor'] = '#C97B3A';
    } else {
      final effectiveLedMode = merged['ledMode'] as String?;
      if (effectiveLedMode == 'manual') {
        merged['ledMode'] = 'manual';
      } else {
        merged['ledMode'] = 'off';
        merged['ledColor'] = '#FFFFFF';
        merged['ledBrightness'] = 0;
      }
    }

    return merged;
  }

  Future<void> saveSchedule({
    required List<String> days,
    required TimeOfDay start,
    required TimeOfDay end,
    required String modeId,
    required String modeName,
    String source = 'manual',
  }) async {
    final ref = _userRef.collection('schedules').doc();
    final mode = await getMode(modeId);
    await ref.set({
      'scheduleId': ref.id,
      'deviceId': primaryDeviceId,
      'days': days,
      'startMinutes': start.hour * 60 + start.minute,
      'endMinutes': end.hour * 60 + end.minute,
      'modeId': modeId,
      'modeName': modeName,
      'source': source,
      if (mode != null) ...{
        'noiseType': mode['noiseType'],
        'volume': mode['volume'],
        'sensitivity': mode['sensitivity'],
        'ledColor': mode['ledColor'],
      },
      'enabled': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> recordNoiseEvent(AudioInsight insight) async {
    final settings = await getSettings();
    final autoMasking = settings['autoMasking'] as bool? ?? true;
    final maskingRequired = insight.shouldMask && autoMasking;
    final maskingType = autoMasking
        ? insight.maskingType.name
        : settings['noiseType'] as String? ?? insight.maskingType.name;
    final maskingVersion =
        autoMasking ? null : settings['noiseVersion'] as int? ?? 1;
    final volume = settings['volume'] as int? ?? 42;
    final eventRef = _deviceRef.collection('noiseEvents').doc();
    final batch = _firestore.batch();
    batch.set(
      _deviceRef,
      {
        'deviceId': primaryDeviceId,
        'ownerId': _user.uid,
        'deviceName': 'PuriSound Speaker 001',
        'model': 'H-01',
        'connectionStatus': 'connected',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(eventRef, {
      'noiseEventId': eventRef.id,
      'deviceId': primaryDeviceId,
      'ownerId': _user.uid,
      'db': insight.db,
      'frequencyHz': insight.frequencyHz,
      'yamnetLabel': insight.label,
      'noiseType': insight.maskingType.name,
      'confidence': insight.confidence,
      'maskingRequired': maskingRequired,
      'detectedAt': FieldValue.serverTimestamp(),
    });

    if (maskingRequired) {
      final actionRef = _deviceRef.collection('maskingActions').doc();
      batch.set(actionRef, {
        'actionId': actionRef.id,
        'noiseEventId': eventRef.id,
        'deviceId': primaryDeviceId,
        'ownerId': _user.uid,
        'noiseType': maskingType,
        if (maskingVersion != null) 'noiseVersion': maskingVersion,
        'volume': volume,
        'triggerType': 'automatic',
        'result': 'started',
        'startedAt': FieldValue.serverTimestamp(),
      });
    }

    final date = DateTime.now();
    final dayId =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final summaryRef = _deviceRef.collection('dailySummaries').doc(dayId);
    batch.set(
      summaryRef,
      {
        'date': dayId,
        'ownerId': _user.uid,
        'eventCount': FieldValue.increment(1),
        'dbTotal': FieldValue.increment(insight.db),
        'maxDb': insight.db,
        '${insight.maskingType.name}Count': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> recordManualMasking({
    required String noiseType,
    int? noiseVersion,
    required int volume,
  }) async {
    final ref = _deviceRef.collection('maskingActions').doc();
    final batch = _firestore.batch();
    batch.set(
      _deviceRef,
      {
        'deviceId': primaryDeviceId,
        'ownerId': _user.uid,
        'deviceName': 'PuriSound Speaker 001',
        'connectionStatus': 'connected',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(ref, {
      'actionId': ref.id,
      'deviceId': primaryDeviceId,
      'ownerId': _user.uid,
      'noiseType': noiseType,
      if (noiseVersion != null) 'noiseVersion': noiseVersion,
      'volume': volume,
      'triggerType': 'manual',
      'result': 'started',
      'startedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  Future<void> createNotification({
    required String type,
    required String title,
    required String body,
    String? noiseEventId,
  }) async {
    final ref = _userRef.collection('notifications').doc();
    await ref.set({
      'notificationId': ref.id,
      'deviceId': primaryDeviceId,
      'noiseEventId': noiseEventId,
      'type': type,
      'title': title,
      'body': body,
      'isRead': false,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveAiRecommendation({
    String? recommendationId,
    required String title,
    required String noiseType,
    required double confidence,
    required String recommendedMode,
    String? modeId,
    String? subtitle,
    int? periodDays,
    List<String>? days,
    int? startMinutes,
    int? endMinutes,
    String? aiSuggestion,
  }) async {
    final ref = recommendationId == null
        ? _userRef.collection('aiRecommendations').doc()
        : _userRef.collection('aiRecommendations').doc(recommendationId);
    final existing = await ref.get();
    await ref.set({
      'recommendationId': ref.id,
      'deviceId': primaryDeviceId,
      'title': title,
      'noiseType': noiseType,
      'confidence': confidence,
      'recommendedMode': recommendedMode,
      if (modeId != null) 'modeId': modeId,
      if (subtitle != null) 'subtitle': subtitle,
      if (periodDays != null) 'periodDays': periodDays,
      if (days != null) 'days': days,
      if (startMinutes != null) 'startMinutes': startMinutes,
      if (endMinutes != null) 'endMinutes': endMinutes,
      if (aiSuggestion != null) 'aiSuggestion': aiSuggestion,
      if (!existing.exists) ...{
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAiRecommendation(
          String recommendationId) =>
      _userRef
          .collection('aiRecommendations')
          .doc(recommendationId)
          .snapshots();

  Future<void> rateAiRecommendation(String recommendationId, int rating) {
    return _userRef.collection('aiRecommendations').doc(recommendationId).set({
      'rating': rating,
      'ratedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> updateAiRecommendationStatus(
      String recommendationId, String status) {
    return _userRef.collection('aiRecommendations').doc(recommendationId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAiRecommendations() {
    return _userRef
        .collection('aiRecommendations')
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  Future<AiRecommendationAnalysis> generateAiRecommendationAnalysis({
    required int periodDays,
  }) async {
    await ensureNoiseEventTrainingData();

    final end = DateTime.now();
    final start = DateTime(end.year, end.month, end.day)
        .subtract(Duration(days: periodDays - 1));
    final eventSnapshot = await _deviceRef
        .collection('noiseEvents')
        .where('detectedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    final ratingSnapshot = await _userRef.collection('aiRecommendations').get();
    final buckets = <String, _NoiseBucket>{};
    final heatmap = List.generate(7, (_) => List<double>.filled(8, 0));

    for (final doc in eventSnapshot.docs) {
      final data = doc.data();
      final detectedAt = (data['detectedAt'] as Timestamp?)?.toDate();
      if (detectedAt == null) continue;
      final weekdayIndex = detectedAt.weekday - 1;
      final minuteOfDay = detectedAt.hour * 60 + detectedAt.minute;
      final bucketStart = (minuteOfDay ~/ 30) * 30;
      final bucketKey = '${detectedAt.weekday}-$bucketStart';
      final bucket = buckets.putIfAbsent(
        bucketKey,
        () => _NoiseBucket(
          weekday: detectedAt.weekday,
          bucketStartMinutes: bucketStart,
        ),
      );
      final noiseType = data['noiseType'] as String? ?? 'white';
      final db = (data['db'] as num?)?.toDouble() ?? 0;
      bucket.uniqueDates.add(
        '${detectedAt.year}-${detectedAt.month}-${detectedAt.day}',
      );
      bucket.eventCount += 1;
      bucket.dbTotal += db;
      bucket.noiseTypeCounts.update(noiseType, (value) => value + 1,
          ifAbsent: () => 1);
      heatmap[weekdayIndex][detectedAt.hour ~/ 3] += 1;
    }

    final maxHeat = heatmap
        .expand((row) => row)
        .fold<double>(0, (current, value) => math.max(current, value));
    final normalizedHeatmap = maxHeat == 0
        ? heatmap
        : heatmap
            .map((row) => row.map((value) => value / maxHeat).toList())
            .toList();

    final ratingDocs = ratingSnapshot.docs.map((doc) => doc.data()).toList();
    final recommendations = <AiScheduleRecommendation>[];
    final sortedBuckets = buckets.values.toList()
      ..sort((a, b) {
        final byDays = b.uniqueDates.length.compareTo(a.uniqueDates.length);
        if (byDays != 0) return byDays;
        return b.eventCount.compareTo(a.eventCount);
      });

    for (final bucket in sortedBuckets) {
      final repeatDays = bucket.uniqueDates.length;
      if (repeatDays < 2) continue;
      final dominantNoiseType = bucket.noiseTypeCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
      final mode = _recommendedModeForNoise(dominantNoiseType);
      final avgRating = _averageRatingForMode(
        ratingDocs,
        noiseType: dominantNoiseType,
        modeId: mode.$1,
      );
      final baseConfidence = repeatDays / periodDays;
      final adjustedConfidence = (baseConfidence + (avgRating - 3) * 0.04)
          .clamp(0.05, 0.98)
          .toDouble();
      if (adjustedConfidence < 0.20) continue;

      final nextOccurrence = _nextOccurrenceDate(
        bucket.weekday,
        bucket.bucketStartMinutes,
      );
      final title = _recommendationTitle(
        nextOccurrence,
        dominantNoiseType,
      );
      final subtitle =
          '최근 $periodDays일 중 $repeatDays일 동일 시간대 감지 (${(adjustedConfidence * 100).round()}%)';
      final endMinutes = _recommendedEndMinutes(
        bucket.bucketStartMinutes,
        dominantNoiseType,
      );
      final recommendationId =
          'pattern_${periodDays}_${bucket.weekday}_${bucket.bucketStartMinutes}_${mode.$1}';

      await saveAiRecommendation(
        recommendationId: recommendationId,
        title: title,
        noiseType: dominantNoiseType,
        confidence: adjustedConfidence,
        recommendedMode: mode.$2,
        modeId: mode.$1,
        subtitle: subtitle,
        periodDays: periodDays,
        days: [_weekdayLabel(bucket.weekday)],
        startMinutes: bucket.bucketStartMinutes,
        endMinutes: endMinutes,
        aiSuggestion: '$subtitle · ${noiseTypeLabel(dominantNoiseType)} 우세',
      );

      recommendations.add(
        AiScheduleRecommendation(
          recommendationId: recommendationId,
          title: title,
          subtitle: subtitle,
          noiseType: dominantNoiseType,
          confidence: adjustedConfidence,
          modeId: mode.$1,
          modeName: mode.$2,
          days: [_weekdayLabel(bucket.weekday)],
          startMinutes: bucket.bucketStartMinutes,
          endMinutes: endMinutes,
        ),
      );
      if (recommendations.length == 3) break;
    }

    if (recommendations.isEmpty) {
      final seeded = await seedDemoAiRecommendations(periodDays: periodDays);
      return AiRecommendationAnalysis(
        periodDays: periodDays,
        totalEvents: eventSnapshot.docs.length,
        recommendations: seeded,
        heatmap: normalizedHeatmap,
      );
    }

    return AiRecommendationAnalysis(
      periodDays: periodDays,
      totalEvents: eventSnapshot.docs.length,
      recommendations: recommendations,
      heatmap: normalizedHeatmap,
    );
  }

  Future<void> ensureNoiseEventTrainingData({int minimumEvents = 18}) async {
    final threshold = DateTime.now().subtract(const Duration(days: 30));
    final snapshot = await _deviceRef
        .collection('noiseEvents')
        .where('detectedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(threshold))
        .get();
    if (snapshot.docs.length >= minimumEvents) return;

    final seedEvents = _buildSeedNoiseEvents();
    final batch = _firestore.batch();
    for (final event in seedEvents) {
      final ref = _deviceRef.collection('noiseEvents').doc(event['id'] as String);
      batch.set(ref, {
        'noiseEventId': ref.id,
        'deviceId': primaryDeviceId,
        'ownerId': _user.uid,
        'db': event['db'],
        'frequencyHz': event['frequencyHz'],
        'yamnetLabel': event['label'],
        'noiseType': event['noiseType'],
        'confidence': event['confidence'],
        'maskingRequired': event['maskingRequired'],
        'source': 'seeded',
        'detectedAt': Timestamp.fromDate(event['detectedAt'] as DateTime),
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  Future<List<AiScheduleRecommendation>> seedDemoAiRecommendations({
    required int periodDays,
  }) async {
    final demo = <AiScheduleRecommendation>[
      AiScheduleRecommendation(
        recommendationId: 'demo_night_impact_$periodDays',
        title: '내일 밤 10:30 PM 충격음 예상',
        subtitle:
            '최근 ${periodDays == 7 ? '7일' : '30일'} 중 ${periodDays == 7 ? '5일' : '18일'} 동일 시간대 감지 (${periodDays == 7 ? '71' : '60'}%)',
        noiseType: 'brown',
        confidence: periodDays == 7 ? 0.71 : 0.60,
        modeId: 'sleep',
        modeName: '수면 모드',
        days: [_weekdayLabel(DateTime.now().add(const Duration(days: 1)).weekday)],
        startMinutes: 22 * 60 + 30,
        endMinutes: 7 * 60,
      ),
      AiScheduleRecommendation(
        recommendationId: 'demo_traffic_evening_$periodDays',
        title: '금요일 오후 7:20 PM 교통 소음 예상',
        subtitle:
            '퇴근 시간대 반복 감지 (${periodDays == 7 ? '64' : '57'}%)',
        noiseType: 'pink',
        confidence: periodDays == 7 ? 0.64 : 0.57,
        modeId: 'traffic',
        modeName: '교통 소음 모드',
        days: const ['금'],
        startMinutes: 19 * 60 + 20,
        endMinutes: 21 * 60,
      ),
    ];

    for (final item in demo) {
      await saveAiRecommendation(
        recommendationId: item.recommendationId,
        title: item.title,
        noiseType: item.noiseType,
        confidence: item.confidence,
        recommendedMode: item.modeName,
        modeId: item.modeId,
        subtitle: item.subtitle,
        periodDays: periodDays,
        days: item.days,
        startMinutes: item.startMinutes,
        endMinutes: item.endMinutes,
        aiSuggestion: 'demo-seeded',
      );
    }

    return demo;
  }

  Future<void> generateReport({required int days}) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    final snapshot = await _deviceRef
        .collection('noiseEvents')
        .where('detectedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    final values = snapshot.docs
        .map((doc) => (doc.data()['db'] as num?)?.toDouble() ?? 0)
        .toList();
    final ref = _userRef.collection('reports').doc();
    await ref.set({
      'reportId': ref.id,
      'deviceId': primaryDeviceId,
      'periodDays': days,
      'periodStart': Timestamp.fromDate(start),
      'periodEnd': Timestamp.fromDate(end),
      'totalEvents': values.length,
      'averageDb':
          values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length,
      'maxDb': values.isEmpty ? 0 : values.reduce(math.max),
      'generatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchRecentNoiseEvents() {
    return _deviceRef
        .collection('noiseEvents')
        .orderBy('detectedAt', descending: true)
        .limit(3)
        .snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> watchPrimaryDevice() {
    return _deviceRef.snapshots();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>?> watchLatestNoiseEvent() {
    return _deviceRef
        .collection('noiseEvents')
        .orderBy('detectedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty ? null : snapshot.docs.first);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchProfile() =>
      _userRef.snapshots();

  List<Map<String, dynamic>> _buildSeedNoiseEvents() {
    final now = DateTime.now();
    final seeds = <Map<String, dynamic>>[];

    void addSeed({
      required String id,
      required int daysAgo,
      required int hour,
      required int minute,
      required String noiseType,
      required double db,
      required double frequencyHz,
      required String label,
      required double confidence,
      required bool maskingRequired,
    }) {
      final date = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: daysAgo));
      seeds.add({
        'id': id,
        'detectedAt': DateTime(date.year, date.month, date.day, hour, minute),
        'noiseType': noiseType,
        'db': db,
        'frequencyHz': frequencyHz,
        'label': label,
        'confidence': confidence,
        'maskingRequired': maskingRequired,
      });
    }

    addSeed(
        id: 'seed_impact_1',
        daysAgo: 1,
        hour: 22,
        minute: 30,
        noiseType: 'brown',
        db: 58,
        frequencyHz: 72,
        label: '충격음 감지 · 저주파',
        confidence: 0.88,
        maskingRequired: true);
    addSeed(
        id: 'seed_impact_2',
        daysAgo: 2,
        hour: 22,
        minute: 30,
        noiseType: 'brown',
        db: 61,
        frequencyHz: 68,
        label: '충격음 감지 · 저주파',
        confidence: 0.89,
        maskingRequired: true);
    addSeed(
        id: 'seed_impact_3',
        daysAgo: 4,
        hour: 22,
        minute: 30,
        noiseType: 'brown',
        db: 56,
        frequencyHz: 70,
        label: '충격음 감지 · 저주파',
        confidence: 0.84,
        maskingRequired: true);
    addSeed(
        id: 'seed_impact_4',
        daysAgo: 5,
        hour: 22,
        minute: 30,
        noiseType: 'brown',
        db: 63,
        frequencyHz: 76,
        label: '충격음 감지 · 저주파',
        confidence: 0.91,
        maskingRequired: true);
    addSeed(
        id: 'seed_impact_5',
        daysAgo: 6,
        hour: 22,
        minute: 30,
        noiseType: 'brown',
        db: 60,
        frequencyHz: 73,
        label: '충격음 감지 · 저주파',
        confidence: 0.87,
        maskingRequired: true);

    addSeed(
        id: 'seed_traffic_1',
        daysAgo: 0,
        hour: 19,
        minute: 30,
        noiseType: 'pink',
        db: 51,
        frequencyHz: 540,
        label: '교통·실외기 지속음',
        confidence: 0.76,
        maskingRequired: true);
    addSeed(
        id: 'seed_traffic_2',
        daysAgo: 7,
        hour: 19,
        minute: 30,
        noiseType: 'pink',
        db: 49,
        frequencyHz: 520,
        label: '교통·실외기 지속음',
        confidence: 0.73,
        maskingRequired: true);
    addSeed(
        id: 'seed_traffic_3',
        daysAgo: 14,
        hour: 19,
        minute: 30,
        noiseType: 'pink',
        db: 52,
        frequencyHz: 560,
        label: '교통·실외기 지속음',
        confidence: 0.77,
        maskingRequired: true);
    addSeed(
        id: 'seed_traffic_4',
        daysAgo: 21,
        hour: 19,
        minute: 30,
        noiseType: 'pink',
        db: 50,
        frequencyHz: 535,
        label: '교통·실외기 지속음',
        confidence: 0.75,
        maskingRequired: true);

    addSeed(
        id: 'seed_voice_1',
        daysAgo: 3,
        hour: 9,
        minute: 0,
        noiseType: 'white',
        db: 44,
        frequencyHz: 1850,
        label: '생활·대화음',
        confidence: 0.68,
        maskingRequired: false);
    addSeed(
        id: 'seed_voice_2',
        daysAgo: 10,
        hour: 9,
        minute: 0,
        noiseType: 'white',
        db: 46,
        frequencyHz: 1720,
        label: '생활·대화음',
        confidence: 0.69,
        maskingRequired: true);
    addSeed(
        id: 'seed_voice_3',
        daysAgo: 17,
        hour: 9,
        minute: 0,
        noiseType: 'white',
        db: 43,
        frequencyHz: 1780,
        label: '생활·대화음',
        confidence: 0.66,
        maskingRequired: false);

    addSeed(
        id: 'seed_misc_1',
        daysAgo: 8,
        hour: 23,
        minute: 0,
        noiseType: 'brown',
        db: 57,
        frequencyHz: 80,
        label: '충격음 감지 · 저주파',
        confidence: 0.83,
        maskingRequired: true);
    addSeed(
        id: 'seed_misc_2',
        daysAgo: 11,
        hour: 23,
        minute: 0,
        noiseType: 'brown',
        db: 59,
        frequencyHz: 78,
        label: '충격음 감지 · 저주파',
        confidence: 0.85,
        maskingRequired: true);
    addSeed(
        id: 'seed_misc_3',
        daysAgo: 18,
        hour: 20,
        minute: 0,
        noiseType: 'pink',
        db: 48,
        frequencyHz: 500,
        label: '교통·실외기 지속음',
        confidence: 0.71,
        maskingRequired: true);
    addSeed(
        id: 'seed_misc_4',
        daysAgo: 25,
        hour: 8,
        minute: 30,
        noiseType: 'white',
        db: 42,
        frequencyHz: 1600,
        label: '생활·대화음',
        confidence: 0.65,
        maskingRequired: false);

    return seeds;
  }
}

class AiRecommendationAnalysis {
  const AiRecommendationAnalysis({
    required this.periodDays,
    required this.totalEvents,
    required this.recommendations,
    required this.heatmap,
  });

  final int periodDays;
  final int totalEvents;
  final List<AiScheduleRecommendation> recommendations;
  final List<List<double>> heatmap;
}

class AiScheduleRecommendation {
  const AiScheduleRecommendation({
    required this.recommendationId,
    required this.title,
    required this.subtitle,
    required this.noiseType,
    required this.confidence,
    required this.modeId,
    required this.modeName,
    required this.days,
    required this.startMinutes,
    required this.endMinutes,
  });

  final String recommendationId;
  final String title;
  final String subtitle;
  final String noiseType;
  final double confidence;
  final String modeId;
  final String modeName;
  final List<String> days;
  final int startMinutes;
  final int endMinutes;
}

class _NoiseBucket {
  _NoiseBucket({
    required this.weekday,
    required this.bucketStartMinutes,
  });

  final int weekday;
  final int bucketStartMinutes;
  final Set<String> uniqueDates = <String>{};
  final Map<String, int> noiseTypeCounts = <String, int>{};
  int eventCount = 0;
  double dbTotal = 0;
}

(String, String) _recommendedModeForNoise(String noiseType) => switch (noiseType) {
      'brown' => ('sleep', '수면 모드'),
      'pink' => ('traffic', '교통 소음 모드'),
      'white' => ('focus', '집중 모드'),
      _ => ('custom', '커스텀 모드'),
    };

double _averageRatingForMode(
  List<Map<String, dynamic>> docs, {
  required String noiseType,
  required String modeId,
}) {
  final ratings = docs
      .where((doc) =>
          doc['noiseType'] == noiseType &&
          doc['modeId'] == modeId &&
          doc['rating'] is num)
      .map((doc) => (doc['rating'] as num).toDouble())
      .toList();
  if (ratings.isEmpty) return 3;
  return ratings.reduce((a, b) => a + b) / ratings.length;
}

DateTime _nextOccurrenceDate(int weekday, int startMinutes) {
  final now = DateTime.now();
  final todayMinutes = now.hour * 60 + now.minute;
  var daysUntil = (weekday - now.weekday) % 7;
  if (daysUntil == 0 && startMinutes <= todayMinutes) {
    daysUntil = 7;
  }
  final target = DateTime(now.year, now.month, now.day)
      .add(Duration(days: daysUntil));
  return DateTime(
    target.year,
    target.month,
    target.day,
    startMinutes ~/ 60,
    startMinutes % 60,
  );
}

String _recommendationTitle(DateTime time, String noiseType) {
  final period = time.hour < 12
      ? '오전'
      : time.hour < 18
          ? '오후'
          : '밤';
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final prefix = time.difference(DateTime.now()).inDays == 0
      ? '오늘'
      : time.difference(DateTime.now()).inDays == 1
          ? '내일'
          : '${_weekdayLabel(time.weekday)}요일';
  final label = switch (noiseType) {
    'brown' => '충격음',
    'pink' => '교통 소음',
    'white' => '생활 소음',
    _ => '소음',
  };
  return '$prefix $period $hour12:$minute $label 예상';
}

int _recommendedEndMinutes(int startMinutes, String noiseType) {
  if (noiseType == 'brown' && startMinutes >= 21 * 60) {
    return 7 * 60;
  }
  final duration = switch (noiseType) {
    'pink' => 120,
    'white' => 90,
    _ => 150,
  };
  return (startMinutes + duration) % (24 * 60);
}

const List<Map<String, dynamic>> _systemModes = [
  {
    'id': 'sleep',
    'name': '수면 모드',
    'noiseType': 'brown',
    'volume': 35,
    'sensitivity': 'normal',
    'ledColor': '#000000',
    'isSystemMode': true,
  },
  {
    'id': 'baby',
    'name': '베이비 모드',
    'noiseType': 'brown',
    'volume': 25,
    'sensitivity': 'high',
    'ledColor': '#F9C6D0',
    'isSystemMode': true,
  },
  {
    'id': 'focus',
    'name': '집중 모드',
    'noiseType': 'white',
    'volume': 55,
    'sensitivity': 'low',
    'ledColor': '#E8F0FE',
    'isSystemMode': true,
  },
  {
    'id': 'traffic',
    'name': '교통 소음 모드',
    'noiseType': 'pink',
    'volume': 60,
    'sensitivity': 'normal',
    'ledColor': '#E88FAD',
    'isSystemMode': true,
  },
  {
    'id': 'custom',
    'name': '커스텀 모드',
    'noiseType': 'brown',
    'volume': 40,
    'sensitivity': 'normal',
    'ledColor': '#E6007E',
    'isSystemMode': false,
  },
];
