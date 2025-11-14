import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/auth/auth_event.dart';
import '../../../logic/auth/auth_state.dart';
import '../../../router/app_router.dart';
import 'auth_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// Placeholder credentials for the mock login flow. Replace when wiring auth.
  static const String _mockPhoneNumber = '9998887776';
  static const String _mockPassword = 'demo@1234';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _rememberMe = true;

  @override
  void initState() {
    super.initState();
    _phoneController.text = _mockPhoneNumber;
    _passwordController.text = _mockPassword;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  void _handleLogin(BuildContext context) {
    FocusScope.of(context).unfocus();
    final phone = _phoneController.text.trim().isEmpty
        ? _mockPhoneNumber
        : _phoneController.text.trim();
    context.read<AuthBloc>().add(
          AuthCitizenLoginRequested(
            phone: phone,
          ),
        );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFBBDCC1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFFBBDCC1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF1B5E20), width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = GoogleFonts.rubikTextTheme(theme.textTheme);
    final primaryTextTheme = GoogleFonts.rubikTextTheme(theme.primaryTextTheme);
    final themedContext = theme.copyWith(
      textTheme: textTheme,
      primaryTextTheme: primaryTextTheme,
    );

    return Theme(
      data: themedContext,
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
                const AuthBackground(),
            SafeArea(
              child: BlocConsumer<AuthBloc, AuthState>(
                listener: (context, state) {
                  if (state is AuthStateFailure) {
                    _showSnack(state.message, Colors.red);
                  }
                },
                builder: (context, state) {
                  final bool isLoading = state is AuthStateLoading;
                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 30,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Image.asset('assets/images/logo.png'),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _LoginCard(
                              formKey: _formKey,
                              phoneController: _phoneController,
                              passwordController: _passwordController,
                              rememberMe: _rememberMe,
                              onRememberMeChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                              onForgotPassword: () {
                                _showSnack(
                                  'Password resets will arrive shortly!',
                                  const Color(0xFF1B5E20),
                                );
                              },
                              onLogin: () => _handleLogin(context),
                              isSubmitting: isLoading,
                              inputDecorationBuilder: _inputDecoration,
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: () =>
                                  context.go(AppRoutePaths.citizenRegister),
                              child: const Text(
                                "Don't have an account? Sign up",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isLoading)
                        const Positioned.fill(
                          child: ColoredBox(
                            color: Colors.black26,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.formKey,
    required this.phoneController,
    required this.passwordController,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onForgotPassword,
    required this.onLogin,
    required this.isSubmitting,
    required this.inputDecorationBuilder,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final bool rememberMe;
  final ValueChanged<bool?> onRememberMeChanged;
  final VoidCallback onForgotPassword;
  final VoidCallback onLogin;
  final bool isSubmitting;
  final InputDecoration Function({
    required String label,
    required String hint,
    required IconData icon,
  }) inputDecorationBuilder;

  static const Color _primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/loginbackground.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(210, 27, 94, 32),
                          Color.fromARGB(210, 46, 125, 90),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome Back',
                          style: textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Login to your account.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: inputDecorationBuilder(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: inputDecorationBuilder(
                        label: 'Password',
                        hint: 'Enter a secure password',
                        icon: Icons.lock_outline,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        if (value.length < 4) {
                          return 'Password must be at least 4 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox.adaptive(
                              value: rememberMe,
                              activeColor: _primaryGreen,
                              onChanged: isSubmitting ? null : onRememberMeChanged,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Remember me',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: TextButton(
                            onPressed: isSubmitting ? null : onForgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              alignment: Alignment.centerRight,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                color: _primaryGreen,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : onLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryGreen,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
