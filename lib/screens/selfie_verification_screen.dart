import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';

/// شاشة التحقق بالـ selfie: التقاط صورة وإرسالها للتحقق.
class SelfieVerificationScreen extends StatefulWidget {
  const SelfieVerificationScreen({super.key});

  @override
  State<SelfieVerificationScreen> createState() =>
      _SelfieVerificationScreenState();
}

class _SelfieVerificationScreenState extends State<SelfieVerificationScreen> {
  final UserSettingsService _userSettings = UserSettingsService();
  final ImagePicker _picker = ImagePicker();

  File? _selfieFile;
  bool _loading = false;
  bool _submitted = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final status = await _userSettings.getSelfieVerificationStatus(userId);
    if (mounted) {
      setState(() {
        _submitted = status == 'submitted' || status == 'verified';
        _statusMessage = status;
      });
    }
  }

  Future<void> _takeSelfie() async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (xfile != null && mounted) {
        setState(() => _selfieFile = File(xfile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    if (_selfieFile == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await _userSettings.submitSelfieVerification(userId, _selfieFile!);
      if (mounted) {
        setState(() {
          _loading = false;
          _submitted = true;
          _selfieFile = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).answerSaved),
            backgroundColor: AppColors.forestGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.selfieVerification,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_submitted) ...[
              Icon(Icons.verified_user, size: 80, color: AppColors.forestGreen),
              const SizedBox(height: 16),
              Text(
                _statusMessage == 'verified'
                    ? 'Your profile is verified.'
                    : 'Your selfie has been submitted for verification. We will review it shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkBlack.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _statusMessage == 'verified'
                    ? 'Verified'
                    : 'Pending verification',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.hingePurple,
                ),
              ),
            ] else ...[
              Text(
                l10n.selfieVerificationDesc,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.darkBlack.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              if (_selfieFile != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selfieFile!,
                    height: 280,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _takeSelfie,
                        icon: const Icon(Icons.camera_alt),
                        label: Text(l10n.changePhoto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _loading ? null : _submitVerification,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.hingePurple,
                        ),
                        child: _loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(l10n.postConfirm),
                      ),
                    ),
                  ],
                ),
              ] else
                FilledButton.icon(
                  onPressed: _loading ? null : _takeSelfie,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(l10n.takePhoto),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.hingePurple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
