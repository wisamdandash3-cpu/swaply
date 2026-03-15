import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/chat_message.dart';
import '../services/block_service.dart';
import '../services/broadcast_unread_service.dart';
import '../services/complaint_service.dart';
import '../services/chat_read_service.dart';
import '../services/message_service.dart';
import '../services/profile_like_service.dart';
import '../services/wallet_service.dart' show WalletBalance, WalletService;
import '../services/profile_display_service.dart';
import '../services/user_settings_service.dart';
import '../widgets/cinematic_rose_widget.dart';
import '../widgets/coffee_icon_widget.dart';
import '../widgets/draggable_3d_rose_widget.dart';
import '../widgets/ring_icon_widget.dart';
import '../widgets/falling_rose_petals_overlay.dart'
    show FallingPetalsInBox, FallingRosePetalsOverlay;
import '../widgets/flying_gift_message_overlay.dart';
import '../constants/gift_pricing.dart';
import '../widgets/buy_roses_sheet.dart';
import '../widgets/rose_gift_overlay.dart';
import '../widgets/empty_state_illustration.dart';
import '../widgets/star_icon_widget.dart';
import '../widgets/verified_badge.dart';
import 'profile_view_screen.dart';

/// معرّف بروفايل Swaply النظامي في الدردشة (يُعرض كأول محادثة مع شعار 344.png دائري).
const String kSwaplyPartnerId = 'swaply_system';
const String kSwaplyLogoAsset = 'assets/344.png';

/// نوع فلتر قائمة المحادثات (الترتيب أو التصفية).
enum ChatFilterType {
  newest,
  oldest,
  giftsOnly,
  unreadOnly,
}

/// شاشة الدردشة: قائمة محادثات ثم محادثة مع عرض بروفايل المرسل (اسم + صورة).
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    this.isVisible = true,
    this.filterType = ChatFilterType.newest,
    this.onGoToDiscovery,
    this.onGoToLikedYou,
    this.onGoToSubscription,
    this.onConversationsChanged,
  });

  /// يُحمّل المحادثات فقط عند عرض التبويب (تجنب التجميد).
  final bool isVisible;

  /// فلتر/ترتيب قائمة المحادثات (الأحدث، الأقدم، من أرسل هدايا، غير مقروءة).
  final ChatFilterType filterType;

  /// عند عدم وجود محادثات: الانتقال للرئيسية (الاكتشاف).
  final VoidCallback? onGoToDiscovery;

  /// عند عدم وجود محادثات: فتح شاشة الاشتراك.
  final VoidCallback? onGoToSubscription;

  /// عند عدم وجود محادثات: الانتقال لتبويب أعجبوك.
  final VoidCallback? onGoToLikedYou;

  /// يُستدعى عند تغيّر قائمة المحادثات (لتحديث الأشعار في الشريط السفلي).
  final VoidCallback? onConversationsChanged;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final MessageService _messageService = MessageService();
  final ProfileDisplayService _profileDisplay = ProfileDisplayService();
  final ChatReadService _chatReadService = ChatReadService();
  final UserSettingsService _userSettings = UserSettingsService();
  final BlockService _blockService = BlockService();
  final ProfileLikeService _likeService = ProfileLikeService();

  List<
    ({
      String id,
      String name,
      String? avatarUrl,
      bool isVerified,
      int unreadCount,
      bool isOnline,
      String? giftType,
    })
  >
  _partners = [];
  /// معرّفات المطابقات المتبادلة الذين لديهم محادثة (يُعرضون في الصف العلوي).
  List<String> _mutualMatchPartnerIds = [];
  /// منهم: من لم يفتح المستخدم المحادثة بعد (يُظهر شارة «جديد» فقط).
  List<String> _newMatchPartnerIds = [];
  /// عدد من أعجبوا بي ولم أُعجب بهم بعد (للأيقونة الأولى في الصف العلوي).
  int _incomingLikesCount = 0;
  bool _loading = true;
  String? _swaplyLogoUrl;

  static const String _matchSeenPrefKeyPrefix = 'swaply_match_seen_';

  Future<void> _loadSwaplyLogoUrl() async {
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'broadcast_avatar_url')
          .maybeSingle();
      if (!mounted) return;
      final url = res?['value'] as String?;
      if (url != null && url.trim().isNotEmpty) {
        setState(() => _swaplyLogoUrl = url.trim());
      }
    } catch (_) {}
  }

  void _scheduleLoadWhenVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.isVisible) _loadConversations();
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) {
      _scheduleLoadWhenVisible();
      _loadSwaplyLogoUrl();
    }
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // عند العودة لتاب الدردشة (مثلاً بعد إلغاء الحظر) نحدّث القائمة لتعود المحادثة كما كانت
    if (!oldWidget.isVisible && widget.isVisible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadConversations();
          _loadSwaplyLogoUrl();
        }
      });
    }
  }

  Widget _swaplyListFallback() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.darkBlack,
      alignment: Alignment.center,
      child: Text(
        'S',
        style: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _loadConversations() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }
    setState(() => _loading = true);
    final iBlocked = await _blockService.getBlockedIds(userId);
    final whoBlockedMe = await _blockService.getWhoBlockedMe(userId);
    final hideWith = {...iBlocked, ...whoBlockedMe};

    List<String> ids;
    Map<String, int> unreadMap = {};

    final serverList = await _messageService.getConversationList(userId);
    if (serverList.isNotEmpty) {
      ids = serverList.map((e) => e.partnerId).where((id) => !hideWith.contains(id)).toList();
      for (final e in serverList) {
        if (!hideWith.contains(e.partnerId)) {
          unreadMap[e.partnerId] = e.unreadCount;
        }
      }
    } else {
      var listIds = await _messageService.getConversationPartnerIds(userId);
      ids = listIds.where((id) => !hideWith.contains(id)).toList();
      unreadMap = await _chatReadService.getUnreadCountsByPartner(userId, ids);
    }

    if (ids.isEmpty) {
      final broadcastUnread = await getBroadcastUnreadCount();
      if (mounted) {
        setState(() {
          _partners = [
            (
              id: kSwaplyPartnerId,
              name: 'Swaply',
              avatarUrl: null,
              isVerified: true,
              unreadCount: broadcastUnread,
              isOnline: false,
              giftType: null,
            ),
          ];
          _loading = false;
        });
        widget.onConversationsChanged?.call();
      }
      return;
    }

    final results = await Future.wait(<Future<dynamic>>[
      Future.wait(ids.map((id) => _profileDisplay.getDisplayInfo(id))),
      Future.wait(ids.map((id) => _userSettings.isOnline(id))),
      Future.wait(ids.map((id) => _messageService.getConversationGiftType(userId, id))),
      getBroadcastUnreadCount(),
      getLastBroadcastMessageAt(),
    ]);
    final infos =
        results[0]
            as List<({String displayName, String? avatarUrl, bool isVerified})>;
    final onlines = results[1] as List<bool>;
    final giftTypes = results[2] as List<String?>;
    final broadcastUnread = results[3] as int;
    final lastBroadcastAt = results[4] as DateTime?;

    final userPartners =
        <
          ({
            String id,
            String name,
            String? avatarUrl,
            bool isVerified,
            int unreadCount,
            bool isOnline,
            String? giftType,
          })
        >[];
    for (var i = 0; i < ids.length; i++) {
      userPartners.add((
        id: ids[i],
        name: infos[i].displayName,
        avatarUrl: infos[i].avatarUrl,
        isVerified: infos[i].isVerified,
        unreadCount: unreadMap[ids[i]] ?? 0,
        isOnline: onlines[i],
        giftType: giftTypes[i],
      ));
    }

    final swaplyEntry = (
      id: kSwaplyPartnerId,
      name: 'Swaply',
      avatarUrl: null,
      isVerified: true,
      unreadCount: broadcastUnread,
      isOnline: false,
      giftType: null,
    );

    final List<
        ({
          String id,
          String name,
          String? avatarUrl,
          bool isVerified,
          int unreadCount,
          bool isOnline,
          String? giftType,
        })> partners;

    if (serverList.isNotEmpty) {
      final lastAtByPartner = {for (final e in serverList) e.partnerId: e.lastMessageAt};
      final withTime = <({String id, DateTime? at})>[
        for (final id in ids) (id: id, at: lastAtByPartner[id]),
        (id: kSwaplyPartnerId, at: lastBroadcastAt),
      ];
      withTime.sort((a, b) {
        final atA = a.at;
        final atB = b.at;
        if (atA == null && atB == null) return 0;
        if (atA == null) return 1;
        if (atB == null) return -1;
        return atB.compareTo(atA);
      });
      final idToPartner = {for (final p in userPartners) p.id: p};
      partners = [
        for (final e in withTime)
          e.id == kSwaplyPartnerId ? swaplyEntry : idToPartner[e.id]!,
      ];
    } else {
      partners = [...userPartners, swaplyEntry];
    }
    if (mounted) {
      setState(() {
        _partners = partners;
        _loading = false;
      });
      widget.onConversationsChanged?.call();
      _loadNewMatchIds(partners.map((e) => e.id).toSet());
      _loadIncomingLikesCount();
    }
  }

  Future<void> _loadIncomingLikesCount() async {
    if (!mounted) return;
    try {
      final count = await _likeService.getIncomingUnmatchedCount();
      if (mounted) setState(() => _incomingLikesCount = count);
    } catch (_) {
      if (mounted) setState(() => _incomingLikesCount = 0);
    }
  }

  Future<void> _loadNewMatchIds(Set<String> partnerIds) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;
    try {
      final mutualIds = await _likeService.getMutualMatchPartnerIds();
      final prefs = await SharedPreferences.getInstance();
      final key = '$_matchSeenPrefKeyPrefix$userId';
      final seenJson = prefs.getString(key);
      final seenIds = <String>{};
      if (seenJson != null) {
        final list = jsonDecode(seenJson) as List<dynamic>?;
        if (list != null) {
          for (final e in list) {
            if (e is String) seenIds.add(e);
          }
        }
      }
      final mutualWithChat = mutualIds.where(partnerIds.contains).toList();
      final newIds =
          mutualWithChat.where((id) => !seenIds.contains(id)).toList();
      if (mounted) {
        setState(() {
          _mutualMatchPartnerIds = mutualWithChat;
          _newMatchPartnerIds = newIds;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
        _mutualMatchPartnerIds = [];
        _newMatchPartnerIds = [];
      });
      }
    }
  }

  Future<void> _markMatchSeen(String partnerId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_matchSeenPrefKeyPrefix$userId';
      final seenJson = prefs.getString(key);
      final list = <String>[];
      if (seenJson != null) {
        final decoded = jsonDecode(seenJson) as List<dynamic>?;
        if (decoded != null) {
          for (final e in decoded) {
            if (e is String) list.add(e);
          }
        }
      }
      if (!list.contains(partnerId)) {
        list.add(partnerId);
        await prefs.setString(key, jsonEncode(list));
      }
    } catch (_) {}
  }

  /// إيموجي الهدية 🎁 في قائمة المحادثات.
  static Widget _giftEmojiWidget({double size = 18}) =>
      Text('🎁', style: TextStyle(fontSize: size, height: 1.2));

  /// لون محايد لعناصر الهدية في القائمة (بدون وردي/ذهبي/بني).
  static Color _giftListNeutralColor() =>
      AppColors.darkBlack.withValues(alpha: 0.55);

  void _openConversation(
    String partnerId,
    String partnerName,
    String? partnerAvatarUrl, {
    bool partnerIsVerified = false,
  }) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    if (partnerId != kSwaplyPartnerId) {
      _messageService.markConversationRead(userId, partnerId);
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (context) => ConversationScreen(
              currentUserId: userId,
              partnerId: partnerId,
              partnerName: partnerName,
              partnerAvatarUrl: partnerAvatarUrl,
              partnerIsVerified: partnerIsVerified,
              onMessageSent: () => _loadConversations(),
            ),
          ),
        )
        .then((_) async {
          await _markMatchSeen(partnerId);
          if (mounted) _loadConversations();
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hingePurple),
      );
    }

    if (_partners.isEmpty) {
      return _ChatEmptyState(
        onGoToDiscovery: widget.onGoToDiscovery,
        onGoToLikedYou: widget.onGoToLikedYou,
        onGoToSubscription: widget.onGoToSubscription,
      );
    }

    List<
        ({
          String id,
          String name,
          String? avatarUrl,
          bool isVerified,
          int unreadCount,
          bool isOnline,
          String? giftType,
        })> displayedPartners;
    switch (widget.filterType) {
      case ChatFilterType.newest:
        displayedPartners = List.from(_partners);
        break;
      case ChatFilterType.oldest:
        displayedPartners = _partners.reversed.toList();
        break;
      case ChatFilterType.giftsOnly:
        displayedPartners = _partners.where((p) => p.giftType != null).toList();
        break;
      case ChatFilterType.unreadOnly:
        displayedPartners = _partners.where((p) => p.unreadCount > 0).toList();
        break;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final l10n = AppLocalizations.of(context);
    final mutualMatchPartners = _partners
        .where((p) => _mutualMatchPartnerIds.contains(p.id))
        .toList();
    final showLikesYouFirst = widget.onGoToLikedYou != null;
    final showTopRow =
        showLikesYouFirst || mutualMatchPartners.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTopRow) ...[
          Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 0),
            color: AppColors.darkBlack.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: (showLikesYouFirst ? 1 : 0) + mutualMatchPartners.length,
              itemBuilder: (context, i) {
                if (showLikesYouFirst && i == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _LikesYouCard(
                      count: _incomingLikesCount,
                      label: l10n.tabMatches,
                      onTap: widget.onGoToLikedYou!,
                    ),
                  );
                }
                final partnerIndex = showLikesYouFirst ? i - 1 : i;
                final p = mutualMatchPartners[partnerIndex];
                final showNewBadge = _newMatchPartnerIds.contains(p.id);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: InkWell(
                    onTap: () => _openConversation(
                      p.id,
                      p.name,
                      p.avatarUrl,
                      partnerIsVerified: p.isVerified,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.hingePurple.withValues(alpha: 0.2),
                              backgroundImage: p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                                  ? NetworkImage(p.avatarUrl!)
                                  : null,
                              child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                                  ? Text(
                                      p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                      style: GoogleFonts.montserrat(
                                        color: AppColors.hingePurple,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 22,
                                      ),
                                    )
                                  : null,
                            ),
                            if (showNewBadge)
                              Positioned(
                                right: -4,
                                top: -4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.rosePink,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.rosePink.withValues(alpha: 0.5),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    l10n.newMatchLabel,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: 72,
                          child: Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.darkBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 1.5,
            margin: const EdgeInsets.symmetric(vertical: 0),
            color: AppColors.darkBlack.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            itemCount: displayedPartners.length,
            itemBuilder: (context, i) {
              final p = displayedPartners[i];
              final isSwaply = p.id == kSwaplyPartnerId;
              final content = Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSwaply
                  ? AppColors.warmSand.withValues(alpha: 0.12)
                  : (p.giftType != null
                      ? AppColors.warmSand.withValues(alpha: 0.14)
                      : Colors.transparent),
            ),
            child: ListTile(
              minLeadingWidth: 56,
              leading: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                  if (isSwaply)
                    ClipOval(
                      child: _swaplyLogoUrl != null && _swaplyLogoUrl!.trim().isNotEmpty
                          ? Image.network(
                              _swaplyLogoUrl!,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _swaplyListFallback(),
                            )
                          : Transform.scale(
                              scale: 1.68,
                              child: Image.asset(
                                kSwaplyLogoAsset,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _swaplyListFallback(),
                              ),
                            ),
                    )
                  else
                  Container(
                    decoration: p.giftType != null
                        ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _giftListNeutralColor(),
                              width: 2,
                            ),
                          )
                        : null,
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.hingePurple.withValues(
                        alpha: 0.2,
                      ),
                      backgroundImage:
                          p.avatarUrl != null && p.avatarUrl!.isNotEmpty
                          ? NetworkImage(p.avatarUrl!)
                          : null,
                      child: p.avatarUrl == null || p.avatarUrl!.isEmpty
                          ? Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                              style: GoogleFonts.montserrat(
                                color: AppColors.hingePurple,
                                fontWeight: FontWeight.w600,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                  ),
                  if (!isSwaply && p.isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
                ),
              ),
              title: Row(
                children: [
                  if (p.giftType != null) ...[
                    _giftEmojiWidget(size: 18),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (p.isVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge(size: 30),
                        ],
                      ],
                    ),
                  ),
                  if (p.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF3D3D3D),
                            Color(0xFF252525),
                            Color(0xFF1A1A1A),
                          ],
                          stops: [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Text(
                        p.unreadCount > 99 ? '99+' : '${p.unreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (p.giftType != null) ...[
                    Text(
                      AppLocalizations.of(context).giftSenderLabel,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _giftListNeutralColor(),
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    p.unreadCount > 0
                        ? (p.unreadCount == 1
                            ? 'رسالة جديدة'
                            : '${p.unreadCount} رسائل جديدة')
                        : AppLocalizations.of(context).tapToViewConversation,
                  ),
                ],
              ),
              onTap: () => _openConversation(
                p.id,
                p.name,
                p.avatarUrl,
                partnerIsVerified: p.isVerified,
              ),
            ),
          );
              if (isSwaply) return content;
              return Dismissible(
                key: ValueKey(p.id),
                direction: DismissDirection.startToEnd,
                background: Container(
                  color: Colors.red,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsetsDirectional.only(start: 24),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                onDismissed: (_) async {
                  final partnerId = p.id;
                  setState(() => _partners.removeWhere((e) => e.id == partnerId));
                  widget.onConversationsChanged?.call();
                  await _messageService.deleteConversation(userId, partnerId);
                },
                child: content,
              );
            },
          ),
        ),
      ],
    );
  }
}

