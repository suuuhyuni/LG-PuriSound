part of hrgg_app;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final Set<String> selectedDays = {'월', '화', '수', '목', '금'};
  String modeId = 'sleep';
  String mode = '수면 모드';
  TimeOfDay sleepTime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay wakeTime = const TimeOfDay(hour: 7, minute: 0);

  TimeOfDay _shiftTime(TimeOfDay time, int minutes) {
    final total = (time.hour * 60 + time.minute + minutes) % (24 * 60);
    final normalized = total < 0 ? total + 24 * 60 : total;
    return TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? sleepTime : wakeTime,
      helpText: isSleep ? '시작 시간 설정' : '종료 시간 설정',
    );
    if (picked == null) return;
    setState(() {
      if (isSleep) {
        sleepTime = picked;
      } else {
        wakeTime = picked;
      }
    });
  }

  Future<void> _selectMode() async {
    final selected = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: context.c.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('연동 모드 선택', style: context.t.titleMedium),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: appDataService.watchModes(),
                  builder: (context, snapshot) {
                    final docs = (snapshot.data?.docs ?? [])
                        .where((doc) => const [
                              'sleep',
                              'baby',
                              'focus',
                              'traffic'
                            ].contains(doc.id))
                        .toList();
                    if (docs.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return SizedBox(
                      height: math.min(
                          MediaQuery.sizeOf(context).height * 0.55, 520),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: context.c.border),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data();
                          final name =
                              data['name'] as String? ?? '이름 없는 모드';
                          final type =
                              data['noiseType'] as String? ?? 'brown';
                          final volume = data['volume'] as int? ?? 40;
                          final selectedMode = doc.id == modeId;
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  noiseTypeColor(type).withValues(alpha: 0.16),
                              child: Icon(
                                doc.id == 'custom'
                                    ? Icons.edit_rounded
                                    : Icons.graphic_eq_rounded,
                                color: noiseTypeColor(type),
                              ),
                            ),
                            title: Text(name, style: context.t.bodyMedium),
                            subtitle: Text(
                                '${noiseTypeLabel(type)} · $volume%',
                                style: context.t.bodySmall),
                            trailing: Icon(
                              selectedMode
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              color: selectedMode
                                  ? HrggColors.primary
                                  : context.c.textTertiary,
                            ),
                            onTap: () => Navigator.of(sheetContext).pop({
                              'id': doc.id,
                              'name': name,
                            }),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || !mounted) return;
    setState(() {
      modeId = selected['id']!;
      mode = selected['name']!;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '스케줄 설정',
      leadingBack: true,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['월', '화', '수', '목', '금', '토', '일'].map((d) {
            return GestureDetector(
              onTap: () => setState(() => selectedDays.contains(d)
                  ? selectedDays.remove(d)
                  : selectedDays.add(d)),
              child: StatusChip(
                  label: d,
                  color: HrggColors.primary,
                  soft: !selectedDays.contains(d)),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        HrggCard(
          child: Row(children: [
            Expanded(
                child: timeBlock(context, '시작 시간', sleepTime,
                    onIncrease: () =>
                        setState(() => sleepTime = _shiftTime(sleepTime, 30)),
                    onDecrease: () =>
                        setState(() => sleepTime = _shiftTime(sleepTime, -30)),
                    onTap: () => _pickTime(true))),
            Icon(Icons.arrow_forward_rounded, color: context.c.textTertiary),
            Expanded(
                child: timeBlock(context, '종료 시간', wakeTime,
                    onIncrease: () =>
                        setState(() => wakeTime = _shiftTime(wakeTime, 30)),
                    onDecrease: () =>
                        setState(() => wakeTime = _shiftTime(wakeTime, -30)),
                    onTap: () => _pickTime(false)))
          ]),
        ),
        const SizedBox(height: 12),
        settingRow(context, '연동 모드', mode, onTap: _selectMode),
        const SectionHeader('활성 스케줄'),
        const ScheduleList(),
        const SizedBox(height: 18),
        PrimaryButton(
            label: '스케줄 저장',
            onPressed: () async {
              await appDataService.saveSchedule(
                days: selectedDays.toList(),
                start: sleepTime,
                end: wakeTime,
                modeId: modeId,
                modeName: mode,
              );
              if (!context.mounted) return;
              showAppSnack(context,
                  '${selectedDays.length}개 요일 · ${formatTime(context, sleepTime)}-${formatTime(context, wakeTime)} 스케줄을 저장했습니다');
            }),
      ],
    );
  }
}

class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appDataService.watchSchedules(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return HrggCard(
            child: Text('등록된 스케줄이 없습니다.', style: context.t.bodyMedium),
          );
        }
        return Column(
          children: docs.map((doc) {
            final data = doc.data();
            final days = (data['days'] as List<dynamic>? ?? []).join('·');
            final start = _minutesLabel(data['startMinutes'] as int? ?? 0);
            final end = _minutesLabel(data['endMinutes'] as int? ?? 0);
            return scheduleRow(
              context,
              days,
              '$start - $end',
              data['modeName'] as String? ?? '직접 설정',
              onDelete: () => appDataService.deleteSchedule(doc.id),
            );
          }).toList(),
        );
      },
    );
  }
}

