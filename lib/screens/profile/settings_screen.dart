// ---------------------------------------------------------------------------
// settings_screen.dart
// ---------------------------------------------------------------------------
// Cinematic Noir settings screen for profile management.
//
// Features:
//   • Interactive avatar widget with camera overlay — tapping opens the
//     device gallery via image_picker.
//   • Editable display name and email fields with the app's glass-card styling.
//   • Gradient CTA save button.
//   • Sign-out button at the bottom.
//
// Avatar upload flow (step-by-step):
//   1. User taps avatar → ImagePicker opens device gallery.
//   2. Selected image path is stored in local state for preview.
//   3. On "Save Changes", if a new image was picked:
//      a. ProfileService.uploadAvatar() uploads to Firebase Storage at
//         `avatars/{uid}.jpg`.
//      b. The download URL is retrieved from Storage.
//      c. Firebase Auth user.updatePhotoURL() is called.
//      d. Firestore user document's `photoUrl` field is updated.
//   4. Display name changes are saved via ProfileService.updateUserProfile().
//   5. The Profile Screen's StreamBuilder picks up the Firestore change and
//      the header updates in real-time.
// ---------------------------------------------------------------------------

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_theme.dart';
import '../../services/profile_service.dart';
import '../auth/login_screeen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final _formKey = GlobalKey<FormState>();

  // ── Form controllers ──────────────────────────────────────────────────────
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // ── Avatar state ──────────────────────────────────────────────────────────
  /// The locally picked image bytes (works on web and mobile).
  Uint8List? _pickedImageBytes;

  /// The current network URL of the user's avatar (from Firebase).
  String? _currentPhotoUrl;

  // ── Loading / Error state ─────────────────────────────────────────────────
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Loads the current user's data into the form fields.
  Future<void> _loadCurrentProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final profile = await _profileService.getUserProfile();

    setState(() {
      _nameController.text = profile['displayName'] as String? ??
          user?.displayName ??
          user?.email?.split('@').first ??
          '';
      _emailController.text =
          profile['email'] as String? ?? user?.email ?? '';
      _currentPhotoUrl =
          profile['photoUrl'] as String? ?? user?.photoURL;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CinephileTheme.background,
      appBar: AppBar(
        backgroundColor: CinephileTheme.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: CinephileTheme.onSurfaceVariant,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SETTINGS',
          style: CinephileTheme.headlineLgMobile(
            color: CinephileTheme.primary,
          ).copyWith(letterSpacing: 2.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(CinephileTheme.spacingContainerPadding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 8),

              // ── Avatar Section ───────────────────────────────────────────
              _buildAvatarSection(),
              const SizedBox(height: 32),

              // ── Display Name Field ───────────────────────────────────────
              _buildTextField(
                controller: _nameController,
                label: 'Display Name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a display name';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Email Field (read-only) ──────────────────────────────────
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                readOnly: true,
                hintText: 'Email cannot be changed here',
              ),
              const SizedBox(height: 32),

              // ── Error / Success Messages ─────────────────────────────────
              if (_errorMessage != null)
                _buildMessageBanner(
                  message: _errorMessage!,
                  color: CinephileTheme.error,
                  icon: Icons.error_outline,
                ),
              if (_successMessage != null)
                _buildMessageBanner(
                  message: _successMessage!,
                  color: Colors.greenAccent,
                  icon: Icons.check_circle_outline,
                ),
              if (_errorMessage != null || _successMessage != null)
                const SizedBox(height: 16),

              // ── Save Button ──────────────────────────────────────────────
              _buildSaveButton(),
              const SizedBox(height: 24),

              // ── Divider ──────────────────────────────────────────────────
              Divider(
                color: CinephileTheme.outlineVariant.withAlpha(40),
              ),
              const SizedBox(height: 16),

              // ── Sign Out Button ──────────────────────────────────────────
              _buildSignOutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AVATAR SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAvatarSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              // Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: CinephileTheme.ctaGradient,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: CinephileTheme.background,
                  ),
                  child: CircleAvatar(
                    radius: 56,
                    backgroundColor: CinephileTheme.surfaceContainerHigh,
                    backgroundImage: _getAvatarImage(),
                    child: _shouldShowPlaceholder()
                        ? const Icon(
                            Icons.person,
                            size: 56,
                            color: CinephileTheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
              ),

              // Camera overlay badge
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: CinephileTheme.primaryContainer,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: CinephileTheme.background,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CinephileTheme.primaryContainer.withAlpha(80),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 18,
                    color: CinephileTheme.background,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to change avatar',
          style: CinephileTheme.labelSm(
            color: CinephileTheme.onSurfaceVariant,
          ).copyWith(fontSize: 11),
        ),
      ],
    );
  }

  /// Returns the appropriate image provider for the avatar.
  ImageProvider? _getAvatarImage() {
    // Prefer the locally picked image (preview before save).
    if (_pickedImageBytes != null) {
      return MemoryImage(_pickedImageBytes!);
    }
    // Fall back to the network URL from Firebase.
    if (_currentPhotoUrl != null) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  /// Determines whether to show the placeholder icon.
  bool _shouldShowPlaceholder() {
    return _pickedImageBytes == null && _currentPhotoUrl == null;
  }

  /// Opens the device gallery to pick an avatar image.
  Future<void> _pickImage() async {
    if (_isPickingImage) return;
    _isPickingImage = true;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null && mounted) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _errorMessage = null;
          _successMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not pick image: ${e.toString()}';
        });
      }
    } finally {
      _isPickingImage = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FORM FIELDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CinephileTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        border: Border.all(
          color: CinephileTheme.outlineVariant.withAlpha(60),
        ),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        style: CinephileTheme.bodyMd(color: CinephileTheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          hintStyle: CinephileTheme.bodyMd(
            color: CinephileTheme.onSurfaceVariant,
          ).copyWith(fontSize: 12),
          labelStyle: CinephileTheme.labelSm(
            color: CinephileTheme.onSurfaceVariant,
          ),
          prefixIcon: Icon(
            icon,
            color: readOnly
                ? CinephileTheme.onSurfaceVariant.withAlpha(100)
                : CinephileTheme.primaryContainer,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          suffixIcon: readOnly
              ? Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: CinephileTheme.onSurfaceVariant.withAlpha(80),
                )
              : null,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: _isSaving ? null : CinephileTheme.ctaGradient,
          color: _isSaving ? CinephileTheme.surfaceContainerHigh : null,
          borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: CinephileTheme.primaryContainer,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Save Changes',
                      style: CinephileTheme.headlineMd(color: Colors.white)
                          .copyWith(fontSize: 16),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN OUT BUTTON
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout, size: 18),
        label: Text(
          'Sign Out',
          style: CinephileTheme.labelMd(color: CinephileTheme.error),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: CinephileTheme.error,
          side: BorderSide(color: CinephileTheme.error.withAlpha(80)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MESSAGE BANNER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMessageBanner({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(CinephileTheme.radiusMd),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: CinephileTheme.labelSm(color: color).copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAVE LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _saveProfile() async {
    // Validate form fields.
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Step 1: Upload avatar if a new image was picked.
      String? newPhotoUrl;
      if (_pickedImageBytes != null) {
        newPhotoUrl = await _profileService.uploadAvatar(_pickedImageBytes!);
      }

      // Step 2: Update display name (always saved).
      await _profileService.updateUserProfile(
        displayName: _nameController.text.trim(),
        photoUrl: newPhotoUrl,
      );

      setState(() {
        _successMessage = 'Profile updated successfully!';
        _pickedImageBytes = null; // Clear picked image — now persisted.
        if (newPhotoUrl != null) _currentPhotoUrl = newPhotoUrl;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save: ${e.toString()}';
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGN OUT LOGIC
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: CinephileTheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CinephileTheme.radiusLg),
        ),
        title: Text(
          'Sign Out',
          style: CinephileTheme.headlineMd(color: CinephileTheme.onSurface),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: CinephileTheme.bodyMd(color: CinephileTheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: CinephileTheme.labelMd(
                color: CinephileTheme.onSurfaceVariant,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Sign Out',
              style: CinephileTheme.labelMd(color: CinephileTheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
