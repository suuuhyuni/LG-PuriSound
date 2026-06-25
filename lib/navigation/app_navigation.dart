part of hrgg_app;

Route<T> slideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final offset = Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation);
      return SlideTransition(position: offset, child: child);
    },
  );
}

void pushScreen(BuildContext context, Widget screen) {
  Navigator.of(context).push(slideRoute(screen));
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(onSelectTab: _select),
      MonitorScreen(onSelectTab: _select),
      MyModesScreen(onSelectTab: _select),
      ReportScreen(onSelectTab: _select),
      MyPageScreen(onSelectTab: _select),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: HrggBottomTabBar(index: _index, onChanged: _select),
    );
  }
}

class HrggBottomTabBar extends StatelessWidget {
  const HrggBottomTabBar({required this.index, required this.onChanged, super.key});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, '홈'),
      (Icons.monitor_heart_rounded, '모니터링'),
      (Icons.grid_view_rounded, '나의 모드'),
      (Icons.bar_chart_rounded, '리포트'),
      (Icons.person_rounded, '마이페이지'),
    ];
    return Container(
      height: 83,
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: List.generate(items.length, (i) {
            final active = i == index;
            return Expanded(
              child: InkWell(
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      Icon(items[i].$1, color: active ? HrggColors.primary : context.c.textTertiary, size: 22),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        maxLines: 1,
                        style: context.t.labelSmall?.copyWith(
                          fontSize: 10,
                          color: active ? HrggColors.primary : context.c.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