String _minutesLabel(int minutes) {
  final hour = (minutes ~/ 60).toString().padLeft(2, '0');
  final minute = (minutes % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

class AIRecommendScreen extends StatefulWidget {
  const AIRecommendScreen({super.key});

  @override
  State<AIRecommendScreen> createState() => _AIRecommendScreenState();
}

class _AIRecommendScreenState extends State<AIRecommendScreen> {
  Future<AiRecommendationAnalysis>? _analysisFuture;

  @override
  void initState() {
    super.initState();
    _analysisFuture = _loadAnalysis();
  }

  Future<AiRecommendationAnalysis> _loadAnalysis() =>
      appDataService.generateAiRecommendationAnalysis(
        periodDays: 7,
      );

  Future<void> _saveRecommendation(
    BuildContext context, {
    required AiScheduleRecommendation recommendation,
  }) async {
    await appDataService.saveSchedule(
      days: recommendation.days,
      start: TimeOfDay(
        hour: recommendation.startMinutes ~/ 60,
        minute: recommendation.startMinutes % 60,
      ),
      end: TimeOfDay(
        hour: recommendation.endMinutes ~/ 60,
        minute: recommendation.endMinutes % 60,
      ),
      modeId: recommendation.modeId,
      modeName: recommendation.modeName,
      source: 'aiRecommendation',
    );
    await appDataService.updateAiRecommendationStatus(
        recommendation.recommendationId, 'accepted');
    if (!context.mounted) return;
    showAppSnack(
      context,
      '${recommendation.days.join('·')} ${_minutesLabel(recommendation.startMinutes)}-${_minutesLabel(recommendation.endMinutes)} · ${recommendation.modeName} 스케줄을 저장했습니다',
      icon: Icons.schedule_rounded,
    );
    setState(() {
      _analysisFuture = _loadAnalysis();
    });
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: 'AI 추천 스케줄',
      leadingBack: true,
      children: [
        warningBanner(
            context, '최근 반복 소음 패턴을 기반으로 추천 스케줄을 생성합니다', HrggColors.primary,
            icon: Icons.auto_awesome_rounded),
        const SizedBox(height: 14),
        FutureBuilder<AiRecommendationAnalysis>(
          future: _analysisFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final analysis = snapshot.data;
            if (analysis == null || analysis.recommendations.isEmpty) {
              return HrggCard(
                child: Text(
                  '추천할 반복 패턴이 아직 충분하지 않습니다. 소음 이벤트를 더 수집한 뒤 다시 분석해주세요.',
                  style: context.t.bodyMedium,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '최근 분석 이벤트 ${analysis.totalEvents}건',
                  style: context.t.bodySmall
                      ?.copyWith(color: context.c.textSecondary),
                ),
                const SizedBox(height: 12),
                ...analysis.recommendations.map(
                  (recommendation) => recommendationCard(
                    context,
                    recommendation,
                    onRegister: () =>
                        _saveRecommendation(context, recommendation: recommendation),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

String _weekdayLabel(int weekday) =>
    const ['월', '화', '수', '목', '금', '토', '일'][weekday - 1];

class ReportScreen extends StatefulWidget {
  const ReportScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int period = 0;

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '소음 리포트',
      children: [
        segmented(
            context, ['7일', '30일'], period, (v) => setState(() => period = v)),
        const SizedBox(height: 14),
        warningBanner(
          context,
          '${period == 0 ? '7일' : '30일'} 기준 소음 데이터와 반복 패턴을 분석합니다',
          HrggColors.primary,
          icon: Icons.insights_rounded,
        ),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.5,
          children: [
            statCard(context, '총 소음 이벤트', '47회'),
            statCard(context, '평균 야간 소음', '39 dB'),
            statCard(context, '최악의 날', '화요일'),
            statCard(context, '가장 조용한 날', '일요일')
          ],
        ),
        const SectionHeader('요일별 소음 빈도'),
        HrggCard(child: barChart(context)),
        const SectionHeader('시간대별 소음 분포'),
        HrggCard(child: timeHeatmap(context)),
        const SizedBox(height: 18),
        SecondaryButton(
            label: 'PDF로 저장',
            onPressed: () async {
              await appDataService.generateReport(days: period == 0 ? 7 : 30);
              if (!context.mounted) return;
              showAppSnack(
                  context, '${period == 0 ? '7일' : '30일'} 리포트를 DB에 생성했습니다',
                  icon: Icons.download_done_rounded);
            }),
      ],
    );
  }
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseAuth.instance.currentUser == null
          ? null
          : appDataService.watchProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data?.data();
        final authUser = FirebaseAuth.instance.currentUser;
        final name = profile?['displayName'] as String? ??
            authUser?.displayName ??
            'PuriSound 사용자';
        final email =
            profile?['email'] as String? ?? authUser?.email ?? '로그인 정보 없음';
        return HrggScaffold(
          title: '마이페이지',
          trailing: const ThemeIconButton(),
          children: [
            HrggCard(
              child: Row(children: [
                CircleAvatar(
                    radius: 28,
                    backgroundColor: HrggColors.primary.withValues(alpha: 0.12),
                child: Text(name.trim().isEmpty ? 'P' : name.characters.first,
                        style: context.t.headlineMedium
                            ?.copyWith(color: HrggColors.primary))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name, style: context.t.titleMedium),
                      Text(email, style: context.t.bodySmall)
                    ])),
                TextButton(
                  onPressed: () => showInfoDialog(
                      context, '프로필 수정', '프로필 이름과 이메일 변경 기능을 준비 중입니다.'),
                  child: const Text('프로필 수정',
                      style: TextStyle(color: HrggColors.primary)),
                ),
              ]),
            ),
            const SectionHeader('서비스 설정'),
            serviceRow(context, '마스킹 사운드 설정', Icons.graphic_eq_rounded,
                () => pushScreen(context, const NoiseSelectScreen())),
            serviceRow(context, '모드 관리', Icons.grid_view_rounded,
                () => onSelectTab(2)),
            serviceRow(context, '스케줄 관리', Icons.schedule_rounded,
                () => pushScreen(context, const ScheduleScreen())),
            serviceRow(context, '민감도 설정', Icons.tune_rounded,
                () => pushScreen(context, const SensitivityScreen())),
            serviceRow(context, 'LED 설정', Icons.lightbulb_outline_rounded,
                () => pushScreen(context, const LEDScreen())),
            serviceRow(context, '알림 설정', Icons.notifications_none_rounded,
                () => pushScreen(context, const NotificationsScreen())),
            serviceRow(context, '디바이스 관리', Icons.speaker_rounded,
                () => pushScreen(context, const DeviceManageScreen())),
            const SectionHeader('화면 설정'),
            HrggCard(
                child: Row(children: [
              Expanded(
                  child: Text('다크 모드',
                      style: context.t.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700))),
              const ThemeIconButton()
            ])),
            const SectionHeader('앱 정보'),
            ...['앱 버전 v1.0.0', '개인정보처리방침', '이용약관', '문의하기'].map((e) =>
                serviceRow(context, e, Icons.info_outline_rounded,
                    () => showInfoDialog(context, e, '$e 관련 정보를 표시합니다.'))),
            Row(children: [
              Expanded(
                  child: TextButton(
                      onPressed: () => showLogoutSheet(context),
                      child: const Text('로그아웃',
                          style: TextStyle(color: HrggColors.error)))),
              Expanded(
                  child: TextButton(
                      onPressed: () => showDeleteAccountDialog(context),
                      child: const Text('회원탈퇴',
                          style: TextStyle(color: HrggColors.error)))),
            ]),
          ],
        );
      },
    );
  }
}

