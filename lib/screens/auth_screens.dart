part of hrgg_app;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null || !mounted) return;
      Navigator.of(context).pushReplacement(slideRoute(const AppShell()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              HrggColors.primary.withValues(alpha: 0.10),
              context.c.background
            ],
            radius: 0.9,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.graphic_eq_rounded,
                    color: HrggColors.primary, size: 76),
                const SizedBox(height: 14),
                Text('LG PuriSound',
                    style: context.t.displayLarge
                        ?.copyWith(color: HrggColors.primary, fontSize: 34)),
                const SizedBox(height: 10),
                Text('AI가 지키는 우리 집의 고요함',
                    style: context.t.bodyMedium
                        ?.copyWith(color: context.c.textSecondary)),
                const Spacer(),
                PrimaryButton(
                    label: '시작하기',
                    onPressed: () => pushScreen(context, const SignUpScreen())),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => pushScreen(context, const LoginScreen()),
                  child: const Text('이미 계정이 있으신가요? 로그인',
                      style: TextStyle(color: HrggColors.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted || !_privacyAccepted) {
      setState(() => _error = '필수 약관에 모두 동의해주세요.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await firebaseAuthService.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        slideRoute(const DeviceRegisterScreen()),
        (_) => false,
      );
    } catch (error) {
      if (mounted) setState(() => _error = firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '회원가입',
      leadingBack: true,
      children: [
        Form(
          key: _formKey,
          child: HrggCard(
            child: Column(
              children: [
                AuthTextField(
                  controller: _nameController,
                  label: '이름',
                  icon: Icons.person_outline_rounded,
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? '이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _emailController,
                  label: '이메일 주소',
                  icon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  validator: validateEmail,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _passwordController,
                  label: '비밀번호',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  onVisibilityToggle: () => setState(
                      () => _obscurePassword = !_obscurePassword),
                  validator: validatePassword,
                ),
                const SizedBox(height: 12),
                AuthTextField(
                  controller: _passwordConfirmController,
                  label: '비밀번호 확인',
                  icon: Icons.lock_reset_rounded,
                  obscureText: true,
                  validator: (value) => value != _passwordController.text
                      ? '비밀번호가 일치하지 않습니다.'
                      : null,
                ),
                const SizedBox(height: 18),
                termsRow(
                  context,
                  '서비스 이용약관 동의 (필수)',
                  _termsAccepted,
                  (value) => setState(() => _termsAccepted = value),
                ),
                const SizedBox(height: 8),
                termsRow(
                  context,
                  '개인정보 수집 및 이용 동의 (필수)',
                  _privacyAccepted,
                  (value) => setState(() => _privacyAccepted = value),
                ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          warningBanner(context, _error!, HrggColors.error,
              icon: Icons.error_outline_rounded),
        ],
        const SizedBox(height: 24),
        PrimaryButton(label: _loading ? '가입 중...' : '가입 완료', onPressed: _loading ? null : _register),
      ],
    );
  }
}

Widget termsRow(BuildContext context, String title, bool value,
    ValueChanged<bool> onChanged) {
  return Row(
    children: [
      Checkbox(
        value: value,
        activeColor: HrggColors.primary,
        onChanged: (checked) => onChanged(checked ?? false),
      ),
      Expanded(child: Text(title, style: context.t.bodyMedium)),
      TextButton(
        onPressed: () =>
            showInfoDialog(context, title, '약관 상세 내용을 확인하고 동의할 수 있습니다.'),
        child: const Text('보기', style: TextStyle(color: HrggColors.primary)),
      ),
    ],
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _emailLogin() async {
    if (!_formKey.currentState!.validate()) return;
    await _performLogin(() => firebaseAuthService.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        ));
  }

  Future<void> _googleLogin() {
    return _performLogin(firebaseAuthService.signInWithGoogle);
  }

  Future<void> _performLogin(Future<UserCredential> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final credential = await action();
      if (!mounted) return;
      final destination = credential.additionalUserInfo?.isNewUser ?? false
          ? const DeviceRegisterScreen()
          : const AppShell();
      Navigator.of(context).pushAndRemoveUntil(slideRoute(destination), (_) => false);
    } catch (error) {
      if (mounted) setState(() => _error = firebaseAuthErrorMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final emailError = validateEmail(_emailController.text);
    if (emailError != null) {
      setState(() => _error = '비밀번호를 재설정할 이메일 주소를 입력해주세요.');
      return;
    }
    try {
      await firebaseAuthService.sendPasswordResetEmail(_emailController.text);
      if (mounted) showAppSnack(context, '비밀번호 재설정 이메일을 전송했습니다.');
    } catch (error) {
      if (mounted) setState(() => _error = firebaseAuthErrorMessage(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return HrggScaffold(
      title: '',
      leadingBack: true,
      children: [
        const SizedBox(height: 20),
        Center(
            child: Icon(Icons.graphic_eq_rounded,
                color: HrggColors.primary, size: 46)),
        Center(
            child: Text('LG PuriSound',
                style: context.t.titleMedium
                    ?.copyWith(color: HrggColors.primary))),
        const SizedBox(height: 30),
        Text('로그인', style: context.t.displayLarge),
        const SizedBox(height: 22),
        Form(
          key: _formKey,
          child: Column(
            children: [
              AuthTextField(
                controller: _emailController,
                label: '이메일 주소',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: validateEmail,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                controller: _passwordController,
                label: '비밀번호',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                onVisibilityToggle: () => setState(
                    () => _obscurePassword = !_obscurePassword),
                validator: validatePassword,
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          warningBanner(context, _error!, HrggColors.error,
              icon: Icons.error_outline_rounded),
        ],
        const SizedBox(height: 18),
        PrimaryButton(label: _loading ? '로그인 중...' : '로그인', onPressed: _loading ? null : _emailLogin),
        const SizedBox(height: 18),
        Center(
          child: TextButton(
            onPressed: _loading ? null : _resetPassword,
            child: const Text('비밀번호 찾기',
                style: TextStyle(color: HrggColors.primary)),
          ),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: Divider(color: context.c.border)),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('또는', style: context.t.bodySmall)),
          Expanded(child: Divider(color: context.c.border))
        ]),
        const SizedBox(height: 16),
        HrggCard(
          padding: const EdgeInsets.all(14),
          onTap: _loading ? null : _googleLogin,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('G',
                  style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const SizedBox(width: 10),
              Text('Google로 로그인', style: context.t.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Center(
            child: TextButton(
                onPressed: () => pushScreen(context, const SignUpScreen()),
                child: const Text('계정이 없으신가요? 회원가입',
                    style: TextStyle(color: HrggColors.primary)))),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.onVisibilityToggle,
    this.validator,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onVisibilityToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19),
        suffixIcon: onVisibilityToggle == null
            ? null
            : IconButton(
                onPressed: onVisibilityToggle,
                icon: Icon(obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
              ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? context.c.elevated
            : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: context.c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: HrggColors.primary, width: 2),
        ),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return '이메일 주소를 입력해주세요.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return '올바른 이메일 주소를 입력해주세요.';
  }
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) return '비밀번호는 6자 이상 입력해주세요.';
  return null;
}
