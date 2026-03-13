import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../services/block_service.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_display_service.dart';
import '../services/profile_fields_service.dart';
import '../services/user_settings_service.dart';
import '../utils/profile_completion.dart';
import '../widgets/verified_badge.dart';
import 'profile_view_screen.dart';

/// شاشة "مميزون": بروفايلات ١٠٠٪ مكتملة وموثّقة، عرض جانبي (تمرير يسار/يمين).
class FeaturedScreen extends StatefulWidget {
  const FeaturedScreen({super.key, this.onGiftRoseTap});

  /// عند الضغط على أيقونة الوردة في البطاقة — يُستدعى مع معرّف البروفايل لفتح ورقة إرسال الهدية.
  final void Function(String profileId)? onGiftRoseTap;

  @override
  State<FeaturedScreen> createState() => _FeaturedScreenState();
}

class _FeaturedScreenState extends State<FeaturedScreen> {
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileFieldsService _profileFields = ProfileFieldsService();
  final UserSettingsService _userSettings = UserSettingsService();
  final BlockService _blockService = BlockService();
  final ProfileDisplayService _displayService = ProfileDisplayService();

  List<String> _profileIds = [];
  bool _loading = true;

  /// حسابات تجريبية لعرض التصميم عند عدم وجود مميزين حقيقيين — أسماء أجنبية لشباب وبنات.
  static const List<({String name, String avatarUrl})> _demoPlaceholders = [
    (name: 'Emma', avatarUrl: 'https://i.pravatar.cc/400?u=featured1'),
    (name: 'Sophia', avatarUrl: 'https://i.pravatar.cc/400?u=featured2'),
    (name: 'James', avatarUrl: 'https://i.pravatar.cc/400?u=featured3'),
    (name: 'Olivia', avatarUrl: 'https://i.pravatar.cc/400?u=featured4'),
    (name: 'Noah', avatarUrl: 'https://i.pravatar.cc/400?u=featured5'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final blockedIds = await _blockService.getBlockedIds(currentUserId);
      final whoBlockedMe = await _blockService.getWhoBlockedMe(currentUserId);
      final exclude = {...blockedIds, ...whoBlockedMe};

      var ids = await _answerService.getDiscoveryProfileIds(
        excludeUserId: currentUserId,
        excludeBlockedUserIds: exclude,
      );
      if (!mounted) return;

      final featured = <String>[];
      for (final id in ids) {
        try {
          final results = await Future.wait([
            _answerService.getByProfileId(id),
            _profileFields.getFields(id),
            _userSettings.getSelfieVerificationStatus(id),
          ]);
          final answers = results[0] as List<ProfileAnswer>;
          final fields =
              results[1] as Map<String, ({String value, String visibility})>;
          final verificationStatus = results[2] as String?;
          final percent = ProfileCompletion.computePercent(
            answers: answers,
            fields: fields,
          );
          if (percent >= 100 && verificationStatus == 'verified') {
            featured.add(id);
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _profileIds = featured;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hingePurple),
      );
    }
    if (_profileIds.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              l10n.featuredEmptyDescription,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.4,
                color: AppColors.darkBlack.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: PageView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _demoPlaceholders.length,
              itemBuilder: (context, index) {
                final p = _demoPlaceholders[index];
                return _FeaturedPlaceholderCard(name: p.name, avatarUrl: p.avatarUrl);
              },
            ),
          ),
        ],
      );
    }
    return PageView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _profileIds.length,
      itemBuilder: (context, index) {
        return _FeaturedProfileCard(
          profileId: _profileIds[index],
          displayService: _displayService,
          onTap: () => _openProfile(context, _profileIds[index]),
          onGiftRoseTap: widget.onGiftRoseTap != null
              ? () => widget.onGiftRoseTap!(_profileIds[index])
              : null,
        );
      },
    );
  }

  void _openProfile(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileViewScreen(
          userId: userId,
          displayName: '',
        ),
      ),
    );
  }
}

class _FeaturedProfileCard extends StatefulWidget {
  const _FeaturedProfileCard({
    required this.profileId,
    required this.displayService,
    required this.onTap,
    this.onGiftRoseTap,
  });

  final String profileId;
  final ProfileDisplayService displayService;
  final VoidCallback onTap;
  final VoidCallback? onGiftRoseTap;

  @override
  State<_FeaturedProfileCard> createState() => _FeaturedProfileCardState();
}

