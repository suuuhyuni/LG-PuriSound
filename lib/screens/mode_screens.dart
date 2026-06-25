part of hrgg_app;

class NoiseSelectScreen extends StatefulWidget {
  const NoiseSelectScreen({super.key});

  @override
  State<NoiseSelectScreen> createState() => _NoiseSelectScreenState();
}

class _NoiseSelectScreenState extends State<NoiseSelectScreen> {
  bool auto = true;
  int? selected;
  int fadeSpeed = 1;
  double volume = 42;
  bool _noiseSelectionDirty = false;
  Map<String, int> noiseVersions = const {
    'brown': 1,
    'pink': 1,
    'white': 1,
  };

  String get selectedType =>
      selected == null ? 'off' : ['brown', 'pink', 'white'][selected!];

  int get selectedVersion =>
      selected == null ? 1 : noiseVersions[selectedType] ?? 1;

  Future<void> _saveNoiseSelection({
    bool showFeedback = true,
    bool recordManual = false,
  }) async {
    final noiseType = auto ? 'auto' : selectedType;
    final currentVolume = volume.round();
    await appDataService.saveSettings({
      'autoMasking': auto,
      'autoNoiseSelection': FieldValue.delete(),
      'noiseType': noiseType,
      'noiseVersion': auto || selected == null ? null : selectedVersion,
      'noiseVersions': noiseVersions,
      'volume': currentVolume,
      'fadeSpeed': ['smooth', 'normal', 'immediate'][fadeSpeed],
    });
    if (recordManual && !auto && selected != null) {
      await appDataService.recordManualMasking(
        noiseType: noiseType,
        noiseVersion: selectedVersion,
        volume: currentVolume,
      );
    }
    if (!mounted) return;
    setState(() => _noiseSelectionDirty = false);
    if (!showFeedback) return;
    showAppSnack(
      context,
      auto
          ? 'AI 자동 선택으로 저장했습니다'
          : selected == null
              ? '노이즈 재생 안 함으로 저장했습니다'
              : '${noiseTypeLabel(noiseType)} $selectedVersion · ${currentVolume}%로 저장했습니다',
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSettings());
  }

