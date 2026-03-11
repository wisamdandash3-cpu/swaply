import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../constants/gift_pricing.dart';
import '../services/wallet_service.dart';
import '../widgets/buy_roses_sheet.dart';
import '../widgets/flying_gift_message_overlay.dart';
import '../models/profile_answer.dart';
import '../models/profile_like.dart';
import '../services/user_settings_service.dart';
import '../services/profile_display_service.dart';
import '../services/profile_like_service.dart';
import '../services/gift_received_storage.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/chat_read_service.dart';
import '../services/message_service.dart';
import '../utils/profile_completion.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_fields_service.dart';
import '../services/profile_service.dart';
import '../widgets/gift_received_overlay.dart';
import '../widgets/profile_visibility_prompt_dialog.dart';
import '../widgets/star_icon_widget.dart';
import 'account_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'chat_screen.dart';
import 'discovery_screen.dart';
import 'featured_screen.dart';
import 'filter_screen.dart';
import 'likes_you_screen.dart';
import 'subscription_screen.dart';
import 'profile_screen.dart';

/// الصفحة الرئيسية بأسلوب Hinge: تبويبات Discover، Likes you، Matches.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _chatBadgeCount = 0;
  int _likesYouBadgeCount = 0;
  int _rosesBalance = 0;
  String? _profileAvatarUrl;

  /// عند التمرير في بروفايل الاكتشاف: اسم البروفايل يعرض في الشريط العلوي؛ null = "Swaply".
  String? _discoveryAppBarTitle;

  /// لا نبني أي محتوى تبويب في الإطار الأول — نعرض هيكل فقط حتى تستجيب الشاشة للنقر.
  bool _bodyReady = false;

  /// عرضت نافذة "احصل على ظهور أكثر" في هذه الجلسة فلا نكررها.
  bool _visibilityPromptShown = false;
  final UserSettingsService _userSettings = UserSettingsService();
  final ProfileDisplayService _profileDisplay = ProfileDisplayService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // إظهار الهيكل بسرعة ثم المحتوى بعد إطار واحد (تجنب التجمّد بعد إكمال التسجيل).
    // على Android: عرض المحتوى فوراً (Duration.zero) — تحسين ثابت للأداء.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final delay = Platform.isAndroid
          ? Duration.zero
          : const Duration(milliseconds: 50);
      Future.delayed(delay, () {
        if (!mounted) return;
        setState(() => _bodyReady = true);
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        if (!_bodyReady) setState(() => _bodyReady = true);
      });
    });
    // تحميلات متتابعة بدل المتزامنة لتجنب ضغط الشبكة والتجمّد
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 400), () async {
        if (!mounted) return;
        _loadChatBadge();
        await Future.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        _loadLikesYouBadge();
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        _loadProfileAvatar();
        _loadRosesBalance();
        _updateLastActive();
      });
      // عرض نافذة "احصل على ظهور أكثر" مرة واحدة — بعد استقرار الشاشة (تجنب التجمّد).
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted || !_bodyReady) return;
        _checkAndShowVisibilityPrompt();
      });
    });
  }

  Future<void> _loadProfileAvatar() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final info = await _profileDisplay
          .getDisplayInfo(userId)
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _profileAvatarUrl = info.avatarUrl);
    } catch (_) {}
  }

  Future<void> _loadRosesBalance() async {
    try {
      final balance = await WalletService().getBalance().timeout(
        const Duration(seconds: 5),
      );
      if (mounted) setState(() => _rosesBalance = balance.roses);
    } catch (_) {}
  }

  /// عند الضغط على زر الوردة: عرض شاشة اختيار نوع الهدية. إن [recipientProfileId] معرّف المستلم يُنفّذ الإرسال الفعلي.
  void _showGiftChoiceSheet(BuildContext context, [String? recipientProfileId]) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _GiftChoiceSheetContent(
        recipientProfileId: recipientProfileId,
        parentContext: context,
        onBuyRoses: (String? giftType) {
          Navigator.pop(modalContext);
          showBuyRosesSheet(context, initialGiftType: giftType);
        },
        onDismiss: () => Navigator.pop(modalContext),
        onGiftSent: _loadRosesBalance,
      ),
    );
  }

  /// إذا كان إكمال البروفايل أقل من 50٪ ولم نعرض النافذة بعد — نعرض شعار "أكمل بروفايلك" (صفحة أولى) مرة واحدة في الجلسة.
  Future<void> _checkAndShowVisibilityPrompt() async {
    if (_visibilityPromptShown || !mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final answerService = ProfileAnswerService();
      final fieldsService = ProfileFieldsService();
      final results = await Future.wait([
        answerService
            .getByProfileId(userId)
            .timeout(const Duration(seconds: 5)),
        fieldsService.getFields(userId).timeout(const Duration(seconds: 5)),
      ]);
      final answers = results[0] as List<ProfileAnswer>;
      final fields =
          results[1] as Map<String, ({String value, String visibility})>;
      final percent = ProfileCompletion.computePercent(
        answers: answers,
        fields: fields,
      );
      if (percent >= 50 || !mounted) return;
      _visibilityPromptShown = true;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ProfileVisibilityPromptDialog(
          completionPercent: percent,
          onAnswerQuestions: () {
            Navigator.of(ctx).pop();
            // تأجيل الانتقال لتجنب التجمّد (فتح شاشة ثقيلة في إطار منفصل).
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => EditProfileScreen(userId: userId),
                ),
              );
            });
          },
          onLater: () => Navigator.of(ctx).pop(),
        ),
      );
    } catch (_) {
      // تجاهل الخطأ لئلا يؤثر على تجربة المستخدم
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateLastActive();
      _loadLikesYouBadge();
      _loadChatBadge();
    }
  }

  Future<void> _updateLastActive() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        await _userSettings
            .updateLastActive(userId)
            .timeout(const Duration(seconds: 3));
        final offsetMinutes = DateTime.now().timeZoneOffset.inMinutes;
        await ProfileService().updateTimezone(userId, offsetMinutes).timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {}
    }
  }

  Future<void> _checkAndShowGiftReceived() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;
    try {
      final likeService = ProfileLikeService();
      final List<ProfileLike> incoming = await likeService.getIncomingLikes();
      final List<ProfileLike> gifts = incoming
          .where(
            (ProfileLike g) => g.giftType != null && g.giftType!.isNotEmpty,
          )
          .toList();
      if (gifts.isEmpty || !mounted) return;
      final List<ProfileLike> unshown = await GiftReceivedStorage.filterUnshown(
        gifts,
        (ProfileLike g) => g.id,
      );
      if (unshown.isEmpty || !mounted) return;
      final ProfileLike gift = unshown.first;
      await GiftReceivedStorage.markAsShown(gift.id);
      if (!mounted) return;
      final profileDisplay = ProfileDisplayService();
      final senderInfo = await profileDisplay.getDisplayInfo(gift.fromUserId);
      if (!mounted) return;
      final receiverInfo = await profileDisplay.getDisplayInfo(userId);
      if (!mounted) return;
      final bool? reply = await GiftReceivedOverlay.show(
        context,
        senderName: senderInfo.displayName,
        senderAvatarUrl: senderInfo.avatarUrl,
        receiverAvatarUrl: receiverInfo.avatarUrl,
        giftType: gift.giftType ?? 'rose_gift',
        giftMessage: gift.giftMessage ?? '',
      );
      if (reply == true && mounted) {
        Navigator.of(context)
            .push(
              MaterialPageRoute<void>(
                builder: (context) => ConversationScreen(
                  currentUserId: userId,
                  partnerId: gift.fromUserId,
                  partnerName: senderInfo.displayName,
                  partnerAvatarUrl: senderInfo.avatarUrl,
                  partnerIsVerified: senderInfo.isVerified,
                  onMessageSent: () => _loadChatBadge(),
                ),
              ),
            )
            .then((_) => _loadChatBadge());
      }
    } catch (_) {
      // تجاهل أي خطأ لئلا يتعلق التطبيق
    }
  }

  Future<void> _loadChatBadge() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final ids = await MessageService()
          .getConversationPartnerIds(userId)
          .timeout(const Duration(seconds: 5));
      final unreadMap = await ChatReadService()
          .getUnreadCountsByPartner(userId, ids)
          .timeout(const Duration(seconds: 5));
      final count = unreadMap.values.where((c) => c > 0).length;
      if (mounted) setState(() => _chatBadgeCount = count);
    } catch (_) {
      if (mounted) setState(() => _chatBadgeCount = 0);
    }
  }

  /// عدد من أعجبوا بي ولم أُعجب بهم بعد (شارة "معجب بك" — يتناقص عند المطابقة).
  Future<void> _loadLikesYouBadge() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final count = await ProfileLikeService()
          .getIncomingUnmatchedCount()
          .timeout(const Duration(seconds: 5));
      if (mounted) setState(() => _likesYouBadgeCount = count);
    } catch (_) {
      if (mounted) setState(() => _likesYouBadgeCount = 0);
    }
  }

  String get _profileDisplayName {
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        '';
  }

  /// تبويب يُبنى فقط عند اختياره لأول مرة (تبويب كسول) — يقلل العمل عند الرسم الأول.
  static Widget _lazyTab(int index, int currentIndex, Widget Function() build) {
    return _LazyTabSlot(isSelected: index == currentIndex, tabBuilder: build);
  }

  List<Widget> _buildTabs(int currentIndex) => [
    _lazyTab(
      0,
      currentIndex,
      () => DiscoveryScreen(
        isVisible: true,
        onAppBarTitleChange: (title) {
          if (mounted) setState(() => _discoveryAppBarTitle = title);
        },
      ),
    ),
    _lazyTab(
      1,
      currentIndex,
      () => FeaturedScreen(
        onGiftRoseTap: (profileId) => _showGiftChoiceSheet(context, profileId),
      ),
    ),
    _lazyTab(
      2,
      currentIndex,
      () => LikesYouScreen(
        isVisible: true,
        onLikesChanged: _loadLikesYouBadge,
        onGoToDiscovery: () => setState(() => _currentIndex = 0),
        onGoToSubscription: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SubscriptionScreen(),
            ),
          );
        },
      ),
    ),
    _lazyTab(
      3,
      currentIndex,
      () => ChatScreen(
        isVisible: true,
        onGoToSubscription: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (context) => const SubscriptionScreen(),
            ),
          );
        },
        onGoToLikedYou: () => setState(() => _currentIndex = 2),
        onConversationsChanged: _loadChatBadge,
      ),
    ),
    _lazyTab(4, currentIndex, () => ProfileScreen(isVisible: true)),
  ];

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
          _currentIndex == 4 && _profileDisplayName.isNotEmpty
              ? _profileDisplayName
              : (_currentIndex == 1
                    ? l10n.tabLikesYou
                    : (_currentIndex == 0 && _discoveryAppBarTitle != null
                          ? _discoveryAppBarTitle!
                          : 'Swaply')),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_currentIndex == 1)
            _RosesBalancePill(
              roses: _rosesBalance,
              l10n: l10n,
              onTap: () => showBuyRosesSheet(context),
            ),
          IconButton(
            icon: const Icon(Icons.tune_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const FilterScreen(),
                ),
              );
            },
          ),
          if (_currentIndex == 4)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () async {
                final tabIndex = await Navigator.of(context).push<int>(
                  MaterialPageRoute<int>(
                    builder: (context) => const AccountSettingsScreen(),
                  ),
                );
                if (tabIndex != null && mounted) {
                  setState(() => _currentIndex = tabIndex);
                }
              },
            ),
        ],
      ),
      body: _bodyReady
          ? IndexedStack(
              index: _currentIndex,
              children: _buildTabs(_currentIndex),
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.hingePurple),
            ),
      bottomNavigationBar: _SwaplyBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          final wasNotReady = !_bodyReady;
          setState(() {
            _currentIndex = i;
            if (i != 0) _discoveryAppBarTitle = null;
          });
          if (wasNotReady) {
            // تأجيل بناء المحتوى للإطار التالي حتى لا يتجمّد عند أول ضغطة
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _bodyReady = true);
            });
          }
          if (i == 1) {
            _loadRosesBalance(); // تحديث رصيد الورود عند فتح تبويب مميزون
          }
          if (i == 2) {
            _loadLikesYouBadge(); // تحديث شارة "معجب بك" عند فتح التبويب
          }
          if (i == 4) {
            _loadProfileAvatar(); // تحديث صورة البروفايل في الشريط السفلي
          }
          if (i == 3) {
            _loadChatBadge();
            Future.delayed(
              const Duration(milliseconds: 500),
              () => _checkAndShowGiftReceived(),
            );
          }
        },
        l10n: l10n,
        chatBadgeCount: _chatBadgeCount,
        likesYouBadgeCount: _likesYouBadgeCount,
        profileAvatarUrl: _profileAvatarUrl,
        profileDisplayName: _profileDisplayName,
      ),
    );
  }
}

