import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../models/profile_like.dart';
import '../services/comment_filter_service.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_display_service.dart';
import '../services/profile_like_service.dart';
import '../services/subscription_service.dart';
import '../services/user_settings_service.dart';
/// شاشة "معجب بك" — عرض من أعجب ببروفايلك (شبكة بطاقات بدون زر قلب). المطابقة من الرئيسية أو مميزون.
class LikesYouScreen extends StatefulWidget {
  const LikesYouScreen({
    super.key,
    this.isVisible = true,
    this.onLikesChanged,
    this.onGoToDiscovery,
    this.onGoToSubscription,
  });

  final bool isVisible;
  final VoidCallback? onLikesChanged;
  final VoidCallback? onGoToDiscovery;
  final VoidCallback? onGoToSubscription;

  @override
  State<LikesYouScreen> createState() => _LikesYouScreenState();
}

class _LikesYouScreenState extends State<LikesYouScreen> {
  final ProfileLikeService _likeService = ProfileLikeService();
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileDisplayService _displayService = ProfileDisplayService();
  final UserSettingsService _userSettings = UserSettingsService();

  List<ProfileLike> _incoming = [];
  Map<String, ({String displayName, String? avatarUrl, bool isVerified})> _displayInfo = {};
  Map<String, String> _ages = {};
  Map<String, bool> _isOnline = {};
  bool _loading = true;
  bool _loadedWhenVisible = false;

  /// اعجابات وهمية لعرض التصميم عند عدم وجود إعجابات حقيقية — أسماء أجنبية لشباب وبنات.
  static const List<({String userId, String name, String avatarUrl, String age})> _demoLikesPlaceholders = [
    (userId: 'demo-like-1', name: 'Emma', avatarUrl: 'https://i.pravatar.cc/400?u=likes1', age: '26'),
    (userId: 'demo-like-2', name: 'Sophia', avatarUrl: 'https://i.pravatar.cc/400?u=likes2', age: '28'),
    (userId: 'demo-like-3', name: 'James', avatarUrl: 'https://i.pravatar.cc/400?u=likes3', age: '30'),
    (userId: 'demo-like-4', name: 'Olivia', avatarUrl: 'https://i.pravatar.cc/400?u=likes4', age: '24'),
    (userId: 'demo-like-5', name: 'Noah', avatarUrl: 'https://i.pravatar.cc/400?u=likes5', age: '27'),
    (userId: 'demo-like-6', name: 'Isabella', avatarUrl: 'https://i.pravatar.cc/400?u=likes6', age: '29'),
    (userId: 'demo-like-7', name: 'Liam', avatarUrl: 'https://i.pravatar.cc/400?u=likes7', age: '31'),
    (userId: 'demo-like-8', name: 'Mia', avatarUrl: 'https://i.pravatar.cc/400?u=likes8', age: '25'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _scheduleLoadWhenVisible();
  }

  @override
  void didUpdateWidget(covariant LikesYouScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) {
      if (_loadedWhenVisible) {
        // عند العودة لتبويب "معجب بك" نحدّث القائمة لظهور الإعجابات الجديدة (مثلاً من جهاز آخر).
        _load();
      } else {
        _scheduleLoadWhenVisible();
      }
    }
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
      var list = await _likeService.getIncomingUnmatchedLikes();
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        final filterEnabled = await _userSettings.getCommentFilterEnabled(currentUserId);
        if (filterEnabled) {
          list = list.where((like) {
            return !CommentFilterService.containsDisrespectfulLanguage(like.giftMessage);
          }).toList();
        }
      }
      final byUser = list.map((e) => e.fromUserId).toSet().toList();
      final displayMap = <String, ({String displayName, String? avatarUrl, bool isVerified})>{};
      final ageMap = <String, String>{};
      final onlineMap = <String, bool>{};
      for (final uid in byUser) {
        final answers = await _answerService.getByProfileId(uid);
        displayMap[uid] = await _displayService.getDisplayInfo(uid);
        ageMap[uid] = _ageFromAnswers(answers);
      }
      final onlineResults = await Future.wait(
        byUser.map((uid) => _userSettings.isOnline(uid, withinMinutes: 15)),
      );
      for (var i = 0; i < byUser.length; i++) {
        onlineMap[byUser[i]] = onlineResults[i];
      }
      if (mounted) {
        setState(() {
          _incoming = list;
          _displayInfo = displayMap;
          _ages = ageMap;
          _isOnline = onlineMap;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

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
    margin: const EdgeInsets.only(left: 4),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.forestGreen,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: AppColors.forestGreen.withValues(alpha: 0.6),
          blurRadius: 4,
          spreadRadius: 0.5,
        ),
      ],
    ),
  );

  Widget _blurPlaceholderBox() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.warmSand.withValues(alpha: 0.5),
      child: Icon(
        Icons.person,
        size: 48,
        color: AppColors.darkBlack.withValues(alpha: 0.2),
      ),
    );
  }

  List<({String userId, List<ProfileLike> likes})> _groupByLiker() {
    final map = <String, List<ProfileLike>>{};
    for (final like in _incoming) {
      map.putIfAbsent(like.fromUserId, () => []).add(like);
    }
    return map.entries
        .map((e) => (userId: e.key, likes: e.value))
        .toList();
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

    final groups = _groupByLiker();
    final showDemoLikes = groups.isEmpty;
    final displayCount = showDemoLikes ? _demoLikesPlaceholders.length : groups.length;

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
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.88,
        ),
        itemCount: displayCount,
        itemBuilder: (context, index) {
          final String avatarUrl;
          final String displayName;
          final String age;
          final bool isOnline;
          if (showDemoLikes) {
            final p = _demoLikesPlaceholders[index];
            avatarUrl = p.avatarUrl;
            displayName = p.name;
            age = p.age;
            isOnline = index % 2 == 0;
          } else {
            final g = groups[index];
            final info = _displayInfo[g.userId];
            avatarUrl = info?.avatarUrl ?? '';
            displayName = info?.displayName ?? '';
            age = _ages[g.userId] ?? '';
            isOnline = _isOnline[g.userId] ?? false;
          }
          final isSubscribed = SubscriptionService.instance.isSubscribed;
          final showUnblurred = isSubscribed;
          final avatarWidget = avatarUrl.isNotEmpty
              ? Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => _blurPlaceholderBox(),
                )
              : _blurPlaceholderBox();
          final nameAndAgeRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (displayName.isNotEmpty)
                Flexible(
                  child: Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 13,
                    ),
                  ),
                ),
              if (age.isNotEmpty) ...[
                if (displayName.isNotEmpty) const SizedBox(width: 6),
                Text(
                  age,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          );
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppColors.warmSandBorder.withValues(alpha: 0.5)),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                showUnblurred
                    ? avatarWidget
                    : ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: avatarWidget,
                      ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (displayName.isNotEmpty || age.isNotEmpty)
                            Flexible(
                              child: showUnblurred
                                  ? nameAndAgeRow
                                  : ImageFiltered(
                                      imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                                      child: nameAndAgeRow,
                                    ),
                            ),
                          if (isOnline) _onlineDot(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
            child: Text(
              l10n.likesYouPrompt,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.darkBlack.withValues(alpha: 0.5),
                    height: 1.3,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