  Future<void> _loadSettings() async {
    final settings = await appDataService.getSettings();
    if (!mounted) return;
    final type = settings['noiseType'] as String? ?? 'brown';
    final savedVersions =
        (settings['noiseVersions'] as Map<String, dynamic>? ?? {});
    setState(() {
      auto = settings['autoMasking'] as bool? ?? true;
      selected = switch (type) {
        'brown' => 0,
        'pink' => 1,
        'white' => 2,
        _ => null,
      };
      noiseVersions = {
        'brown': savedVersions['brown'] as int? ?? 1,
        'pink': savedVersions['pink'] as int? ?? 1,
        'white': savedVersions['white'] as int? ?? 1,
      };
      volume = (settings['volume'] as num?)?.toDouble() ?? 42;
      fadeSpeed = switch (settings['fadeSpeed']) {
        'smooth' => 0,
        'immediate' => 2,
        _ => 1,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: appDataService.watchSettings(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? {};
        final syncedAuto = settings['autoMasking'] as bool? ?? auto;
        final syncedNoiseType = settings['noiseType'] as String? ?? 'off';
        final syncedSelected = switch (syncedNoiseType) {
          'brown' => 0,
          'pink' => 1,
          'white' => 2,
          _ => null,
        };
        if (auto != syncedAuto && !_noiseSelectionDirty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => auto = syncedAuto);
          });
        }
        if (selected != syncedSelected && !_noiseSelectionDirty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => selected = syncedSelected);
          });
        }
        return HrggScaffold(
      title: '마스킹 사운드 설정',
      leadingBack: true,
      children: [
        HrggCard(
          child: Row(children: [
            Expanded(
                child: Text('AI가 자동으로 선택',
                    style: context.t.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700))),
            Switch(
                value: syncedAuto,
                activeTrackColor: HrggColors.primary,
                onChanged: (v) async {
                  if (mounted) {
                    setState(() {
                      _noiseSelectionDirty = true;
                      auto = v;
                      selected = null;
                      if (!v) {
                        volume = 0;
                      }
                    });
                  }
                  await _saveNoiseSelection(showFeedback: true);
                })
          ]),
        ),
        const SizedBox(height: 14),
        if (!auto) ...[
          HrggCard(
            color: selected == null
                ? HrggColors.primary.withValues(alpha: 0.08)
                : context.c.surface,
            borderColor: selected == null
                ? HrggColors.primary
                : context.c.border,
            child: Row(
              children: [
                Icon(
                  selected == null
                      ? Icons.volume_off_rounded
                      : Icons.graphic_eq_rounded,
                  color: selected == null
                      ? HrggColors.primary
                      : context.c.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected == null ? '현재 상태: OFF' : '현재 상태: ${noiseTypeLabel(selectedType)}',
                    style: context.t.bodyMedium?.copyWith(
                      color: selected == null
                          ? HrggColors.primary
                          : context.c.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              setState(() {
                selected = null;
                _noiseSelectionDirty = true;
                volume = 0;
              });
              await _saveNoiseSelection(showFeedback: true);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected == null
                    ? HrggColors.primary
                    : context.c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HrggColors.primary,
                  width: selected == null ? 0 : 1.5,
                ),
              ),
              child: Text(
                'OFF',
                style: context.t.titleSmall?.copyWith(
                  color:
                      selected == null ? Colors.white : HrggColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '변경 사항은 자동으로 저장됩니다',
              textAlign: TextAlign.center,
              style:
                  context.t.bodySmall?.copyWith(color: context.c.textSecondary),
            ),
          ),
        ],
        noiseTypeCard(context, 0, '브라운 노이즈', '층간 충격음 · 50~100Hz',
            '발소리, 가구 끌기 등 저주파 충격음에 최적', HrggColors.brownNoise, false),
        noiseTypeCard(context, 1, '핑크 노이즈', '교통·실외기 · 500Hz+',
            '차량 소음, 실외기 등 중고주파 지속 소음에 최적', HrggColors.pinkNoise, true),
        noiseTypeCard(context, 2, '화이트 노이즈', '생활·대화음 · 전 대역',
            '이웃 대화, TV 소음 등 전 주파수 생활음에 최적', HrggColors.whiteNoise, true),
        if (!auto && selected != null) ...[
          const SectionHeader('노이즈 버전'),
          HrggCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${noiseTypeLabel(selectedType)} 버전을 선택하세요',
                    style: context.t.bodyMedium),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(5, (index) {
                    final version = index + 1;
                    final isSelected = selectedVersion == version;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: index == 4 ? 0 : 8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            setState(() {
                              _noiseSelectionDirty = true;
                              noiseVersions = {
                                ...noiseVersions,
                                selectedType: version,
                              };
                            });
                            await _saveNoiseSelection(
                              showFeedback: true,
                              recordManual: true,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? HrggColors.primary
                                  : context.c.elevated,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isSelected
                                      ? HrggColors.primary
                                      : context.c.border),
                            ),
                            child: Text('$version',
                                style: context.t.bodyMedium?.copyWith(
                                    color: isSelected
                                        ? Colors.white
                                        : context.c.textPrimary,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
        const SectionHeader('음량 설정'),
        valueSlider(
          context,
          volume,
          (v) => setState(() {
            if (!auto && selected == null) {
              volume = 0;
              return;
            }
            volume = v;
          }),
          '${volume.round()}%',
          onChangeEnd: auto
              ? null
              : (_) async {
                  if (selected == null) {
                    setState(() => volume = 0);
                  }
                  await _saveNoiseSelection(
                    showFeedback: true,
                    recordManual: selected != null,
                  );
                },
        ),
      ],
    );
      },
    );
  }

  Widget noiseTypeCard(BuildContext context, int index, String name,
      String meta, String desc, Color color, bool dense) {
    final isSelected = selected == index;
    return Opacity(
      opacity: auto ? 0.58 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: HrggCard(
          borderColor:
              isSelected && !auto ? HrggColors.primary : context.c.border,
          color: isSelected && !auto
              ? color.withValues(alpha: 0.08)
              : context.c.surface,
          onTap: auto
              ? null
              : () async {
                  setState(() {
                    selected = index;
                    _noiseSelectionDirty = true;
                    if (volume == 0) {
                      volume = 42;
                    }
                  });
                  await _saveNoiseSelection(
                    showFeedback: true,
                    recordManual: true,
                  );
                },
          child: Row(
            children: [
              Container(
                  width: 5,
                  height: 92,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 12),
              SizedBox(
                  width: 74,
                  height: 48,
                  child: AnimatedWaveform(color: color, dense: dense)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(name, style: context.t.titleMedium),
                    Text(meta,
                        style: context.t.bodySmall?.copyWith(
                            color: color, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(desc,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.t.bodySmall)
                  ])),
              Icon(
                  auto
                      ? Icons.lock_rounded
                      : (isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded),
                  color: isSelected && !auto
                      ? HrggColors.primary
                      : context.c.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

class MyModesScreen extends StatefulWidget {
  const MyModesScreen({required this.onSelectTab, super.key});

  final ValueChanged<int> onSelectTab;

  @override
  State<MyModesScreen> createState() => _MyModesScreenState();
}

class _MyModesScreenState extends State<MyModesScreen> {
  int selected = 0;
  bool _autoMasking = true;
  bool _selectionDirty = false;
  final Map<String, Map<String, dynamic>> _modeOverrides = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _modeSubscription;

  @override
  void initState() {
    super.initState();
    _modeSubscription = appDataService.watchModes().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        for (final doc in snapshot.docs) {
          _modeOverrides[doc.id] = doc.data();
        }
      });
    });
    unawaited(appDataService.getSettings().then((settings) {
      if (!mounted) return;
      final autoMasking = settings['autoMasking'] as bool? ?? true;
      final id = settings['activeModeId'] as String? ?? 'sleep';
      final index = ['sleep', 'baby', 'focus', 'traffic', 'custom'].indexOf(id);
      setState(() {
        _autoMasking = autoMasking;
        _selectionDirty = false;
        selected = autoMasking ? 0 : (index < 0 ? 1 : index + 1);
      });
    }));
  }

  @override
  void dispose() {
    _modeSubscription?.cancel();
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
        final autoMasking = settings['autoMasking'] as bool? ?? _autoMasking;
        final defaults = [
          ModeData('sleep', '수면 모드', Icons.nights_stay_rounded, 'brown', 35,
              '#000000', const [Color(0xFF3A2D6B), Color(0xFF1A1440)], Colors.white),
          ModeData(
              'baby',
              '베이비 모드',
              Icons.child_care_rounded,
              'brown',
              25,
              '#F9C6D0',
              const [Color(0xFFF9C6D0), Color(0xFFF0A0B8)],
              const Color(0xFF1A1A1A)),
          ModeData('focus', '집중 모드', Icons.center_focus_strong_rounded, 'white',
              55, '#E8F0FE', const [Color(0xFF1A3A4A), Color(0xFF0D2030)], Colors.white),
          ModeData('traffic', '교통 소음 모드', Icons.directions_car_rounded, 'pink',
              60, '#E88FAD', const [Color(0xFF3D3D5C), Color(0xFF25253D)], Colors.white),
          ModeData('custom', '커스텀 모드', Icons.edit_rounded, 'brown', 40, '#E6007E',
              const [HrggColors.primary, Color(0xFFC0006A)], Colors.white),
        ];
        final modes = defaults.map((mode) {
          final data = _modeOverrides[mode.id];
          if (data == null) return mode;
          return ModeData(
            mode.id,
            data['name'] as String? ?? mode.name,
            mode.icon,
            data['noiseType'] as String? ?? mode.noiseType,
            data['volume'] as int? ?? mode.volume,
            data['ledColor'] as String? ?? mode.ledColor,
            mode.colors,
            mode.textColor,
          );
        }).toList();
        final allModes = [
          ModeData(
            'ai_auto',
            'AI 자동 모드',
            Icons.auto_awesome_rounded,
            'auto',
            0,
            '#E6007E',
            const [Color(0xFF3A0F2A), Color(0xFFE6007E)],
            Colors.white,
          ),
          ...modes,
        ];
        final activeModeId = settings['activeModeId'] as String? ?? 'sleep';
        final activeIndex =
            ['sleep', 'baby', 'focus', 'traffic', 'custom'].indexOf(activeModeId);
        final syncedSelected = !puriSoundEnabled
            ? selected
            : autoMasking
                ? 0
                : (activeIndex < 0 ? 1 : activeIndex + 1);
        final visibleSelected = _selectionDirty ? selected : syncedSelected;
        if (!_selectionDirty &&
            (selected != syncedSelected || _autoMasking != autoMasking)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _autoMasking = autoMasking;
              selected = syncedSelected;
            });
          });
        }
        return HrggScaffold(
          title: '나의 모드',
          leadingBack: true,
          onBack: () => widget.onSelectTab(0),
          children: [
            Text('상황에 맞는 모드를 선택하세요',
                style: context.t.bodyMedium
                    ?.copyWith(color: context.c.textSecondary)),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allModes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.82),
              itemBuilder: (context, i) {
                final mode = allModes[i];
                final canSelect = puriSoundEnabled && (autoMasking ? i == 0 : i != 0);
                return modeCard(
                  context,
                  mode,
                  i == visibleSelected,
                  () async {
                    if (!canSelect) {
                      showAppSnack(
                        context,
                        !puriSoundEnabled
                            ? 'LG PuriSound가 꺼져 있어 모드를 선택할 수 없습니다'
                            : autoMasking
                                ? '자동 마스킹이 켜져 있어 AI 자동 모드만 사용할 수 있습니다'
                                : '자동 마스킹이 꺼져 있어 수동 모드를 선택할 수 있습니다',
                      );
                      return;
                    }
                    if (mode.id == 'custom') {
                      final saved = await Navigator.of(context)
                          .push<bool>(slideRoute(ModeEditScreen(mode: mode)));
                      if (saved == true && mounted) {
                        setState(() {
                          selected = i;
                          _selectionDirty = true;
                        });
                      }
                    } else {
                      setState(() {
                        selected = i;
                        _selectionDirty = true;
                      });
                    }
                  },
                  onEdit: () async {
                    if (mode.id == 'ai_auto') return;
                    final saved = await Navigator.of(context)
                        .push<bool>(slideRoute(ModeEditScreen(mode: mode)));
                    if (saved == true && mounted && mode.id == 'custom') {
                      setState(() => selected = i);
                    }
                  },
                  enabled: canSelect,
                );
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: '적용',
              onPressed: !puriSoundEnabled
                  ? null
                  : () async {
                final selectedMode = allModes[visibleSelected];
                if (selectedMode.id == 'ai_auto') {
                  await appDataService.saveSettings({
                    'puriSoundEnabled': true,
                    'autoMasking': true,
                    'noiseType': 'auto',
                    'activeModeId': 'ai_auto',
                    'activeModeName': 'AI 자동 모드',
                    'autoNoiseSelection': FieldValue.delete(),
                  });
                } else {
                  await appDataService.setActiveMode(
                    selectedMode.id,
                    selectedMode.name,
                    autoMasking: false,
                  );
                }
                if (!context.mounted) return;
                setState(() => _selectionDirty = false);
                showAppSnack(
                  context,
                  selectedMode.id == 'ai_auto'
                      ? 'AI 자동 모드를 적용했습니다'
                      : '${selectedMode.name}를 적용했습니다',
                );
                widget.onSelectTab(0);
              },
            ),
            const SizedBox(height: 10),
            SecondaryButton(
                label: puriSoundEnabled
                    ? 'LG PuriSound 끄기'
                    : 'LG PuriSound 켜기',
                onPressed: () async {
                  await appDataService.setPuriSoundEnabled(!puriSoundEnabled);
                  if (!context.mounted) return;
                  showAppSnack(
                    context,
                    puriSoundEnabled
                        ? 'LG PuriSound를 껐습니다'
                        : 'LG PuriSound를 켰습니다',
                  );
                }),
          ],
        );
      },
    );
  }
}

