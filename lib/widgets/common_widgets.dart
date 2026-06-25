part of hrgg_app;

class HrggScaffold extends StatelessWidget {
  const HrggScaffold({
    required this.title,
    required this.children,
    this.leadingBack = false,
    this.onBack,
    this.trailing,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final bool leadingBack;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: leadingBack
                          ? IconButton(
                              onPressed:
                                  onBack ?? () => Navigator.of(context).pop(),
                              icon: Icon(Icons.arrow_back_ios_new_rounded,
                                  size: 20, color: context.c.textPrimary),
                            )
                          : null,
                    ),
                    Expanded(child: Text(title, style: context.t.titleMedium)),
                    SizedBox(
                        width: trailing == null ? 44 : 100, child: trailing),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeIconButton extends StatelessWidget {
  const ThemeIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: AppThemeScope.of(context).toggleTheme,
      icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: context.c.textPrimary),
    );
  }
}

class HrggCard extends StatelessWidget {
  const HrggCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? context.c.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: child,
    );
    return onTap == null
        ? box
        : InkWell(
            borderRadius: BorderRadius.circular(16), onTap: onTap, child: box);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {required this.label,
      required this.onPressed,
      this.destructive = false,
      super.key});

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: destructive ? HrggColors.error : HrggColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: HrggColors.primary, width: 1.5),
          foregroundColor: HrggColors.primary,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(
      {required this.label,
      required this.color,
      this.soft = false,
      this.icon,
      super.key});

  final String label;
  final Color color;
  final bool soft;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.14) : color,
        borderRadius: BorderRadius.circular(soft ? 20 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: soft ? color : Colors.white, size: 13),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: context.t.labelSmall?.copyWith(
                  color: soft ? color : Colors.white,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {this.action, this.onTap, super.key});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.t.headlineMedium)),
          if (action != null)
            TextButton(
                onPressed: onTap,
                child: Text(action!,
                    style: const TextStyle(color: HrggColors.primary))),
        ],
      ),
    );
  }
}

Widget inputField(BuildContext context, String hint, IconData icon,
    {String? error}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? context.c.elevated
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: error == null ? context.c.border : HrggColors.error),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.c.textTertiary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(hint,
                    style: context.t.bodyMedium
                        ?.copyWith(color: context.c.textTertiary))),
          ],
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 6),
        Text(error,
            style: context.t.bodySmall?.copyWith(color: HrggColors.error)),
      ],
    ],
  );
}

Widget segmented(BuildContext context, List<String> labels, int selected,
    ValueChanged<int> onChanged) {
  return Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
        color: context.c.elevated, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: List.generate(labels.length, (i) {
        final active = i == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(i),
            child: Container(
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: active ? HrggColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(9)),
              child: Text(labels[i],
                  style: context.t.bodySmall?.copyWith(
                      color: active ? Colors.white : context.c.textSecondary,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        );
      }),
    ),
  );
}

Widget valueSlider(BuildContext context, double value,
    ValueChanged<double> onChanged, String label,
    {ValueChanged<double>? onChangeEnd}) {
  return HrggCard(
    child: Column(
      children: [
        Row(children: [
          Expanded(child: Text('현재 값', style: context.t.bodySmall)),
          Text(label,
              style: context.t.titleMedium?.copyWith(color: HrggColors.primary))
        ]),
        Slider(
            value: value,
            min: 0,
            max: 100,
            activeColor: HrggColors.primary,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd),
      ],
    ),
  );
}

Widget warningBanner(BuildContext context, String text, Color color,
    {IconData icon = Icons.warning_rounded}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28))),
    child: Row(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Expanded(
          child: Text(text,
              style: context.t.bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)))
    ]),
  );
}

void showAppSnack(BuildContext context, String message,
    {IconData icon = Icons.check_circle_rounded}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: context.c.textPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            Icon(icon, color: context.c.background, size: 19),
            const SizedBox(width: 9),
            Expanded(
                child: Text(message,
                    style: TextStyle(
                        color: context.c.background,
                        fontWeight: FontWeight.w600))),
          ],
        ),
      ),
    );
}

Future<void> showInfoDialog(BuildContext context, String title, String body) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: context.c.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title, style: context.t.titleMedium),
      content: Text(body, style: context.t.bodyMedium),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('확인', style: TextStyle(color: HrggColors.primary)),
        ),
      ],
    ),
  );
}
