part of hrgg_app;

final AudioIntelligenceService audioIntelligence =
    PersistingAudioIntelligenceService(MockAudioIntelligenceService());

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _scheduleClock;

  @override
  void initState() {
    super.initState();
    _scheduleClock = Timer.periodic(
      const Duration(minutes: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _scheduleClock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: appDataService.watchSettings(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? {};
        final puriSoundEnabled =
            settings['puriSoundEnabled'] as bool? ?? true;
        final autoMasking = settings['autoMasking'] as bool? ?? true;
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: appDataService.watchSchedules(),
          builder: (context, scheduleSnapshot) {
            final scheduledMode =
                _currentScheduledMode(scheduleSnapshot.data?.docs ?? []);
            final effectiveModeId = !puriSoundEnabled
                ? 'power_off'
                : autoMasking
                ? 'ai_auto'
                : scheduledMode?.modeId ??
                    settings['activeModeId'] as String? ??
                    'sleep';
            final effectiveModeName = !puriSoundEnabled
                ? 'LG PuriSound 꺼짐'
                : autoMasking
                ? 'AI 자동 모드'
                : scheduledMode?.modeName ??
                    settings['activeModeName'] as String? ??
                    '수면 모드';
            final autoNoise = puriSoundEnabled && autoMasking;
            final configuredType = scheduledMode?.noiseType ??
                settings['noiseType'] as String? ??
                'brown';
            final configuredVersion =
                settings['noiseVersion'] as int? ?? 1;
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
              stream: appDataService.watchPrimaryDevice(),
              builder: (context, deviceSnapshot) {
                final deviceData = deviceSnapshot.data?.data() ?? {};
                return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
                  stream: appDataService.watchLatestNoiseEvent(),
                  builder: (context, latestNoiseEventSnapshot) {
                    final latestNoiseEvent =
                        latestNoiseEventSnapshot.data?.data() ?? {};
                    return StreamBuilder<AudioInsight>(
          stream: audioIntelligence.insights,
          initialData: const AudioInsight(
              db: 42,
              frequencyHz: 64,
              label: '충격음 감지 · 저주파',
              maskingType: NoiseMaskingType.brown,
              confidence: 0.86,
              shouldMask: true),
          builder: (context, snapshot) {
            final insight = snapshot.data!;
            final displayedDb =
                (deviceData['decibel'] as num?)?.toDouble() ??
                insight.db;
            final latestNoiseType =
                latestNoiseEvent['noiseType'] as String?;
            final latestMaskingRequired =
                latestNoiseEvent['maskingRequired'] as bool?;
            final activeType =
                !puriSoundEnabled
                    ? 'off'
                    : autoNoise
                        ? (latestNoiseType ?? insight.maskingType.name)
                        : configuredType;
            final activeColor = noiseTypeColor(activeType);
            final activeLabel = noiseTypeLabel(activeType);
            final activeVersionLabel =
                autoNoise ? activeLabel : '$activeLabel $configuredVersion';
            final isPlaybackActive = !puriSoundEnabled
                ? false
                : autoNoise
                    ? (latestMaskingRequired ?? insight.shouldMask)
                    : true;
            final maskingStatusLabel =
                '${autoMasking ? activeLabel : activeVersionLabel} · ${isPlaybackActive ? '재생 중' : '재생 안 함'}';
            final shouldShowMaskingChip = puriSoundEnabled && (autoMasking || !autoNoise);
        return HrggScaffold(
          title: 'LG PuriSound',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ThemeIconButton(),
              IconButton(
                tooltip: '알림 설정',
                onPressed: () =>
                    pushScreen(context, const NotificationsScreen()),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          children: [
            const StatusChip(
                label: 'PuriSound Speaker · 연결됨',
                color: HrggColors.active,
                icon: Icons.circle),
            const SizedBox(height: 12),
            modeBanner(
              context,
              effectiveModeId,
              effectiveModeName,
              () => widget.onSelectTab(2),
              scheduled: puriSoundEnabled && !autoMasking && scheduledMode != null,
            ),
            const SizedBox(height: 14),
            HrggCard(
              child: Column(
                children: [
                  SizedBox(
                    height: 190,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: AnimatedNoiseBlob(
                            db: displayedDb,
                            color: shouldShowMaskingChip && isPlaybackActive
                                ? activeColor
                                : context.c.textTertiary,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${displayedDb.round()} dB',
                                style: context.t.displayLarge
                                    ?.copyWith(fontSize: 42)),
                            Text(
                                '현재 소음 수준 · 신뢰도 ${(insight.confidence * 100).round()}%',
                                style: context.t.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (shouldShowMaskingChip) ...[
                    const SizedBox(height: 14),
                    StatusChip(
                        label: maskingStatusLabel,
                        color: isPlaybackActive ? activeColor : HrggColors.inactive,
                        soft: true,
                        icon: isPlaybackActive
                            ? Icons.graphic_eq_rounded
                            : Icons.volume_off_rounded),
                  ],
                  const Divider(height: 28),
                  Row(
                    children: [
                      Expanded(
                          child: Text('자동 마스킹',
                              style: context.t.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700))),
                      Switch(
                        value: puriSoundEnabled && autoMasking,
                        activeTrackColor: HrggColors.primary,
                        onChanged: puriSoundEnabled ? (v) async {
                          await appDataService.saveSettings({
                            'autoMasking': v,
                            'ledMode': v ? 'auto' : 'off',
                            if (v) 'ledColor': '#C97B3A',
                            'autoNoiseSelection': FieldValue.delete(),
                          });
                          if (!context.mounted) return;
                          showAppSnack(
                              context, v ? 'AI 자동 모드를 시작했습니다' : '수동 모드로 전환했습니다');
                        } : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(children: [
              quickAction(context, Icons.schedule_rounded, '스케줄',
                  () => pushScreen(context, const ScheduleScreen())),
              quickAction(context, Icons.graphic_eq_rounded, '노이즈',
                  () => pushScreen(context, const NoiseSelectScreen())),
              quickAction(context, Icons.bar_chart_rounded, '리포트',
                  () => widget.onSelectTab(3)),
              quickAction(context, Icons.lightbulb_outline_rounded, 'LED 설정',
                  () => pushScreen(context, const LEDScreen())),
            ]),
            const SizedBox(height: 14),
            aiBanner(
                context, () => pushScreen(context, const AIRecommendScreen())),
          ],
        );
          },
        );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

({String modeId, String modeName, String? noiseType})? _currentScheduledMode(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> schedules) {
  final now = DateTime.now();
  final currentMinutes = now.hour * 60 + now.minute;
  final today = _weekdayLabel(now.weekday);
  final yesterday =
      _weekdayLabel(now.subtract(const Duration(days: 1)).weekday);

  for (final schedule in schedules) {
    final data = schedule.data();
    if (data['enabled'] == false) continue;
    final days = (data['days'] as List<dynamic>? ?? []).cast<String>();
    final start = data['startMinutes'] as int? ?? 0;
    final end = data['endMinutes'] as int? ?? 0;
    final active = start < end
        ? days.contains(today) &&
            currentMinutes >= start &&
            currentMinutes < end
        : start > end
            ? (days.contains(today) && currentMinutes >= start) ||
                (days.contains(yesterday) && currentMinutes < end)
            : days.contains(today);
    if (!active) continue;
    return (
      modeId: data['modeId'] as String? ?? 'sleep',
      modeName: data['modeName'] as String? ?? '수면 모드',
      noiseType: data['noiseType'] as String?,
    );
  }
  return null;
}

String noiseTypeLabel(String type) => switch (type) {
      'brown' => '브라운 노이즈',
      'pink' => '핑크 노이즈',
      'white' => '화이트 노이즈',
      'auto' => 'AI 자동 선택',
      'off' => '출력 중지',
      _ => '화이트 노이즈',
    };

Color noiseTypeColor(String type) => switch (type) {
      'brown' => HrggColors.brownNoise,
      'pink' => HrggColors.pinkNoise,
      'white' => HrggColors.whiteNoise,
      'off' => HrggColors.inactive,
      _ => HrggColors.primary,
    };

class MonitorScreen extends StatelessWidget {
  const MonitorScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
      stream: appDataService.watchPrimaryDevice(),
      builder: (context, deviceSnapshot) {
        final deviceData = deviceSnapshot.data?.data() ?? {};
        return StreamBuilder<AudioInsight>(
          stream: audioIntelligence.insights,
          initialData: const AudioInsight(
              db: 48,
              frequencyHz: 64,
              label: '충격음 감지 · 저주파',
              maskingType: NoiseMaskingType.brown,
              confidence: 0.86,
              shouldMask: true),
          builder: (context, snapshot) {
            final insight = snapshot.data!;
            final displayedDb =
                (deviceData['decibel'] as num?)?.toDouble() ?? insight.db;
            return HrggScaffold(
              title: '실시간 모니터링',
              children: [
                HrggCard(
                  child: SizedBox(
                    height: 190,
                    child: CustomPaint(
                      painter: GaugePainter(context, displayedDb),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${displayedDb.round()} dB',
                                style: context.t.displayLarge),
                            StatusChip(
                                label:
                                    '${insight.label} (${insight.frequencyHz.round()}Hz)',
                                color: insight.color,
                                soft: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SectionHeader('주파수 분석'),
                HrggCard(
                    child: Row(children: [
                  frequencyBars(context, '저주파', HrggColors.brownNoise,
                      insight.frequencyHz < 200),
                  frequencyBars(context, '중주파', HrggColors.pinkNoise,
                      insight.frequencyHz >= 200 && insight.frequencyHz < 2000),
                  frequencyBars(context, '고주파', HrggColors.whiteNoise,
                      insight.frequencyHz >= 2000)
                ])),
                const SectionHeader('개입 판단 상태'),
                HrggCard(
                    child: Text(
                        insight.shouldMask
                            ? '소음 지속 5초 도달 · ${insight.maskingLabel} 시작'
                            : '기준치 미만 · 이벤트 기록만 수행',
                        style: context.t.bodyMedium?.copyWith(
                            color: HrggColors.primary,
                            fontWeight: FontWeight.w700))),
                const SectionHeader('최근 이벤트'),
                const RecentNoiseEvents(),
              ],
            );
          },
        );
      },
    );
  }
}

Widget modeBanner(
    BuildContext context, String modeId, String modeName, VoidCallback onTap,
    {bool scheduled = false}) {
  final (colors, icon) = switch (modeId) {
    'power_off' => (
        const [Color(0xFF5C5C60), Color(0xFF2C2C2E)],
        Icons.power_settings_new_rounded
      ),
    'ai_auto' => (
        const [Color(0xFF3A0F2A), Color(0xFFE6007E)],
        Icons.auto_awesome_rounded
      ),
    'baby' => (
        const [Color(0xFFF9C6D0), Color(0xFFF0A0B8)],
        Icons.child_care_rounded
      ),
    'focus' => (
        const [Color(0xFF1A3A4A), Color(0xFF0D2030)],
        Icons.center_focus_strong_rounded
      ),
    'traffic' => (
        const [Color(0xFF3D3D5C), Color(0xFF25253D)],
        Icons.directions_car_rounded
      ),
    'custom' => (
        const [HrggColors.primary, Color(0xFFC0006A)],
        Icons.edit_rounded
      ),
    _ => (
        const [Color(0xFF3A2D6B), Color(0xFF1A1440)],
        Icons.nights_stay_rounded
      ),
  };
  final foreground = modeId == 'baby' ? const Color(0xFF1A1A1A) : Colors.white;
  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(16)),
    child: Row(children: [
      Icon(icon, color: foreground),
      const SizedBox(width: 10),
      Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$modeName 활성 중',
                  style: context.t.titleMedium?.copyWith(color: foreground)),
              if (scheduled)
                Text('저장된 스케줄로 자동 적용됨',
                    style: context.t.labelSmall?.copyWith(color: foreground)),
            ],
          )),
      TextButton(
          onPressed: onTap,
          child: Text('모드 변경', style: TextStyle(color: foreground)))
    ]),
  );
}

Widget quickAction(
    BuildContext context, IconData icon, String label, VoidCallback onTap) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: HrggCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        onTap: onTap,
        child: Column(children: [
          CircleAvatar(
              radius: 20,
              backgroundColor: context.c.elevated,
              child: Icon(icon, color: HrggColors.primary, size: 20)),
          const SizedBox(height: 7),
          Text(label, style: context.t.labelSmall)
        ]),
      ),
    ),
  );
}

Widget aiBanner(BuildContext context, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [HrggColors.primary, Color(0xFFC0006A)]),
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(
            child: Text('오늘 밤 11시, 충격음 반복 예상 - 브라운 노이즈 스케줄을 추천합니다',
                style: context.t.bodyMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w700))),
        const Icon(Icons.chevron_right_rounded, color: Colors.white)
      ]),
    ),
  );
}