class LEDScreen extends StatefulWidget {
  const LEDScreen({super.key});

  @override
  State<LEDScreen> createState() => _LEDScreenState();
}

class _LEDScreenState extends State<LEDScreen> {
  static const _offWhiteColor = Color(0xFFFFFFFF);
  int colorMode = 0;
  double brightness = 35;
  Color selectedColor = const Color(0xFFE88FAD);
  Color linkedModeColor = HrggColors.sleep;
  String linkedModeName = '수면 모드';
  bool autoMaskingEnabled = true;
  String ledMode = 'auto';

  static const manualColors = [
    Color(0xFFC97B3A),
    Color(0xFFE88FAD),
    Color(0xFFF9C6D0),
    Color(0xFFE8F0FE),
    Color(0xFF7B8FA1),
    Color(0xFF34C759),
    Color(0xFF3A2D6B),
    Color(0xFFE6007E),
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await appDataService.getSettings();
    final activeModeId = settings['activeModeId'] as String? ?? 'sleep';
    final activeMode = await appDataService.getMode(activeModeId);
    if (!mounted) return;
    final color = _colorFromHex(settings['ledColor'] as String?);
    final modeColor = _colorFromHex(activeMode?['ledColor'] as String?);
    final autoMasking = settings['autoMasking'] as bool? ?? true;
    final storedLedMode = settings['ledMode'] as String?;
    setState(() {
      autoMaskingEnabled = autoMasking;
      ledMode = autoMasking
          ? 'auto'
          : (storedLedMode == 'manual' ? 'manual' : 'off');
      colorMode = switch (ledMode) {
        'manual' => 1,
        'off' => 2,
        _ => 0,
      };
      brightness = ledMode == 'off'
          ? 0
          : (settings['ledBrightness'] as num?)?.toDouble() ?? 35;
      if (color != null) selectedColor = color;
      if (modeColor != null) linkedModeColor = modeColor;
      linkedModeName = activeMode?['name'] as String? ??
          settings['activeModeName'] as String? ??
          '수면 모드';
    });
  }