class ModeData {
  ModeData(this.id, this.name, this.icon, this.noiseType, this.volume,
      this.ledColor, this.colors, this.textColor);
  final String id;
  final String name;
  final IconData icon;
  final String noiseType;
  final int volume;
  final String ledColor;
  final List<Color> colors;
  final Color textColor;

  String get settings =>
      id == 'ai_auto'
          ? '주변 소음을 분석해 자동으로 노이즈를 재생'
          : '${noiseTypeLabel(noiseType)} · $volume% · LED ${ledColor == '#000000' ? '꺼짐' : ledColor}';
}

Widget modeCard(
    BuildContext context, ModeData mode, bool selected, VoidCallback onTap,
    {required VoidCallback onEdit, bool enabled = true}) {
  return GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: enabled ? 1 : 0.42,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: mode.colors),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? HrggColors.primary : Colors.transparent,
                width: selected ? 3 : 0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(mode.icon, color: mode.textColor, size: 34),
              const Spacer(),
              if (mode.id != 'ai_auto')
                IconButton(
                  tooltip: '모드 편집',
                  onPressed: enabled ? onEdit : null,
                  icon:
                      Icon(Icons.tune_rounded, color: mode.textColor, size: 20),
                ),
            ]),
            const Spacer(),
            Text(mode.name,
                style: context.t.titleMedium?.copyWith(color: mode.textColor)),
            const SizedBox(height: 6),
            Text(mode.settings,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.t.labelSmall
                    ?.copyWith(color: mode.textColor.withValues(alpha: 0.86))),
          ],
        ),
      ),
    ),
  );
}