/// شاشة اختيار الهدية لصفحة مميزون — تصميم مميز (عنوان مزدوج، هدايا، رسالة، إرسال). إن لم يكن رصيد كافٍ تُفتح صفحة تعبئة الرصيد.
class _GiftChoiceSheetContent extends StatefulWidget {
  const _GiftChoiceSheetContent({
    this.recipientProfileId,
    this.parentContext,
    required this.onBuyRoses,
    required this.onDismiss,
    this.onGiftSent,
  });

  /// معرّف المستلم عند الإرسال من تبويب مميزون — إن وُجد يُنفّذ الإرسال الفعلي.
  final String? recipientProfileId;
  /// سياق الشاشة الرئيسية — لعرض الورقة الطائرة بعد إغلاق الشيت.
  final BuildContext? parentContext;
  final void Function(String? giftType) onBuyRoses;
  final VoidCallback onDismiss;
  /// يُستدعى بعد إرسال هدية بنجاح — لتحديث عرض الرصيد في الشريط.
  final VoidCallback? onGiftSent;

  @override
  State<_GiftChoiceSheetContent> createState() => _GiftChoiceSheetContentState();
}

class _GiftChoiceSheetContentState extends State<_GiftChoiceSheetContent> {
  final WalletService _walletService = WalletService();
  final UserSettingsService _userSettings = UserSettingsService();
  final ProfileLikeService _likeService = ProfileLikeService();
  final MessageService _messageService = MessageService();
  final TextEditingController _messageController = TextEditingController();
  WalletBalance? _balance;
  bool _loading = true;
  bool _sending = false;
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