  Color get previewColor {
    if (ledMode == 'off') return _offWhiteColor;
    if (ledMode == 'manual') return selectedColor;
    return const Color(0xFFC97B3A);
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(title: 'LED 설정', leadingBack: true, children: [
      Center(
          child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: previewColor.withValues(alpha: brightness / 100),
                  boxShadow: [
                    BoxShadow(
                        color: previewColor.withValues(alpha: brightness / 180),
                        blurRadius: 34,
                        spreadRadius: 10)
                  ]))),
      const SizedBox(height: 18),
      segmented(context, ['자동', '수동', '끄기'], colorMode, (index) {
        if (index == 0) {
          if (!autoMaskingEnabled) {
            showAppSnack(context, '자동 마스킹을 켜야 LED 자동 모드를 사용할 수 있습니다');
            return;
          }
          setState(() {
            ledMode = 'auto';
            colorMode = 0;
          });
          return;
        }
        if (index == 1) {
          setState(() {
            ledMode = 'manual';
            colorMode = 1;
            if (brightness == 0) brightness = 35;
          });
          showAppSnack(context, 'LED를 수동 모드로 전환했습니다');
          return;
        }
        setState(() {
          ledMode = 'off';
          colorMode = 2;
          brightness = 0;
          selectedColor = _offWhiteColor;
        });
        showAppSnack(context, 'LED를 끄도록 설정했습니다');
      }),
      const SizedBox(height: 12),
      settingRow(
          context,
          '현재 색상',
          ledMode == 'auto'
              ? '따뜻한 주황'
              : ledMode == 'manual'
                  ? '사용자 선택'
                  : '꺼짐'),
      if (ledMode == 'manual') ...[
        const SectionHeader('색상 선택'),
        HrggCard(
          child: Wrap(
            spacing: 14,
            runSpacing: 14,
            children: manualColors.map((color) {
              final selected = selectedColor == color;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedColor = color;
                  });
                  showAppSnack(context, 'LED 색상을 변경했습니다');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: selected
                            ? HrggColors.primary
                            : context.c.border,
                        width: selected ? 3 : 1),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 2)
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: selected
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 20)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ],
      valueSlider(context, brightness, (v) => setState(() => brightness = v),
          '${brightness.round()}%'),
      const SizedBox(height: 18),
      PrimaryButton(
          label: '저장',
          onPressed: () async {
            final savedColor = switch (ledMode) {
              'auto' => const Color(0xFFC97B3A),
              'off' => _offWhiteColor,
              _ => selectedColor,
            };
            final savedBrightness = switch (ledMode) {
              'off' => 0,
              _ => brightness.round(),
            };
            await appDataService.saveSettings({
              'ledMode': ledMode,
              'ledColor':
                  '#${savedColor.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
              'ledBrightness': savedBrightness,
            });
            if (context.mounted) showAppSnack(context, 'LED 설정을 저장했습니다');
          }),
    ]);
  }
}

