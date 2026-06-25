part of hrgg_app;

class DeviceRegisterScreen extends StatelessWidget {
  const DeviceRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '디바이스 등록',
      leadingBack: true,
      children: [
        progressBar(context, ['등록', '설정', '완료'], 0),
        const SizedBox(height: 28),
        Center(child: deviceIllustration(context, 180)),
        const SizedBox(height: 20),
        HrggCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('디바이스를 추가해주세요', style: context.t.titleMedium),
              const SizedBox(height: 12),
              Text('1. 전원 켜기\n2. 동일 Wi-Fi 연결\n3. 아래 버튼으로 검색',
                  style: context.t.bodyMedium
                      ?.copyWith(color: context.c.textSecondary)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: const [
                StatusChip(
                    label: '마이크 권한',
                    color: HrggColors.active,
                    icon: Icons.check_rounded),
                StatusChip(
                    label: '스피커 권한',
                    color: HrggColors.warning,
                    icon: Icons.warning_rounded),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 12),
        warningBanner(
            context, '디바이스를 찾을 수 없습니다 - 전원 및 네트워크를 확인하세요', HrggColors.warning),
        const SizedBox(height: 20),
        PrimaryButton(
            label: '디바이스 검색',
            onPressed: () => pushScreen(context, const InitialSetupScreen())),
      ],
    );
  }
}

class InitialSetupScreen extends StatefulWidget {
  const InitialSetupScreen({super.key});

  @override
  State<InitialSetupScreen> createState() => _InitialSetupScreenState();
}

class _InitialSetupScreenState extends State<InitialSetupScreen> {
  int selectedNoise = 0;
  int sensitivity = 1;
  int selectedZone = 0;
  double volume = 42;

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '초기 설정',
      leadingBack: true,
      children: [
        progressBar(context, ['등록', '설정', '완료'], 1),
        const SectionHeader('마스킹 사운드 선택'),
        noiseSetupCard(
            context, 0, '브라운 노이즈', '층간 충격음 · 50~100Hz', HrggColors.brownNoise),
        noiseSetupCard(
            context, 1, '핑크 노이즈', '교통·실외기 · 500Hz+', HrggColors.pinkNoise),
        noiseSetupCard(
            context, 2, '화이트 노이즈', '생활·대화음 · 전 대역', HrggColors.whiteNoise),
        const SectionHeader('기본 음량'),
        valueSlider(context, volume, (v) => setState(() => volume = v),
            '${volume.round()}%'),
        const SectionHeader('개입 민감도'),
        segmented(context, ['낮음', '보통', '높음'], sensitivity,
            (v) => setState(() => sensitivity = v)),
        const SectionHeader('Local Zone'),
        Wrap(
          spacing: 8,
          children: List.generate(['침실', '거실', '서재'].length, (i) {
            return GestureDetector(
              onTap: () => setState(() => selectedZone = i),
              child: StatusChip(
                  label: ['침실', '거실', '서재'][i],
                  color: HrggColors.primary,
                  soft: selectedZone != i),
            );
          }),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: '설정 완료 → 모니터링 시작',
          onPressed: () async {
            await appDataService.registerPrimaryDevice(
              zone: ['침실', '거실', '서재'][selectedZone],
              noiseType: ['brown', 'pink', 'white'][selectedNoise],
              volume: volume.round(),
              sensitivity: ['low', 'normal', 'high'][sensitivity],
              applyInitialSettings: true,
            );
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(slideRoute(const AppShell()));
          },
        ),
      ],
    );
  }

  Widget noiseSetupCard(
      BuildContext context, int index, String title, String meta, Color color) {
    final selected = selectedNoise == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HrggCard(
        borderColor: selected ? HrggColors.primary : context.c.border,
        onTap: () => setState(() => selectedNoise = index),
        child: Row(
          children: [
            Container(
                width: 5,
                height: 64,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(5))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(title, style: context.t.titleMedium),
                  Text(meta,
                      style: context.t.bodySmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w700))
                ])),
            Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? HrggColors.primary : context.c.textTertiary),
          ],
        ),
      ),
    );
  }
}

Widget progressBar(BuildContext context, List<String> steps, int active) {
  return Row(
    children: List.generate(steps.length, (i) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(children: [
            Container(
                height: 5,
                decoration: BoxDecoration(
                    color: i <= active ? HrggColors.primary : context.c.border,
                    borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Text(steps[i],
                style: context.t.labelSmall?.copyWith(
                    color: i == active
                        ? HrggColors.primary
                        : context.c.textTertiary)),
          ]),
        ),
      );
    }),
  );
}

Widget deviceIllustration(BuildContext context, double size) {
  return Container(
    width: size,
    height: size,
    decoration:
        BoxDecoration(shape: BoxShape.circle, color: context.c.elevated),
    child: Center(
      child: Container(
        width: size * 0.5,
        height: size * 0.66,
        decoration: BoxDecoration(
            color: context.c.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.c.border)),
        child: Icon(Icons.graphic_eq_rounded,
            color: HrggColors.primary, size: size * 0.22),
      ),
    ),
  );
}
