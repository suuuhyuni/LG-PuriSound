part of hrgg_app;

class HrggColors extends ThemeExtension<HrggColors> {
  const HrggColors({
    required this.background,
    required this.surface,
    required this.elevated,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.secondaryAccent,
  });

  final Color background;
  final Color surface;
  final Color elevated;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color secondaryAccent;

  static const primary = Color(0xFFE6007E);
  static const active = Color(0xFF34C759);
  static const warning = Color(0xFFFF9500);
  static const error = Color(0xFFFF3B30);
  static const inactive = Color(0xFFC7C7CC);
  static const brownNoise = Color(0xFFA0522D);
  static const pinkNoise = Color(0xFFD96B8A);
  static const whiteNoise = Color(0xFF7B8FA1);
  static const sleep = Color(0xFF3A2D6B);
  static const baby = Color(0xFFF9C6D0);
  static const focus = Color(0xFF1A3A4A);

  @override
  HrggColors copyWith({
    Color? background,
    Color? surface,
    Color? elevated,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? secondaryAccent,
  }) {
    return HrggColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      elevated: elevated ?? this.elevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      secondaryAccent: secondaryAccent ?? this.secondaryAccent,
    );
  }

  @override
  HrggColors lerp(ThemeExtension<HrggColors>? other, double t) {
    if (other is! HrggColors) return this;
    return HrggColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      elevated: Color.lerp(elevated, other.elevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
    );
  }
}

class HrggTheme {
  static ThemeData light() => _base(
        Brightness.light,
        const HrggColors(
          background: Color(0xFFF7F7F7),
          surface: Colors.white,
          elevated: Color(0xFFF0F0F5),
          border: Color(0xFFE5E5EA),
          textPrimary: Color(0xFF1A1A1A),
          textSecondary: Color(0xFF6D6D72),
          textTertiary: Color(0xFFAEAEB2),
          secondaryAccent: Color(0xFFC0006A),
        ),
      );

  static ThemeData dark() => _base(
        Brightness.dark,
        const HrggColors(
          background: Color(0xFF0D0D0D),
          surface: Color(0xFF1C1C1E),
          elevated: Color(0xFF2C2C2E),
          border: Color(0xFF3A3A3C),
          textPrimary: Color(0xFFF2F2F7),
          textSecondary: Color(0xFFAEAEB2),
          textTertiary: Color(0xFF6D6D72),
          secondaryAccent: Color(0xFFFF3DAC),
        ),
      );

  static ThemeData _base(Brightness brightness, HrggColors colors) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HrggColors.primary,
        brightness: brightness,
        primary: HrggColors.primary,
        surface: colors.surface,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: colors.textPrimary),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: colors.textPrimary),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: colors.textPrimary),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colors.textPrimary),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: colors.textSecondary),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textSecondary),
      ),
      extensions: [colors],
    );
  }
}

extension ThemeX on BuildContext {
  HrggColors get c => Theme.of(this).extension<HrggColors>()!;
  TextTheme get t => Theme.of(this).textTheme;
}