class SensitivityScreen extends StatefulWidget {
  const SensitivityScreen({super.key});

  @override
  State<SensitivityScreen> createState() => _SensitivityScreenState();
}

class _SensitivityScreenState extends State<SensitivityScreen> {
  double sensitivity = 55;
  bool adaptive = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await appDataService.getSettings();
    if (!mounted) return;
    setState(() {
      sensitivity = switch (settings['sensitivity']) {
        'low' => 20,
        'high' => 85,
        _ => 55,
      };
      adaptive = settings['adaptiveEnabled'] as bool? ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(title: '개입 민감도 설정', leadingBack: true, children: [
      warningBanner(
          context, '소음이 몇 초 이상 지속될 때 마스킹을 시작할지 설정합니다', HrggColors.primary,
          icon: Icons.tune_rounded),
      const SectionHeader('민감도'),
      valueSlider(
          context,
          sensitivity,
          (v) => setState(() => sensitivity = v),
          '현재: ${sensitivity < 34 ? '10' : sensitivity < 67 ? '5' : '3'}초 이상'),
      HrggCard(
          child: Text(
              '${sensitivity < 34 ? '낮음' : sensitivity < 67 ? '보통' : '높음'} 모드 · 지속 소음 또는 반복 패턴 감지 시 마스킹 시작.',
              style: context.t.bodyMedium)),
      const SizedBox(height: 12),
      HrggCard(
          child: Row(children: [
        Expanded(
            child: Text('패턴 학습 기반 자동 조정',
                style: context.t.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
        Switch(
            value: adaptive,
            activeTrackColor: HrggColors.primary,
            onChanged: (v) => setState(() => adaptive = v))
      ])),
      const SizedBox(height: 20),
      PrimaryButton(
          label: '저장',
          onPressed: () async {
            await appDataService.saveSettings({
              'sensitivity': sensitivity < 34
                  ? 'low'
                  : sensitivity < 67
                      ? 'normal'
                      : 'high',
              'adaptiveEnabled': adaptive,
            });
            if (!context.mounted) return;
            showAppSnack(context, '민감도 설정을 저장했습니다');
            Navigator.of(context).pop();
          }),
    ]);
  }
}

class DeviceManageScreen extends StatelessWidget {
  const DeviceManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(title: '디바이스 관리', leadingBack: true, children: [
      warningBanner(context, '스피커 출력 오류 감지 - 탭하여 원인 확인', HrggColors.warning),
      const SizedBox(height: 12),
      HrggCard(
          child: Row(children: [
        deviceIllustration(context, 82),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('PuriSound Speaker 001', style: context.t.titleMedium),
          Text('Model H-01 · firmware v1.2.3', style: context.t.bodySmall),
          const SizedBox(height: 8),
          const StatusChip(
              label: 'Wi-Fi 연결됨', color: HrggColors.active, soft: true)
        ]))
      ])),
      const SectionHeader('설정'),
      settingRow(context, '디바이스 이름 변경', '',
          onTap: () => showInfoDialog(
              context, '디바이스 이름 변경', '현재 이름은 PuriSound Speaker 001입니다.')),
      settingRow(context, 'Local Zone 재설정', '',
          onTap: () => pushScreen(context, const InitialSetupScreen())),
      settingRow(context, '마이크·스피커 권한 재확인', '',
          onTap: () => showAppSnack(context, '마이크·스피커 권한이 정상입니다')),
      settingRow(context, '디바이스 재시작', '',
          onTap: () => showAppSnack(context, '디바이스 재시작을 요청했습니다')),
      settingRow(context, '초기화 (공장 설정 복원)', '주의',
          onTap: () =>
              showInfoDialog(context, '공장 초기화', '디바이스의 모든 로컬 설정이 삭제됩니다.')),
      const SizedBox(height: 18),
      SecondaryButton(
          label: '디바이스 추가',
          onPressed: () => pushScreen(context, const DeviceRegisterScreen())),
    ]);
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final values = [true, true, true, false];

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await appDataService.getSettings();
    final notifications =
        (settings['notifications'] as Map<dynamic, dynamic>?) ?? {};
    if (!mounted) return;
    setState(() {
      values[0] = notifications['quietHoursNoise'] as bool? ?? true;
      values[1] = notifications['thresholdExceeded'] as bool? ?? true;
      values[2] = notifications['deviceDisconnected'] as bool? ?? true;
      values[3] = notifications['weeklyReportReady'] as bool? ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      '지정 시간 이후 소음 감지 시',
      '소음이 기준치 초과 시',
      '디바이스 연결 끊김 시',
      '주간 리포트 준비 완료 시'
    ];
    return HrggScaffold(title: '알림 설정', leadingBack: true, children: [
      ...List.generate(
          labels.length,
          (i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HrggCard(
                    child: Row(children: [
                  Expanded(
                      child: Text(labels[i],
                          style: context.t.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700))),
                  Switch(
                      value: values[i],
                      activeTrackColor: HrggColors.primary,
                      onChanged: (v) => setState(() => values[i] = v))
                ])),
              )),
      const SectionHeader('미리보기'),
      HrggCard(
          color: context.c.elevated,
          child: Text(
              'LG PuriSound · 방금\n소음 감지 - 오후 11:02 · 충격음 48dB · 브라운 노이즈 마스킹 시작',
              style: context.t.bodyMedium)),
      const SizedBox(height: 18),
      PrimaryButton(
          label: '저장',
          onPressed: () async {
            await appDataService.saveSettings({
              'notifications': {
                'quietHoursNoise': values[0],
                'thresholdExceeded': values[1],
                'deviceDisconnected': values[2],
                'weeklyReportReady': values[3],
              }
            });
            if (context.mounted) showAppSnack(context, '알림 설정을 저장했습니다');
          }),
    ]);
  }
}