  @override
  void dispose() {
    _messageController.removeListener(_onMessageChanged);
    _messageController.dispose();
    super.dispose();
  }

  bool get _canSend =>
      !_sending &&
      _selectedGiftType != null &&
      _messageController.text.trim().isNotEmpty;

  Future<void> _loadBalance() async {
    final b = await _walletService.getBalance();
    if (mounted) setState(() {
      _balance = b;
      _loading = false;
    });
  }

  Future<void> _onSendPressed() async {
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
      widget.onBuyRoses(_selectedGiftType);
      return;
    }
    final recipientId = widget.recipientProfileId;
    if (recipientId == null || recipientId.isEmpty) {
      FlyingGiftMessageOverlay.show(context, l10n.giftSentSuccess);
      widget.onDismiss();
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || !mounted) return;
    setState(() => _sending = true);
    final giftType = _selectedGiftType!;
    final messageText = _messageController.text.trim();
    try {
      final deducted = await _walletService.deductGift(giftType).timeout(
        const Duration(seconds: 10),
        onTimeout: () => false,
      );
      if (!mounted) return;
      if (!deducted) {
        widget.onBuyRoses(giftType);
        return;
      }
      try {
        await _likeService.sendMatchGift(
          toUserId: recipientId,
          giftType: giftType,
          message: messageText,
        ).timeout(const Duration(seconds: 15));
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' ||
            (e.message.contains('gift_message') ||
                e.message.contains('gift_type'))) {
          debugPrint(
            'profile_likes gift columns missing: run 005_profile_likes_gift.sql',
          );
        }
        rethrow;
      }
      if (!mounted) return;
      final result = await _messageService.sendMessage(
        senderId: userId,
        receiverId: recipientId,
        content: messageText,
        photoUrl: giftType,
      ).timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (!result.isOk) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? l10n.errorOccurred),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final successMessage = l10n.giftSentSuccess;
      widget.onGiftSent?.call();
      widget.onDismiss();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = widget.parentContext;
        if (ctx != null && ctx.mounted) {
          FlyingGiftMessageOverlay.show(ctx, successMessage);
        }
      });
    } on TimeoutException catch (_) {
      debugPrint('GiftChoiceSheet send timeout');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('GiftChoiceSheet send error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorOccurred),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBFE),
            Color(0xFFF3E8F4),
            Color(0xFFFCE4EC),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: AppColors.hingePurple.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة قلب في دائرة بنفسجية — تصميم مميز لمميزون
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.hingePurple.withValues(alpha: 0.9),
                    AppColors.rosePink.withValues(alpha: 0.85),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hingePurple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite_rounded,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.sendNiceMessageTitle,
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.sendGift,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.hingePurple.withValues(alpha: 0.9),
              ),
              textAlign: TextAlign.center,
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: CircularProgressIndicator(color: AppColors.hingePurple),
              )
            else ...[
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _PulsatingGiftCard(
                    child: _GiftChoiceCard(
                      imagePath: 'assets/34.png',
                      label: l10n.giftRose,
                      price: '€${GiftPricing.formatCents(GiftPricing.rosePriceCents)}',
                      accentColor: const Color(0xFFD81B60),
                      cardColor: const Color(0xFFFFE4EC),
                      hasBalance: _balance?.roses != null && _balance!.roses > 0,
                      selected: _selectedGiftType == 'rose_gift',
                      onTap: () => setState(() => _selectedGiftType = 'rose_gift'),
                      onBuyNow: () => widget.onBuyRoses('rose_gift'),
                    ),
                  ),
                  _PulsatingGiftCard(
                    child: _GiftChoiceCard(
                      imagePath: 'assets/ring_icon.png',
                      label: l10n.giftRing,
                      price: '€${GiftPricing.formatCents(GiftPricing.ringPriceCents)}',
                      accentColor: const Color(0xFFB8860B),
                      cardColor: const Color(0xFFFFF8E1),
                      hasBalance: _balance?.rings != null && _balance!.rings > 0,
                      selected: _selectedGiftType == 'ring_gift',
                      onTap: () => setState(() => _selectedGiftType = 'ring_gift'),
                      onBuyNow: () => widget.onBuyRoses('ring_gift'),
                    ),
                  ),
                  _PulsatingGiftCard(
                    child: _GiftChoiceCard(
                      imagePath: 'assets/coffee_icon.png',
                      label: l10n.giftCoffee,
                      price: '€${GiftPricing.formatCents(GiftPricing.coffeePriceCents)}',
                      accentColor: const Color(0xFF5D4037),
                      cardColor: const Color(0xFFEFEBE9),
                      hasBalance: _balance?.coffee != null && _balance!.coffee > 0,
                      selected: _selectedGiftType == 'coffee_gift',
                      onTap: () => setState(() => _selectedGiftType = 'coffee_gift'),
                      onBuyNow: () => widget.onBuyRoses('coffee_gift'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _messageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _giftHint ?? l10n.sendNiceMessageHint,
                  hintStyle: GoogleFonts.montserrat(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.hingePurple.withValues(alpha: 0.2),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.hingePurple.withValues(alpha: 0.25),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppColors.hingePurple,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSend ? _onSendPressed : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _canSend
                        ? AppColors.hingePurple
                        : Colors.grey.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _sending
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          l10n.sendNiceMessageButton,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => widget.onBuyRoses(null),
                icon: Icon(Icons.add_shopping_cart, size: 18, color: AppColors.hingePurple),
                label: Text(
                  l10n.buyRoses,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.hingePurple,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// غلاف يضيف تأثير نبض (تكبير/تصغير خفيف) لأيقونة الهدية — لمميزون.
class _PulsatingGiftCard extends StatefulWidget {
  const _PulsatingGiftCard({required this.child});

  final Widget child;

  @override
  State<_PulsatingGiftCard> createState() => _PulsatingGiftCardState();
}

class _PulsatingGiftCardState extends State<_PulsatingGiftCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.98, end: 1.05).animate(
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
      builder: (context, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _GiftChoiceCard extends StatelessWidget {
  const _GiftChoiceCard({
    required this.imagePath,
    required this.label,
    required this.price,
    required this.accentColor,
    required this.cardColor,
    required this.hasBalance,
    required this.selected,
    required this.onTap,
    required this.onBuyNow,
  });

  final String imagePath;
  final String label;
  final String price;
  final Color accentColor;
  final Color cardColor;
  final bool hasBalance;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onBuyNow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasBalance ? onTap : onBuyNow,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? accentColor : accentColor.withValues(alpha: 0.4),
              width: selected ? 2.5 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: cardColor,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                imagePath,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.card_giftcard_rounded,
                  size: 44,
                  color: accentColor,
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
              if (!hasBalance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

/// حبة رصيد الورود في شريط مميزون — تصميم بيضوي بنفسجي فاتح مع أيقونة وردة ونص أبيض. تنبض بلحياة عند العرض.
class _RosesBalancePill extends StatefulWidget {
  const _RosesBalancePill({
    required this.roses,
    required this.l10n,
    required this.onTap,
  });

  final int roses;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  State<_RosesBalancePill> createState() => _RosesBalancePillState();
}

class _RosesBalancePillState extends State<_RosesBalancePill>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.96, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 10, bottom: 10),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.hingePurple.withValues(alpha: 0.85),
                    AppColors.hingePurple.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.hingePurple.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_florist_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.l10n.rosesBalance(widget.roses),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
}

/// يبني محتوى التبويب فقط عند عرضه لأول مرة؛ يبقي المحتوى المُحمّل في الشجرة عند التبديل (حفظ الحالة).
class _LazyTabSlot extends StatefulWidget {
  const _LazyTabSlot({required this.isSelected, required this.tabBuilder});

  final bool isSelected;
  final Widget Function() tabBuilder;

  @override
  State<_LazyTabSlot> createState() => _LazyTabSlotState();
}

class _LazyTabSlotState extends State<_LazyTabSlot> {
  Widget? _built;
  bool _scheduleBuild = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isSelected && _built == null) {
      if (!_scheduleBuild) {
        _scheduleBuild = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _built = widget.tabBuilder());
        });
      }
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hingePurple),
      );
    }
    return _built ?? const SizedBox.expand();
  }
}

