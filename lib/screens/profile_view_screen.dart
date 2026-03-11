import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import 'report_complaint_screen.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_fields_service.dart';
import '../services/user_settings_service.dart';
import '../widgets/verified_badge.dart';
import '../widgets/vertical_profile_view.dart';

/// عرض بروفايل مستخدم آخر (من الدردشة أو الاكتشاف).
class ProfileViewScreen extends StatefulWidget {
  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.displayName = '',
    this.onMessage,
  });

  final String userId;
  final String displayName;
  /// عند الضغط على "رسالة" — مثلاً للعودة للدردشة.
  final VoidCallback? onMessage;

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileFieldsService _profileFields = ProfileFieldsService();
  final UserSettingsService _userSettings = UserSettingsService();

  List<ProfileAnswer>? _answers;
  Map<String, String> _fields = {};
  bool _loading = true;
  bool _isVerified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _answerService.getByProfileId(widget.userId)
            .timeout(const Duration(seconds: 8), onTimeout: () => <ProfileAnswer>[]),
        _profileFields.getFields(widget.userId)
            .timeout(const Duration(seconds: 8), onTimeout: () => <String, ({String value, String visibility})>{}),
        _userSettings.getSelfieVerificationStatus(widget.userId),
      ]);
      final answers = results[0] as List<ProfileAnswer>;
      final fields = results[1] as Map<String, ({String value, String visibility})>;
      final verificationStatus = results[2] as String?;
      final fieldValues = <String, String>{};
      for (final e in fields.entries) {
        final v = e.value.value.trim();
        if (v.isNotEmpty) fieldValues[e.key] = v;
      }
      if (mounted) {
        setState(() {
          _answers = answers;
          _fields = fieldValues;
          _isVerified = verificationStatus == 'verified';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rawName = widget.displayName.trim();
    final displayName = rawName.isNotEmpty ? rawName : l10n.profile;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: const TextStyle(
                  color: AppColors.darkBlack,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_isVerified) ...[
              const SizedBox(width: 8),
              const VerifiedBadge(size: 30),
            ],
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        actions: [
          if (widget.onMessage != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              onPressed: widget.onMessage,
              tooltip: l10n.message,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'report') {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReportComplaintScreen(
                        reporterId: userId,
                        reportedId: widget.userId,
                        displayName: displayName,
                        contextType: 'profile',
                      ),
                    ),
                  );
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'report', child: Text(l10n.reportAbuse)),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.hingePurple))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.profileLoadFailed,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                )
              : _answers == null || _answers!.isEmpty
                  ? Center(
                      child: Text(
                        l10n.noProfileData,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                  : VerticalProfileView(
                      answers: _answers!,
                      showActionButtons: false,
                      personalInfoOverrides: _fields.isNotEmpty ? _fields : null,
                      lightweightMode: true,
                      locale: Localizations.localeOf(context).languageCode,
                    ),
    );
  }
}
