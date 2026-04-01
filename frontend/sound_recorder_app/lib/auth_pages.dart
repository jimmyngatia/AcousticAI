import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'main.dart' show AppSession;

// ─────────────────────────── USER STORE ──────────────────────────────
// Acts as an in-memory "database" for the session.
// Pre-seeded with demo accounts; new sign-ups are added at runtime.
class _UserStore {
  _UserStore._();
  static final Map<String, String> _db = {
    'jimmy':    'Testing321',
    'user1':    'Testing321',
    'rickmwas': 'Testing321',
    'user2':    'Testing321',
  };

  /// Returns null on success, or an error string on failure.
  static String? signUp({
    required String username,
    required String password,
  }) {
    final key = username.trim().toLowerCase();
    if (_db.containsKey(key)) return 'Username "$key" is already taken.';
    _db[key] = password;
    return null; // success
  }

  /// Returns null on success, or an error string on failure.
  static String? signIn({
    required String username,
    required String password,
  }) {
    final key = username.trim().toLowerCase();
    final expected = _db[key];
    if (expected == null) return 'Username not found.';
    if (expected != password) return 'Incorrect password.';
    return null; // success
  }
}

// ══════════════════════════ SIGN-IN PAGE ══════════════════════════════

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _authError;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _authError = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final error = _UserStore.signIn(
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    if (error != null) {
      setState(() { _loading = false; _authError = error; });
      return;
    }

    setState(() => _loading = false);
    if (!mounted) return;

    final username = _userCtrl.text.trim().toLowerCase();
    AppSession.isLoggedIn = true;
    AppSession.username = username;
    Navigator.popUntil(context, (r) => r.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Welcome back, $username!'),
      backgroundColor: Colors.greenAccent.shade700,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_voice_rounded,
                        size: 52, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(height: 28),
                const Center(
                  child: Text('Welcome Back',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Sign in to continue your respiratory health analysis',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                  ),
                ),
                const SizedBox(height: 40),

                // ── Error banner ──
                if (_authError != null) ...[
                  _ErrorBanner(_authError!),
                  const SizedBox(height: 20),
                ],

                _FieldLabel('Username'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _userCtrl,
                  hint: 'Enter your username',
                  icon: Icons.person_outline_rounded,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your username' : null,
                ),
                const SizedBox(height: 20),

                _FieldLabel('Password'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _passCtrl,
                  hint: '••••••••',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscure,
                  suffixIcon: _EyeButton(
                    obscure: _obscure,
                    onTap: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 36),

                _PrimaryButton(
                  label: 'Sign In',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 32),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => kIsWeb
                            ? _MobileShell(child: const SignUpPage())
                            : const SignUpPage(),
                      ),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════ SIGN-UP PAGE ══════════════════════════════

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _userCtrl     = TextEditingController();
  final _passCtrl     = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _loading        = false;
  bool _agreed         = false;
  String? _authError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _authError = null);
    if (!_formKey.currentState!.validate()) return;
    if (!_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please agree to the Terms & Privacy Policy.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    final error = _UserStore.signUp(
      username: _userCtrl.text,
      password: _passCtrl.text,
    );

    if (error != null) {
      setState(() { _loading = false; _authError = error; });
      return;
    }

    setState(() => _loading = false);
    if (!mounted) return;

    // ── Success: show dialog then go to sign-in ──
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SuccessDialog(
        name: _nameCtrl.text.trim().isNotEmpty
            ? _nameCtrl.text.trim()
            : _userCtrl.text.trim(),
      ),
    );

    if (!mounted) return;
    // Replace with sign-in page so user can log in immediately
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => kIsWeb
            ? _MobileShell(child: const SignInPage())
            : const SignInPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.settings_voice_rounded,
                        size: 52, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text('Create Account',
                      style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Start monitoring your respiratory health today',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Error banner ──
                if (_authError != null) ...[
                  _ErrorBanner(_authError!),
                  const SizedBox(height: 20),
                ],

                _FieldLabel('Full Name'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _nameCtrl,
                  hint: 'John Doe',
                  icon: Icons.badge_outlined,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Enter your full name' : null,
                ),
                const SizedBox(height: 20),

                _FieldLabel('Username'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _userCtrl,
                  hint: 'Choose a username',
                  icon: Icons.person_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Choose a username';
                    if (v.trim().length < 3) return 'Username must be at least 3 characters';
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                      return 'Only letters, numbers and underscores';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                _FieldLabel('Password'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _passCtrl,
                  hint: 'Min. 8 characters',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscurePass,
                  suffixIcon: _EyeButton(
                    obscure: _obscurePass,
                    onTap: () => setState(() => _obscurePass = !_obscurePass),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Create a password';
                    if (v.length < 8) return 'Password must be at least 8 characters';
                    if (!v.contains(RegExp(r'[A-Z]'))) return 'Include at least one uppercase letter';
                    if (!v.contains(RegExp(r'[0-9]'))) return 'Include at least one number';
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                _PasswordStrengthBar(password: _passCtrl.text),
                const SizedBox(height: 20),

                _FieldLabel('Confirm Password'),
                const SizedBox(height: 8),
                _AuthField(
                  controller: _confirmCtrl,
                  hint: 'Re-enter password',
                  icon: Icons.lock_outline_rounded,
                  obscure: _obscureConfirm,
                  suffixIcon: _EyeButton(
                    obscure: _obscureConfirm,
                    onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // ── Terms ──
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 24, height: 24,
                      child: Checkbox(
                        value: _agreed,
                        activeColor: const Color(0xFFEF4444),
                        checkColor: Colors.white,
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        onChanged: (v) => setState(() => _agreed = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreed = !_agreed),
                        child: RichText(
                          text: const TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                    color: Color(0xFFEF4444),
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                _PrimaryButton(
                  label: 'Create Account',
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 36),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Already have an account? ',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                        children: [
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                                color: Color(0xFFEF4444),
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════ SUCCESS DIALOG ════════════════════════════

class _SuccessDialog extends StatelessWidget {
  final String name;
  const _SuccessDialog({required this.name});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.greenAccent.withOpacity(0.4), width: 1.5),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.greenAccent, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'Account Created!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            Text(
              'Welcome, $name! Your account is ready.\nYou can now sign in with your credentials.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Go to Sign In',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════ SHARED WIDGETS ════════════════════════════

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  final bool obscure;
  final VoidCallback onTap;
  const _EyeButton({required this.obscure, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: Colors.grey,
        size: 20,
      ),
      onPressed: onTap,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;
  const _PrimaryButton(
      {required this.label,
      required this.loading,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)),
          elevation: 4,
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3));
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
                const BorderSide(color: Colors.redAccent, width: 1.5)),
        errorStyle:
            const TextStyle(color: Colors.redAccent, fontSize: 11),
      ),
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final String password;
  const _PasswordStrengthBar({required this.password});

  int _strength() {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength();
    if (password.isEmpty) return const SizedBox.shrink();
    final colors = [Colors.redAccent, Colors.orange, Colors.yellowAccent, Colors.greenAccent];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];
    final idx = (s - 1).clamp(0, 3);
    return Row(
      children: [
        ...List.generate(4, (i) => Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < s ? colors[idx] : Colors.white12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Text(labels[idx],
            style: TextStyle(color: colors[idx], fontSize: 11)),
      ],
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 450),
          decoration: const BoxDecoration(
            border: Border.symmetric(
                vertical: BorderSide(color: Colors.white10, width: 0.5)),
          ),
          child: child,
        ),
      ),
    );
  }
}