/// رسم فقاعة دردشة أنيقة (رسم يدوي) للتاب الدردشة.
class _ChatBubblePainter extends CustomPainter {
  _ChatBubblePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    final path = Path();
    // جسم الفقاعة: مستطيل بزوايا دائرية
    const r = 4.5;
    final bodyTop = 0.0;
    final bodyBottom = h - 6;
    path.moveTo(r, bodyTop);
    path.lineTo(w - r, bodyTop);
    path.arcToPoint(Offset(w, bodyTop + r), radius: const Radius.circular(r));
    path.lineTo(w, bodyBottom - r);
    path.arcToPoint(
      Offset(w - r, bodyBottom),
      radius: const Radius.circular(r),
    );
    // ذيل الفقاعة (مثلث صغير لأسفل)
    path.lineTo(w * 0.5 + 4, bodyBottom);
    path.lineTo(w * 0.5, h);
    path.lineTo(w * 0.5 - 4, bodyBottom);
    path.lineTo(r, bodyBottom);
    path.arcToPoint(
      Offset(0, bodyBottom - r),
      radius: const Radius.circular(r),
    );
    path.lineTo(0, bodyTop + r);
    path.arcToPoint(Offset(r, bodyTop), radius: const Radius.circular(r));
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ChatBubblePainter oldDelegate) =>
      oldDelegate.color != color;
}

