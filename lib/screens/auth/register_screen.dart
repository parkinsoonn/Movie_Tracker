// ---------------------------------------------------------------------------
// register_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir register screen — pixel-matched to the Stitch design.
//
// Features:
//   • Ambient purple/amber background blobs
//   • Large "Create Account" display heading
//   • Glassmorphism form container with labeled inputs
//   • Purple→Amber gradient "Sign Up" button
//   • Firebase AuthService integration
// ---------------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result.isSuccess) {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to sign up.'),
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
          // ── Ambient Background Blobs ─────────────────────────────────
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CinephileTheme.brandPurple.withAlpha(38),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    CinephileTheme.brandAmber.withAlpha(20),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main Content ────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── AppBar Header ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CinephileTheme.spacingContainerPadding,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white.withAlpha(13),
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                color: CinephileTheme.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/logo.png',
                                  height: 20,
                                  width: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'CINEPHILE',
                                  style: CinephileTheme.headlineMd(
                                    color: CinephileTheme.primary,
                                  ).copyWith(
                                    fontSize: 16,
                                    letterSpacing: 4.0,
                                    color: CinephileTheme.primary.withAlpha(77),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40), // Spacer for centering
                        ],
                      ),
                    ),

                    // ── Page Title ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CinephileTheme.spacingContainerPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            'Create\nAccount',
                            style: CinephileTheme.displayLg(
                              color: CinephileTheme.primary,
                            ).copyWith(height: 1.1),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join the community of film enthusiasts.',
                            style: CinephileTheme.bodyLg(
                              color: CinephileTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: CinephileTheme.spacingStackMd),

                    // ── Form Container (Glass Panel) ──────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: CinephileTheme.spacingContainerPadding,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(
                          CinephileTheme.spacingContainerPadding,
                        ),
                        decoration: BoxDecoration(
                          color: CinephileTheme.surfaceContainerHigh
                              .withAlpha(102), // ~40%
                          borderRadius: BorderRadius.circular(
                            CinephileTheme.radiusXxl,
                          ),
                          border: Border.all(
                            color: Colors.white.withAlpha(13),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Rim light
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
                            const SizedBox(height: 16),

                            _buildLabeledInput(
                              controller: _nameController,
                              label: 'FULL NAME',
                              hint: 'John Doe',
                              icon: Icons.person_outlined,
                            ),
                            const SizedBox(height: CinephileTheme.spacingStackMd),

                            _buildLabeledInput(
                              controller: _emailController,
                              label: 'EMAIL',
                              hint: 'john@example.com',
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: CinephileTheme.spacingStackMd),

                            _buildPasswordInput(
                              controller: _passwordController,
                              label: 'PASSWORD',
                              isVisible: _isPasswordVisible,
                              onToggle: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                            const SizedBox(height: CinephileTheme.spacingStackMd),

                            _buildPasswordInput(
                              controller: _confirmPasswordController,
                              label: 'CONFIRM PASSWORD',
                              isVisible: _isConfirmPasswordVisible,
                              onToggle: () => setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Sign Up button
                            _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(
                                      color: CinephileTheme.brandAmber,
                                    ),
                                  )
                                : _buildGradientButton(
                                    label: 'Sign Up',
                                    onPressed: _signUp,
                                  ),

                            const SizedBox(height: CinephileTheme.spacingStackMd),

                            // Terms & Privacy
                            Text(
                              'By signing up, you agree to our Terms\nand Privacy Policy.',
                              textAlign: TextAlign.center,
                              style: CinephileTheme.bodyMd(
                                color: CinephileTheme.onSurfaceVariant,
                              ).copyWith(fontSize: 12, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: CinephileTheme.spacingStackLg),

                    // ── Footer ──────────────────────────────────────
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: CinephileTheme.bodyMd(
                              color: CinephileTheme.onSurfaceVariant,
                            ).copyWith(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: CinephileTheme.headlineMd(
                                color: CinephileTheme.primary,
                              ).copyWith(
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                                decorationColor: CinephileTheme.primary
                                    .withAlpha(77),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Labeled Input Field ──────────────────────────────────────────────────

  Widget _buildLabeledInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: CinephileTheme.labelMd(
              color: CinephileTheme.onSurfaceVariant,
            ).copyWith(letterSpacing: 1.5),
          ),
        ),
        TextFormField(
          controller: controller,
          style: CinephileTheme.bodyMd(color: CinephileTheme.primary),
          validator: (v) =>
              v == null || v.isEmpty ? 'This field is required' : null,
          decoration: _inputDecoration(hint: hint, icon: icon),
        ),
      ],
    );
  }

  // ── Password Input Field ─────────────────────────────────────────────────

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: CinephileTheme.labelMd(
              color: CinephileTheme.onSurfaceVariant,
            ).copyWith(letterSpacing: 1.5),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          style: CinephileTheme.bodyMd(color: CinephileTheme.primary),
          validator: (v) =>
              v == null || v.isEmpty ? 'This field is required' : null,
          decoration: _inputDecoration(
            hint: '••••••••',
            icon: Icons.lock_outline,
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: CinephileTheme.onSurfaceVariant.withAlpha(128),
              ),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }

  // ── Shared Input Decoration ──────────────────────────────────────────────

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: CinephileTheme.bodyMd(
        color: CinephileTheme.onSurfaceVariant.withAlpha(77),
      ),
      prefixIcon: Icon(
        icon,
        color: CinephileTheme.onSurfaceVariant.withAlpha(128),
      ),
      filled: true,
      fillColor: CinephileTheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        borderSide: BorderSide(color: Colors.white.withAlpha(13)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        borderSide: BorderSide(color: Colors.white.withAlpha(13)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        borderSide: const BorderSide(
          color: CinephileTheme.primaryContainer,
          width: 1.5,
        ),
      ),
    );
  }

  // ── Gradient Button ──────────────────────────────────────────────────────

  Widget _buildGradientButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: CinephileTheme.ctaGradientDiagonal,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        boxShadow: [
          BoxShadow(
            color: CinephileTheme.brandPurple.withAlpha(77),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: CinephileTheme.headlineMd(color: CinephileTheme.background),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward,
              color: CinephileTheme.background,
              weight: 700,
            ),
          ],
        ),
      ),
    );
  }
}