String formatTime(BuildContext context, TimeOfDay time) {
  return MaterialLocalizations.of(context)
      .formatTimeOfDay(time, alwaysUse24HourFormat: true);
}

Color? _colorFromHex(String? value) {
  if (value == null) return null;
  final hex = value.replaceFirst('#', '');
  if (hex.length != 6) return null;
  return Color(int.parse('FF$hex', radix: 16));
}

Widget timeBlock(
  BuildContext context,
  String title,
  TimeOfDay time, {
  required VoidCallback onIncrease,
  required VoidCallback onDecrease,
  required VoidCallback onTap,
}) {
  return Column(children: [
    Text(title, style: context.t.bodySmall),
    IconButton(
        tooltip: '$title 30분 증가',
        visualDensity: VisualDensity.compact,
        onPressed: onIncrease,
        icon: const Icon(Icons.keyboard_arrow_up_rounded)),
    InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Text(formatTime(context, time),
            style: context.t.displayLarge?.copyWith(fontSize: 26)),
      ),
    ),
    IconButton(
        tooltip: '$title 30분 감소',
        visualDensity: VisualDensity.compact,
        onPressed: onDecrease,
        icon: const Icon(Icons.keyboard_arrow_down_rounded))
  ]);
}

Widget scheduleRow(BuildContext context, String days, String time, String mode,
    {required Future<void> Function() onDelete}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: HrggCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          StatusChip(label: days, color: HrggColors.primary, soft: true),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(time,
                    style: context.t.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(mode, style: context.t.bodySmall)
              ])),
          IconButton(
              onPressed: () => showAppSnack(context, '상단 시간 설정에서 수정 후 저장하세요',
                  icon: Icons.edit_rounded),
              icon: const Icon(Icons.edit_outlined, size: 19)),
          IconButton(
              onPressed: () async {
                await onDelete();
                if (context.mounted) {
                  showAppSnack(context, '$days 스케줄을 삭제했습니다',
                      icon: Icons.delete_outline_rounded);
                }
              },
              icon: const Icon(Icons.close_rounded, size: 19)),
        ],
      ),
    ),
  );
}