List<Widget> recentEvents(BuildContext context) {
  final rows = [
    ('브라운 노이즈', '2분 전', '48 dB', HrggColors.brownNoise),
    ('핑크 노이즈', '18분 전', '44 dB', HrggColors.pinkNoise),
    ('화이트 노이즈', '1시간 전', '39 dB', HrggColors.whiteNoise),
  ];
  return rows.map((e) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HrggCard(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          CircleAvatar(radius: 5, backgroundColor: e.$4),
          const SizedBox(width: 10),
          Expanded(
              child: Text(e.$1,
                  style: context.t.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700))),
          Text('${e.$2} · ${e.$3}', style: context.t.bodySmall)
        ]),
      ),
    );
  }).toList();
}

class RecentNoiseEvents extends StatelessWidget {
  const RecentNoiseEvents({super.key});

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Column(children: recentEvents(context));
    }
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appDataService.watchRecentNoiseEvents(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return Column(children: recentEvents(context));
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final type = data['noiseType'] as String? ?? 'unknown';
            final color = switch (type) {
              'brown' => HrggColors.brownNoise,
              'pink' => HrggColors.pinkNoise,
              _ => HrggColors.whiteNoise,
            };
            final label = switch (type) {
              'brown' => '브라운 노이즈',
              'pink' => '핑크 노이즈',
              _ => '화이트 노이즈',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: HrggCard(
                padding: const EdgeInsets.all(13),
                child: Row(children: [
                  CircleAvatar(radius: 5, backgroundColor: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(label,
                        style: context.t.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text('${(data['db'] as num?)?.round() ?? 0} dB',
                      style: context.t.bodySmall),
                ]),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

Widget frequencyBars(
    BuildContext context, String label, Color color, bool active) {
  return Expanded(
    child: Column(
      children: [
        SizedBox(
          height: 86,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final h = [36.0, 58.0, 74.0, 52.0, 42.0][i] * (active ? 1 : 0.55);
              return Container(
                  width: 8,
                  height: h,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                      color: (active ? color : context.c.textTertiary)
                          .withValues(alpha: active ? 0.9 : 0.35),
                      borderRadius: BorderRadius.circular(8)));
            }),
          ),
        ),
        Text(label,
            style: context.t.labelSmall?.copyWith(
                color: active ? color : context.c.textSecondary,
                fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
