import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_display_service.dart';
import '../services/profile_like_service.dart';
import '../services/user_settings_service.dart';
import '../widgets/verified_badge.dart';

/// شاشة المطابقات — من أعجب فيك وأعجبت فيه (مطابقة متبادلة).
class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, this.isVisible = true});

  final bool isVisible;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ProfileLikeService _likeService = ProfileLikeService();
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileDisplayService _profileDisplay = ProfileDisplayService();
  final UserSettingsService _userSettings = UserSettingsService();

  List<String> _matchedUserIds = [];
  Map<String, String?> _avatarUrls = {};
  Map<String, String> _displayNames = {};
  Map<String, String> _ages = {};
  Map<String, bool> _isOnlineToday = {};
  Map<String, bool> _verified = {};
  bool _loading = true;
  bool _loadedWhenVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _scheduleLoadWhenVisible();
  }

  @override
  void didUpdateWidget(covariant MatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) _scheduleLoadWhenVisible();
  }

  void _scheduleLoadWhenVisible() {
    if (_loadedWhenVisible || !mounted) return;
    _loadedWhenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final incoming = await _likeService.getIncomingLikes();
      final outgoing = await _likeService.getOutgoingLikes();

      final incomingFrom = incoming.map((e) => e.fromUserId).toSet();
      final outgoingTo = outgoing.map((e) => e.toUserId).toSet();
      final mutual = incomingFrom.intersection(outgoingTo).toList();

      final avatarMap = <String, String?>{};
      final nameMap = <String, String>{};
      final ageMap = <String, String>{};
      final onlineMap = <String, bool>{};
      final verifiedMap = <String, bool>{};
      for (final uid in mutual) {
        final answers = await _answerService.getByProfileId(uid);
        final info = await _profileDisplay.getDisplayInfo(uid);
        avatarMap[uid] = info.avatarUrl;
        nameMap[uid] = info.displayName;
        ageMap[uid] = _ageFromAnswers(answers);
        onlineMap[uid] = await _userSettings.isOnline(uid, withinMinutes: 24 * 60);
        verifiedMap[uid] = info.isVerified;
      }

      if (mounted) {
        setState(() {
          _matchedUserIds = mutual;
          _avatarUrls = avatarMap;
          _displayNames = nameMap;
          _ages = ageMap;
          _isOnlineToday = onlineMap;
          _verified = verifiedMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  static String _ageFromAnswers(List<ProfileAnswer> answers) {
    for (final a in answers) {
      if (a.content.trim().length >= 8 &&
          (RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(a.content.trim()) ||
              RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(a.content.trim()))) {
        final age = _ageFromDateString(a.content.trim());
        if (age != null) return age.toString();
      }
    }
    return '';
  }

  static Widget _onlineDot() => Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 6),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          const Color(0xFF4ADE80),
          AppColors.forestGreen,
        ],
        stops: const [0.3, 1.0],
      ),
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.forestGreen.withValues(alpha: 0.6),
          blurRadius: 6,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    ),
  );

  static int? _ageFromDateString(String s) {
    try {
      DateTime? date;
      if (s.contains('-')) {
        date = DateTime.tryParse(s.split(' ').first);
      } else if (s.contains('/')) {
        final parts = s.split('/');
        if (parts.length >= 3) {
          final y = int.tryParse(parts[2]);
          final m = int.tryParse(parts[0]);
          final d = int.tryParse(parts[1]);
          if (y != null && m != null && d != null) date = DateTime(y, m, d);
        }
      }
      if (date == null) return null;
      final now = DateTime.now();
      var age = now.year - date.year;
      if (now.month < date.month || (now.month == date.month && now.day < date.day)) age--;
      return age > 0 && age < 120 ? age : null;
    } catch (_) {
      return null;
    }
  }

  Widget _buildMatchSquare(BuildContext context, String userId, double side) {
    final avatarUrl = _avatarUrls[userId];
    final name = _displayNames[userId] ?? '';
    final age = _ages[userId] ?? '';
    final isOnlineToday = _isOnlineToday[userId] ?? false;
    final isVerified = _verified[userId] ?? false;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: side,
          height: side,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.forestGreen.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // صورة مغبّشة (خلفية)
              ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _squareFallback(side),
                      )
                    : _squareFallback(side),
              ),
              // طبقة داكنة أسفل للمقروئية
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: side * 0.4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
              // العمر واضح + نقطة خضراء إن متصل اليوم + الاسم مغبّش
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (age.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            age,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isOnlineToday) _onlineDot(),
                        ],
                      ),
                    if (name.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          if (isVerified) ...[
                            const SizedBox(width: 4),
                            ImageFiltered(
                              imageFilter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                              child: const VerifiedBadge(size: 14),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _squareFallback(double side) {
    return Container(
      width: side,
      height: side,
      color: AppColors.forestGreen.withValues(alpha: 0.25),
      alignment: Alignment.center,
      child: const Icon(
        Icons.favorite,
        color: AppColors.forestGreen,
        size: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppColors.neonCoral)),
      );
    }

    if (_matchedUserIds.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.darkBlack,
          elevation: 0,
          title: Text(
            l10n.tabMatches,
            style: const TextStyle(
              color: AppColors.darkBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.youMatched,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkBlack.withValues(alpha: 0.7),
                  ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.tabMatches,
          style: const TextStyle(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final padding = 12.0;
          final spacing = 8.0;
          final side = (constraints.maxWidth - padding * 2 - spacing) / 2;
          return GridView.builder(
            padding: EdgeInsets.all(padding),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: 1,
            ),
            itemCount: _matchedUserIds.length,
            itemBuilder: (context, index) {
              final userId = _matchedUserIds[index];
              return _buildMatchSquare(context, userId, side);
            },
          );
        },
      ),
    );
  }
}