Widget recommendationCard(
  BuildContext context,
  AiScheduleRecommendation recommendation, {
  required Future<void> Function() onRegister,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: HrggCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusChip(label: 'AI 추천', color: HrggColors.primary),
          const SizedBox(height: 12),
          StatusChip(
            label: noiseTypeLabel(recommendation.noiseType),
            color: noiseTypeColor(recommendation.noiseType),
            soft: true,
          ),
          const SizedBox(height: 8),
          Text(recommendation.title, style: context.t.titleMedium),
          Text(recommendation.subtitle, style: context.t.bodySmall),
          const SizedBox(height: 10),
          StatusChip(
              label: '${recommendation.modeName} 추천',
              color: HrggColors.primary,
              soft: true,
              icon: Icons.auto_awesome_rounded),
          const SizedBox(height: 8),
          Text(
            '${recommendation.days.join('·')} · ${_minutesLabel(recommendation.startMinutes)}-${_minutesLabel(recommendation.endMinutes)} · 신뢰도 ${(recommendation.confidence * 100).round()}%',
            style: context.t.bodySmall?.copyWith(
              color: context.c.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
              label: '스케줄 등록',
              onPressed: () async => onRegister()),
          TextButton(
              onPressed: () async {
                await appDataService.updateAiRecommendationStatus(
                    recommendation.recommendationId, 'ignored');
                if (context.mounted) {
                  showAppSnack(context, '추천을 무시했습니다',
                      icon: Icons.visibility_off_rounded);
                }
              },
              child: const Text('무시',
                  style: TextStyle(color: HrggColors.primary))),
          const Divider(height: 24),
          Text('이 추천이 도움이 되었나요?', style: context.t.bodyMedium),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream:
                appDataService.watchAiRecommendation(recommendation.recommendationId),
            builder: (context, snapshot) {
              final rating = snapshot.data?.data()?['rating'] as int? ?? 0;
              return Row(
                children: List.generate(5, (index) {
                  final score = index + 1;
                  return IconButton(
                    tooltip: '$score점',
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      await appDataService.rateAiRecommendation(
                          recommendation.recommendationId, score);
                      if (context.mounted) {
                        showAppSnack(context, '추천 만족도를 $score점으로 저장했습니다',
                            icon: Icons.star_rounded);
                      }
                    },
                    icon: Icon(
                      score <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: score <= rating
                          ? HrggColors.warning
                          : context.c.textTertiary,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    ),
  );
}

Widget statCard(BuildContext context, String title, String value) {
  return HrggCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: context.t.bodySmall),
    const Spacer(),
    Text(value,
        style: context.t.headlineMedium?.copyWith(color: HrggColors.primary))
  ]));
}

Widget recommendationHeatmap(
    BuildContext context, List<List<double>> values) {
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  const times = ['00', '03', '06', '09', '12', '15', '18', '21'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const SizedBox(width: 28),
          ...times.map((time) => Expanded(
                child: Center(
                  child: Text(time, style: context.t.labelSmall),
                ),
              )),
        ],
      ),
      const SizedBox(height: 6),
      ...List.generate(values.length, (row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(days[row], style: context.t.labelSmall),
              ),
              ...values[row].map((value) => Expanded(
                    child: Container(
                      height: 20,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFFFFF0F6),
                          HrggColors.primary,
                          value.clamp(0, 1),
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  )),
            ],
          ),
        );
      }),
    ],
  );
}