/// أول عنصر في صف المطابقات: أيقونة «معجب بك» مع العدد (بنفس تصميم الصورة المرجعية).
class _LikesYouCard extends StatelessWidget {
  const _LikesYouCard({
    required this.count,
    required this.label,
    required this.onTap,
  });

  final int count;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final displayCount = count > 99 ? '99+' : count.toString();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.ringGold,
                    width: 2.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.ringGold.withValues(alpha: 0.25),
                      AppColors.warmSand.withValues(alpha: 0.35),
                      AppColors.hingePurple.withValues(alpha: 0.12),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ringGold,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ringGold.withValues(alpha: 0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      displayCount,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -6,
                child: Center(
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 20,
                    color: AppColors.ringGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// حالة عدم وجود محادثات: تصميم موحّد مع دائرة وأيقونات + زرّان (ممیزون، اشتراك).
class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({
    this.onGoToDiscovery,
    this.onGoToLikedYou,
    this.onGoToSubscription,
  });

  final VoidCallback? onGoToDiscovery;
  final VoidCallback? onGoToLikedYou;
  final VoidCallback? onGoToSubscription;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return EmptyStateIllustration(
      title: l10n.tabChat,
      description: l10n.chatEmptyDescription,
      primaryButtonLabel: onGoToLikedYou != null ? l10n.tabMatches : null,
      primaryButtonIcon: onGoToLikedYou != null
          ? StarIconWidget(color: Colors.white, size: 30, isSelected: true)
          : null,
      onPrimaryPressed: onGoToLikedYou,
      secondaryButtonLabel: onGoToSubscription != null ? l10n.swaplySubscription : null,
      onSecondaryPressed: onGoToSubscription,
    );
  }
}

/// شاشة محادثة واحدة: رسائل مع اسم وصورة المرسل.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({
    super.key,
    required this.currentUserId,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    this.partnerIsVerified = false,
    this.onMessageSent,
  });

  final String currentUserId;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final bool partnerIsVerified;
  final VoidCallback? onMessageSent;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final MessageService _messageService = MessageService();
  final ChatReadService _chatReadService = ChatReadService();
  final UserSettingsService _userSettings = UserSettingsService();
  final BlockService _blockService = BlockService();
  final ComplaintService _complaintService = ComplaintService();
  final WalletService _walletService = WalletService();
  final ProfileLikeService _likeService = ProfileLikeService();
  final ProfileDisplayService _profileDisplay = ProfileDisplayService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _lastUnreadKey = GlobalKey();

  List<ChatMessage> _messages = [];
  int? _lastUnreadIndex;
  bool _loading = true;
  bool _partnerOnline = false;
  String? _currentUserAvatarUrl;
  RealtimeChannel? _realtimeChannel;
  bool _partnerTyping = false;
  Timer? _typingDebounceTimer;
  Timer? _typingStopTimer;
  Timer? _partnerTypingHideTimer;
  ChatMessage? _replyingTo;
  final Map<String, String> _reactions = {};
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordingDurationSec = 0;
  bool _recordingPaused = false;
  final List<double> _waveformHeights = [];
  Timer? _recordingTimer;
  Timer? _amplitudeTimer;
  String? _recordingPath;
  List<Map<String, dynamic>> _broadcastMessages = [];
  String? _currentUserDisplayName;
  String? _swaplyLogoUrl;

  /// صحيح فقط بعد أن يرد الطرف الآخر؛ قبلها لا يُعرض شريط الكتابة.
  bool get _hasPartnerReplied =>
      _messages.any((m) => m.senderId == widget.partnerId);

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadPartnerOnline();
    _loadCurrentUserAvatar();
    _subscribeToNewMessages();
    _controller.addListener(_onTypingChanged);
    if (widget.partnerId == kSwaplyPartnerId) _loadBroadcastMessages();
    _loadSwaplyLogoUrl();
  }

  Future<void> _loadSwaplyLogoUrl() async {
    try {
      final res = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'broadcast_avatar_url')
          .maybeSingle();
      if (!mounted) return;
      final url = res?['value'] as String?;
      if (url != null && url.trim().isNotEmpty) {
        setState(() => _swaplyLogoUrl = url.trim());
      }
    } catch (_) {}
  }

  Future<void> _loadBroadcastMessages() async {
    try {
      final list = await Supabase.instance.client
          .from('broadcast_messages')
          .select('id, content, image_url, video_url, created_at')
          .order('created_at', ascending: false);
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      final lastSeen = prefs.getString('broadcast_last_seen_at');
      DateTime? lastSeenDt;
      if (lastSeen != null) lastSeenDt = DateTime.tryParse(lastSeen);
      bool hasNew = false;
      if (list.isNotEmpty && lastSeenDt != null) {
        final latest = list.first;
        final created = latest['created_at'] as String?;
        if (created != null) {
          final createdDt = DateTime.tryParse(created);
          if (createdDt != null && createdDt.isAfter(lastSeenDt)) hasNew = true;
        }
      } else if (list.isNotEmpty) hasNew = true;
      setState(() => _broadcastMessages = List<Map<String, dynamic>>.from(list));
      if (hasNew && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('رسالة جديدة من فريق سوابلي'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      final latestCreated = list.isNotEmpty ? list.first['created_at'] as String? : null;
      if (latestCreated != null) await prefs.setString('broadcast_last_seen_at', latestCreated);
    } catch (e, st) {
      debugPrint('BroadcastMessage load error: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> _loadCurrentUserAvatar() async {
    final info = await _profileDisplay.getDisplayInfo(widget.currentUserId);
    if (mounted) {
      setState(() {
        _currentUserAvatarUrl = info.avatarUrl;
        _currentUserDisplayName = info.displayName;
      });
    }
  }

  /// اسم القناة المشتركة بين الطرفين (مرتب ليتفق الطرفان على نفس الاسم).
  static String _typingChannelName(String userId1, String userId2) {
    final ids = [userId1, userId2]..sort();
    return 'chat:${ids[0]}:${ids[1]}';
  }

  /// اشتراك Realtime لظهور الرسائل الجديدة ومؤشر "جاري الكتابة".
  void _subscribeToNewMessages() {
    final currentUserId = widget.currentUserId;
    final partnerId = widget.partnerId;
    final channelName = _typingChannelName(currentUserId, partnerId);
    _realtimeChannel = Supabase.instance.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final map = payload.newRecord as Map<String, dynamic>?;
            if (map == null) return;
            final senderId = map['sender_id'] as String?;
            final receiverId = map['receiver_id'] as String?;
            final isFromPartner =
                senderId == partnerId && receiverId == currentUserId;
            final isFromMe =
                senderId == currentUserId && receiverId == partnerId;
            if ((isFromPartner || isFromMe) && mounted) {
              _loadMessages(showLoading: false);
            }
          },
        )
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final userId = payload['userId'] as String?;
            final typing = payload['typing'] as bool?;
            if (userId != partnerId || !mounted) return;
            _partnerTypingHideTimer?.cancel();
            if (typing == true) {
              setState(() => _partnerTyping = true);
              _partnerTypingHideTimer = Timer(const Duration(seconds: 4), () {
                if (mounted) setState(() => _partnerTyping = false);
              });
            } else {
              setState(() => _partnerTyping = false);
            }
          },
        )
        .subscribe();
  }

  void _onTypingChanged() {
    _typingStopTimer?.cancel();
    if (_controller.text.trim().isEmpty) {
      _sendTyping(false);
      return;
    }
    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _sendTyping(true);
      _typingStopTimer = Timer(
        const Duration(seconds: 2),
        () => _sendTyping(false),
      );
    });
  }

  void _sendTyping(bool typing) {
    _typingDebounceTimer?.cancel();
    _typingStopTimer?.cancel();
    _realtimeChannel?.sendBroadcastMessage(
      event: 'typing',
      payload: {'userId': widget.currentUserId, 'typing': typing},
    );
  }

  Future<void> _loadPartnerOnline() async {
    final online = await _userSettings.isOnline(widget.partnerId);
    if (mounted) setState(() => _partnerOnline = online);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTypingChanged);
    _sendTyping(false);
    _typingDebounceTimer?.cancel();
    _typingStopTimer?.cancel();
    _partnerTypingHideTimer?.cancel();
    _recordingTimer?.cancel();
    _amplitudeTimer?.cancel();
    final ch = _realtimeChannel;
    if (ch != null) {
      ch.unsubscribe();
      Supabase.instance.client.removeChannel(ch);
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  static final Set<String> _shownRoseMessageIds = {};

  Future<void> _loadMessages({bool showLoading = true}) async {
    if (widget.partnerId == kSwaplyPartnerId) {
      if (mounted) {
        setState(() {
        _messages = [];
        _loading = false;
      });
      }
      return;
    }
    if (showLoading) setState(() => _loading = true);
    final lastSeen = await _chatReadService.getLastSeen(
      widget.currentUserId,
      widget.partnerId,
    );
    final list = await _messageService.getMessagesBetween(
      widget.currentUserId,
      widget.partnerId,
    );
    int? lastUnreadIndex;
    if (list.isNotEmpty) {
      if (lastSeen == null) {
        lastUnreadIndex = list.length - 1;
      } else {
        for (var i = list.length - 1; i >= 0; i--) {
          if (list[i].senderId == widget.partnerId &&
              list[i].createdAt.isAfter(lastSeen)) {
            lastUnreadIndex = i;
            break;
          }
        }
      }
    }
    if (mounted) {
      setState(() {
        _messages = list;
        _lastUnreadIndex = lastUnreadIndex;
        _loading = false;
      });
      _showRoseGiftIfNeeded(list);
      if (lastUnreadIndex != null && lastUnreadIndex >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final ctx = _lastUnreadKey.currentContext;
          if (ctx != null) {
            Scrollable.ensureVisible(
              ctx,
              alignment: 0.0,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
            );
          }
          _chatReadService.markConversationAsRead(
            widget.currentUserId,
            widget.partnerId,
          );
        });
      } else {
        _chatReadService.markConversationAsRead(
          widget.currentUserId,
          widget.partnerId,
        );
      }
    }
  }

  static const List<String> _giftTypes = [
    'rose_gift',
    'ring_gift',
    'coffee_gift',
  ];

  void _showRoseGiftIfNeeded(List<ChatMessage> list) {
    final giftMessages = list
        .where(
          (m) =>
              m.receiverId == widget.currentUserId &&
              m.photoUrl != null &&
              _giftTypes.contains(m.photoUrl),
        )
        .toList();
    if (giftMessages.isEmpty) return;
    final last = giftMessages.last;
    if (_shownRoseMessageIds.contains(last.id)) return;
    _shownRoseMessageIds.add(last.id);
    if (!mounted) return;
    RoseGiftOverlay.show(
      context,
      senderName: widget.partnerName,
      message: last.content.trim().isEmpty ? null : last.content.trim(),
      onComplete: () {},
      senderAvatarUrl: widget.partnerAvatarUrl,
      giftType: last.photoUrl!,
    );
  }

  void _showMessageActions(ChatMessage message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MessageActionTile(
                icon: Icons.reply_rounded,
                label: l10n.messageActionReply,
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = message);
                },
              ),
              _MessageActionTile(
                icon: Icons.emoji_emotions_outlined,
                label: l10n.messageActionReact,
                onTap: () {
                  Navigator.pop(ctx);
                  _showReactPicker(message);
                },
              ),
              _MessageActionTile(
                icon: Icons.copy_rounded,
                label: l10n.messageActionCopy,
                onTap: () {
                  if (message.content.trim().isNotEmpty) {
                    Clipboard.setData(ClipboardData(text: message.content));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.messageCopied),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                  Navigator.pop(ctx);
                },
              ),
              _MessageActionTile(
                icon: Icons.delete_outline_rounded,
                label: l10n.messageActionDelete,
                onTap: () async {
                  Navigator.pop(ctx);
                  final ok = await _messageService.deleteMessage(message.id);
                  if (!mounted) return;
                  if (ok) {
                    setState(() {
                      _messages = _messages
                          .where((m) => m.id != message.id)
                          .toList();
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.messageDeletedForBoth),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorOccurred),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReactPicker(ChatMessage message) {
    if (!mounted) return;
    const emojis = ['👍', '❤️', '😂', '😮', '😢'];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: emojis
                .map(
                  (e) => IconButton(
                    onPressed: () {
                      setState(() {
                        if (_reactions[message.id] == e) {
                          _reactions.remove(message.id);
                        } else {
                          _reactions[message.id] = e;
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    icon: Text(e, style: const TextStyle(fontSize: 32)),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.hingePurple.withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }

  void _onSwipeToReply(ChatMessage message) {
    setState(() => _replyingTo = message);
  }

  /// نص يُعرض/يُرسل عند الرد: للهدايا نستخدم وصفاً ثابتاً، وإلا محتوى الرسالة.
  String _getReplyDisplayContent(ChatMessage message) {
    if (!mounted) return message.content;
    final l10n = AppLocalizations.of(context);
    if (_MessageBubble.isGiftMessage(message)) return l10n.seriousGiftMessage;
    return message.content;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    // منع الإرسال إذا الطرف الآخر حظرني — لا إزعاج
    final partnerBlockedMe = await _blockService.hasBlocked(
      widget.partnerId,
      widget.currentUserId,
    );
    if (partnerBlockedMe && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).blockedCannotSend),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _sendTyping(false);
    final replyingTo = _replyingTo;
    setState(() => _replyingTo = null);
    _controller.clear();
    // ظهور الرسالة فوراً (optimistic)
    final replyToPhotoUrl =
        replyingTo != null && _MessageBubble.isGiftMessage(replyingTo)
        ? replyingTo.photoUrl
        : null;
    final tempMsg = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderId: widget.currentUserId,
      receiverId: widget.partnerId,
      content: text,
      createdAt: DateTime.now(),
      replyToId: replyingTo?.id,
      replyToContent: replyingTo != null
          ? _getReplyDisplayContent(replyingTo)
          : null,
      replyToSenderId: replyingTo?.senderId,
      replyToPhotoUrl: replyToPhotoUrl,
    );
    if (mounted) {
      setState(() {
        _messages = [..._messages, tempMsg];
      });
    }
    final replyContent = replyingTo != null
        ? _getReplyDisplayContent(replyingTo)
        : null;
    final result = await _messageService.sendMessage(
      senderId: widget.currentUserId,
      receiverId: widget.partnerId,
      content: text,
      replyToId: replyingTo?.id,
      replyToContent: replyContent != null
          ? (replyContent.length > 500
                ? '${replyContent.substring(0, 500)}...'
                : replyContent)
          : null,
      replyToSenderId: replyingTo?.senderId,
      replyToPhotoUrl: replyToPhotoUrl,
    );
    if (mounted) {
      if (result.isOk && result.messageId != null) {
        setState(() {
          _messages = _messages.map((m) {
            if (m.id == tempMsg.id) {
              return ChatMessage(
                id: result.messageId!,
                senderId: m.senderId,
                receiverId: m.receiverId,
                content: m.content,
                createdAt: m.createdAt,
                photoUrl: m.photoUrl,
                replyToId: m.replyToId,
                replyToContent: m.replyToContent,
                replyToSenderId: m.replyToSenderId,
                replyToPhotoUrl: m.replyToPhotoUrl,
              );
            }
            return m;
          }).toList();
        });
        widget.onMessageSent?.call();
      } else {
        setState(
          () => _messages = _messages.where((m) => m.id != tempMsg.id).toList(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? ''),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBlockOrReportSheet(BuildContext context, {required bool isBlock}) {
    final l10n = AppLocalizations.of(context);
    if (isBlock) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.blockUser,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.darkBlack,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.blockConfirmMessage(widget.partnerName),
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: AppColors.darkBlack.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final ok = await _blockService.block(
                          widget.currentUserId,
                          widget.partnerId,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok ? l10n.blockedSuccess : l10n.errorOccurred,
                              ),
                              backgroundColor: ok
                                  ? AppColors.hingePurple
                                  : Colors.red,
                            ),
                          );
                          if (ok) Navigator.of(context).pop();
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: Text(l10n.block),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      _showReportComplaintSheet(context);
    }
  }

  void _showReportComplaintSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    File? evidenceFile;
    final reasonController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.reportAbuse,
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.complaintReason,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: l10n.complaintReasonHint,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.complaintEvidence,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.darkBlack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (evidenceFile != null)
                      Stack(
                        alignment: Alignment.topLeft,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              evidenceFile!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setModalState(() => evidenceFile = null),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final xfile = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 85,
                            maxWidth: 1080,
                          );
                          if (xfile != null) {
                            setModalState(
                              () => evidenceFile = File(xfile.path),
                            );
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text(l10n.complaintAddEvidence),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed:
                                (reasonController.text.trim().isEmpty ||
                                    evidenceFile == null)
                                ? null
                                : () async {
                                    final reasonText = reasonController.text
                                        .trim();
                                    Navigator.pop(ctx);
                                    final err = await _complaintService
                                        .reportUser(
                                          reporterId: widget.currentUserId,
                                          reportedId: widget.partnerId,
                                          reason: reasonText,
                                          context: 'chat',
                                          evidenceImage: evidenceFile,
                                        );
                                    if (mounted) {
                                      final ok = err == null;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok ? l10n.reportSent : err,
                                          ),
                                          backgroundColor: ok
                                              ? AppColors.hingePurple
                                              : Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.hingePurple,
                            ),
                            child: Text(l10n.sendReport),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPartnerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileViewScreen(
          userId: widget.partnerId,
          displayName: widget.partnerName,
          onMessage: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _startVoiceRecording() async {
    if (_isRecording || !mounted) return;
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).microphonePermissionDenied,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: path);
      if (!mounted) return;
      setState(() {
        _isRecording = true;
        _recordingDurationSec = 0;
        _recordingPaused = false;
        _waveformHeights.clear();
        _recordingPath = path;
      });
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          if (!_recordingPaused) _recordingDurationSec++;
        });
      });
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 80), (
        _,
      ) async {
        try {
          final amp = await _audioRecorder.getAmplitude();
          if (!mounted) return;
          setState(() {
            double v = 0.15;
            if (amp.current > -90) {
              v = 0.15 + 0.85 * ((amp.current + 90) / 90).clamp(0.0, 1.0);
            }
            _waveformHeights.add(v);
            if (_waveformHeights.length > 80) _waveformHeights.removeAt(0);
          });
        } catch (_) {}
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).voicePlaybackFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _cancelVoiceRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    try {
      await _audioRecorder.cancel();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDurationSec = 0;
        _recordingPaused = false;
        _waveformHeights.clear();
        _recordingPath = null;
      });
    }
  }

  Future<void> _pauseResumeVoiceRecording() async {
    if (!_isRecording) return;
    try {
      if (_recordingPaused) {
        await _audioRecorder.resume();
      } else {
        await _audioRecorder.pause();
      }
      if (mounted) setState(() => _recordingPaused = !_recordingPaused);
    } catch (_) {}
  }

  Future<void> _sendVoiceRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _amplitudeTimer?.cancel();
    _amplitudeTimer = null;
    final path = _recordingPath;
    try {
      final p = await _audioRecorder.stop();
      final filePath = p ?? path;
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDurationSec = 0;
          _recordingPaused = false;
          _waveformHeights.clear();
          _recordingPath = null;
        });
      }
      if (filePath != null && filePath.isNotEmpty) {
        await _uploadAndSendVoiceMessage(filePath);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDurationSec = 0;
          _recordingPaused = false;
          _waveformHeights.clear();
          _recordingPath = null;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).voiceUploadFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _uploadAndSendVoiceMessage(String filePath) async {
    try {
      final partnerBlockedMe = await _blockService.hasBlocked(
        widget.partnerId,
        widget.currentUserId,
      );
      if (partnerBlockedMe && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).blockedCannotSend),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final file = File(filePath);
      if (!await file.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).voiceUploadFailed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      const bucket = 'profile-audio';
      final fileName =
          '${widget.currentUserId}/${widget.partnerId}/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await Supabase.instance.client.storage
          .from(bucket)
          .upload(fileName, file, fileOptions: const FileOptions(upsert: true));
      final url = Supabase.instance.client.storage
          .from(bucket)
          .getPublicUrl(fileName);
      final result = await _messageService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.partnerId,
        content: AppLocalizations.of(context).voiceRecording,
        photoUrl: url,
      );
      if (mounted) {
        if (!result.isOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? ''),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          widget.onMessageSent?.call();
          _loadMessages(showLoading: false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).voiceUploadFailed),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showGiftSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => _GiftSheetContent(
        walletService: _walletService,
        likeService: _likeService,
        messageService: _messageService,
        blockService: _blockService,
        partnerId: widget.partnerId,
        currentUserId: widget.currentUserId,
        onSent: (String? giftType, String? messageId) {
          Navigator.pop(modalContext);
          if (giftType != null) {
            FallingRosePetalsOverlay.playMagicChime(true);
            final id =
                messageId ??
                'temp-gift-${DateTime.now().millisecondsSinceEpoch}';
            final msg = ChatMessage(
              id: id,
              senderId: widget.currentUserId,
              receiverId: widget.partnerId,
              content: ' ',
              createdAt: DateTime.now(),
              photoUrl: giftType,
            );
            setState(() {
              _messages = [..._messages, msg];
            });
          }
          Future.delayed(const Duration(milliseconds: 800), () {
            if (!mounted) return;
            _loadMessages();
          });
          widget.onMessageSent?.call();
        },
        onBuyGifts: (String? initialType) {
          Navigator.pop(context);
          showBuyRosesSheet(context, initialGiftType: initialType);
        },
      ),
    );
  }

  /// تاريخ تسجيل المستخدم من Auth (لعرضه في محادثة Swaply).
  static DateTime? _userRegistrationDate() {
    try {
      final raw = Supabase.instance.client.auth.currentUser;
      if (raw == null) return null;
      final createdAt = raw.createdAt;
      if (createdAt.isNotEmpty) {
        return DateTime.parse(createdAt);
      }
    } catch (_) {}
    return null;
  }

  static const Color _swaplyCreamBg = Color(0xFFF5F0E8);

  /// بناء ترحيب غني: اسم المستخدم بلون أسود غامق وعريض (w700).
  Widget _buildSwaplyWelcomeRichText(BuildContext context, AppLocalizations l10n) {
    final name = _currentUserDisplayName?.trim() ?? '';
    if (name.isEmpty) {
      return Text(
        l10n.swaplyWelcomeMessage,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          color: AppColors.darkBlack.withValues(alpha: 0.85),
          height: 1.55,
        ),
      );
    }
    final fullText = l10n.swaplyWelcomeMessageWithName(name);
    final nameStart = fullText.indexOf(name);
    if (nameStart < 0) {
      return Text(
        fullText,
        style: GoogleFonts.montserrat(
          fontSize: 15,
          color: AppColors.darkBlack.withValues(alpha: 0.85),
          height: 1.55,
        ),
      );
    }
    final before = fullText.substring(0, nameStart);
    final after = fullText.substring(nameStart + name.length);
    final baseStyle = GoogleFonts.montserrat(
      fontSize: 15,
      color: AppColors.darkBlack.withValues(alpha: 0.85),
      height: 1.55,
    );
    final nameStyle = GoogleFonts.montserrat(
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: AppColors.darkBlack,
      height: 1.55,
    );
    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: before),
          TextSpan(text: name, style: nameStyle),
          TextSpan(text: after),
        ],
      ),
    );
  }

  /// واجهة محادثة Swaply: شعار 344.png دائري + صورة المستخدم، ورسالة ترحيب.
  Widget _buildSwaplyConversationScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final regDate = _userRegistrationDate() ?? DateTime.now();
    final dateOnly = DateFormat('d. MMMM yyyy', locale.languageCode).format(regDate);
    final dateWithTime = DateFormat('d. MMMM yyyy \'at\' HH:mm', locale.languageCode).format(regDate);

    return Scaffold(
      backgroundColor: _swaplyCreamBg,
      appBar: AppBar(
        backgroundColor: _swaplyCreamBg,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SwaplyLogoCircle(size: 36, assetPath: kSwaplyLogoAsset, imageUrl: _swaplyLogoUrl),
            const SizedBox(width: 10),
            Text(
              'Swaply',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: AppColors.darkBlack,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadBroadcastMessages,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Text(
                  dateOnly,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _CrushAvatarsStack(
                logoAssetPath: kSwaplyLogoAsset,
                logoImageUrl: _swaplyLogoUrl,
                profileImageUrl: _currentUserAvatarUrl,
                avatarSize: 72,
                overlap: -14,
                heartSize: 36,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.youCrushedWithSwaply,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  fontStyle: FontStyle.italic,
                  color: AppColors.darkBlack,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateWithTime,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // رسالة الترحيب تظهر دائماً أولاً (خاصة للحسابات الجديدة)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _buildSwaplyWelcomeRichText(context, l10n),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _SwaplyLogoCircle(size: 20, assetPath: kSwaplyLogoAsset, imageUrl: _swaplyLogoUrl),
                        const SizedBox(width: 8),
                        Text(
                          l10n.swaplyTeam,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlack.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // ثم الرسائل الجماعية المرسلة من لوحة التحكم
              ...List.generate(_broadcastMessages.length, (i) {
                  final m = _broadcastMessages[i];
                  final content = (m['content'] as String?)?.trim() ?? '';
                  final imageUrl = m['image_url'] as String?;
                  final videoUrl = m['video_url'] as String?;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (content.isNotEmpty)
                                Text(
                                  content,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 15,
                                    color: AppColors.darkBlack.withValues(alpha: 0.85),
                                    height: 1.55,
                                  ),
                                ),
                              if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                if (content.isNotEmpty) const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  ),
                                ),
                              ],
                              if (videoUrl != null && videoUrl.isNotEmpty) ...[
                                if (content.isNotEmpty || (imageUrl != null && imageUrl.isNotEmpty)) const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    color: Colors.grey.shade200,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.play_circle_fill, color: AppColors.darkBlack),
                                        const SizedBox(width: 8),
                                        Text('فيديو', style: GoogleFonts.montserrat(fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SwaplyLogoCircle(size: 20, assetPath: kSwaplyLogoAsset, imageUrl: _swaplyLogoUrl),
                            const SizedBox(width: 8),
                            Text(
                              l10n.swaplyTeam,
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlack.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (widget.partnerId == kSwaplyPartnerId) {
      return _buildSwaplyConversationScaffold(context);
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.grey.shade200),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            padding: const EdgeInsets.all(8),
            onSelected: (value) {
              if (value == 'gift') {
                _showGiftSheet();
              } else if (value == 'block') {
                _showBlockOrReportSheet(context, isBlock: true);
              } else if (value == 'report') {
                _showBlockOrReportSheet(context, isBlock: false);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'gift', child: Text(l10n.giftSenderLabel)),
              PopupMenuItem(value: 'block', child: Text(l10n.blockUser)),
              PopupMenuItem(value: 'report', child: Text(l10n.reportAbuse)),
            ],
          ),
        ],
        title: InkWell(
          onTap: _openPartnerProfile,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.ringGold.withValues(alpha: 0.9),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.ringGold.withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey.shade700,
                        backgroundImage:
                            widget.partnerAvatarUrl != null &&
                                widget.partnerAvatarUrl!.isNotEmpty
                            ? NetworkImage(widget.partnerAvatarUrl!)
                            : null,
                        child:
                            widget.partnerAvatarUrl == null ||
                                widget.partnerAvatarUrl!.isEmpty
                            ? Text(
                                widget.partnerName.isNotEmpty
                                    ? widget.partnerName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.montserrat(
                                  color: Colors.grey.shade200,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                    if (_partnerOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.forestGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF383838),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          widget.partnerName,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade200,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.partnerIsVerified) ...[
                        const SizedBox(width: 6),
                        const VerifiedBadge(size: 30),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        backgroundColor: const Color(0xFF383838),
        foregroundColor: Colors.grey.shade200,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.hingePurple,
                    ),
                  )
                : _messages.isEmpty
                ? Center(
                    child: Text(
                      'لا رسائل بعد. ابدأ المحادثة.',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        key: ValueKey(
                          'messages_${Localizations.localeOf(context).languageCode}',
                        ),
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, i) {
                          final realIndex = _messages.length - 1 - i;
                          final message = _messages[realIndex];
                          final isMe = message.senderId == widget.currentUserId;
                          final bubble = _MessageBubble(
                            message: message,
                            currentUserId: widget.currentUserId,
                            partnerId: widget.partnerId,
                            partnerName: widget.partnerName,
                            partnerAvatarUrl: widget.partnerAvatarUrl,
                            currentUserAvatarUrl: _currentUserAvatarUrl,
                            l10n: l10n,
                            onTapPartner: _openPartnerProfile,
                            onTapMessage: _showMessageActions,
                            onRoseGiftTap:
                                (!isMe &&
                                    (message.photoUrl == 'rose_gift' ||
                                        message.photoUrl == 'ring_gift' ||
                                        message.photoUrl == 'coffee_gift'))
                                ? _showGiftSheet
                                : null,
                            reactionEmoji: _reactions[message.id],
                            onReactionTap: _reactions.containsKey(message.id)
                                ? () => setState(
                                    () => _reactions.remove(message.id),
                                  )
                                : null,
                          );
                          final isRTL = Directionality.of(context).index == 1;
                          final replyVelocity = isRTL ? 300.0 : -300.0;
                          final wrapped = GestureDetector(
                            onHorizontalDragEnd: (details) {
                              final v = details.primaryVelocity ?? 0;
                              if (isRTL
                                  ? v > replyVelocity
                                  : v < replyVelocity) {
                                _onSwipeToReply(message);
                              }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: bubble,
                          );
                          if (realIndex == _lastUnreadIndex) {
                            return Container(
                              key: _lastUnreadKey,
                              child: wrapped,
                            );
                          }
                          return wrapped;
                        },
                      ),
                    ],
                  ),
          ),
          if (_hasPartnerReplied) ...[
            if (_partnerTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.hingePurple.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'جاري الكتابة...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            if (_replyingTo != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.hingePurple.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        () {
                          final s = _getReplyDisplayContent(_replyingTo!);
                          return s.length > 50 ? '${s.substring(0, 50)}...' : s;
                        }(),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() => _replyingTo = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            _ChatInputBar(
              controller: _controller,
              onSend: _sendMessage,
              onGiftTap: _showGiftSheet,
              onVoiceTap: _startVoiceRecording,
              isRecording: _isRecording,
              recordingDurationSeconds: _recordingDurationSec,
              recordingPaused: _recordingPaused,
              waveformHeights: List.from(_waveformHeights),
              onVoiceCancel: _cancelVoiceRecording,
              onVoicePauseResume: _pauseResumeVoiceRecording,
              onVoiceSend: _sendVoiceRecording,
            ),
          ],
        ],
      ),
    );
  }
}