class _FeaturedProfileCardState extends State<_FeaturedProfileCard> {
  String _name = '';
  String? _avatarUrl;
  bool _isVerified = false;
  String _promptText = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final answerService = ProfileAnswerService();
    final info = await widget.displayService.getDisplayInfo(widget.profileId);
    List<ProfileAnswer> answers = [];
    try {
      answers = await answerService.getByProfileId(widget.profileId);
    } catch (_) {}
    String promptText = '';
    for (final a in answers) {
      if (a.itemType != 'text') continue;
      final display = _extractPromptDisplayText(a.content.trim());
      if (display.isEmpty || display.length < 10 || display.length > 200) continue;
      promptText = display.length > 120 ? '${display.substring(0, 120)}...' : display;
      break;
    }
    if (promptText.isEmpty && answers.isNotEmpty) {
      final textAnswers = answers.where((a) => a.itemType == 'text');
      if (textAnswers.isNotEmpty) {
        final first = textAnswers.first;
        final display = _extractPromptDisplayText(first.content);
        promptText = display.length > 80 ? '${display.substring(0, 80)}...' : display;
      }
    }
    if (mounted) {
      setState(() {
        _name = info.displayName;
        _avatarUrl = info.avatarUrl;
        _isVerified = info.isVerified;
        _promptText = promptText;
        _loaded = true;
      });
    }
  }

  /// يستخرج نص العرض من محتوى قد يكون JSON مثل {"prompt_id":"p1","answer":"..."}.
  static String _extractPromptDisplayText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final answer = decoded['answer']?.toString().trim();
        if (answer != null && answer.isNotEmpty) return answer;
      }
    } catch (_) {}
    return content;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hingePurple),
      );
    }
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: widget.onTap,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? Image.network(
                          _avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                  Positioned(
                    left: 16,
                    top: 20,
                    child: Builder(
                      builder: (context) {
                        final isRtl = Directionality.of(context) == TextDirection.rtl;
                        final nameWidget = Text(
                          _name,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 1)),
                            ],
                          ),
                        );
                        final badgeWidget = _isVerified
                            ? const VerifiedBadge(size: 30, color: Colors.white)
                            : const SizedBox.shrink();
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          children: isRtl
                              ? [
                                  if (_isVerified) badgeWidget,
                                  if (_isVerified) const SizedBox(width: 6),
                                  nameWidget,
                                ]
                              : [
                                  nameWidget,
                                  if (_isVerified) const SizedBox(width: 6),
                                  if (_isVerified) badgeWidget,
                                ],
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              _promptText.isEmpty ? '...' : _promptText,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 17,
                                color: AppColors.darkBlack,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _GiftIconButton(
                            onTap: widget.onGiftRoseTap ?? widget.onTap,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.hingePurple.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          _name.isNotEmpty ? _name[0].toUpperCase() : '?',
          style: GoogleFonts.montserrat(
            fontSize: 64,
            fontWeight: FontWeight.w600,
            color: AppColors.hingePurple.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}

/// أيقونة إرسال الهدية في زاوية البطاقة — نابضة بلون وردي حيوي.
class _GiftIconButton extends StatefulWidget {
  const _GiftIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GiftIconButton> createState() => _GiftIconButtonState();
}

class _GiftIconButtonState extends State<_GiftIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.rosePink,
                  AppColors.rosePink.withValues(alpha: 0.85),
                  Color(0xFFD81B60),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.9),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.rosePink.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: AppColors.rosePink.withValues(alpha: 0.25),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(
              Icons.local_florist_rounded,
              size: 22,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة تجريبية لعرض تصميم "مميزون" عند عدم وجود بيانات حقيقية — نفس تصميم صورة الثانية مع أيقونة هدية.
class _FeaturedPlaceholderCard extends StatelessWidget {
  const _FeaturedPlaceholderCard({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholderBox(),
                ),
                Positioned(
                  left: 16,
                  top: 20,
                  child: Builder(
                    builder: (context) {
                      final isRtl = Directionality.of(context) == TextDirection.rtl;
                      final nameWidget = Text(
                        name,
                        style: GoogleFonts.montserrat(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 1)),
                          ],
                        ),
                      );
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                        children: isRtl
                            ? [
                                const VerifiedBadge(size: 30, color: Colors.white),
                                const SizedBox(width: 6),
                                nameWidget,
                              ]
                            : [
                                nameWidget,
                                const SizedBox(width: 6),
                                const VerifiedBadge(size: 30, color: Colors.white),
                              ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            '...',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 17,
                              color: AppColors.darkBlack,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _GiftIconButton(onTap: () {}),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholderBox() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: AppColors.hingePurple.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: GoogleFonts.montserrat(
            fontSize: 64,
            fontWeight: FontWeight.w600,
            color: AppColors.hingePurple.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}