Widget timeHeatmap(BuildContext context) {
  final random = math.Random(21);
  const days = ['월', '화', '수', '목', '금', '토', '일'];
  const times = [
    '00',
    '02',
    '04',
    '06',
    '08',
    '10',
    '12',
    '14',
    '16',
    '18',
    '20',
    '22'
  ];
  const cellWidth = 30.0;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const SizedBox(width: 25),
              ...times.map((time) => SizedBox(
                    width: cellWidth,
                    child: Text(time,
                        textAlign: TextAlign.center,
                        style: context.t.labelSmall),
                  ))
            ]),
            const SizedBox(height: 5),
            ...List.generate(days.length, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  SizedBox(
                      width: 25,
                      child: Text(days[row], style: context.t.labelSmall)),
                  ...List.generate(times.length, (col) {
                    final eveningBoost = col >= 10 ? 0.25 : 0.0;
                    final intensity =
                        (0.08 + random.nextDouble() * 0.67 + eveningBoost)
                            .clamp(0.0, 1.0);
                    return Container(
                      width: cellWidth - 3,
                      height: 24,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: Color.lerp(const Color(0xFFFFF0F6),
                            HrggColors.primary, intensity),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  })
                ]),
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Row(children: [
        Text('시간 (2시간 단위)', style: context.t.labelSmall),
        const Spacer(),
        Text('낮음', style: context.t.labelSmall),
        const SizedBox(width: 5),
        ...List.generate(
            3,
            (i) => Container(
                width: 16,
                height: 8,
                margin: const EdgeInsets.only(right: 3),
                color: Color.lerp(
                    const Color(0xFFFFF0F6), HrggColors.primary, (i + 1) / 3))),
        Text('높음', style: context.t.labelSmall),
      ]),
    ],
  );
}

Widget barChart(BuildContext context) {
  final values = [38.0, 78.0, 52.0, 46.0, 62.0, 31.0, 22.0];
  return SizedBox(
      height: 150,
      child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(
              values.length,
              (i) => Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                        Container(
                            width: 24,
                            height: values[i],
                            decoration: BoxDecoration(
                                color: i == 1
                                    ? HrggColors.primary
                                    : HrggColors.brownNoise,
                                borderRadius: BorderRadius.circular(8))),
                        const SizedBox(height: 8),
                        Text(['월', '화', '수', '목', '금', '토', '일'][i],
                            style: context.t.labelSmall)
                      ])))));
}

Widget serviceRow(
    BuildContext context, String label, IconData icon, VoidCallback onTap) {
  return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: HrggCard(
          padding: const EdgeInsets.all(14),
          onTap: onTap,
          child: Row(children: [
            Icon(icon, color: HrggColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
                child: Text(label,
                    style: context.t.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700))),
            Icon(Icons.chevron_right_rounded, color: context.c.textTertiary)
          ])));
}

void showLogoutSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      decoration: BoxDecoration(
          color: context.c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
                color: context.c.border,
                borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 22),
        CircleAvatar(
            radius: 24,
            backgroundColor: context.c.elevated,
            child: Icon(Icons.logout_rounded, color: context.c.textSecondary)),
        const SizedBox(height: 16),
        Text('로그아웃 하시겠어요?', style: context.t.titleMedium),
        const SizedBox(height: 8),
        Text('로그아웃 후에도 디바이스는 설정된 마스킹을 계속 유지합니다.',
            textAlign: TextAlign.center, style: context.t.bodySmall),
        const SizedBox(height: 20),
        PrimaryButton(
            label: '로그아웃',
            destructive: true,
            onPressed: () async {
              await firebaseAuthService.signOut();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                  slideRoute(const LoginScreen()), (_) => false);
            }),
        const SizedBox(height: 10),
        SecondaryButton(
            label: '취소', onPressed: () => Navigator.of(context).pop())
      ]),
    ),
  );
}

void showDeleteAccountDialog(BuildContext context) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: context.c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('회원탈퇴 하시겠어요?', style: context.t.titleMedium),
      content: Text('계정과 서버에 저장된 리포트 및 스케줄 데이터가 삭제됩니다.',
          style: context.t.bodyMedium),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('취소')),
        TextButton(
          onPressed: () {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pushAndRemoveUntil(
                slideRoute(const LoginScreen()), (_) => false);
          },
          child: const Text('회원탈퇴', style: TextStyle(color: HrggColors.error)),
        ),
      ],
    ),
  );
}
