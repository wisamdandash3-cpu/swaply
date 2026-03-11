import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../data/mock_profiles.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../services/message_service.dart';
import '../services/block_service.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_service.dart';
import '../services/user_settings_service.dart';
import '../services/profile_fields_service.dart';
import '../services/like_limit_service.dart';
import '../services/profile_like_service.dart';
import '../services/filter_preferences_service.dart';
import '../services/wallet_service.dart';
import '../utils/profile_completion.dart';
import '../widgets/action_feedback_overlay.dart';
import '../widgets/like_limit_overlay.dart';
import '../widgets/match_animation_overlay.dart';
import '../widgets/profile_completion_dialog.dart';
import '../widgets/vertical_profile_view.dart';
import '../widgets/buy_roses_sheet.dart';
import '../widgets/flying_gift_message_overlay.dart';
import 'chat_screen.dart';
import 'edit_profile_screen.dart';

/// شاشة الاكتشاف بأسلوب Hinge: بطاقة واحدة لكل بروفايل، إعجاب بعنصر أو تخطّي.
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({
    super.key,
    this.isVisible = true,
    this.onAppBarTitleChange,
  });

  /// يُحمّل المحتوى فقط عند عرض التبويب (تجنب التجميد عند فتح التطبيق).
  final bool isVisible;

  /// عند التمرير للأسفل: اسم البروفايل؛ عند الأعلى: null (ليظهر "Swaply").
  final void Function(String? title)? onAppBarTitleChange;

  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen> {
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileFieldsService _profileFields = ProfileFieldsService();
  final LikeLimitService _likeLimitService = LikeLimitService();
  final ProfileLikeService _likeService = ProfileLikeService();
  final MessageService _messageService = MessageService();
  final WalletService _walletService = WalletService();
  final UserSettingsService _userSettings = UserSettingsService();
  final BlockService _blockService = BlockService();
  final ProfileService _profileService = ProfileService();
  final FilterPreferencesService _filterPrefs = FilterPreferencesService();

  List<String> _profileIds = [];
  int _currentIndex = 0;
  List<ProfileAnswer>? _currentAnswers;

  /// حقول البروفايل الحالي (user_profile_fields) لجميع المستخدمين — للعرض ولخوارزميات التشابه.
  Map<String, String> _currentProfileFields = {};
  bool _currentProfileOnline = false;
  bool _currentProfileVerified = false;
  bool _isLoading = true;
  bool _isSendingLike = false;
  bool _usingMockProfiles = false;
  List<
    ({String profileId, List<ProfileAnswer> answers, double lat, double lng})
  >
  _mockProfiles = [];
  double? _userLat;
  double? _userLng;
  bool _loadedWhenVisible = false;
  bool _useImperialUnits = false;
  bool _profileOwnerShowDistance = true;
  double? _currentProfileLat;
  double? _currentProfileLng;

  /// عداد إعجابات وهمية للاختبار (عند استخدام mock profiles).
  int _mockLikesCount = 0;
  DateTime? _mockCooldownUntil;

  /// تلميح رسالة الهدية (ماذا سوف تهمس له/لها) من إعدادات الضمير.
  String? _giftMessageHint;

  /// إزاحة طلبات الاكتشاف (لتحميل المزيد).
  int _discoveryOffset = 0;
  bool _hasMoreDiscovery = false;
  bool _isLoadingMore = false;

  static const double _scrollThresholdPx = 220;
  static const int _discoveryPageSize = 500;
  static const int _discoveryLoadMoreSize = 100;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_onScrollForAppBarTitle);

  void _onScrollForAppBarTitle() {
    if (!mounted || widget.onAppBarTitleChange == null) return;
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    final showName = offset > _scrollThresholdPx;
    final name =
        showName && _currentAnswers != null && _currentAnswers!.isNotEmpty
        ? _profileDisplayData(_currentAnswers!).displayName
        : null;
    widget.onAppBarTitleChange!(showName ? name : null);
  }

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _scheduleLoadWhenVisible();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollForAppBarTitle);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DiscoveryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isVisible && widget.isVisible) _scheduleLoadWhenVisible();
  }

  Future<void> _loadGiftMessageHint() async {
    if (!mounted) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final l10n = AppLocalizations.of(context);
    final pronounSetting = await _userSettings.getPreferredRecipientPronoun(userId);
    final pronoun = pronounSetting == 'female' ? l10n.pronounHer : l10n.pronounHim;
    if (mounted) setState(() => _giftMessageHint = l10n.giftMessageWhisperHint(pronoun));
  }

  void _scheduleLoadWhenVisible() {
    if (_loadedWhenVisible || !mounted) return;
    _loadedWhenVisible = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadGiftMessageHint();
      _loadUserLocationFromProfile(); // موقع المستخدم من profiles فوراً لعرض المسافة
      // تحميل البروفايلات الحقيقية على Android و iOS — عند الفشل أو الفراغ نعرض الوهمية.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _loadDiscovery();
      });
      Future.delayed(const Duration(seconds: 6), () {
        if (mounted && _isLoading && _currentAnswers == null) {
          _showFallbackProfiles();
        }
      });
      // الموقع يُطلب لاحقاً لتجنب التجمّد (Geolocator ثقيل على iOS و Android).
      Future.delayed(const Duration(seconds: 5), () {
        if (!mounted) return;
        _loadUserLocation();
      });
    });
  }

  /// تحميل موقع المستخدم من جدول profiles (محفوظ من الـ onboarding أو تعديل البروفايل).
  /// يعمل فوراً بدون انتظار GPS أو إذن الموقع.
  Future<void> _loadUserLocationFromProfile() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final loc = await _profileService
          .getLocation(userId)
          .timeout(const Duration(seconds: 3));
      if (loc != null && mounted) {
        setState(() {
          _userLat = loc.lat;
          _userLng = loc.lng;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 3),
      );
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission().timeout(
          const Duration(seconds: 5),
        );
      }
      final postPerm = await Geolocator.checkPermission().timeout(
        const Duration(seconds: 2),
      );
      if (postPerm == LocationPermission.denied ||
          postPerm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      ).timeout(const Duration(seconds: 8));
      if (mounted) {
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadDiscovery() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _currentAnswers = null;
    });
    try {
      final ok = await _loadDiscoveryIds().timeout(
        const Duration(seconds: 8),
        onTimeout: () => false,
      );
      if (ok || !mounted) return;
    } on TimeoutException catch (_) {
      if (mounted) _showFallbackProfiles();
      return;
    } catch (_) {
      if (mounted) _showFallbackProfiles();
      return;
    }
    _showFallbackProfiles();
  }

  /// يحمّل قائمة المعرّفات من السيرفر؛ يرجع true إذا وُجدت بروفايلات حقيقية وتم تحديث الواجهة.
  /// يفلتر البروفايلات غير المكتملة (< 50%) فلا تظهر للآخرين.
  Future<bool> _loadDiscoveryIds() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return false;
    final pausedIds = await _userSettings.getPausedUserIds().timeout(
      const Duration(seconds: 5),
      onTimeout: () => <String>{},
    );
    final blockedIds = await _blockService
        .getBlockedIds(currentUserId)
        .timeout(const Duration(seconds: 5), onTimeout: () => <String>{});
    final prefsForFilter = await _filterPrefs.load().timeout(
      const Duration(seconds: 2),
      onTimeout: () => <String, String?>{},
    );
    final maxDistanceKm = _parseMaxDistanceKm(prefsForFilter['maxDistance']);
    final ageMin = int.tryParse(prefsForFilter['ageMin'] ?? '');
    final ageMax = int.tryParse(prefsForFilter['ageMax'] ?? '');
    final interestedIn = prefsForFilter['interestedIn']?.trim();
    var realIds = await _answerService
        .getDiscoveryProfileIds(
          excludeUserId: currentUserId,
          excludePausedUserIds: pausedIds,
          excludeBlockedUserIds: blockedIds,
          maxDistanceKm: (maxDistanceKm != null && maxDistanceKm > 0 &&
                  _userLat != null && _userLng != null)
              ? maxDistanceKm
              : null,
          userLat: _userLat,
          userLng: _userLng,
          ageMin: (ageMin != null && ageMin > 0) ? ageMin : null,
          ageMax: (ageMax != null && ageMax > 0) ? ageMax : null,
          interestedIn: (interestedIn != null && interestedIn.isNotEmpty) ? interestedIn : null,
          limit: _discoveryPageSize,
          offset: 0,
        )
        .timeout(const Duration(seconds: 6), onTimeout: () => <String>[]);
    if (realIds.isEmpty || !mounted) return false;

    // فلترة البروفايلات غير المكتملة (< 50%) — مثل Parship.
    final filtered = await _filterByCompletion(realIds);
    realIds = filtered.ids;
    if (realIds.isEmpty || !mounted) return false;

    // ترتيب حسب التطابق مع تفضيلات المواعدة: الأقرب أولاً ثم العشوائي في النهاية.
    realIds = _sortIdsByPreferenceMatch(
      realIds,
      filtered.fieldsByProfileId,
      prefsForFilter,
    );

    setState(() {
      _profileIds = realIds;
      _currentIndex = 0;
      _usingMockProfiles = false;
      _mockProfiles = [];
      _isLoading = false;
      _discoveryOffset = _discoveryPageSize;
      _hasMoreDiscovery = realIds.length >= _discoveryPageSize;
    });
    _loadViewerUnitsPreference();
    _loadCurrentProfile();
    return true;
  }

  /// تحميل المزيد من بروفايلات الاكتشاف (ترقيم الصفحات).
  Future<void> _loadMoreDiscoveryIds() async {
    if (_isLoadingMore || !_hasMoreDiscovery || _usingMockProfiles) return;
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final pausedIds = await _userSettings.getPausedUserIds().timeout(
        const Duration(seconds: 5),
        onTimeout: () => <String>{},
      );
      final blockedIds = await _blockService
          .getBlockedIds(currentUserId)
          .timeout(const Duration(seconds: 5), onTimeout: () => <String>{});
      final prefsForFilter = await _filterPrefs.load().timeout(
        const Duration(seconds: 2),
        onTimeout: () => <String, String?>{},
      );
      final maxDistanceKm = _parseMaxDistanceKm(prefsForFilter['maxDistance']);
      final ageMin = int.tryParse(prefsForFilter['ageMin'] ?? '');
      final ageMax = int.tryParse(prefsForFilter['ageMax'] ?? '');
      final interestedIn = prefsForFilter['interestedIn']?.trim();
      final rawNewIds = await _answerService
          .getDiscoveryProfileIds(
            excludeUserId: currentUserId,
            excludePausedUserIds: pausedIds,
            excludeBlockedUserIds: blockedIds,
            maxDistanceKm: (maxDistanceKm != null &&
                    maxDistanceKm > 0 &&
                    _userLat != null &&
                    _userLng != null)
                ? maxDistanceKm
                : null,
            userLat: _userLat,
            userLng: _userLng,
            ageMin: (ageMin != null && ageMin > 0) ? ageMin : null,
            ageMax: (ageMax != null && ageMax > 0) ? ageMax : null,
            interestedIn: (interestedIn != null && interestedIn.isNotEmpty) ? interestedIn : null,
            limit: _discoveryLoadMoreSize,
            offset: _discoveryOffset,
          )
          .timeout(const Duration(seconds: 6), onTimeout: () => <String>[]);
      if (rawNewIds.isEmpty || !mounted) {
        if (mounted) {
          setState(() {
            _hasMoreDiscovery = false;
            _isLoadingMore = false;
          });
        }
        return;
      }
      final filtered = await _filterByCompletion(rawNewIds);
      final newIds = _sortIdsByPreferenceMatch(
        filtered.ids,
        filtered.fieldsByProfileId,
        prefsForFilter,
      );
      if (!mounted) return;
      setState(() {
        _profileIds = [..._profileIds, ...newIds];
        _discoveryOffset += _discoveryLoadMoreSize;
        _hasMoreDiscovery = rawNewIds.length >= _discoveryLoadMoreSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  /// يفلتر القائمة ليحتفظ فقط بالبروفايلات المكتملة (>= 50%).
  /// يُرجع أيضاً حقول كل بروفايل لاستخدامها في ترتيب التطابق مع التفضيلات.
  Future<
    ({List<String> ids, Map<String, Map<String, String>> fieldsByProfileId})
  >
  _filterByCompletion(List<String> profileIds) async {
    final filtered = <String>[];
    final fieldsByProfileId = <String, Map<String, String>>{};
    for (final id in profileIds) {
      try {
        final results = await Future.wait([
          _answerService.getByProfileId(id).timeout(const Duration(seconds: 4)),
          _profileFields.getFields(id).timeout(const Duration(seconds: 4)),
        ]);
        final answers = results[0] as List<ProfileAnswer>;
        final fields =
            results[1] as Map<String, ({String value, String visibility})>;
        final percent = ProfileCompletion.computePercent(
          answers: answers,
          fields: fields,
        );
        if (percent >= ProfileCompletion.minPercentToLike) {
          filtered.add(id);
          final valueMap = <String, String>{};
          for (final e in fields.entries) {
            final v = e.value.value.trim();
            if (v.isNotEmpty) valueMap[e.key] = v;
          }
          fieldsByProfileId[id] = valueMap;
        }
      } catch (_) {
        // عند الخطأ نستبعد البروفايل (تحفظاً)
      }
    }
    return (ids: filtered, fieldsByProfileId: fieldsByProfileId);
  }

  /// استخراج الحد الأقصى للمسافة بالكم من نص الفلتر (مثل "160 km" أو "500 km").
  double? _parseMaxDistanceKm(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final numStr = value.replaceAll(RegExp(r'[^\d.]'), '');
    final km = double.tryParse(numStr);
    return (km != null && km > 0) ? km : null;
  }

  /// يرتب المعرّفات: الأقرب لتفضيلات المستخدم أولاً، ثم الأقل تطابقاً، ثم عشوائي في النهاية.
  List<String> _sortIdsByPreferenceMatch(
    List<String> ids,
    Map<String, Map<String, String>> fieldsByProfileId,
    Map<String, String?> prefs,
  ) {
    if (ids.isEmpty) return ids;
    final hasAnyPref = prefs.values.any(
      (v) => v != null && v.toString().trim().isNotEmpty,
    );
    if (!hasAnyPref) {
      ids = List<String>.from(ids)..shuffle(math.Random());
      return ids;
    }

    final ageMin = int.tryParse(prefs['ageMin'] ?? '');
    final ageMax = int.tryParse(prefs['ageMax'] ?? '');
    final interestedIn = (prefs['interestedIn'] ?? '').trim().toLowerCase();
    final ethnicityPref = (prefs['ethnicity'] ?? '').trim();
    final religionPref = (prefs['religion'] ?? '').trim();
    final relationshipPref = (prefs['relationshipType'] ?? '').trim();

    bool isOpenToAll(String? v) {
      if (v == null || v.trim().isEmpty) return true;
      final lower = v.trim().toLowerCase();
      if (lower.contains('open') && lower.contains('all')) return true;
      if (v.contains('الجميع')) return true; // مفتوح للجميع
      return false;
    }

    int scoreFor(String profileId) {
      final fields = fieldsByProfileId[profileId] ?? {};
      int score = 0;

      // تفضيل الجنس / المهتم بـ
      if (interestedIn.isNotEmpty && !isOpenToAll(prefs['interestedIn'])) {
        final gender = (fields['gender'] ?? '').trim().toLowerCase();
        if (gender.isNotEmpty) {
          if ((interestedIn.contains('men') || interestedIn.contains('man')) &&
              (gender == 'man' || gender == 'male' || gender.contains('man'))) {
            score += 10;
          } else if ((interestedIn.contains('women') ||
                  interestedIn.contains('woman')) &&
              (gender == 'woman' ||
                  gender == 'female' ||
                  gender.contains('woman'))) {
            score += 10;
          }
        }
      }

      // العمر ضمن النطاق
      if (ageMin != null && ageMax != null) {
        final ageVal = int.tryParse(fields['age'] ?? '');
        if (ageVal != null && ageVal >= ageMin && ageVal <= ageMax) {
          score += 10;
        }
      }

      // عرق، دين، نوع العلاقة (مطابقة نصية بسيطة)
      if (ethnicityPref.isNotEmpty && !isOpenToAll(prefs['ethnicity'])) {
        final eth = (fields['ethnicity'] ?? '').trim().toLowerCase();
        if (eth.contains(ethnicityPref.toLowerCase())) score += 5;
      }
      if (religionPref.isNotEmpty && !isOpenToAll(prefs['religion'])) {
        final religion =
            (fields['religious_beliefs'] ?? fields['religion'] ?? '')
                .trim()
                .toLowerCase();
        if (religion.contains(religionPref.toLowerCase())) score += 5;
      }
      if (relationshipPref.isNotEmpty &&
          !isOpenToAll(prefs['relationshipType'])) {
        final rel =
            (fields['relationship_type'] ?? fields['relationship'] ?? '')
                .trim()
                .toLowerCase();
        if (rel.contains(relationshipPref.toLowerCase())) score += 5;
      }

      return score;
    }

    final scored = ids.map((id) => (id: id, score: scoreFor(id))).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));

    // داخل كل مجموعة نفس الدرجة نخلط عشوائياً حتى لا يكون الترتيب ثابتاً.
    final result = <String>[];
    int i = 0;
    while (i < scored.length) {
      final s = scored[i].score;
      var j = i;
      while (j < scored.length && scored[j].score == s) {
        j++;
      }
      final chunk = scored.sublist(i, j).map((e) => e.id).toList();
      chunk.shuffle(math.Random());
      result.addAll(chunk);
      i = j;
    }
    return result;
  }

  void _showFallbackProfiles() {
    final mock = getMockProfiles();
    if (mounted) {
      setState(() {
        _profileIds = mock.map((m) => m.profileId).toList();
        _currentIndex = 0;
        _usingMockProfiles = true;
        _mockProfiles = mock;
        _isLoading = false;
      });
      _loadViewerUnitsPreference();
      _loadCurrentProfile();
    }
  }

  Future<void> _loadViewerUnitsPreference() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final units = await _userSettings.getUnits(userId);
    if (mounted && (units == 'mi_ft') != _useImperialUnits) {
      setState(() => _useImperialUnits = units == 'mi_ft');
    }
  }

  Future<void> _loadCurrentProfile() async {
    if (_currentIndex >= _profileIds.length) return;
    final profileId = _profileIds[_currentIndex];
    if (_usingMockProfiles) {
      final mock = _mockProfiles.firstWhere((m) => m.profileId == profileId);
      if (mounted) {
        setState(() {
          _currentAnswers = mock.answers;
          _currentProfileOnline = false;
          _currentProfileVerified = false;
          _profileOwnerShowDistance = true;
          _currentProfileLat = mock.lat;
          _currentProfileLng = mock.lng;
          _isLoading = false;
        });
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _answerService
            .getByProfileId(profileId)
            .timeout(const Duration(seconds: 6)),
        _profileFields.getFields(profileId).timeout(const Duration(seconds: 6)),
      ]);
      final answers = results[0] as List<ProfileAnswer>;
      final fields =
          results[1] as Map<String, ({String value, String visibility})>;
      final fieldValues = <String, String>{};
      for (final e in fields.entries) {
        final v = e.value.value.trim();
        if (v.isNotEmpty) fieldValues[e.key] = v;
      }
      final online = await _userSettings.isOnline(
        profileId,
        withinMinutes: 180,
      );
      final verified = await _userSettings.getSelfieVerificationStatus(
        profileId,
      );
      final prefs = await _userSettings.getPrivacyPreferences(profileId);
      final showDist = prefs == null ? true : (prefs['show_distance'] != false);
      final loc = await _profileService.getLocation(profileId);
      if (mounted) {
        setState(() {
          _currentAnswers = answers;
          _currentProfileFields = fieldValues;
          _currentProfileOnline = online;
          _currentProfileVerified = verified == 'verified';
          _profileOwnerShowDistance = showDist;
          _currentProfileLat = loc?.lat;
          _currentProfileLng = loc?.lng;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentProfileFields = {};
        });
        _nextProfile();
      }
    }
  }

  void _nextProfile() {
    widget.onAppBarTitleChange?.call(null);
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
    if (_currentIndex + 1 < _profileIds.length) {
      setState(() {
        _currentIndex++;
        _currentAnswers = null;
        _currentProfileFields = {};
        _currentProfileOnline = false;
        _currentProfileVerified = false;
        _currentProfileLat = null;
        _currentProfileLng = null;
      });
      _loadCurrentProfile();
    } else {
      setState(() {
        _currentAnswers = null;
        _currentIndex = _profileIds.length;
      });
    }
  }

  Future<void> _onLike(ProfileAnswer item) async {
    if (_isSendingLike || _currentAnswers == null) return;

    if (_usingMockProfiles) {
      final now = DateTime.now();
      if (_mockCooldownUntil != null && now.isBefore(_mockCooldownUntil!)) {
        LikeLimitOverlay.show(
          context,
          cooldownUntil: _mockCooldownUntil!,
          onDismiss: () {},
        );
        return;
      }
      if (_mockCooldownUntil != null && now.isAfter(_mockCooldownUntil!)) {
        setState(() {
          _mockCooldownUntil = null;
          _mockLikesCount = 0;
        });
      }
      if (_mockLikesCount >= LikeLimitService.maxFreeLikes) {
        setState(() {
          _mockCooldownUntil = DateTime.now().add(
            LikeLimitService.cooldownDuration,
          );
        });
        LikeLimitOverlay.show(
          context,
          cooldownUntil: _mockCooldownUntil!,
          onDismiss: () {},
        );
        return;
      }
      setState(() => _mockLikesCount++);
    } else {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final result = await _likeLimitService.checkCanLike(userId);
        if (!mounted) return;
        if (!result.canLike && result.cooldownUntil != null) {
          LikeLimitOverlay.show(
            context,
            cooldownUntil: result.cooldownUntil!,
            onDismiss: () {},
          );
          return;
        }
      }
    }

    ActionFeedbackOverlay.show(
      context,
      type: ActionFeedbackType.like,
      onComplete: () => _performLike(item),
    );
  }

  Future<void> _performLike(ProfileAnswer item) async {
    if (_currentAnswers == null) return;
    final profileId = _profileIds[_currentIndex];
    final profileData = _profileDisplayData(_currentAnswers!);

    // فحص إكمال البروفايل دائماً (حتى مع البروفايلات التجريبية) — مثل Parship.
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) {
      try {
        final results = await Future.wait([
          _profileFields.getFields(userId).timeout(const Duration(seconds: 5)),
          _answerService
              .getByProfileId(userId)
              .timeout(const Duration(seconds: 5)),
        ]);
        final fields =
            results[0] as Map<String, ({String value, String visibility})>;
        final answers = results[1] as List<ProfileAnswer>;
        final percent = ProfileCompletion.computePercent(
          answers: answers,
          fields: fields,
        );
        if (percent < ProfileCompletion.minPercentToLike && mounted) {
          final photoAnswers = answers
              .where((a) => a.isImage && a.content.trim().isNotEmpty)
              .toList();
          final photoUrl = photoAnswers.isNotEmpty
              ? photoAnswers.first.content.trim()
              : null;
          _showProfileCompletionDialog(
            percent: percent,
            profilePhotoUrl: photoUrl,
            userId: userId,
          );
          return;
        }
      } catch (_) {
        // عند الخطأ نسمح بالإعجاب
      }
    }

    setState(() => _isSendingLike = true);
    if (_usingMockProfiles) {
      if (mounted) {
        _nextProfile();
      }
      setState(() => _isSendingLike = false);
      return;
    }
    try {
      final wasMatch = await _likeService.hasLikedMe(profileId);
      await _likeService.likeItem(toUserId: profileId, itemId: item.id);
      if (mounted) {
        if (wasMatch) {
          _showMatchAnimation(
            partnerId: profileId,
            partnerName: profileData.displayName,
            otherImageUrl: profileData.photoUrls.isNotEmpty
                ? profileData.photoUrls.first
                : null,
          );
        } else {
          _nextProfile();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).authError} $e'),
          ),
        );
        _nextProfile();
      }
    } finally {
      if (mounted) setState(() => _isSendingLike = false);
    }
  }

  void _showMatchAnimation({
    String? partnerId,
    String? partnerName,
    String? otherImageUrl,
  }) async {
    String? myImageUrl;
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        final myAnswers = await _answerService.getByProfileId(userId);
        for (final a in myAnswers) {
          if (a.isImage && a.content.trim().isNotEmpty) {
            myImageUrl = a.content;
            break;
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      pageBuilder: (ctx, anim, sec) => MatchAnimationOverlay(
        myImageUrl: myImageUrl,
        otherImageUrl: otherImageUrl,
        partnerId: partnerId,
        partnerName: partnerName ?? '',
        partnerAvatarUrl: otherImageUrl,
        onComplete: () {
          Navigator.of(context).pop();
          _nextProfile();
        },
        onSendFeeling: partnerId != null
            ? (String receiverId, String message, String giftType) async {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                final balance = await _walletService.getBalance();
                if (!balance.canSend(giftType)) {
                  if (mounted) {
                    Navigator.of(context).pop();
                    showBuyRosesSheet(context, initialGiftType: giftType);
                  }
                  return;
                }
                final deducted = await _walletService.deductGift(giftType);
                if (!deducted && mounted) {
                  Navigator.of(context).pop();
                  showBuyRosesSheet(context, initialGiftType: giftType);
                  return;
                }
                try {
                  await _likeService.sendMatchGift(
                    toUserId: receiverId,
                    giftType: giftType,
                    message: message.trim().isEmpty ? ' ' : message.trim(),
                  );
                } on PostgrestException catch (e) {
                  if (e.code == 'PGRST204' ||
                      (e.message.contains('gift_message') ||
                          e.message.contains('gift_type'))) {
                    debugPrint(
                      'profile_likes gift columns missing: run 005_profile_likes_gift.sql',
                    );
                  } else {
                    rethrow;
                  }
                }
                if (message.trim().isNotEmpty) {
                  await _messageService.sendMessage(
                    senderId: userId,
                    receiverId: receiverId,
                    content: message.trim(),
                    photoUrl: null,
                  );
                }
                await _messageService.sendMessage(
                  senderId: userId,
                  receiverId: receiverId,
                  content: ' ',
                  photoUrl: giftType,
                );
              }
            : null,
        onNavigateToChat: partnerId != null && partnerName != null
            ? (String id, String name, String? avatar) {
                Navigator.of(context).pop();
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ConversationScreen(
                        currentUserId: userId,
                        partnerId: id,
                        partnerName: name,
                        partnerAvatarUrl: avatar,
                        onMessageSent: () => _loadDiscovery(),
                      ),
                    ),
                  );
                }
              }
            : null,
        onSendTextOnly: partnerId != null
            ? (String receiverId, String message) async {
                final userId = Supabase.instance.client.auth.currentUser?.id;
                if (userId == null) return;
                await _messageService.sendMessage(
                  senderId: userId,
                  receiverId: receiverId,
                  content: message,
                  photoUrl: null,
                );
              }
            : null,
      ),
    );
  }

  void _onPass() {
    ActionFeedbackOverlay.show(
      context,
      type: ActionFeedbackType.pass,
      onComplete: _nextProfile,
    );
  }

  void _showProfileCompletionDialog({
    required int percent,
    String? profilePhotoUrl,
    required String userId,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ProfileCompletionDialog(
        completionPercent: percent,
        profilePhotoUrl: profilePhotoUrl,
        onFillNow: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => EditProfileScreen(
                userId: userId,
                onComplete: () => Navigator.of(context).pop(),
              ),
            ),
          );
        },
        onNotNow: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Future<void> _onSendGiftWithMessage(
    String receiverId,
    String message,
    String giftType,
  ) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final balance = await _walletService.getBalance();
    if (!balance.canSend(giftType)) {
      if (mounted) showBuyRosesSheet(context, initialGiftType: giftType);
      return;
    }
    final deducted = await _walletService.deductGift(giftType);
    if (!deducted && mounted) {
      showBuyRosesSheet(context, initialGiftType: giftType);
      return;
    }
    try {
      try {
        await _likeService.sendMatchGift(
          toUserId: receiverId,
          giftType: giftType,
          message: message.trim().isEmpty ? ' ' : message.trim(),
        );
      } on PostgrestException catch (e) {
        if (e.code == 'PGRST204' ||
            (e.message.contains('gift_message') ||
                e.message.contains('gift_type'))) {
          debugPrint(
            'profile_likes gift columns missing: run 005_profile_likes_gift.sql',
          );
        } else {
          rethrow;
        }
      }
      if (message.trim().isNotEmpty) {
        await _messageService.sendMessage(
          senderId: userId,
          receiverId: receiverId,
          content: message.trim(),
          photoUrl: null,
        );
      }
      await _messageService.sendMessage(
        senderId: userId,
        receiverId: receiverId,
        content: ' ',
        photoUrl: giftType,
      );
    } catch (e) {
      debugPrint('Discovery _onSendGiftWithMessage error: $e');
      rethrow;
    }
  }

  double? _computedDistanceKm() {
    if (_userLat == null || _userLng == null) return null;
    if (_usingMockProfiles) {
      if (_currentIndex >= _mockProfiles.length) return null;
      final mock = _mockProfiles[_currentIndex];
      return distanceKm(_userLat!, _userLng!, mock.lat, mock.lng);
    }
    if (_currentProfileLat == null || _currentProfileLng == null) return null;
    return distanceKm(
      _userLat!,
      _userLng!,
      _currentProfileLat!,
      _currentProfileLng!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_isLoading && _currentAnswers == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.neonCoral),
              const SizedBox(height: 16),
              Text(
                _profileIds.isEmpty ? l10n.noMoreProfiles : '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkBlack.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentAnswers == null || _currentAnswers!.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.noMoreProfiles,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.darkBlack.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _isLoading ? null : () => _loadDiscovery(),
                  icon: const Icon(Icons.refresh, size: 20),
                  label: Text(l10n.retry),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.hingePurple,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final imageAnswers = _currentAnswers!
        .where((a) => a.isImage && a.content.trim().isNotEmpty)
        .toList();
    final locale = Localizations.localeOf(context).languageCode;
    final v = _currentProfileFields;
    final overrides = <String, String>{};
    if ((v['height'] ?? '').isNotEmpty) overrides['height'] = v['height']!;
    if ((v['languages_spoken'] ?? '').isNotEmpty) {
      overrides['languages'] = v['languages_spoken']!;
    }
    final job = (v['work'] ?? '').isNotEmpty
        ? v['work']!
        : (v['job_title'] ?? '');
    if (job.isNotEmpty) overrides['job'] = job;
    final education = (v['education_level'] ?? '').isNotEmpty
        ? v['education_level']!
        : (v['college_or_university'] ?? '');
    if (education.isNotEmpty) overrides['education'] = education;
    if ((v['exercise'] ?? '').isNotEmpty) {
      overrides['exercise'] = v['exercise']!;
    }
    if ((v['top_photo_enabled'] ?? '').isNotEmpty) {
      overrides['top_photo_enabled'] = v['top_photo_enabled']!;
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final profileOwnerId =
        _profileIds.isNotEmpty && _currentIndex < _profileIds.length
        ? _profileIds[_currentIndex]
        : null;
    final showLoadMore = _profileIds.isNotEmpty &&
        _currentIndex == _profileIds.length - 1 &&
        _hasMoreDiscovery &&
        !_usingMockProfiles;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _SwipeableProfileWrap(
            onSwipeRight: imageAnswers.isNotEmpty
                ? () => _onLike(imageAnswers.first)
                : null,
            onSwipeLeft: _onPass,
            isSendingLike: _isSendingLike,
            child: VerticalProfileView(
          answers: _currentAnswers!,
          distanceKm: _computedDistanceKm(),
          giftMessageHint: _giftMessageHint,
          useImperialUnits: _useImperialUnits,
        showDistance: _profileOwnerShowDistance,
        isOnline: _currentProfileOnline,
        isVerified: _currentProfileVerified,
        locale: locale,
        lightweightMode:
            true, // تقليل استهلاك الموارد ومنع التجمّد عند عرض البروفايلات
        scrollController: widget.onAppBarTitleChange != null
            ? _scrollController
            : null,
        onLike: imageAnswers.isNotEmpty
            ? () => _onLike(imageAnswers.first)
            : null,
        onPass: _onPass,
        isSendingLike: _isSendingLike,
        personalInfoOverrides: overrides.isNotEmpty ? overrides : null,
        currentUserId: currentUserId,
        onSendGiftWithMessage:
            profileOwnerId != null &&
                currentUserId != null &&
                !profileOwnerId.startsWith('mock-')
            ? _onSendGiftWithMessage
            : null,
        onGiftSentSuccess: (message) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              FlyingGiftMessageOverlay.show(context, message);
            }
          });
        },
        onSendMessage: profileOwnerId != null && currentUserId != null
            ? (String receiverId, String message, String? photoUrl) async {
                final messenger = ScaffoldMessenger.of(context);
                final l10n = AppLocalizations.of(context);
                if (receiverId.startsWith('mock-')) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text(
                        'لا يمكن إرسال رسائل للبروفايلات التجريبية. تصفح بروفايلات حقيقية لإرسال الرسائل.',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                final result = await _messageService.sendMessage(
                  senderId: currentUserId,
                  receiverId: receiverId,
                  content: message,
                  photoUrl: photoUrl,
                );
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      result.isOk
                          ? l10n.messageSent
                          : (result.error ?? l10n.messageSent),
                    ),
                    backgroundColor: result.isOk
                        ? AppColors.hingePurple
                        : Colors.red,
                    duration: !result.isOk
                        ? const Duration(seconds: 6)
                        : const Duration(seconds: 2),
                  ),
                );
              }
            : null,
          ),
        ),
          if (showLoadMore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: Semantics(
                  button: true,
                  label: l10n.loadMoreProfiles,
                  child: TextButton.icon(
                    onPressed: _isLoadingMore ? null : _loadMoreDiscoveryIds,
                    icon: _isLoadingMore
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.neonCoral,
                          ),
                        )
                      : const Icon(Icons.add_circle_outline, size: 22),
                  label: Text(l10n.loadMoreProfiles),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.hingePurple,
                  ),
                ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  ({
    List<String> photoUrls,
    String displayName,
    String age,
    List<String> interestTags,
  })
  _profileDisplayData(List<ProfileAnswer> answers) {
    final sorted = List<ProfileAnswer>.from(answers)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // ترتيب الصور حسب السلوتات 200–205 (مطابق لـ vertical_profile_view).
    const photoSortBase = 200;
    final photoUrls = <String>[];
    for (int slot = 0; slot < 6; slot++) {
      final a = sorted
          .where((e) => e.isImage && e.sortOrder == photoSortBase + slot)
          .firstOrNull;
      if (a != null && a.content.trim().isNotEmpty) {
        photoUrls.add(a.content.trim());
      }
    }
    String displayName = 'User';
    String age = '';
    final interestTags = <String>[];
    final textContents = <String>[];

    for (final a in sorted) {
      // صور البروفايل (200–205) مُضافة أعلاه فقط
      if (!a.isImage) {
        textContents.add(a.content.trim());
      }
    }

    if (textContents.isNotEmpty) {
      final first = textContents.first;
      if (_looksLikeDate(first)) {
        age = _ageFromDateString(first) ?? '';
        if (textContents.length > 1) displayName = textContents[1];
      } else {
        displayName = first;
        if (textContents.length > 1 && _looksLikeDate(textContents[1])) {
          age = _ageFromDateString(textContents[1]) ?? '';
        }
      }
      for (var i = 2; i < textContents.length && interestTags.length < 6; i++) {
        final t = textContents[i];
        if (t.isNotEmpty && !_looksLikeDate(t) && t.length < 50) {
          interestTags.add(t);
        }
      }
    }

    if (interestTags.isEmpty) {
      interestTags.addAll(['Coffee ☕', 'Hiking 🥾', 'Travel ✈️', 'Books 📚']);
    }

    return (
      photoUrls: photoUrls,
      displayName: displayName,
      age: age,
      interestTags: interestTags,
    );
  }

  static bool _looksLikeDate(String s) {
    final trimmed = s.trim();
    if (trimmed.length < 8) return false;
    final dash = RegExp(r'^\d{4}-\d{2}-\d{2}');
    final slash = RegExp(r'^\d{1,2}/\d{1,2}/\d{4}');
    return dash.hasMatch(trimmed) || slash.hasMatch(trimmed);
  }

  static String? _ageFromDateString(String s) {
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
      if (now.month < date.month ||
          (now.month == date.month && now.day < date.day)) {
        age--;
      }
      return age > 0 && age < 120 ? '$age' : null;
    } catch (_) {
      return null;
    }
  }
}

/// يغلّف المحتوى ويمسك السحب الأفقي: يمين = قلب، يسار = X.
class _SwipeableProfileWrap extends StatefulWidget {
  const _SwipeableProfileWrap({
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.isSendingLike = false,
  });

  final Widget child;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final bool isSendingLike;

  @override
  State<_SwipeableProfileWrap> createState() => _SwipeableProfileWrapState();
}

class _SwipeableProfileWrapState extends State<_SwipeableProfileWrap> {
  double _dragDx = 0;

  static const double _swipeThreshold = 80;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: (details) {
        setState(() => _dragDx += details.delta.dx);
      },
      onHorizontalDragEnd: (details) {
        final dx = _dragDx;
        setState(() => _dragDx = 0);
        if (widget.isSendingLike) return;
        if (dx > _swipeThreshold && widget.onSwipeRight != null) {
          HapticFeedback.lightImpact();
          widget.onSwipeRight!();
        } else if (dx < -_swipeThreshold && widget.onSwipeLeft != null) {
          HapticFeedback.lightImpact();
          widget.onSwipeLeft!();
        }
      },
      onHorizontalDragCancel: () => setState(() => _dragDx = 0),
      child: widget.child,
    );
  }
}