/// رسم قلب واضح (فصّان علويان مستديران، طرف سفلي مدبّب) لتاب المطابقات.
class _HeartIconPainter extends CustomPainter {
  _HeartIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    final path = Path();
    final cx = w * 0.5;
    // الطرف السفلي المدبّب
    path.moveTo(cx, h * 0.90);
    // من الأسفل صعوداً إلى الفص الأيسر (استدارة دائرية أوضح)
    path.cubicTo(cx, h * 0.62, w * 0.00, h * 0.42, w * 0.18, h * 0.18);
    path.cubicTo(w * 0.32, h * 0.02, cx, h * 0.20, cx, h * 0.32);
    // من انخفاض الوسط إلى الفص الأيمن (استدارة دائرية أوضح)
    path.cubicTo(cx, h * 0.20, w * 0.68, h * 0.02, w * 0.82, h * 0.18);
    path.cubicTo(w, h * 0.42, cx, h * 0.62, cx, h * 0.90);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartIconPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// شريط تنقل سفلي أنيق بخمس أيقونات: الرئيسية، النجمة، القلب، الدردشة، الملف الشخصي.
class _SwaplyBottomNav extends StatelessWidget {
  const _SwaplyBottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.l10n,
    this.chatBadgeCount = 0,
    this.likesYouBadgeCount = 0,
    this.profileAvatarUrl,
    this.profileDisplayName = '',
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final AppLocalizations l10n;
  final int chatBadgeCount;
  final int likesYouBadgeCount;
  final String? profileAvatarUrl;
  final String profileDisplayName;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(top: 12, bottom: safeBottom + 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore,
                label: l10n.tabHome,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
                logoAssetPath: 'assets/swaply_logo.png',
              ),
              _NavItem(
                icon: Icons.star_border,
                activeIcon: Icons.star,
                label: l10n.tabLikesYou,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
                useCustomStarIcon: true,
              ),
              _NavItem(
                icon: Icons.favorite_border,
                activeIcon: Icons.favorite,
                label: l10n.tabMatches,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
                badgeCount: likesYouBadgeCount,
                useCustomMatchesIcon: true,
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                activeIcon: Icons.chat_bubble,
                label: l10n.tabChat,
                isSelected: currentIndex == 3,
                onTap: () => onTap(3),
                badgeCount: chatBadgeCount,
                useCustomChatIcon: true,
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: l10n.tabProfile,
                isSelected: currentIndex == 4,
                onTap: () => onTap(4),
                showBadge: true,
                profileAvatarUrl: profileAvatarUrl,
                profileDisplayName: profileDisplayName,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
    this.badgeCount = 0,
    this.profileAvatarUrl,
    this.profileDisplayName = '',
    this.logoAssetPath,
    this.useCustomChatIcon = false,
    this.useCustomMatchesIcon = false,
    this.useCustomStarIcon = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;

  /// مسار شعار التطبيق (لتاب الرئيسية).
  final String? logoAssetPath;

  /// رسم فقاعة دردشة مخصص بدل الأيقونة.
  final bool useCustomChatIcon;

  /// رسم قلب مخصص لتاب المطابقات.
  final bool useCustomMatchesIcon;

  /// رسم نجمة مخصصة لتاب مميزون.
  final bool useCustomStarIcon;

  /// عدد الأشخاص (لأيقونة الدردشة: عدد المحادثات).
  final int badgeCount;
  final String? profileAvatarUrl;
  final String profileDisplayName;

  Widget _profileIconFallback(Color color) {
    if (profileDisplayName.isNotEmpty) {
      return Container(
        color: Colors.white.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Text(
          profileDisplayName[0].toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      );
    }
    return Container(
      color: Colors.white.withValues(alpha: 0.2),
      alignment: Alignment.center,
      child: Icon(Icons.person, size: 20, color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.5);

    final showProfileAvatar =
        profileAvatarUrl != null || profileDisplayName.isNotEmpty;
    final showLogo = logoAssetPath != null && logoAssetPath!.isNotEmpty;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showLogo)
                    Text(
                      'S',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        height: 1.0,
                      ),
                    )
                  else if (showProfileAvatar)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            profileAvatarUrl != null &&
                                profileAvatarUrl!.isNotEmpty
                            ? Image.network(
                                profileAvatarUrl!,
                                fit: BoxFit.cover,
                                width: 28,
                                height: 28,
                                errorBuilder: (_, __, ___) =>
                                    _profileIconFallback(color),
                              )
                            : _profileIconFallback(color),
                      ),
                    )
                  else if (useCustomChatIcon)
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CustomPaint(
                        painter: _ChatBubblePainter(color: color),
                        size: const Size(26, 26),
                      ),
                    )
                  else if (useCustomMatchesIcon)
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: CustomPaint(
                        painter: _HeartIconPainter(color: color),
                        size: const Size(30, 30),
                      ),
                    )
                  else if (useCustomStarIcon)
                    StarIconWidget(
                      color: color,
                      size: 40,
                      isSelected: isSelected,
                    )
                  else
                    Icon(
                      isSelected ? activeIcon : icon,
                      size: 26,
                      color: color,
                    ),
                  if (showBadge || badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: badgeCount > 0
                            ? const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              )
                            : EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: badgeCount > 0 ? 18 : 8,
                          minHeight: badgeCount > 0 ? 18 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neonCoral,
                          shape: badgeCount > 0
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: badgeCount > 0
                              ? BorderRadius.circular(9)
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: badgeCount > 0
                            ? Text(
                                badgeCount > 99 ? '99+' : '$badgeCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
