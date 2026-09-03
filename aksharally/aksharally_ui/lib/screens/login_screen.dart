import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool obscurePassword = true;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  String _preferredLanguage = 'en';
  String? _ageGroup;

late AuthService auth;

@override
void initState() {
  super.initState();
    auth = AuthService();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
}

  static const gradientColors = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
  ];

  // HANDLE LOGIN / REGISTER
  Future<void> handleAuth() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isLogin) {
        final user = await auth.login(email, password);
        if (user != null) {
          await auth.restoreUserPreferences(user);
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        final user = await auth.register(email, password);
        if (user != null) {
          await auth.saveUserProfile(
            user,
            fullName: fullNameController.text.trim(),
            preferredLanguage: _preferredLanguage,
            ageGroup: _ageGroup,
          );
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthService.friendlyError(error))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSocial(Future<User?> Function() signIn) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final user = await signIn();
      if (user == null) return; // The user cancelled the provider flow.
      await auth.saveUserProfile(user);
      await auth.restoreUserPreferences(user);
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthService.friendlyError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  Widget _registrationFields() {
    if (isLogin) return const SizedBox.shrink();
    return Column(
      children: [
        TextFormField(
          controller: fullNameController,
          textCapitalization: TextCapitalization.words,
          decoration: _fieldDecoration("Full Name", Icons.person_outline),
          validator: (value) => value == null || value.trim().isEmpty
              ? 'Please enter your full name.'
              : null,
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _onboardingFields() {
    if (isLogin) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Optional reading preferences',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black87),
        ),
        const SizedBox(height: 10),
        const Text(
          'Preferred language',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _languageChip('English', 'en'),
            _languageChip('हिंदी', 'hi'),
            _languageChip('मराठी', 'mr'),
          ],
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          value: _ageGroup,
          decoration: _fieldDecoration(
            'Age group (optional)',
            Icons.calendar_today_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'under_13', child: Text('Under 13')),
            DropdownMenuItem(value: '13_17', child: Text('13–17')),
            DropdownMenuItem(value: '18_24', child: Text('18–24')),
            DropdownMenuItem(value: '25_44', child: Text('25–44')),
            DropdownMenuItem(value: '45_plus', child: Text('45+')),
            DropdownMenuItem(
              value: 'prefer_not_to_say',
              child: Text('Prefer not to say'),
            ),
          ],
          onChanged: (value) => setState(() => _ageGroup = value),
        ),
      ],
    );
  }

  Widget _languageChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _preferredLanguage == value,
      onSelected: (_) => setState(() => _preferredLanguage = value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                  const SizedBox(height: 40),

                  // ICON
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: gradientColors),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // LOGIN / REGISTER TOGGLE
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => setState(() => isLogin = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: isLogin
                                    ? const LinearGradient(colors: gradientColors)
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    color: isLogin ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: () => setState(() => isLogin = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                gradient: !isLogin
                                    ? const LinearGradient(colors: gradientColors)
                                    : null,
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Center(
                                child: Text(
                                  "Register",
                                  style: TextStyle(
                                    color: !isLogin ? Colors.white : Colors.black,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // TITLE
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        const LinearGradient(colors: gradientColors)
                            .createShader(bounds),
                    child: Text(
                      isLogin ? "Welcome Back!" : "Create Account",
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  _registrationFields(),

                  // EMAIL FIELD
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration("Email", Icons.email_outlined),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) return 'Please enter your email.';
                      final valid = RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch(email);
                      return valid ? null : 'Please enter a valid email address.';
                    },
                  ),

                  const SizedBox(height: 20),

                  // PASSWORD FIELD
                  TextFormField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: _fieldDecoration("Password", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password.';
                      }
                      if (!isLogin && value.length < 6) {
                        return 'Use at least 6 characters.';
                      }
                      return null;
                    },
                  ),

                  if (!isLogin) ...[
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscurePassword,
                      decoration: _fieldDecoration(
                        "Confirm Password",
                        Icons.lock_reset_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        return value == passwordController.text
                            ? null
                            : 'Passwords do not match.';
                      },
                    ),
                    _onboardingFields(),
                  ],

                  const SizedBox(height: 25),

                  // LOGIN / REGISTER BUTTON
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: _isLoading ? null : handleAuth,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF66BB6A),
                            Color(0xFF43A047),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isLogin ? "Login" : "Register",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Or continue with",
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  // GOOGLE BUTTON
                  _socialButton(
                    "Continue with Google",
                    () => _handleSocial(auth.signInWithGoogle),
                  ),

                  const SizedBox(height: 15),

                  // APPLE BUTTON
                  _socialButton(
                    "Continue with Apple",
                    () => _handleSocial(auth.signInWithApple),
                  ),

                  const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // SOCIAL BUTTON UI
  Widget _socialButton(String text, VoidCallback onPressed) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: _isLoading ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}