/// دائرة كاملة لشعار Swaply — صورة دائرية. إن وُجد imageUrl (من لوحة التحكم) تُعرض، وإلا الشعار الافتراضي.
class _SwaplyLogoCircle extends StatelessWidget {
  const _SwaplyLogoCircle({required this.size, required this.assetPath, this.imageUrl});

  final double size;
  final String assetPath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    Widget imageChild;
    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      imageChild = Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        width: size,
        height: size,
        errorBuilder: (_, __, ___) => _fallbackLogo(size),
      );
    } else {
      imageChild = Transform.scale(
        scale: 1.68,
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          width: size,
          height: size,
          errorBuilder: (_, __, ___) => _fallbackLogo(size),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: imageChild,
      ),
    );
  }

  static Widget _fallbackLogo(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.darkBlack,
      alignment: Alignment.center,
      child: Text(
        'S',
        style: GoogleFonts.montserrat(
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// صف الأيقونات الثلاث بتصميم الصورة الثالثة: لوغو وبروفايل بنفس الحجم مع تداخل وإطار أبيض، وقلب أسود وأبيض فوق التداخل.
class _CrushAvatarsStack extends StatelessWidget {
  const _CrushAvatarsStack({
    required this.logoAssetPath,
    this.logoImageUrl,
    required this.profileImageUrl,
    required this.avatarSize,
    required this.overlap,
    required this.heartSize,
  });

  final String logoAssetPath;
  final String? logoImageUrl;
  final String? profileImageUrl;
  final double avatarSize;
  final double overlap;
  final double heartSize;

  @override
  Widget build(BuildContext context) {
    final stackWidth = avatarSize * 2 - overlap;
    final heartLeft = (stackWidth - heartSize) / 2;
    final heartTop = (avatarSize - heartSize) / 2 + 10;

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _CrushAvatarFrame(
              size: avatarSize,
              assetPath: logoImageUrl != null ? null : logoAssetPath,
              imageUrl: logoImageUrl,
            ),
          ),
          Positioned(
            left: avatarSize - overlap,
            top: 0,
            child: _CrushAvatarFrame(
              size: avatarSize,
              assetPath: null,
              imageUrl: profileImageUrl,
            ),
          ),
          Positioned(
            left: heartLeft,
            top: heartTop,
            child: Container(
              width: heartSize,
              height: heartSize,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: heartSize * 0.62,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// إطار دائري بحد أبيض رفيع (تصميم الصورة الثالثة) للوغو أو صورة البروفايل.
class _CrushAvatarFrame extends StatelessWidget {
  const _CrushAvatarFrame({
    required this.size,
    this.assetPath,
    this.imageUrl,
  });

  final double size;
  final String? assetPath;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: assetPath != null
            ? Transform.scale(
                scale: 1.68,
                child: Image.asset(
                  assetPath!,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (_, __, ___) => Container(
                  width: size,
                  height: size,
                  color: AppColors.darkBlack,
                  alignment: Alignment.center,
                  child: Text(
                    'S',
                    style: GoogleFonts.montserrat(
                      fontSize: size * 0.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
            : (imageUrl != null && imageUrl!.isNotEmpty)
                ? Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.person,
                      size: size * 0.5,
                      color: AppColors.hingePurple,
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: size * 0.5,
                    color: AppColors.hingePurple,
                  ),
      ),
    );
  }
}

/// صف في قائمة إجراءات الرسالة (رد، تفاعل، نسخ، حذف).
class _MessageActionTile extends StatelessWidget {
  const _MessageActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.hingePurple),
      title: Text(
        label,
        style: GoogleFonts.montserrat(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }
}

/// overlay كامل الشاشة: وردة كبيرة قابلة للسحب، تأثير فتح، وإغلاق تلقائي بعد ٥ ثوانٍ.
class _FullScreenDraggableRoseOverlay extends StatefulWidget {
  const _FullScreenDraggableRoseOverlay({required this.onClose});

  final VoidCallback onClose;

  @override
  State<_FullScreenDraggableRoseOverlay> createState() =>
      _FullScreenDraggableRoseOverlayState();
}

class _FullScreenDraggableRoseOverlayState
    extends State<_FullScreenDraggableRoseOverlay>
    with SingleTickerProviderStateMixin {
  static const double _roseSize = 420.0;
  static const double _roseTotal = 520.0;
  Offset _position = Offset.zero;
  bool _initialized = false;
  Timer? _autoCloseTimer;
  late AnimationController _openController;
  late Animation<double> _openScale;
  late Animation<double> _openOpacity;

  @override
  void initState() {
    super.initState();
    _openController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _openScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.85, curve: Curves.elasticOut),
      ),
    );
    _openOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _openController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _openController.forward();
    _autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) widget.onClose();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _initialized) return;
      _initialized = true;
      final size = MediaQuery.of(context).size;
      setState(() {
        _position = Offset(
          size.width * 0.5 - _roseTotal * 0.5,
          size.height * 0.5 - _roseTotal * 0.5,
        );
      });
    });
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    _openController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _openController,
        builder: (context, _) {
          return Opacity(
            opacity: _openOpacity.value,
            child: Stack(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onClose,
                  child: const SizedBox.expand(),
                ),
                Positioned(
                  left: _position.dx.clamp(0.0, size.width - _roseTotal),
                  top: _position.dy.clamp(0.0, size.height - _roseTotal),
                  child: GestureDetector(
                    onPanUpdate: (d) {
                      setState(() {
                        _position += d.delta;
                        _position = Offset(
                          _position.dx.clamp(0.0, size.width - _roseTotal),
                          _position.dy.clamp(0.0, size.height - _roseTotal),
                        );
                      });
                    },
                    child: Transform.scale(
                      scale: _openScale.value,
                      child: Draggable3DRoseWidget(
                        size: _roseSize,
                        withGlow: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// فقاعة رسالة مع بروفايل المرسل (صورة + اسم). الضغط على اسم/صورة الشريك يفتح بروفايله.
class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.currentUserId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerAvatarUrl,
    this.currentUserAvatarUrl,
    required this.l10n,
    this.onTapPartner,
    this.onTapMessage,
    this.onRoseGiftTap,
    this.reactionEmoji,
    this.onReactionTap,
  });

  final ChatMessage message;
  final String currentUserId;
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String? currentUserAvatarUrl;
  final AppLocalizations l10n;
  final VoidCallback? onTapPartner;

  /// عند الضغط على الفقاعة يُستدعى مع الرسالة لإظهار إجراءات (رد، تفاعل، نسخ، حذف).
  final void Function(ChatMessage message)? onTapMessage;

  /// عند الضغط على هدية الوردة يفتح overlay لسحب الوردة في كامل الصفحة.
  final VoidCallback? onRoseGiftTap;

  /// إيموجي التفاعل المعروض على الفقاعة (إن وُجد).
  final String? reactionEmoji;

  /// عند الضغط على التفاعل لإزالته.
  final VoidCallback? onReactionTap;

  static bool isGiftMessage(ChatMessage message) {
    final p = message.photoUrl;
    return p == 'rose_gift' || p == 'ring_gift' || p == 'coffee_gift';
  }

  static bool isGiftPhotoUrl(String? photoUrl) =>
      photoUrl == 'rose_gift' ||
      photoUrl == 'ring_gift' ||
      photoUrl == 'coffee_gift';

  static bool _isGiftMessage(ChatMessage message) =>
      _MessageBubble.isGiftMessage(message);

  static bool _isVoiceMessage(ChatMessage message) {
    final p = message.photoUrl;
    if (p == null || p.isEmpty) return false;
    final lower = p.toLowerCase();
    return lower.contains('.m4a') ||
        lower.contains('.mp3') ||
        lower.contains('.aac') ||
        lower.contains('.wav');
  }

  /// إيموجي الهدية 🎁 في فقاعات الرسائل.
  static Widget _giftEmojiWidget(double size) =>
      Text('🎁', style: TextStyle(fontSize: size, height: 1.2));

  static Color _giftColorForMessage(String? photoUrl) {
    return AppColors.darkBlack.withValues(alpha: 0.6);
  }

  /// أيقونة الهدية في فقاعة المرسل.
  static Widget _senderGiftIcon(String? photoUrl) =>
      _giftEmojiWidget(26);

  Widget _avatar(String name, String? imageUrl) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.hingePurple.withValues(alpha: 0.2),
      backgroundImage: imageUrl != null && imageUrl.isNotEmpty
          ? NetworkImage(imageUrl)
          : null,
      child: imageUrl == null || imageUrl.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.montserrat(
                color: AppColors.hingePurple,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            )
          : null,
    );
  }

  Widget _avatarWithGiftRing(String name, String? imageUrl, String? giftType) {
    final color = _giftColorForMessage(giftType);
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: _avatar(name, imageUrl),
    );
  }

  Widget _wrapIfPartner(bool isMe, Widget child) {
    if (!isMe && onTapPartner != null) {
      return InkWell(
        onTap: onTapPartner,
        borderRadius: BorderRadius.circular(8),
        child: child,
      );
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == currentUserId;
    final isRTL =
        Directionality.of(context).index == 1 ||
        Localizations.localeOf(context).languageCode == 'ar';
    // المرسل (أنت) دائماً يمين الشاشة، والطرف الآخر يسار.
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    final senderName = isMe ? l10n.senderYou : partnerName;
    final isGiftFromPartner = !isMe && _isGiftMessage(message);
    final avatar = isMe
        ? (currentUserAvatarUrl != null && currentUserAvatarUrl!.isNotEmpty
              ? _avatar(l10n.senderYou, currentUserAvatarUrl)
              : const SizedBox(width: 32, height: 32))
        : (isGiftFromPartner
              ? _avatarWithGiftRing(
                  partnerName,
                  partnerAvatarUrl,
                  message.photoUrl,
                )
              : _avatar(partnerName, partnerAvatarUrl));
    final hideAvatarForGift = !isMe &&
        (message.photoUrl == 'rose_gift' ||
            message.photoUrl == 'ring_gift' ||
            message.photoUrl == 'coffee_gift');
    final avatarWidget = _wrapIfPartner(isMe, avatar);
    final nameWidget = isGiftFromPartner
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _giftEmojiWidget(14),
              const SizedBox(width: 6),
              Text(
                senderName,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.hingePurple,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                l10n.giftSenderLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  color: _giftColorForMessage(message.photoUrl),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          )
        : Text(
            senderName,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: AppColors.hingePurple,
              fontWeight: FontWeight.w600,
            ),
          );

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              _wrapIfPartner(isMe, nameWidget),
              const SizedBox(height: 4),
              Directionality(
                textDirection: isRTL
                    ? ui.TextDirection.rtl
                    : ui.TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (!hideAvatarForGift &&
                        ((isRTL && isMe) || (!isRTL && !isMe)))
                      avatarWidget,
                    if (!hideAvatarForGift &&
                        ((isRTL && isMe) || (!isRTL && !isMe)))
                      const SizedBox(width: 8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => onTapMessage?.call(message),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: Radius.circular(isMe ? 20 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 20),
                              ),
                              child: Container(
                                padding:
                                    (message.photoUrl == 'rose_gift' ||
                                            message.photoUrl == 'ring_gift' ||
                                            message.photoUrl == 'coffee_gift')
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                decoration: BoxDecoration(
                                  color:
                                      (message.photoUrl == 'rose_gift' ||
                                              message.photoUrl == 'ring_gift' ||
                                              message.photoUrl == 'coffee_gift')
                                      ? Colors.transparent
                                      : _isGiftMessage(message)
                                      ? (isMe
                                            ? AppColors.rosePink.withValues(
                                                alpha: 0.2,
                                              )
                                            : AppColors.rosePink.withValues(
                                                alpha: 0.12,
                                              ))
                                      : (isMe
                                            ? AppColors.hingePurple.withValues(
                                                alpha: 0.15,
                                              )
                                            : const Color(0xFFE5F5F5)),
                                  border:
                                      (message.photoUrl == 'rose_gift' ||
                                              message.photoUrl == 'ring_gift' ||
                                              message.photoUrl == 'coffee_gift')
                                      ? null
                                      : _isGiftMessage(message)
                                      ? Border.all(
                                          color: AppColors.rosePink.withValues(
                                            alpha: 0.5,
                                          ),
                                          width: 1.2,
                                        )
                                      : (isMe
                                            ? Border.all(
                                                color: AppColors.hingePurple
                                                    .withValues(alpha: 0.4),
                                                width: 1,
                                              )
                                            : null),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                                    bottomRight: Radius.circular(isMe ? 4 : 20),
                                  ),
                                  boxShadow:
                                      (message.photoUrl == 'rose_gift' ||
                                              message.photoUrl == 'ring_gift' ||
                                              message.photoUrl == 'coffee_gift')
                                      ? null
                                      : [
                                          if (_isGiftMessage(message) &&
                                              message.photoUrl !=
                                                      'rose_gift' &&
                                              message.photoUrl !=
                                                      'ring_gift' &&
                                              message.photoUrl !=
                                                      'coffee_gift')
                                            BoxShadow(
                                              color: AppColors.rosePink
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 12,
                                              spreadRadius: 0,
                                              offset: const Offset(0, 2),
                                            ),
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.06,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (message.replyToContent != null &&
                                        message.replyToContent!
                                            .trim()
                                            .isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.hingePurple
                                              .withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border(
                                            left: isRTL
                                                ? BorderSide.none
                                                : BorderSide(
                                                    color:
                                                        AppColors.hingePurple,
                                                    width: 2.5,
                                                  ),
                                            right: isRTL
                                                ? BorderSide(
                                                    color:
                                                        AppColors.hingePurple,
                                                    width: 2.5,
                                                  )
                                                : BorderSide.none,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.04,
                                              ),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (isRTL) ...[
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.reply_rounded,
                                                          size: 14,
                                                          color: AppColors
                                                              .hingePurple
                                                              .withValues(
                                                                alpha: 0.9,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          message.replyToSenderId ==
                                                                  currentUserId
                                                              ? l10n.senderYou
                                                              : partnerName,
                                                          style:
                                                              GoogleFonts.montserrat(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .hingePurple,
                                                              ),
                                                        ),
                                                        if (message.replyToPhotoUrl !=
                                                                null &&
                                                            _MessageBubble.isGiftPhotoUrl(
                                                              message
                                                                  .replyToPhotoUrl,
                                                            )) ...[
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          _MessageBubble._giftEmojiWidget(18),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      message.replyToContent!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey
                                                            .shade900,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Container(
                                                width: 3,
                                                height: 40,
                                                decoration: BoxDecoration(
                                                  color: AppColors.hingePurple,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                            ] else ...[
                                              Container(
                                                width: 3,
                                                height: 40,
                                                margin: const EdgeInsets.only(
                                                  right: 14,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.hingePurple,
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.reply_rounded,
                                                          size: 14,
                                                          color: AppColors
                                                              .hingePurple
                                                              .withValues(
                                                                alpha: 0.9,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          message.replyToSenderId ==
                                                                  currentUserId
                                                              ? l10n.senderYou
                                                              : partnerName,
                                                          style:
                                                              GoogleFonts.montserrat(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: AppColors
                                                                    .hingePurple,
                                                              ),
                                                        ),
                                                        if (message.replyToPhotoUrl !=
                                                                null &&
                                                            _MessageBubble.isGiftPhotoUrl(
                                                              message
                                                                  .replyToPhotoUrl,
                                                            )) ...[
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          _MessageBubble._giftEmojiWidget(18),
                                                        ],
                                                      ],
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      message.replyToContent!,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey
                                                            .shade900,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.grey.shade300,
                                        indent: 0,
                                        endIndent: 0,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (message.photoUrl != null &&
                                        message.photoUrl!.trim().isNotEmpty &&
                                        message.photoUrl != 'rose_gift' &&
                                        message.photoUrl != 'ring_gift' &&
                                        message.photoUrl != 'coffee_gift' &&
                                        !_MessageBubble._isVoiceMessage(
                                          message,
                                        )) ...[
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 200,
                                          child: Image.network(
                                            message.photoUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                  height: 80,
                                                  color: Colors.grey.shade300,
                                                  child: const Icon(
                                                    Icons.image_not_supported,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                    if (_MessageBubble._isVoiceMessage(
                                      message,
                                    )) ...[
                                      _VoiceMessagePlayer(
                                        audioUrl: message.photoUrl!,
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    if (!isMe &&
                                        (message.photoUrl == 'rose_gift' ||
                                            message.photoUrl == 'ring_gift' ||
                                            message.photoUrl ==
                                                'coffee_gift')) ...[
                                      message.photoUrl == 'rose_gift'
                                          ? GestureDetector(
                                              onTap: onRoseGiftTap,
                                              child: FallingPetalsInBox(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: SizedBox(
                                                  width: 520,
                                                  height: 520,
                                                  child: Center(
                                                    child:
                                                        Draggable3DRoseWidget(
                                                          size: 400,
                                                          withGlow: false,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : message.photoUrl == 'ring_gift'
                                          ? GestureDetector(
                                              onTap: onRoseGiftTap,
                                              child: FallingPetalsInBox(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: SizedBox(
                                                  width: 520,
                                                  height: 520,
                                                  child: Center(
                                                    child: RingIconWidget(
                                                      size: 400,
                                                      color: null,
                                                      withGlow: false,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : message.photoUrl == 'coffee_gift'
                                          ? GestureDetector(
                                              onTap: onRoseGiftTap,
                                              child: FallingPetalsInBox(
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                child: SizedBox(
                                                  width: 520,
                                                  height: 520,
                                                  child: Center(
                                                    child: CoffeeIconWidget(
                                                      size: 400,
                                                      color: null,
                                                      withGlow: false,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                      if (message.content.trim().isNotEmpty)
                                        const SizedBox(height: 6),
                                    ],
                                    if (_isGiftMessage(message) && isMe) ...[
                                      // عرض شكل الهدية (وردة / خاتم / قهوة) في فقاعة المرسل
                                      if (message.photoUrl == 'rose_gift')
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: SizedBox(
                                            width: 140,
                                            height: 140,
                                            child: Center(
                                              child: Draggable3DRoseWidget(
                                                size: 120,
                                                withGlow: true,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (message.photoUrl == 'ring_gift')
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: Center(
                                              child: RingIconWidget(
                                                size: 80,
                                                color: null,
                                                withGlow: true,
                                              ),
                                            ),
                                          ),
                                        )
                                      else if (message.photoUrl == 'coffee_gift')
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: SizedBox(
                                            width: 100,
                                            height: 100,
                                            child: Center(
                                              child: CoffeeIconWidget(
                                                size: 80,
                                                color: null,
                                                withGlow: true,
                                              ),
                                            ),
                                          ),
                                        ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _senderGiftIcon(message.photoUrl),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              l10n.giftSentSuccess,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge
                                                  ?.copyWith(
                                                    color: AppColors.darkBlack,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Icon(
                                            isRTL
                                                ? Icons.arrow_forward_rounded
                                                : Icons.arrow_back_rounded,
                                            size: 18,
                                            color: _giftColorForMessage(
                                              message.photoUrl,
                                            ).withValues(alpha: 0.8),
                                          ),
                                        ],
                                      ),
                                    ],
                                    if (!_isGiftMessage(message) &&
                                        !_MessageBubble._isVoiceMessage(
                                          message,
                                        ))
                                      Text(
                                        message.content,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(
                                              color: AppColors.darkBlack,
                                            ),
                                      ),
                                    if ((_isGiftMessage(message) && isMe) ||
                                        !_isGiftMessage(message) ||
                                        _MessageBubble._isVoiceMessage(message))
                                      const SizedBox(height: 4),
                                    Align(
                                      alignment: isMe
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: isMe
                                            ? MainAxisAlignment.end
                                            : MainAxisAlignment.start,
                                        children: [
                                          Text(
                                            DateFormat.Hm().format(
                                              message.createdAt,
                                            ),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          if (reactionEmoji != null &&
                                              reactionEmoji!.isNotEmpty) ...[
                                            const SizedBox(width: 6),
                                            GestureDetector(
                                              onTap: onReactionTap,
                                              behavior: HitTestBehavior.opaque,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.hingePurple
                                                      .withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: AppColors.hingePurple
                                                        .withValues(
                                                          alpha: 0.25,
                                                        ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  reactionEmoji!,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!hideAvatarForGift &&
                        ((isRTL && !isMe) || (!isRTL && isMe)))
                      const SizedBox(width: 8),
                    if (!hideAvatarForGift &&
                        ((isRTL && !isMe) || (!isRTL && isMe)))
                      avatarWidget,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// مشغّل رسالة صوتية داخل الفقاعة: زر تشغيل، موجات، ومدة (مثل الصورة الثالثة).
class _VoiceMessagePlayer extends StatefulWidget {
  const _VoiceMessagePlayer({required this.audioUrl});

  final String audioUrl;

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _position = Duration.zero;
        });
      }
    });
    _player.setSource(UrlSource(widget.audioUrl));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.pause();
    } else {
      if (_position == Duration.zero || _position >= _duration) {
        await _player.play(UrlSource(widget.audioUrl));
      } else {
        await _player.resume();
      }
    }
    if (mounted) setState(() => _playing = !_playing);
  }

  static String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    const barCount = 24;
    final progress = _duration.inMilliseconds > 0
        ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.mic_rounded, color: Colors.blue.shade400, size: 26),
        const SizedBox(width: 6),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _togglePlay,
            borderRadius: BorderRadius.circular(20),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.grey.shade800,
              size: 32,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(barCount, (i) {
                  final p = (i + 1) / barCount;
                  final filled = p <= progress;
                  final h = 0.25 + (0.4 * (i % 4) / 4);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    width: 2.5,
                    height: 10 + (h * 18),
                    decoration: BoxDecoration(
                      color: filled
                          ? Colors.blue.shade400
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                _formatDuration(_position),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatDuration(_duration),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatefulWidget {
  const _ChatInputBar({
    required this.controller,
    required this.onSend,
    required this.onGiftTap,
    this.onVoiceTap,
    this.isRecording = false,
    this.recordingDurationSeconds = 0,
    this.recordingPaused = false,
    this.waveformHeights = const [],
    this.onVoiceCancel,
    this.onVoicePauseResume,
    this.onVoiceSend,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onGiftTap;
  final VoidCallback? onVoiceTap;
  final bool isRecording;
  final int recordingDurationSeconds;
  final bool recordingPaused;
  final List<double> waveformHeights;
  final VoidCallback? onVoiceCancel;
  final VoidCallback? onVoicePauseResume;
  final VoidCallback? onVoiceSend;

  @override
  State<_ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<_ChatInputBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  static String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;

    if (widget.isRecording &&
        widget.onVoiceCancel != null &&
        widget.onVoiceSend != null) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.darkBlack,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              child: IconButton(
                onPressed: widget.onVoiceCancel,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.grey.shade300,
                  size: 24,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  shape: const CircleBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(widget.recordingDurationSeconds),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade200,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, constraints) => _WaveformBars(
                          heights: widget.waveformHeights,
                          maxWidth: constraints.maxWidth,
                        ),
                      ),
                    ),
                    if (widget.onVoicePauseResume != null)
                      Material(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: widget.onVoicePauseResume,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              widget.recordingPaused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              color: Colors.grey.shade200,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onVoiceSend,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.forestGreen,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    const barBg = AppColors.darkBlack;
    final iconColor = Colors.grey.shade300;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomPadding),
      decoration: const BoxDecoration(
        color: barBg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onGiftTap,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: Text(
                  '🎁',
                  style: TextStyle(fontSize: 24, height: 1.2),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white24,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                minLines: 1,
                maxLength: 10000,
                style: TextStyle(
                  color: Colors.grey.shade200,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).messagePlaceholder,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  filled: false,
                  border: InputBorder.none,
                  counterText: '',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  suffixIcon: widget.onVoiceTap != null
                      ? Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: IconButton(
                            onPressed: widget.onVoiceTap,
                            icon: Icon(
                              Icons.mic_rounded,
                              color: iconColor,
                              size: 22,
                            ),
                            style: IconButton.styleFrom(
                              minimumSize: const Size(36, 36),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
          ),
          if (hasText) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onSend,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.send_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// أشرطة الموجة أثناء التسجيل الصوتي — تتفاعل مع مستوى الصوت.
class _WaveformBars extends StatelessWidget {
  const _WaveformBars({required this.heights, this.maxWidth = double.infinity});

  final List<double> heights;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    const barCount = 28;
    const barWidth = 2.5;
    const margin = 0.8;
    final totalBarWidth = (barWidth + margin) * barCount - margin;
    final actualWidth = maxWidth.isFinite && maxWidth < totalBarWidth
        ? maxWidth
        : totalBarWidth;
    final singleBar = actualWidth / barCount;
    final w = (singleBar - margin).clamp(1.2, 4.0);
    List<double> padded;
    if (heights.isEmpty) {
      padded = List.filled(barCount, 0.2);
    } else {
      final last = heights.length > barCount
          ? heights.sublist(heights.length - barCount)
          : List<double>.from(heights);
      padded = List.from(last);
      while (padded.length < barCount) {
        padded.insert(0, 0.2);
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final h = padded[i].clamp(0.15, 1.0);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.4),
          width: w,
          height: 14 + (h * 22),
          decoration: BoxDecoration(
            color: Colors.grey.shade600,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}

class _GiftSheetContent extends StatefulWidget {
  const _GiftSheetContent({
    required this.walletService,
    required this.likeService,
    required this.messageService,
    required this.blockService,
    required this.partnerId,
    required this.currentUserId,
    required this.onSent,
    required this.onBuyGifts,
  });

  final WalletService walletService;
  final ProfileLikeService likeService;
  final MessageService messageService;
  final BlockService blockService;
  final String partnerId;
  final String currentUserId;
  final void Function(String? giftType, String? messageId) onSent;
  final void Function(String? initialGiftType) onBuyGifts;

  @override
  State<_GiftSheetContent> createState() => _GiftSheetContentState();
}

class _GiftSheetContentState extends State<_GiftSheetContent> {
  final TextEditingController _messageController = TextEditingController();
  final UserSettingsService _userSettings = UserSettingsService();
  WalletBalance? _balance;
  bool _loading = true;
  String? _sendingGiftType;
  String? _selectedGiftType;
  String? _giftHint;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onMessageChanged);
    _loadBalance();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGiftHint());
  }

  void _onMessageChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _selectedGiftType != null &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _loadBalance() async {
    final b = await widget.walletService.getBalance();
    if (mounted) {
      setState(() {
        _balance = b;
        _loading = false;
      });
    }
  }

  Future<void> _loadGiftHint() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final l10n = AppLocalizations.of(context);
    final pronounSetting = userId != null
        ? await _userSettings.getPreferredRecipientPronoun(userId)
        : 'male';
    final pronoun = pronounSetting == 'female' ? l10n.pronounHer : l10n.pronounHim;
    if (mounted) setState(() => _giftHint = l10n.giftMessageWhisperHint(pronoun));
  }

  void _onSendPressed() {
    final l10n = AppLocalizations.of(context);
    if (_selectedGiftType == null) {
      FlyingGiftMessageOverlay.show(context, l10n.selectGiftToSend);
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      FlyingGiftMessageOverlay.show(context, l10n.writeMessageToSendWithGift);
      return;
    }
    if (_balance == null || !_balance!.canSend(_selectedGiftType!)) {
      widget.onBuyGifts(_selectedGiftType);
      return;
    }
    _sendGift(_selectedGiftType!);
  }

  Future<void> _sendGift(String giftType) async {
    // منع إرسال الهدية إذا الطرف الآخر حظرني
    final partnerBlockedMe = await widget.blockService.hasBlocked(
      widget.partnerId,
      widget.currentUserId,
    );
    if (partnerBlockedMe && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).blockedCannotSend),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_balance == null || !_balance!.canSend(giftType)) {
      widget.onBuyGifts(giftType);
      return;
    }
    setState(() => _sendingGiftType = giftType);
    final deducted = await widget.walletService.deductGift(giftType);
    if (!mounted) return;
    if (!deducted) {
      setState(() => _sendingGiftType = null);
      widget.onBuyGifts(giftType);
      return;
    }
    try {
      final messageText = _messageController.text.trim();
      await widget.likeService.sendMatchGift(
        toUserId: widget.partnerId,
        giftType: giftType,
        message: messageText,
      );
      final result = await widget.messageService.sendMessage(
        senderId: widget.currentUserId,
        receiverId: widget.partnerId,
        content: messageText,
        photoUrl: giftType,
      );
      if (mounted) {
        setState(() => _sendingGiftType = null);
        if (result.isOk) {
          FlyingGiftMessageOverlay.show(
            context,
            AppLocalizations.of(context).giftSentSuccess,
          );
          widget.onSent(giftType, result.messageId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.error ?? AppLocalizations.of(context).errorOccurred,
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sendingGiftType = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final maxHeight = (screenHeight * 0.78).clamp(380.0, screenHeight - 56.0);
    return SizedBox(
      height: maxHeight,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPadding),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CinematicRoseWidget(size: 48, color: null, withGlow: false),
          const SizedBox(height: 8),
          Text(
            l10n.sendGift,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 15),
            textAlign: TextAlign.center,
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(color: AppColors.hingePurple),
            )
          else ...[
            if (_balance != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BalanceChip(
                      imagePath: 'assets/454.png',
                      color: const Color(0xFF8B7355),
                      count: _balance!.coffee,
                    ),
                    const SizedBox(width: 10),
                    _BalanceChip(
                      imagePath: 'assets/4.png',
                      color: const Color(0xFFC9A227),
                      count: _balance!.rings,
                    ),
                    const SizedBox(width: 10),
                    _BalanceChip(
                      imagePath: 'assets/34.png',
                      color: AppColors.rosePink,
                      count: _balance!.roses,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _GiftOption(
                  imagePath: 'assets/34.png',
                  label: l10n.giftRose,
                  price:
                      '€${GiftPricing.formatCents(GiftPricing.rosePriceCents)}',
                  accentColor: AppColors.rosePink,
                  cardColor: AppColors.rosePink.withValues(alpha: 0.15),
                  selected: _selectedGiftType == 'rose_gift',
                  onTap: _sendingGiftType != null
                      ? null
                      : () => setState(() => _selectedGiftType = 'rose_gift'),
                  disabled: _balance?.roses == 0,
                  sending: _sendingGiftType == 'rose_gift',
                  onBuyNow: _balance?.roses == 0
                      ? () => widget.onBuyGifts('rose_gift')
                      : null,
                ),
                _GiftOption(
                  imagePath: 'assets/4.png',
                  label: l10n.giftRing,
                  price:
                      '€${GiftPricing.formatCents(GiftPricing.ringPriceCents)}',
                  accentColor: AppColors.ringGold,
                  cardColor: AppColors.ringGold.withValues(alpha: 0.15),
                  selected: _selectedGiftType == 'ring_gift',
                  onTap: _sendingGiftType != null
                      ? null
                      : () => setState(() => _selectedGiftType = 'ring_gift'),
                  disabled: _balance?.rings == 0,
                  sending: _sendingGiftType == 'ring_gift',
                  onBuyNow: _balance?.rings == 0
                      ? () => widget.onBuyGifts('ring_gift')
                      : null,
                ),
                _GiftOption(
                  imagePath: 'assets/454.png',
                  label: l10n.giftCoffee,
                  price:
                      '€${GiftPricing.formatCents(GiftPricing.coffeePriceCents)}',
                  accentColor: AppColors.coffeeBrown,
                  cardColor: AppColors.coffeeBrown.withValues(alpha: 0.12),
                  selected: _selectedGiftType == 'coffee_gift',
                  onTap: _sendingGiftType != null
                      ? null
                      : () => setState(() => _selectedGiftType = 'coffee_gift'),
                  disabled: _balance?.coffee == 0,
                  sending: _sendingGiftType == 'coffee_gift',
                  onBuyNow: _balance?.coffee == 0
                      ? () => widget.onBuyGifts('coffee_gift')
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              maxLines: 2,
              minLines: 1,
              maxLength: 10000,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
              decoration: InputDecoration(
                hintText: _giftHint ?? l10n.matchGiftHint,
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                counterText: '',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.hingePurple.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.hingePurple.withValues(alpha: 0.25)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.hingePurple, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_sendingGiftType != null || !_canSend)
                    ? null
                    : _onSendPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: _canSend && _sendingGiftType == null
                      ? AppColors.hingePurple
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  l10n.matchConfirmAndSend,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => widget.onBuyGifts(null),
              icon: const Icon(Icons.add_shopping_cart, size: 20),
              label: Text(l10n.buyRoses),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.hingePurple,
              ),
            ),
          ],
        ],
      ),
        ),
      ),
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.imagePath,
    required this.color,
    required this.count,
  });

  final String imagePath;
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            imagePath,
            width: 28,
            height: 28,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              color == AppColors.rosePink
                  ? Icons.local_florist_rounded
                  : color == AppColors.ringGold
                  ? Icons.diamond_rounded
                  : Icons.coffee_rounded,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftOption extends StatelessWidget {
  const _GiftOption({
    required this.imagePath,
    required this.label,
    required this.price,
    required this.accentColor,
    required this.cardColor,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
    this.sending = false,
    this.onBuyNow,
  });

  final String imagePath;
  final String label;
  final String price;
  final Color accentColor;
  final Color cardColor;
  final VoidCallback? onTap;
  final bool selected;
  final bool disabled;
  final bool sending;
  final VoidCallback? onBuyNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canBuyNow = disabled && onBuyNow != null && !sending;
    return Opacity(
      opacity: disabled && !canBuyNow ? 0.5 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: sending ? null : (canBuyNow ? onBuyNow : onTap),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: accentColor.withValues(
                  alpha: disabled && !canBuyNow ? 0.2 : (selected ? 0.9 : 0.4),
                ),
                width: selected ? 2.5 : 1,
              ),
              borderRadius: BorderRadius.circular(16),
              color: cardColor,
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sending)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      ),
                    ),
                  )
                else
                  Image.asset(
                    imagePath,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      '🎁',
                      style: TextStyle(fontSize: 44, height: 1.2),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkBlack,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                if (canBuyNow)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.buyNow,
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Text(
                    price,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