class ModeEditScreen extends StatefulWidget {
  const ModeEditScreen({required this.mode, super.key});

  final ModeData mode;

  @override
  State<ModeEditScreen> createState() => _ModeEditScreenState();
}

class _ModeEditScreenState extends State<ModeEditScreen> {
  late final TextEditingController nameController;
  late double volume;
  int sensitivity = 1;
  late int noiseIndex;
  late int ledIndex;

  static const ledColors = [
    Color(0xFF000000),
    Color(0xFFC97B3A),
    Color(0xFFE88FAD),
    Color(0xFFF9C6D0),
    Color(0xFFE8F0FE),
    Color(0xFFE6007E),
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.mode.name);
    volume = widget.mode.volume.toDouble();
    noiseIndex = switch (widget.mode.noiseType) {'pink' => 1, 'white' => 2, _ => 0};
    ledIndex = widget.mode.ledColor == '#000000' ? 0 : 5;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '${widget.mode.name} 편집',
      leadingBack: true,
      children: [
        AuthTextField(
          controller: nameController,
          label: '모드 이름',
          icon: Icons.drive_file_rename_outline_rounded,
        ),
        const SectionHeader('설정'),
        segmented(context, ['브라운', '핑크', '화이트'], noiseIndex,
            (v) => setState(() => noiseIndex = v)),
        valueSlider(context, volume, (v) => setState(() => volume = v),
            '${volume.round()}%'),
        const SectionHeader('LED 색상'),
        HrggCard(
          child: Wrap(
            spacing: 12,
            children: List.generate(ledColors.length, (i) => GestureDetector(
              onTap: () => setState(() => ledIndex = i),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: ledColors[i],
                child: ledIndex == i
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null,
              ),
            )),
          ),
        ),
        const SectionHeader('민감도'),
        segmented(context, ['낮음', '보통', '높음'], sensitivity,
            (v) => setState(() => sensitivity = v)),
        const SectionHeader('미리보기'),
        Container(
            height: 118,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [HrggColors.primary, Color(0xFFC0006A)]),
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.edit_rounded, color: Colors.white, size: 42),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(
                      '${nameController.text}\n${noiseTypeLabel(['brown', 'pink', 'white'][noiseIndex])} · ${volume.round()}% · 민감도 ${[
                        '낮음',
                        '보통',
                        '높음'
                      ][sensitivity]}',
                      style:
                          context.t.titleMedium?.copyWith(color: Colors.white)))
            ])),
        const SizedBox(height: 20),
        PrimaryButton(
            label: '저장',
            onPressed: () async {
              await appDataService.saveMode(
                modeId: widget.mode.id,
                name: nameController.text.trim().isEmpty
                    ? widget.mode.name
                    : nameController.text.trim(),
                noiseType: ['brown', 'pink', 'white'][noiseIndex],
                volume: volume.round(),
                sensitivity: ['low', 'normal', 'high'][sensitivity],
                ledColor:
                    '#${ledColors[ledIndex].toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                isSystemMode: widget.mode.id != 'custom',
              );
              if (!context.mounted) return;
              showAppSnack(context, '${nameController.text} 모드를 저장했습니다');
              Navigator.of(context).pop(true);
            }),
      ],
    );
  }
}

Widget settingRow(BuildContext context, String title, String value,
    {VoidCallback? onTap}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: HrggCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(children: [
        Expanded(
            child: Text(title,
                style: context.t.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700))),
        if (value.isNotEmpty)
          StatusChip(label: value, color: HrggColors.primary, soft: true),
        Icon(Icons.chevron_right_rounded, color: context.c.textTertiary)
      ]),
    ),
  );
}
