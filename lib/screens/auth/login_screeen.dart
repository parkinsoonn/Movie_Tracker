// ---------------------------------------------------------------------------
// login_screeen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir login screen — pixel-matched to the Stitch design.
//
// Features:
//   • Radial gradient background (purple + amber ambient glows)
//   • Glassmorphism login card with subtle rim-light effect
//   • Purple→Amber gradient "Sign In" button
//   • "Be Vietnam Pro" headlines, gold accent links
//   • Full Firebase AuthService integration
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to sign in.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      body: Stack(
        children: [
          // ── Ambient Background Glows ─────────────────────────────────
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CinephileTheme.brandPurple.withAlpha(25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CinephileTheme.brandAmber.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: CinephileTheme.spacingContainerPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 60),

                  // ── Brand Header ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(
                            CinephileTheme.radiusMd,
                          ),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 28,
                          width: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'CINEPHILE',
                        style: CinephileTheme.headlineMd(
                          color: CinephileTheme.primary,
                        ).copyWith(letterSpacing: 4.0),
                      ),
                    ],
                  ),

                  const SizedBox(height: 80),

                  // ── Glassmorphism Login Card ──────────────────────
                  Container(
                    padding: const EdgeInsets.all(
                      CinephileTheme.spacingContainerPadding,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E).withAlpha(153), // ~60%
                      borderRadius: BorderRadius.circular(
                        CinephileTheme.radiusXxl,
                      ),
                      border: Border.all(
                        color: Colors.white.withAlpha(13),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(128),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Subtle rim-light on top edge
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withAlpha(51),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Welcome text
                        Text(
                          'Welcome Back',
                          style: CinephileTheme.headlineLg(
                            color: CinephileTheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your private screening starts here.',
                          style: CinephileTheme.bodyMd(
                            color: CinephileTheme.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email field
                        _buildInputField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
                        const SizedBox(height: CinephileTheme.spacingStackSm),

                        // Password field
                        _buildInputField(
                          controller: _passwordController,
                          hint: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),

                        const SizedBox(height: 8),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: Text(
                              'Forgot Password?',
                              style: CinephileTheme.bodyMd(
                                color: CinephileTheme.brandAmber,
                              ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign In button
                        _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: CinephileTheme.brandAmber,
                                ),
                              )
                            : _buildGradientButton(
                                label: 'Sign In',
                                onPressed: _signIn,
                              ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Footer ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: CinephileTheme.bodyMd(
                          color: CinephileTheme.onSurfaceVariant,
                        ).copyWith(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign Up',
                          style: CinephileTheme.bodyMd(
                            color: CinephileTheme.brandAmber,
                          ).copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Input Field Builder ──────────────────────────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      style: CinephileTheme.bodyMd(color: CinephileTheme.onSurface),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: CinephileTheme.bodyMd(
          color: CinephileTheme.onSurfaceVariant.withAlpha(128),
        ),
        prefixIcon: Icon(
          icon,
          color: CinephileTheme.onSurfaceVariant.withAlpha(128),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: CinephileTheme.onSurfaceVariant.withAlpha(178),
                ),
                onPressed: () {
                  setState(
                    () => _isPasswordVisible = !_isPasswordVisible,
                  );
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          borderSide: const BorderSide(
            color: CinephileTheme.brandPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  // ── Gradient CTA Button ──────────────────────────────────────────────────

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: CinephileTheme.ctaGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: CinephileTheme.brandPurple.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: CinephileTheme.headlineMd(color: Colors.white),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
