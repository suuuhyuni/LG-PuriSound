part of hrgg_app;

class HrggApp extends StatefulWidget {
  const HrggApp({super.key});

  @override
  State<HrggApp> createState() => _HrggAppState();
}

class _HrggAppState extends State<HrggApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(_prepareRestoredSession());
    }
  }

  Future<void> _prepareRestoredSession() async {
    await appDataService.ensureUserWorkspace();
    await appDataService.registerPrimaryDevice();
  }

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
    if (FirebaseAuth.instance.currentUser != null) {
      unawaited(appDataService.saveSettings({
        'themeMode': _themeMode == ThemeMode.dark ? 'dark' : 'light',
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeScope(
      themeMode: _themeMode,
      toggleTheme: _toggleTheme,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'LG PuriSound',
        theme: HrggTheme.light(),
        darkTheme: HrggTheme.dark(),
        themeMode: _themeMode,
        home: const SplashScreen(),
      ),
    );
  }
}

class AppThemeScope extends InheritedWidget {
  const AppThemeScope({
    required this.themeMode,
    required this.toggleTheme,
    required super.child,
    super.key,
  });

  final ThemeMode themeMode;
  final VoidCallback toggleTheme;

  static AppThemeScope of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppThemeScope>()!;
  }

  @override
  bool updateShouldNotify(AppThemeScope oldWidget) => themeMode != oldWidget.themeMode;
}
