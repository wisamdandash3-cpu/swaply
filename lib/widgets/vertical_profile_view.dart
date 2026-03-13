import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_colors.dart';
import '../constants/gift_pricing.dart';
import '../data/lifestyle_interests.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../services/prompt_service.dart';
import 'cinematic_rose_widget.dart';
import 'flying_gift_message_overlay.dart';
import 'lifestyle_interests_sheet.dart';
import 'coffee_icon_widget.dart';
import 'ring_icon_widget.dart';
import '../screens/spotify_embed_screen.dart';
import 'verified_badge.dart';

// ignore_for_file: unused_element_parameter

/// sort_order لصور البروفايل (6 slots): 200–205 — يطابق edit_profile_screen.
const int _profilePhotoSortBase = 200;

/// Vertical scrolling profile feed with Glassmorphism and Bento Grid style.
class VerticalProfileView extends StatelessWidget {
  const VerticalProfileView({
    super.key,
    required this.answers,
    this.distanceKm,
    this.useImperialUnits = false,
    this.showDistance = true,
    this.isOnline = false,
    this.locale = 'en',
    this.onLike,
    this.onPass,
    this.isSendingLike = false,
    this.showActionButtons = true,
    this.personalInfoOverrides,

    /// معرّف المستخدم الحالي — إن وُجد وليس صاحب البروفايل، يُفعّل التصويت في الاستطلاع.
    this.currentUserId,
    this.onSendMessage,

    /// إرسال هدية + رسالة معاً من الصفحة الرئيسية: (profileId, message, giftType).
    this.onSendGiftWithMessage,

    /// عند true: تخطي BackdropFilter والخطوط الثقيلة لتجنب التجمّد (معاينة البروفايل).
    this.lightweightMode = false,

    /// إن وُجد يُربط بالـ CustomScrollView (لاستخدامه في اكتشاف التمرير لعنوان الشريط العلوي).
    this.scrollController,

    /// شارة التوثيق (التحقق بالـ selfie) تظهر بجانب الاسم والعمر.
    this.isVerified = false,

    /// تلميح حقل رسالة الهدية (ماذا سوف تهمس له/لها...) — إن وُجد يُستخدم بدل النص الافتراضي.
    this.giftMessageHint,

    /// يُستدعى بعد إرسال هدية بنجاح (نص الرسالة للعرض في الورقة الطائرة).
    this.onGiftSentSuccess,
  });

  final List<ProfileAnswer> answers;
  final double? distanceKm;

  /// عرض المسافة بالأميال بدلاً من الكيلومترات.
  final bool useImperialUnits;

  /// إخفاء المسافة (تفضيلات الخصوصية لصاحب البروفايل).
  final bool showDistance;

  /// إظهار نقطة خضراء إذا كان صاحب البروفايل متصلاً (نشط خلال آخر 3 ساعات).
  final bool isOnline;
  final String locale;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final bool isSendingLike;

  /// عند false (مثلاً معاينة البروفايل كمالك) لا تُعرض أزرار الإعجاب/التخطي.
  final bool showActionButtons;

  /// إن وُجد، يُدمج مع personalInfo المستخرج من answers (مثلاً من user_profile_fields).
  final Map<String, String>? personalInfoOverrides;

  /// معرّف المستخدم الحالي (لتفعيل التصويت في الاستطلاع عند عرض بروفايل غيره).
  final String? currentUserId;

  /// عند الضغط على أيقونة الرسالة في صورة: (profileId, نص الرسالة, رابط الصورة).
  final void Function(String profileId, String message, String? photoUrl)?
  onSendMessage;

  /// إرسال هدية + رسالة معاً: (profileId, message, giftType).
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final bool lightweightMode;
  final ScrollController? scrollController;

  /// عرض شارة التوثيق بجانب الاسم والعمر.
  final bool isVerified;

  /// تلميح حقل رسالة الهدية (من إعدادات الضمير).
  final String? giftMessageHint;

  /// بعد إرسال هدية بنجاح — يُستدعى بنص النجاح لعرض الورقة الطائرة فوق الشاشة.
  final void Function(String successMessage)? onGiftSentSuccess;

  static const double _radius = 24;

  @override
  Widget build(BuildContext context) {
    final l10nMain = AppLocalizations.of(context);
    final parsed = _parseProfileData(
      answers,
      personalInfoOverrides,
      l10nMain.user,
    );
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final showCornerActions =
        showActionButtons && (onLike != null || onPass != null);
    final bottomPadding = (showCornerActions ? 88 : 24) + safeBottom;
    final useSliverAppBar = parsed.photoUrls.isNotEmpty;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.glassLight, AppColors.glassLightGrey],
              ),
            ),
            child: useSliverAppBar
                ? CustomScrollView(
                    controller: scrollController,
                    primary: scrollController == null,
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 500,
                    slivers: [
                      ..._buildSlivers(context, parsed),
                      SliverPadding(
                        padding: EdgeInsets.only(bottom: bottomPadding),
                      ),
                    ],
                  )
                : ListView(
                    primary: true,
                    physics: const ClampingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    cacheExtent: 500,
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    children: _buildFeedChildren(context, parsed),
                  ),
          ),
        ),
        if (showCornerActions)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _CornerActionBar(
              onPass: onPass,
              onLike: onLike,
              isSendingLike: isSendingLike,
            ),
          ),
      ],
    );
  }

  /// بناء الـ slivers عند وجود صورة هيرو: SliverAppBar (اسم يظهر عند التمرير) + باقي المحتوى.
  List<Widget> _buildSlivers(BuildContext context, _ParsedProfile parsed) {
    final showMessageOnPhotos =
        showActionButtons &&
        onSendMessage != null &&
        parsed.profileOwnerId != null &&
        currentUserId != parsed.profileOwnerId;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final expandedHeight = (screenWidth - 32) * (4 / 3) + 48;

    final slivers = <Widget>[
      SliverAppBar(
        expandedHeight: expandedHeight,
        pinned: true,
        backgroundColor: AppColors.glassLight,
        foregroundColor: AppColors.darkBlack,
        flexibleSpace: FlexibleSpaceBar(
          background: _HeroSliverBackground(
            imageUrl: parsed.photoUrls.first,
            displayName: parsed.displayName,
            age: parsed.age,
            distanceKm: showDistance ? distanceKm : null,
            useImperialUnits: useImperialUnits,
            isOnline: isOnline,
            isVerified: isVerified,
            locale: locale,
            profileOwnerId: parsed.profileOwnerId,
            onSendMessage: showMessageOnPhotos ? onSendMessage : null,
            onSendGiftWithMessage: showMessageOnPhotos
                ? onSendGiftWithMessage
                : null,
            photoUrl: parsed.photoUrls.first,
            lightweightMode: lightweightMode,
            topPhotoEnabled: parsed.topPhotoEnabled,
            onLike: showActionButtons ? onLike : null,
            onPass: showActionButtons ? onPass : null,
            isSendingLike: isSendingLike,
            giftMessageHint: giftMessageHint,
            onGiftSentSuccess: onGiftSentSuccess,
          ),
        ),
      ),
      SliverToBoxAdapter(child: const _SectionDivider()),
    ];

    final l10n = AppLocalizations.of(context);
    final filledPersonalItems = _PersonalInfoBentoGrid.getFilledItems(
      parsed.personalInfo,
      l10n,
    );
    final numPhotos = parsed.photoUrls.length;

    // 2. أول قطعة بيانات بعد الصورة الأولى (الهيرو) — واضحة وملفتة
    if (filledPersonalItems.isNotEmpty && numPhotos > 0) {
      final dataChunk0 = _personalInfoChunk(filledPersonalItems, numPhotos, 0);
      if (dataChunk0.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: _PersonalInfoChunkCard(
              items: dataChunk0,
              sectionTitle: l10n.about.toUpperCase(),
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
      }
    }

    // 2b. أول جزء من الاهتمامات بعد الصورة الأولى (الهيرو) مع عنوان القسم
    if (parsed.interestTags.isNotEmpty && numPhotos > 0) {
      final chunk0 = _interestChunk(parsed.interestTags, numPhotos, 0);
      if (chunk0.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).sharedInterests.toUpperCase(),
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _InterestsChipsRow(tags: chunk0, highlightIndex: 0),
                ],
              ),
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
      }
    }

    // 3. Interleaved photos + prompts + data chunks + interest chunks after each photo
    final promptService = PromptService();
    var photoIndex = 1;
    var promptIndex = 0;
    while (photoIndex < parsed.photoUrls.length ||
        promptIndex < parsed.prompts.length) {
      if (promptIndex < parsed.prompts.length &&
          (photoIndex <= 1 || promptIndex < photoIndex)) {
        final p = parsed.prompts[promptIndex];
        final (promptText, answerText) = _parseWrittenPromptContent(
          p.content,
          p.questionId,
          locale,
          promptService,
        );
        final (
          audioUrl,
          spotifyUrl,
          spotifyImageUrl,
          spotifyTitle,
          spotifyArtist,
          durationSeconds,
        ) = _getVoiceRecordingUrls(
          p.content,
        );
        if (promptText == 'تسجيل صوتي' &&
            (audioUrl != null || spotifyUrl != null)) {
          slivers.add(
            SliverToBoxAdapter(
              child: _VoiceRecordingCard(
                promptText: promptText,
                answerText: answerText,
                audioUrl: audioUrl,
                spotifyUrl: spotifyUrl,
                spotifyImageUrl: spotifyImageUrl,
                spotifyTitle: spotifyTitle,
                spotifyArtist: spotifyArtist,
                durationSeconds: durationSeconds,
              ),
            ),
          );
        } else {
          slivers.add(
            SliverToBoxAdapter(
              child: _PromptCard(
                promptText: promptText,
                answerText: answerText,
              ),
            ),
          );
        }
        slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
        promptIndex++;
      }
      if (photoIndex < parsed.photoUrls.length) {
        final showMsg =
            showActionButtons &&
            onSendMessage != null &&
            parsed.profileOwnerId != null &&
            currentUserId != parsed.profileOwnerId;
        slivers.add(
          SliverToBoxAdapter(
            child: _PhotoCard(
              imageUrl: parsed.photoUrls[photoIndex],
              profileOwnerId: showMsg ? parsed.profileOwnerId : null,
              onSendMessage: showMsg ? onSendMessage : null,
              onSendGiftWithMessage: showMsg ? onSendGiftWithMessage : null,
              photoUrl: parsed.photoUrls[photoIndex],
              giftMessageHint: giftMessageHint,
              onGiftSentSuccess: onGiftSentSuccess,
            ),
          ),
        );
        slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
        // عرض الفيديو بين الصور — بعد الصورة الثانية (index 1)
        if (photoIndex == 1 &&
            parsed.videoUrl != null &&
            parsed.videoUrl!.isNotEmpty) {
          slivers.add(
            SliverToBoxAdapter(
              child: _VideoCard(
                videoUrl: parsed.videoUrl!,
                videoCaption: parsed.videoCaption,
              ),
            ),
          );
          slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
        }
        // قطعة بيانات البروفايل بعد هذه الصورة — واضحة وملفتة
        if (filledPersonalItems.isNotEmpty) {
          final dataChunk = _personalInfoChunk(
            filledPersonalItems,
            numPhotos,
            photoIndex,
          );
          if (dataChunk.isNotEmpty) {
            slivers.add(
              SliverToBoxAdapter(
                child: _PersonalInfoChunkCard(
                  items: dataChunk,
                  sectionTitle: l10n.details.toUpperCase(),
                ),
              ),
            );
            slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
          }
        }
        // جزء الاهتمامات بعد هذه الصورة
        if (parsed.interestTags.isNotEmpty) {
          final chunk = _interestChunk(
            parsed.interestTags,
            numPhotos,
            photoIndex,
          );
          if (chunk.isNotEmpty) {
            slivers.add(
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: _InterestsChipsRow(tags: chunk, highlightIndex: null),
                ),
              ),
            );
            slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
          }
        }
        photoIndex++;
      }
    }

    // إذا لم يكن هناك صورة ثانية: عرض الفيديو في النهاية
    if (parsed.photoUrls.length <= 1 &&
        parsed.videoUrl != null &&
        parsed.videoUrl!.isNotEmpty) {
      slivers.add(
        SliverToBoxAdapter(
          child: _VideoCard(
            videoUrl: parsed.videoUrl!,
            videoCaption: parsed.videoCaption,
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
    }
    // عند عدم وجود صور: عرض كل البيانات في كارت واحد واضح وملفت
    if (filledPersonalItems.isNotEmpty && numPhotos == 0) {
      slivers.add(
        SliverToBoxAdapter(
          child: _PersonalInfoChunkCard(
            items: filledPersonalItems,
            sectionTitle: l10n.about.toUpperCase(),
          ),
        ),
      );
      slivers.add(const SliverToBoxAdapter(child: _SectionDivider()));
    }
    // عرض كل الاهتمامات في قسم واحد فقط إذا لم يكن هناك صور (لا توزيع)
    if (parsed.interestTags.isNotEmpty && numPhotos == 0) {
      slivers.add(
        SliverToBoxAdapter(
          child: _BentoChipsSection(tags: parsed.interestTags),
        ),
      );
    }

    return slivers;
  }

  List<Widget> _buildFeedChildren(BuildContext context, _ParsedProfile parsed) {
    final children = <Widget>[];
    final l10n = AppLocalizations.of(context);
    final promptService = PromptService();

    // 1. First image with glassmorphism header overlay
    if (parsed.photoUrls.isNotEmpty) {
      final showMessageOnPhotos =
          showActionButtons &&
          onSendMessage != null &&
          parsed.profileOwnerId != null &&
          currentUserId != parsed.profileOwnerId;
      children.add(
        _HeroPhotoSection(
          imageUrl: parsed.photoUrls.first,
          displayName: parsed.displayName,
          age: parsed.age,
          distanceKm: showDistance ? distanceKm : null,
          useImperialUnits: useImperialUnits,
          isOnline: isOnline,
          isVerified: isVerified,
          locale: locale,
          profileOwnerId: parsed.profileOwnerId,
          onSendMessage: showMessageOnPhotos ? onSendMessage : null,
          onSendGiftWithMessage: showMessageOnPhotos
              ? onSendGiftWithMessage
              : null,
          photoUrl: parsed.photoUrls.first,
          lightweightMode: lightweightMode,
          topPhotoEnabled: parsed.topPhotoEnabled,
          giftMessageHint: giftMessageHint,
        ),
      );
      children.add(const _SectionDivider());
    }

    final filledPersonalItems = _PersonalInfoBentoGrid.getFilledItems(
      parsed.personalInfo,
      l10n,
    );
    final numPhotos = parsed.photoUrls.length;

    // 2. أول قطعة بيانات بعد الصورة الأولى — واضحة وملفتة
    if (filledPersonalItems.isNotEmpty && numPhotos > 0) {
      final dataChunk0 = _personalInfoChunk(filledPersonalItems, numPhotos, 0);
      if (dataChunk0.isNotEmpty) {
        children.add(
          _PersonalInfoChunkCard(
            items: dataChunk0,
            sectionTitle: l10n.about.toUpperCase(),
          ),
        );
        children.add(const _SectionDivider());
      }
    }

    // 2b. أول جزء من الاهتمامات بعد الصورة الأولى مع عنوان القسم
    if (parsed.interestTags.isNotEmpty && numPhotos > 0) {
      final chunk0 = _interestChunk(parsed.interestTags, numPhotos, 0);
      if (chunk0.isNotEmpty) {
        children.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).sharedInterests.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 12),
                _InterestsChipsRow(tags: chunk0, highlightIndex: 0),
              ],
            ),
          ),
        );
        children.add(const _SectionDivider());
      }
    }

    // 3. Interleaved: remaining photos + prompts + interest chunks after each photo
    var photoIndex = 1;
    var promptIndex = 0;
    while (photoIndex < parsed.photoUrls.length ||
        promptIndex < parsed.prompts.length) {
      if (promptIndex < parsed.prompts.length &&
          (photoIndex <= 1 || promptIndex < photoIndex)) {
        final p = parsed.prompts[promptIndex];
        final (promptText, answerText) = _parseWrittenPromptContent(
          p.content,
          p.questionId,
          locale,
          promptService,
        );
        final (
          audioUrl,
          spotifyUrl,
          spotifyImageUrl,
          spotifyTitle,
          spotifyArtist,
          durationSeconds,
        ) = _getVoiceRecordingUrls(
          p.content,
        );
        if (promptText == 'تسجيل صوتي' &&
            (audioUrl != null || spotifyUrl != null)) {
          children.add(
            _VoiceRecordingCard(
              promptText: promptText,
              answerText: answerText,
              audioUrl: audioUrl,
              spotifyUrl: spotifyUrl,
              spotifyImageUrl: spotifyImageUrl,
              spotifyTitle: spotifyTitle,
              spotifyArtist: spotifyArtist,
              durationSeconds: durationSeconds,
            ),
          );
        } else {
          children.add(
            _PromptCard(promptText: promptText, answerText: answerText),
          );
        }
        children.add(const _SectionDivider());
        promptIndex++;
      }
      if (photoIndex < parsed.photoUrls.length) {
        final showMessageOnPhotos =
            showActionButtons &&
            onSendMessage != null &&
            parsed.profileOwnerId != null &&
            currentUserId != parsed.profileOwnerId;
        children.add(
          _PhotoCard(
            imageUrl: parsed.photoUrls[photoIndex],
            profileOwnerId: showMessageOnPhotos ? parsed.profileOwnerId : null,
            onSendMessage: showMessageOnPhotos ? onSendMessage : null,
            onSendGiftWithMessage: showMessageOnPhotos
                ? onSendGiftWithMessage
                : null,
            photoUrl: parsed.photoUrls[photoIndex],
            giftMessageHint: giftMessageHint,
            onGiftSentSuccess: onGiftSentSuccess,
          ),
        );
        children.add(const _SectionDivider());
        // عرض الفيديو بين الصور — بعد الصورة الثانية (index 1)
        if (photoIndex == 1 &&
            parsed.videoUrl != null &&
            parsed.videoUrl!.isNotEmpty) {
          children.add(
            _VideoCard(
              videoUrl: parsed.videoUrl!,
              videoCaption: parsed.videoCaption,
            ),
          );
          children.add(const _SectionDivider());
        }
        if (filledPersonalItems.isNotEmpty) {
          final dataChunk = _personalInfoChunk(
            filledPersonalItems,
            numPhotos,
            photoIndex,
          );
          if (dataChunk.isNotEmpty) {
            children.add(
              _PersonalInfoChunkCard(
                items: dataChunk,
                sectionTitle: l10n.details.toUpperCase(),
              ),
            );
            children.add(const _SectionDivider());
          }
        }
        if (parsed.interestTags.isNotEmpty) {
          final chunk = _interestChunk(
            parsed.interestTags,
            numPhotos,
            photoIndex,
          );
          if (chunk.isNotEmpty) {
            children.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _InterestsChipsRow(tags: chunk, highlightIndex: null),
              ),
            );
            children.add(const _SectionDivider());
          }
        }
        photoIndex++;
      }
    }

    // إذا لم يكن هناك صورة ثانية: عرض الفيديو في النهاية
    if (parsed.photoUrls.length <= 1 &&
        parsed.videoUrl != null &&
        parsed.videoUrl!.isNotEmpty) {
      children.add(
        _VideoCard(
          videoUrl: parsed.videoUrl!,
          videoCaption: parsed.videoCaption,
        ),
      );
      children.add(const _SectionDivider());
    }

    // عند عدم وجود صور: عرض كل البيانات في كارت واحد واضح وملفت
    if (filledPersonalItems.isNotEmpty && numPhotos == 0) {
      children.add(
        _PersonalInfoChunkCard(
          items: filledPersonalItems,
          sectionTitle: l10n.about.toUpperCase(),
        ),
      );
      children.add(const _SectionDivider());
    }
    // 4. قسم الاهتمامات الكامل فقط عند عدم وجود صور (لا توزيع)
    if (parsed.interestTags.isNotEmpty && numPhotos == 0) {
      children.add(_BentoChipsSection(tags: parsed.interestTags));
    }

    return children;
  }

  _ParsedProfile _parseProfileData(
    List<ProfileAnswer> answers, [
    Map<String, String>? overrides,
    String defaultDisplayName = 'User',
  ]) {
    final sorted = List<ProfileAnswer>.from(answers)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    // ترتيب الصور تلقائياً حسب السلوتات 200–205 (لا عشوائية).
    final photoUrls = <String>[];
    for (int slot = 0; slot < 6; slot++) {
      final sortOrder = _profilePhotoSortBase + slot;
      final a = sorted
          .where((e) => e.isImage && e.sortOrder == sortOrder)
          .firstOrNull;
      if (a != null && a.content.trim().isNotEmpty) {
        photoUrls.add(a.content.trim());
      }
    }
    String displayName = defaultDisplayName;
    String age = '';
    final prompts = <ProfileAnswer>[];
    final interestTags = <String>[];
    final personalInfo = <String, String>{};
    String? videoUrl;
    String? videoCaption;
    String? profileOwnerId;

    for (final a in sorted) {
      if (profileOwnerId == null && a.profileId.isNotEmpty) {
        profileOwnerId = a.profileId;
      }
      // صور البروفايل (200–205) مُعالجة أعلاه فقط؛ لا نضيف صوراً أخرى هنا.
      if (a.isVideo && a.content.trim().isNotEmpty) {
        final c = a.content.trim();
        if (c.startsWith('{')) {
          try {
            final decoded = jsonDecode(c) as Map<String, dynamic>?;
            if (decoded != null) {
              final u = (decoded['url'] as Object?).toString().trim();
              final cap = (decoded['caption'] as Object?).toString().trim();
              if (u.isNotEmpty) videoUrl = u;
              if (cap.isNotEmpty) videoCaption = cap;
            }
          } catch (_) {
            videoUrl = c;
          }
        } else {
          videoUrl = c;
        }
      } else if (a.sortOrder >= 100 &&
          a.sortOrder <= 103 &&
          _isWrittenPromptContent(a.content)) {
        prompts.add(a);
      } else if (a.sortOrder == 54) {
        personalInfo['languages'] = a.content.trim();
      } else if (a.questionId != null && a.questionId!.isNotEmpty) {
        personalInfo[a.questionId!] = a.content.trim();
      } else if (_looksLikeDate(a.content)) {
        age = _ageFromDateString(a.content) ?? '';
      } else if (displayName == defaultDisplayName && a.content.length < 50) {
        displayName = a.content.trim();
      } else if (a.content.length < 50 && !_looksLikeDate(a.content)) {
        final trimmed = a.content.trim();
        if (trimmed.isNotEmpty && !trimmed.toLowerCase().startsWith('http')) {
          interestTags.add(trimmed);
        }
      }
    }

    bool topPhotoEnabled = false;
    if (overrides != null) {
      topPhotoEnabled = overrides['top_photo_enabled'] == 'true';
      final lifestyleJson = overrides['lifestyle_interests']?.trim();
      if (lifestyleJson != null && lifestyleJson.isNotEmpty) {
        final ids = parseLifestyleInterestsIds(lifestyleJson);
        if (ids.isNotEmpty) {
          interestTags.clear();
          interestTags.addAll(resolveLifestyleLabels(ids, locale));
        }
      }
      for (final e in overrides.entries) {
        if (e.key == 'lifestyle_interests' || e.key == 'top_photo_enabled') {
          continue;
        }
        if (e.value.trim().isNotEmpty) personalInfo[e.key] = e.value.trim();
      }
    }

    if (interestTags.length > 6) {
      interestTags.removeRange(6, interestTags.length);
    }
    if (interestTags.isEmpty) {
      interestTags.addAll(['Coffee ☕', 'Travel ✈️', 'Reading 📚', 'Yoga 🧘']);
    }

    return _ParsedProfile(
      photoUrls: photoUrls,
      displayName: displayName,
      age: age,
      prompts: prompts,
      interestTags: interestTags,
      personalInfo: personalInfo,
      videoUrl: videoUrl,
      videoCaption: videoCaption,
      profileOwnerId: profileOwnerId,
      topPhotoEnabled: topPhotoEnabled,
    );
  }

  /// Written prompts (sort_order 100-102) have content: {"prompt_id": "...", "answer": "..."}.
  static bool _isWrittenPromptContent(String content) {
    if (content.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded.containsKey('prompt_id') &&
          decoded['prompt_id'] != null &&
          decoded['prompt_id'].toString().isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// إذا كان المحتوى تسجيلاً صوتياً يُرجع (audio_url, spotify_url, spotify_image_url, spotify_title, spotify_artist, duration_seconds).
  static (
    String? audioUrl,
    String? spotifyUrl,
    String? spotifyImageUrl,
    String? spotifyTitle,
    String? spotifyArtist,
    int? durationSeconds,
  )
  _getVoiceRecordingUrls(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic> &&
          decoded['prompt_id']?.toString() == 'voice_recording') {
        final rawAudio = decoded['audio_url']?.toString();
        final rawSpotify = decoded['spotify_url']?.toString();
        final rawImage = decoded['spotify_image_url']?.toString();
        final rawTitle = decoded['spotify_title']?.toString();
        final rawArtist = decoded['spotify_artist']?.toString();
        final audioUrl = rawAudio != null && rawAudio.trim().isNotEmpty
            ? rawAudio.trim()
            : null;
        final spotifyUrl = rawSpotify != null && rawSpotify.trim().isNotEmpty
            ? rawSpotify.trim()
            : null;
        final spotifyImageUrl = rawImage != null && rawImage.trim().isNotEmpty
            ? rawImage.trim()
            : null;
        final spotifyTitle = rawTitle != null && rawTitle.trim().isNotEmpty
            ? rawTitle.trim()
            : null;
        final spotifyArtist = rawArtist != null && rawArtist.trim().isNotEmpty
            ? rawArtist.trim()
            : null;
        final dur = decoded['duration_seconds'];
        final durationSeconds = dur is int
            ? dur
            : (dur is num ? dur.toInt() : null);
        return (
          audioUrl,
          spotifyUrl,
          spotifyImageUrl,
          spotifyTitle,
          spotifyArtist,
          durationSeconds,
        );
      }
    } catch (_) {}
    return (null, null, null, null, null, null);
  }

  static String _formatVoiceDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString()}:${s.toString().padLeft(2, '0')}';
  }

  static List<double> _placeholderWaveformBars(int count) {
    return List.generate(count, (i) => 0.3 + 0.6 * ((i % 5 + 1) / 5.0));
  }

  /// Parses written prompt content (JSON with prompt_id/answer) or falls back to questionId.
  static (String promptText, String answerText) _parseWrittenPromptContent(
    String content,
    String? questionId,
    String locale,
    PromptService promptService,
  ) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) {
        final promptId = decoded['prompt_id']?.toString();
        final answer = decoded['answer']?.toString() ?? '';
        if (promptId != null && promptId.isNotEmpty) {
          if (promptId == 'voice_recording') {
            return ('تسجيل صوتي', answer);
          }
          final prompt = promptService.getPromptById(promptId);
          return (prompt?.textForLocale(locale) ?? promptId, answer);
        }
      }
    } catch (_) {}
    final prompt = promptService.getPromptById(questionId ?? '');
    return (prompt?.textForLocale(locale) ?? questionId ?? '', content);
  }

  static bool _looksLikeDate(String s) {
    final t = s.trim();
    if (t.length < 8) return false;
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t) ||
        RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(t);
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

class _ParsedProfile {
  final List<String> photoUrls;
  final String displayName;
  final String age;
  final List<ProfileAnswer> prompts;
  final List<String> interestTags;
  final Map<String, String> personalInfo;
  final String? videoUrl;
  final String? videoCaption;
  final String? profileOwnerId;

  /// عند true: الصورة الأولى المعروضة هي الرئيسية (حسب السلوت 0 أو الأكثر شعبية لاحقاً).
  final bool topPhotoEnabled;

  _ParsedProfile({
    required this.photoUrls,
    required this.displayName,
    required this.age,
    required this.prompts,
    required this.interestTags,
    required this.personalInfo,
    this.videoUrl,
    this.videoCaption,
    this.profileOwnerId,
    this.topPhotoEnabled = false,
  });
}

/// خلفية الهيرو داخل SliverAppBar — صورة، حافة علوية ضبابية، أزرار تواصل/تجاوز في المنتصف.
class _HeroSliverBackground extends StatelessWidget {
  const _HeroSliverBackground({
    required this.imageUrl,
    required this.displayName,
    required this.age,
    this.distanceKm,
    this.useImperialUnits = false,
    this.isOnline = false,
    this.isVerified = false,
    this.locale = 'en',
    this.profileOwnerId,
    this.onSendMessage,
    this.onSendGiftWithMessage,
    this.photoUrl,
    this.lightweightMode = false,
    this.topPhotoEnabled = false,
    this.onLike,
    this.onPass,
    this.isSendingLike = false,
    this.giftMessageHint,
    this.onGiftSentSuccess,
  });

  final String imageUrl;
  final String displayName;
  final String age;
  final double? distanceKm;
  final bool useImperialUnits;
  final bool isOnline;
  final bool isVerified;
  final String locale;
  final String? profileOwnerId;
  final void Function(String profileId, String message, String? photoUrl)?
  onSendMessage;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final String? photoUrl;
  final bool lightweightMode;
  final bool topPhotoEnabled;
  final VoidCallback? onLike;
  final VoidCallback? onPass;
  final bool isSendingLike;
  final String? giftMessageHint;
  final void Function(String successMessage)? onGiftSentSuccess;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(VerticalProfileView._radius),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            memCacheWidth: lightweightMode ? 400 : null,
            memCacheHeight: lightweightMode ? 500 : null,
            placeholder: (_, _) => Container(
              color: AppColors.hingePurple.withValues(alpha: 0.2),
              child: const Icon(Icons.person, size: 80, color: Colors.white54),
            ),
            errorWidget: (_, _, _) => Container(
              color: AppColors.hingePurple.withValues(alpha: 0.3),
              child: const Icon(Icons.person, size: 80, color: Colors.white54),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 100,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(VerticalProfileView._radius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.glassLight.withValues(alpha: 0.92),
                    AppColors.glassLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (profileOwnerId != null && onSendMessage != null)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 16,
            child: _MessageIconButton(
              profileOwnerId: profileOwnerId!,
              onSendMessage: onSendMessage!,
              onSendGiftWithMessage: onSendGiftWithMessage,
              photoUrl: photoUrl ?? imageUrl,
              giftMessageHint: giftMessageHint,
              onGiftSentSuccess: onGiftSentSuccess,
            ),
          ),
        if (topPhotoEnabled)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                AppLocalizations.of(context).topPhoto,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: lightweightMode
                ? _buildNameDistanceOverlay(context, useBlur: false)
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: _buildNameDistanceOverlay(context, useBlur: true),
                  ),
          ),
        ),
      ],
    );
  }

  /// تراكب الاسم والمسافة — زجاج ضبابي بلون بني–رمادي فاتح، حدود فاتحة، نص أبيض ومحاذاة لليمين (كما في الصورة الرابعة).
  Widget _buildNameDistanceOverlay(
    BuildContext context, {
    required bool useBlur,
  }) {
    final withAge = age.isNotEmpty ? '$displayName, $age' : displayName;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.warmSand.withValues(alpha: useBlur ? 0.72 : 0.78),
            AppColors.warmSandBorder.withValues(alpha: useBlur ? 0.78 : 0.84),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (isOnline) ...[
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.forestGreen,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.8),
                      width: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (isVerified) ...[
                const VerifiedBadge(size: 30, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                withAge,
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 6),
            Text(
              useImperialUnits
                  ? AppLocalizations.of(
                      context,
                    ).distanceMiles((distanceKm! * 0.621371).round())
                  : AppLocalizations.of(
                      context,
                    ).distanceKm(distanceKm!.round().toInt()),
              style: GoogleFonts.montserrat(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Hero photo with glassmorphism header overlay (BackdropFilter).
class _HeroPhotoSection extends StatelessWidget {
  const _HeroPhotoSection({
    required this.imageUrl,
    required this.displayName,
    required this.age,
    this.distanceKm,
    this.useImperialUnits = false,
    this.isOnline = false,
    this.isVerified = false,
    this.locale = 'en',
    this.profileOwnerId,
    this.onSendMessage,
    this.onSendGiftWithMessage,
    this.photoUrl,
    this.lightweightMode = false,
    this.topPhotoEnabled = false,
    this.giftMessageHint,
  });

  final String imageUrl;
  final String displayName;
  final String age;
  final double? distanceKm;
  final bool useImperialUnits;
  final bool isOnline;
  final bool isVerified;
  final String locale;
  final String? profileOwnerId;
  final void Function(String profileId, String message, String? photoUrl)?
  onSendMessage;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final String? photoUrl;
  final bool lightweightMode;
  final bool topPhotoEnabled;
  final String? giftMessageHint;

  static Widget _onlineDot() => Container(
    width: 10,
    height: 10,
    margin: const EdgeInsets.only(left: 6, right: 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [const Color(0xFF4ADE80), AppColors.forestGreen],
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

  Widget _buildNameAgeRow(BuildContext context) {
    final textStyle = lightweightMode
        ? TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          )
        : GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          );
    if (age.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(displayName, style: textStyle),
          if (isVerified) ...[
            const SizedBox(width: 8),
            const VerifiedBadge(size: 30, color: Colors.white),
          ],
          if (isOnline) _onlineDot(),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$displayName, ', style: textStyle),
        Text(age, style: textStyle),
        if (isVerified) ...[
          const SizedBox(width: 8),
          const VerifiedBadge(size: 30, color: Colors.white),
        ],
        if (isOnline) _onlineDot(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VerticalProfileView._radius),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    memCacheWidth: lightweightMode ? 400 : null,
                    memCacheHeight: lightweightMode ? 500 : null,
                    placeholder: (_, _) => Container(
                      color: AppColors.hingePurple.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.hingePurple.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.person,
                        size: 80,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (profileOwnerId != null && onSendMessage != null)
            Positioned(
              top: 16,
              right: 16,
              child: _MessageIconButton(
                profileOwnerId: profileOwnerId!,
                onSendMessage: onSendMessage!,
                onSendGiftWithMessage: onSendGiftWithMessage,
                photoUrl: photoUrl ?? imageUrl,
                giftMessageHint: giftMessageHint,
              ),
            ),
          if (topPhotoEnabled)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppLocalizations.of(context).topPhoto,
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VerticalProfileView._radius),
              child: lightweightMode
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warmSand.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(
                          VerticalProfileView._radius,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNameAgeRow(context),
                          if (distanceKm != null) ...[
                            const SizedBox(height: 6),
                            Text(
                              useImperialUnits
                                  ? AppLocalizations.of(context).distanceMiles(
                                      (distanceKm! * 0.621371).round(),
                                    )
                                  : AppLocalizations.of(
                                      context,
                                    ).distanceKm(distanceKm!.round()),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.95),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.warmSand.withValues(alpha: 0.72),
                              AppColors.warmSandBorder.withValues(alpha: 0.78),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(
                            VerticalProfileView._radius,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildNameAgeRow(context),
                            if (distanceKm != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                useImperialUnits
                                    ? AppLocalizations.of(
                                        context,
                                      ).distanceMiles(
                                        (distanceKm! * 0.621371).round(),
                                      )
                                    : AppLocalizations.of(
                                        context,
                                      ).distanceKm(distanceKm!.round()),
                                style: GoogleFonts.montserrat(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// معلومات شخصية بتصميم قائمة: أيقونة + عنوان رمادي (أحرف كبيرة) + قيمة — تُعرض كل بيانات البروفايل.
class _PersonalInfoBentoGrid extends StatelessWidget {
  const _PersonalInfoBentoGrid({required this.personalInfo});

  final Map<String, String> personalInfo;

  static const _labelStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
  static const _valueStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// ترتيب وعرض كل حقول البروفايل (Steckbrief) مع أيقونة — يطابق مفاتيح user_profile_fields + answers.
  static const _knownKeys = [
    ('pronouns', Icons.badge_outlined),
    ('gender', Icons.wc_outlined),
    ('sexuality', Icons.favorite_border),
    ('im_interested_in', Icons.people_outline),
    ('match_note', Icons.note_outlined),
    ('work', Icons.work_outline),
    ('job_title', Icons.business_center_outlined),
    ('job', Icons.work_outline),
    ('college_or_university', Icons.school_outlined),
    ('education_level', Icons.school_outlined),
    ('education', Icons.school_outlined),
    ('religious_beliefs', Icons.auto_awesome_outlined),
    ('home_town', Icons.location_city_outlined),
    ('politics', Icons.balance_outlined),
    ('languages_spoken', Icons.language),
    ('languages', Icons.language),
    ('dating_intentions', Icons.favorite_outline),
    ('relationship_type', Icons.people_outline),
    ('name', Icons.person_outline),
    ('age', Icons.cake_outlined),
    ('height', Icons.height),
    ('location', Icons.location_on_outlined),
    ('ethnicity', Icons.groups_outlined),
    ('children', Icons.child_care_outlined),
    ('family_plans', Icons.family_restroom_outlined),
    ('covid_vaccine', Icons.medical_services_outlined),
    ('pets', Icons.pets),
    ('zodiac_sign', Icons.star_outline),
    ('drinking', Icons.local_bar_outlined),
    ('smoking', Icons.smoking_rooms_outlined),
    ('marijuana', Icons.eco_outlined),
    ('drugs', Icons.medication_outlined),
    ('exercise', Icons.fitness_center),
  ];

  static String _fieldLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'pronouns':
        return l10n.pronouns;
      case 'gender':
        return l10n.gender;
      case 'sexuality':
        return l10n.sexuality;
      case 'im_interested_in':
        return l10n.imInterestedIn;
      case 'match_note':
        return l10n.matchNote;
      case 'work':
      case 'job':
        return l10n.work;
      case 'job_title':
        return l10n.jobTitle;
      case 'college_or_university':
        return l10n.collegeOrUniversity;
      case 'education_level':
      case 'education':
        return l10n.educationLevel;
      case 'religious_beliefs':
        return l10n.religiousBeliefs;
      case 'home_town':
        return l10n.homeTown;
      case 'politics':
        return l10n.politics;
      case 'languages_spoken':
      case 'languages':
        return l10n.languagesSpoken;
      case 'dating_intentions':
        return l10n.datingIntentions;
      case 'relationship_type':
        return l10n.relationshipType;
      case 'name':
        return l10n.name;
      case 'age':
        return l10n.age;
      case 'height':
        return l10n.height;
      case 'location':
        return l10n.location;
      case 'ethnicity':
        return l10n.ethnicity;
      case 'children':
        return l10n.children;
      case 'family_plans':
        return l10n.familyPlans;
      case 'covid_vaccine':
        return l10n.covidVaccine;
      case 'pets':
        return l10n.pets;
      case 'zodiac_sign':
        return l10n.zodiacSign;
      case 'drinking':
        return l10n.drinking;
      case 'smoking':
        return l10n.smoking;
      case 'marijuana':
        return l10n.marijuana;
      case 'drugs':
        return l10n.drugs;
      case 'exercise':
        return l10n.exercise;
      default:
        return key.toUpperCase().replaceAll('_', ' ');
    }
  }

  /// يُرجع قائمة الحقول المعبأة فقط (للتوزيع بين الصور أو عرض كتلة واحدة).
  static List<_ProfileInfoRowItem> getFilledItems(
    Map<String, String> personalInfo,
    AppLocalizations l10n,
  ) {
    final items = <_ProfileInfoRowItem>[];
    final seen = <String>{};
    for (final e in _knownKeys) {
      seen.add(e.$1);
      final value = personalInfo[e.$1]?.trim();
      if (value == null || value.isEmpty) continue;
      items.add(_ProfileInfoRowItem(e.$2, _fieldLabel(l10n, e.$1), value));
    }
    for (final entry in personalInfo.entries) {
      if (seen.contains(entry.key)) continue;
      final value = entry.value.trim();
      if (value.isEmpty) continue;
      final label = _fieldLabel(l10n, entry.key);
      items.add(_ProfileInfoRowItem(Icons.info_outline_rounded, label, value));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = getFilledItems(personalInfo, l10n);
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) => _ProfileInfoRow(item: item)).toList(),
      ),
    );
  }
}

class _ProfileInfoRowItem {
  final IconData icon;
  final String label;
  final String value;
  _ProfileInfoRowItem(this.icon, this.label, this.value);
}

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.item});

  final _ProfileInfoRowItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 22,
            color: AppColors.hingePurple.withValues(alpha: 0.85),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: _PersonalInfoBentoGrid._labelStyle.copyWith(
                    color: AppColors.darkBlack.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.value,
                  style: _PersonalInfoBentoGrid._valueStyle.copyWith(
                    color: AppColors.darkBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// كارت لعرض قطعة من بيانات البروفايل — تصميم أبيض مع عنوان عريض وحبوب (pills) أيقونة + قيمة كما في الصورة الثالثة.
class _PersonalInfoChunkCard extends StatelessWidget {
  const _PersonalInfoChunkCard({
    required this.items,
    required this.sectionTitle,
  });

  final List<_ProfileInfoRowItem> items;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items
                .map((item) => _AboutPill(icon: item.icon, label: item.value))
                .toList(),
          ),
        ],
      ),
    );
  }
}

/// حبة واحدة: أيقونة + نص (نفس شكل الصورة الثالثة).
class _AboutPill extends StatelessWidget {
  const _AboutPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: AppColors.hingePurple.withValues(alpha: 0.9),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.darkBlack,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة تسجيل صوتي — زر تشغيل أو رابط Spotify.
class _VoiceRecordingCard extends StatefulWidget {
  const _VoiceRecordingCard({
    required this.promptText,
    required this.answerText,
    this.audioUrl,
    this.spotifyUrl,
    this.spotifyImageUrl,
    this.spotifyTitle,
    this.spotifyArtist,
    this.durationSeconds,
  });

  final String promptText;
  final String answerText;
  final String? audioUrl;
  final String? spotifyUrl;
  final String? spotifyImageUrl;
  final String? spotifyTitle;
  final String? spotifyArtist;
  final int? durationSeconds;

  @override
  State<_VoiceRecordingCard> createState() => _VoiceRecordingCardState();
}

class _VoiceRecordingCardState extends State<_VoiceRecordingCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  static final List<double> _waveBars =
      VerticalProfileView._placeholderWaveformBars(28);

  @override
  void dispose() {
    _completeSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _listenToPosition() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _durationSub = _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _positionSub = _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  Future<void> _togglePlay() async {
    final audioUrl = widget.audioUrl;
    if (audioUrl == null || audioUrl.isEmpty || _loading) return;
    if (_playing) {
      await _player.pause();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _loading = true);
    try {
      _completeSub?.cancel();
      _completeSub = _player.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      });
      _listenToPosition();
      await _player.play(UrlSource(audioUrl));
      if (mounted) {
        setState(() {
          _playing = true;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('_VoiceRecordingCard._togglePlay error: $e');
      debugPrint('_VoiceRecordingCard._togglePlay stack: $st');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).voicePlaybackFailed),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _openSpotify(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAudio = widget.audioUrl != null && widget.audioUrl!.isNotEmpty;
    final hasSpotify =
        widget.spotifyUrl != null && widget.spotifyUrl!.isNotEmpty;
    final durationSec = widget.durationSeconds ?? _duration.inSeconds;
    final totalSec = durationSec > 0 ? durationSec : _duration.inSeconds;
    final displayDuration = totalSec > 0
        ? VerticalProfileView._formatVoiceDuration(totalSec)
        : null;

    if (hasSpotify && !hasAudio) {
      final songTitle =
          (widget.spotifyTitle ?? widget.answerText).trim().isEmpty
          ? l10n.voiceAddSpotifySong
          : (widget.spotifyTitle ?? widget.answerText).trim();
      final artistTitle = widget.spotifyArtist?.trim();
      final imageUrl = widget.spotifyImageUrl;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpotifyEmbedScreen(
                      spotifyUrl: widget.spotifyUrl!,
                      title: songTitle != l10n.voiceAddSpotifySong
                          ? songTitle
                          : null,
                      artist: artistTitle,
                    ),
                  ),
                ),
                borderRadius: BorderRadius.circular(
                  VerticalProfileView._radius,
                ),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.hingePurple.withValues(alpha: 0.15),
                        AppColors.hingePurple.withValues(alpha: 0.28),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      VerticalProfileView._radius,
                    ),
                    border: Border.all(
                      color: AppColors.hingePurple.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.hingePurple.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                placeholder: (_, _) => Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.darkBlack.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.spotify,
                                    size: 26,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                                errorWidget: (_, _, _) => Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.darkBlack.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: FaIcon(
                                    FontAwesomeIcons.spotify,
                                    size: 26,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.darkBlack.withValues(
                                    alpha: 0.08,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.spotify,
                                  size: 26,
                                  color: Colors.green.shade700,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              songTitle,
                              style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBlack,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (artistTitle != null &&
                                artistTitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                artistTitle,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  color: AppColors.darkBlack.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SpotifyEmbedScreen(
                                          spotifyUrl: widget.spotifyUrl!,
                                          title:
                                              songTitle !=
                                                  l10n.voiceAddSpotifySong
                                              ? songTitle
                                              : null,
                                          artist: artistTitle,
                                        ),
                                      ),
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                        horizontal: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.play_circle_filled,
                                            size: 20,
                                            color: Colors.green.shade700,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            l10n.playFullSong,
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  Colors.green.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () =>
                                        _openSpotify(widget.spotifyUrl),
                                    borderRadius: BorderRadius.circular(4),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Text(
                                        l10n.spotifyBrand,
                                        style: GoogleFonts.montserrat(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.green.shade600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.spotify,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.spotifyBrand,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(VerticalProfileView._radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSpotify)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpotifyEmbedScreen(
                        spotifyUrl: widget.spotifyUrl!,
                        title:
                            (widget.spotifyTitle ?? widget.answerText)
                                .trim()
                                .isNotEmpty
                            ? (widget.spotifyTitle ?? widget.answerText).trim()
                            : null,
                        artist: widget.spotifyArtist?.trim(),
                      ),
                    ),
                  ),
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.green.shade700.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.green.shade700.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: FaIcon(
                      FontAwesomeIcons.spotify,
                      size: 26,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ),
            if (hasAudio) ...[
              if (hasSpotify) const SizedBox(width: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : _togglePlay,
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.hingePurple.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.hingePurple.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.hingePurple,
                            ),
                          )
                        : Icon(
                            _playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                            color: AppColors.hingePurple,
                          ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.promptText,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkBlack.withValues(alpha: 0.7),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final progress =
                          (_duration.inMilliseconds > 0 && _playing)
                          ? _position.inMilliseconds / _duration.inMilliseconds
                          : 0.0;
                      return SizedBox(
                        height: 28,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_waveBars.length, (i) {
                            final h = _waveBars[i];
                            final isPlayed =
                                progress > 0 &&
                                (i / _waveBars.length) < progress;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 1.5,
                              ),
                              width: 3,
                              height: 6 + h * 16,
                              decoration: BoxDecoration(
                                color: isPlayed
                                    ? AppColors.hingePurple.withValues(
                                        alpha: 0.8,
                                      )
                                    : AppColors.darkBlack.withValues(
                                        alpha: 0.25,
                                      ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                  ),
                  if (displayDuration != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      displayDuration,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.darkBlack.withValues(alpha: 0.5),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    widget.answerText.isEmpty && hasSpotify
                        ? l10n.voiceAddSpotifySong
                        : widget.answerText,
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkBlack,
                      height: 1.35,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSpotify)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SpotifyEmbedScreen(
                                spotifyUrl: widget.spotifyUrl!,
                                title:
                                    (widget.spotifyTitle ?? widget.answerText)
                                        .trim()
                                        .isNotEmpty
                                    ? (widget.spotifyTitle ?? widget.answerText)
                                          .trim()
                                    : null,
                                artist: widget.spotifyArtist?.trim(),
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_circle_filled,
                                  size: 20,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.playFullSong,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green.shade700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Prompt card with semi-transparent Heart button and glow effect on tap.
class _PromptCard extends StatefulWidget {
  const _PromptCard({required this.promptText, required this.answerText});

  final String promptText;
  final String answerText;

  @override
  State<_PromptCard> createState() => _PromptCardState();
}

class _PromptCardState extends State<_PromptCard> {
  bool _isGlowing = false;

  /// لا نعرض الروابط كنص (تجنب overflow وظهور URL في البطاقة).
  static String _displayAnswerText(String answerText) {
    final t = answerText.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return '—';
    return t;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 64, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(VerticalProfileView._radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                if (_isGlowing)
                  BoxShadow(
                    color: AppColors.rosePink.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.promptText,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Text(
                  _displayAnswerText(widget.answerText),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkBlack,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isGlowing = !_isGlowing),
                customBorder: const CircleBorder(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isGlowing
                          ? AppColors.rosePink
                          : Colors.grey.shade300,
                      width: _isGlowing ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    Icons.favorite,
                    size: 22,
                    color: _isGlowing
                        ? AppColors.rosePink
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoCard extends StatelessWidget {
  const _PhotoCard({
    required this.imageUrl,
    this.profileOwnerId,
    this.onSendMessage,
    this.onSendGiftWithMessage,
    this.photoUrl,
    this.giftMessageHint,
    this.onGiftSentSuccess,
  });

  final String imageUrl;
  final String? profileOwnerId;
  final void Function(String profileId, String message, String? photoUrl)?
  onSendMessage;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final String? photoUrl;
  final String? giftMessageHint;
  final void Function(String successMessage)? onGiftSentSuccess;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VerticalProfileView._radius),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_outlined, size: 48),
                ),
                errorWidget: (_, _, _) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 48),
                ),
              ),
            ),
          ),
          if (profileOwnerId != null && onSendMessage != null)
            Positioned(
              top: 16,
              right: 32,
              child: _MessageIconButton(
                profileOwnerId: profileOwnerId!,
                onSendMessage: onSendMessage!,
                onSendGiftWithMessage: onSendGiftWithMessage,
                photoUrl: photoUrl ?? imageUrl,
                giftMessageHint: giftMessageHint,
                onGiftSentSuccess: onGiftSentSuccess,
              ),
            ),
        ],
      ),
    );
  }
}

/// زر أيقونة الرسالة على الصورة — يفتح ورقة إرسال رسالة جميلة مع هدايا.
class _MessageIconButton extends StatelessWidget {
  const _MessageIconButton({
    required this.profileOwnerId,
    required this.onSendMessage,
    this.onSendGiftWithMessage,
    required this.photoUrl,
    this.giftMessageHint,
    this.onGiftSentSuccess,
  });

  final String profileOwnerId;
  final void Function(String profileId, String message, String? photoUrl)
  onSendMessage;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final String photoUrl;
  final String? giftMessageHint;
  final void Function(String successMessage)? onGiftSentSuccess;

  void _openSendMessageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => _SendMessageSheetContent(
        profileOwnerId: profileOwnerId,
        photoUrl: photoUrl,
        onSendMessage: onSendMessage,
        onSendGiftWithMessage: onSendGiftWithMessage,
        giftMessageHint: giftMessageHint,
        onGiftSentSuccess: onGiftSentSuccess,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const size = 52.0;
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: AppColors.hingePurple.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _openSendMessageSheet(context),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: size,
          height: size,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.hingePurple.withValues(alpha: 0.9),
                  AppColors.hingePurple.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.hingePurple.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: AppColors.hingePurple.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ورقة إرسال رسالة جميلة مع اختيار هدية (اختياري).
class _SendMessageSheetContent extends StatefulWidget {
  const _SendMessageSheetContent({
    required this.profileOwnerId,
    required this.photoUrl,
    required this.onSendMessage,
    this.onSendGiftWithMessage,
    this.giftMessageHint,
    this.onGiftSentSuccess,
  });

  final String profileOwnerId;
  final String photoUrl;
  final void Function(String profileId, String message, String? photoUrl)
  onSendMessage;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final void Function(String successMessage)? onGiftSentSuccess;
  final String? giftMessageHint;

  @override
  State<_SendMessageSheetContent> createState() =>
      _SendMessageSheetContentState();
}

class _SendMessageSheetContentState extends State<_SendMessageSheetContent> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedGiftType;
  bool _sending = false;

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (_sending) return;

    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);

    if (_selectedGiftType == null) {
      FlyingGiftMessageOverlay.show(context, l10n.selectGiftToSend);
      return;
    }
    if (text.isEmpty) {
      FlyingGiftMessageOverlay.show(context, l10n.writeMessageToSendWithGift);
      return;
    }
    if (widget.onSendGiftWithMessage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.giftsAvailableWithRealProfiles),
            backgroundColor: AppColors.hingePurple,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() => _sending = true);
    try {
      await widget.onSendGiftWithMessage!(
        widget.profileOwnerId,
        text,
        _selectedGiftType!,
      );
      if (!mounted) return;
      final successMessage = AppLocalizations.of(context).giftSentSuccess;
      navigator.pop();
      widget.onGiftSentSuccess?.call(successMessage);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorOccurred),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  bool get _canSend {
    final hasText = _controller.text.trim().isNotEmpty;
    // دائماً نطلب اختيار هدية ورسالة معاً — لا إرسال بدون هدية.
    return hasText && _selectedGiftType != null;
  }

  String _selectedGiftLabel(AppLocalizations l10n) {
    final giftName = switch (_selectedGiftType) {
      'rose_gift' => l10n.giftRose,
      'ring_gift' => l10n.giftRing,
      'coffee_gift' => l10n.giftCoffee,
      _ => '',
    };
    return l10n.selectedGiftLabel(giftName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final giftsEnabled = widget.onSendGiftWithMessage != null;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 72;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkBlack.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF37474F),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.darkBlack.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.sendNiceMessageTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkBlack,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                l10n.sendGift,
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF546E7A),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _GiftSelectOption(
                      icon: CinematicRoseWidget(
                        size: 48,
                        color: null,
                        withGlow: false,
                      ),
                      label: l10n.giftRose,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.rosePriceCents)}',
                      giftType: 'rose_gift',
                      selected: _selectedGiftType == 'rose_gift',
                      enabled: true,
                      onTap: () {
                        setState(() {
                          _selectedGiftType = _selectedGiftType == 'rose_gift'
                              ? null
                              : 'rose_gift';
                        });
                        if (!giftsEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.giftsAvailableWithRealProfiles,
                              ),
                              backgroundColor: AppColors.hingePurple,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GiftSelectOption(
                      icon: RingIconWidget(
                        size: 40,
                        color: AppColors.ringGold,
                        withGlow: true,
                      ),
                      label: l10n.giftRing,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.ringPriceCents)}',
                      giftType: 'ring_gift',
                      selected: _selectedGiftType == 'ring_gift',
                      enabled: true,
                      onTap: () {
                        setState(() {
                          _selectedGiftType = _selectedGiftType == 'ring_gift'
                              ? null
                              : 'ring_gift';
                        });
                        if (!giftsEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.giftsAvailableWithRealProfiles,
                              ),
                              backgroundColor: AppColors.hingePurple,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _GiftSelectOption(
                      icon: CoffeeIconWidget(
                        size: 48,
                        color: null,
                        withGlow: false,
                      ),
                      label: l10n.giftCoffee,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.coffeePriceCents)}',
                      giftType: 'coffee_gift',
                      selected: _selectedGiftType == 'coffee_gift',
                      enabled: true,
                      onTap: () {
                        setState(() {
                          _selectedGiftType =
                              _selectedGiftType == 'coffee_gift'
                              ? null
                              : 'coffee_gift';
                        });
                        if (!giftsEnabled) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.giftsAvailableWithRealProfiles,
                              ),
                              backgroundColor: AppColors.hingePurple,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              if (_selectedGiftType == null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.selectGiftToSend,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF546E7A),
                  ),
                ),
              ],
              if (_selectedGiftType != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECEFF1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF37474F),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: const Color(0xFF37474F),
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _selectedGiftLabel(l10n),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF37474F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              TextField(
                controller: _controller,
                enabled: !_sending,
                maxLines: 3,
                textInputAction: TextInputAction.newline,
                onSubmitted: null,
                decoration: InputDecoration(
                  hintText: widget.giftMessageHint ?? l10n.sendNiceMessageHint,
                  hintStyle: GoogleFonts.montserrat(
                    color: Colors.grey.shade600,
                    fontSize: 15,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF37474F),
                      width: 1.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  color: AppColors.darkBlack,
                ),
              ),
              const SizedBox(height: 20),
              if (!_canSend && !_sending) ...[
                Text(
                  _selectedGiftType == null
                      ? l10n.selectGiftToSend
                      : l10n.writeMessageToSendWithGift,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF546E7A),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _sending
                      ? null
                      : _canSend
                          ? _send
                          : () {
                              final hasText = _controller.text.trim().isNotEmpty;
                              if (!hasText) {
                                FlyingGiftMessageOverlay.show(
                                    context, l10n.writeMessageToSendWithGift);
                              } else {
                                FlyingGiftMessageOverlay.show(
                                    context, l10n.selectGiftToSend);
                              }
                            },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _canSend && !_sending
                          ? const Color(0xFF37474F)
                          : Colors.grey.shade400,
                      border: !_canSend && !_sending
                          ? Border.all(
                              color: Colors.grey.shade500,
                              width: 1.5,
                            )
                          : null,
                      boxShadow: _canSend && !_sending
                          ? [
                              BoxShadow(
                                color: AppColors.darkBlack.withValues(
                                  alpha: 0.2,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      l10n.sendNiceMessageButton,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _canSend && !_sending
                            ? Colors.white
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// خيار هدية قابل للتحديد (مع حالة محدّد).
class _GiftSelectOption extends StatelessWidget {
  const _GiftSelectOption({
    required this.icon,
    required this.label,
    required this.price,
    required this.giftType,
    required this.selected,
    this.enabled = true,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final String price;
  final String giftType;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  static const Color _formalPrimary = Color(0xFF37474F);
  static const Color _formalBorder = Color(0xFFE0E0E0);
  static const Color _formalSurface = Color(0xFFFAFAFA);

  Color _cardBaseColor() {
    if (!enabled) return Colors.grey.shade200;
    return _formalSurface;
  }

  Color _accentColor() {
    if (!enabled) return AppColors.darkBlack.withValues(alpha: 0.3);
    return _formalPrimary;
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final cardColor = _cardBaseColor();
    final borderColor = enabled
        ? (selected ? accent : _formalBorder)
        : AppColors.darkBlack.withValues(alpha: 0.25);
    final textColor = enabled
        ? AppColors.darkBlack
        : AppColors.darkBlack.withValues(alpha: 0.5);
    final priceColor = enabled
        ? (selected ? accent : AppColors.darkBlack.withValues(alpha: 0.75))
        : AppColors.darkBlack.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 152,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: cardColor,
            border: Border.all(
              color: borderColor,
              width: selected ? 3 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.darkBlack.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              if (selected) ...[
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (selected)
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Center(
                      child: Opacity(
                        opacity: enabled ? 1 : 0.5,
                        child: Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: selected ? accent : _formalBorder,
                              width: selected ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.darkBlack.withValues(
                                  alpha: 0.06,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Center(child: icon),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.montserrat(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          price,
                          style: GoogleFonts.montserrat(
                            fontSize: 13,
                            color: priceColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (selected)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.6),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                        BoxShadow(
                          color: AppColors.darkBlack.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// بطاقة فيديو البروفايل — تُعرض بشكل كامل وتشغيل تلقائي مع وصف اختياري.
class _VideoCard extends StatefulWidget {
  const _VideoCard({required this.videoUrl, this.videoCaption});

  final String videoUrl;
  final String? videoCaption;

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  VideoPlayerController? _controller;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() => _controller = ctrl);
      ctrl.setVolume(0);
      ctrl.play();
      ctrl.setLooping(true);
    } catch (e) {
      if (mounted) setState(() => _initError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    const aspectRatio = 3 / 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (controller != null && controller.value.isInitialized) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (ctx) =>
                      _FullScreenVideoPage(videoUrl: widget.videoUrl),
                ),
              );
            } else if (_initError) {
              setState(() => _initError = false);
              _initVideo();
            }
          },
          borderRadius: BorderRadius.circular(VerticalProfileView._radius),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(VerticalProfileView._radius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(VerticalProfileView._radius),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (controller != null && controller.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller.value.size.width,
                          height: controller.value.size.height,
                          child: VideoPlayer(controller),
                        ),
                      )
                    else if (_initError)
                      Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.videocam_off,
                              size: 48,
                              color: Colors.white54,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'الفيديو غير متاح في المحاكي\nجرّب على جهاز حقيقي',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.montserrat(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'اضغط للمحاولة مجدداً',
                              style: GoogleFonts.montserrat(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    if (widget.videoCaption != null &&
                        widget.videoCaption!.trim().isNotEmpty)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.videoCaption!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                    Shadow(
                                      color: Colors.black38,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صفحة فيديو ملء الشاشة.
class _FullScreenVideoPage extends StatefulWidget {
  const _FullScreenVideoPage({required this.videoUrl});

  final String videoUrl;

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  VideoPlayerController? _controller;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await ctrl.initialize();
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() => _controller = ctrl);
      ctrl.setVolume(1.0);
      ctrl.play();
    } catch (e) {
      if (mounted) setState(() => _initError = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('فيديو البروفايل', style: GoogleFonts.montserrat()),
      ),
      body: Center(
        child: controller != null && controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: controller.value.aspectRatio,
                child: VideoPlayer(controller),
              )
            : _initError
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      size: 48,
                      color: Colors.white54,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'تعذر تشغيل الفيديو في المحاكي.\nجرّب على جهاز حقيقي.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(color: Colors.white70),
                    ),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

/// يُرجع جزء الاهتمامات المخصص لصورة معيّنة (لتوزيع الاهتمامات بين الصور).
List<String> _interestChunk(List<String> tags, int numPhotos, int photoIndex) {
  if (tags.isEmpty ||
      numPhotos <= 0 ||
      photoIndex < 0 ||
      photoIndex >= numPhotos) {
    return [];
  }
  final chunkSize = (tags.length / numPhotos).ceil();
  final start = photoIndex * chunkSize;
  final end = (start + chunkSize).clamp(0, tags.length);
  if (start >= tags.length) return [];
  return tags.sublist(start, end);
}

/// يُرجع جزء بيانات البروفايل المخصص لصورة معيّنة (لتوزيع البيانات بين الصور).
List<_ProfileInfoRowItem> _personalInfoChunk(
  List<_ProfileInfoRowItem> items,
  int numPhotos,
  int photoIndex,
) {
  if (items.isEmpty ||
      numPhotos <= 0 ||
      photoIndex < 0 ||
      photoIndex >= numPhotos) {
    return [];
  }
  final chunkSize = (items.length / numPhotos).ceil();
  final start = photoIndex * chunkSize;
  final end = (start + chunkSize).clamp(0, items.length);
  if (start >= items.length) return [];
  return items.sublist(start, end);
}

/// قسم الاهتمامات — عنوان رمادي بأحرف كبيرة، كبسولات بيضاء/رمادية، الأولى مميزة (بنفسجي).
class _BentoChipsSection extends StatelessWidget {
  const _BentoChipsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final sectionTitle = AppLocalizations.of(context).sharedInterests;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sectionTitle.toUpperCase(),
            style: GoogleFonts.montserrat(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          _InterestsChipsRow(tags: tags, highlightIndex: 0),
        ],
      ),
    );
  }
}

/// صف كبسولات اهتمامات — تصميم زجاجي بحدود متوهجة (تركواز / وردي بنفسجي).
class _InterestsChipsRow extends StatelessWidget {
  const _InterestsChipsRow({required this.tags, this.highlightIndex});

  final List<String> tags;
  final int? highlightIndex;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.asMap().entries.map((e) {
        final index = e.key;
        final useCyan = index % 2 == 0;
        final glowColor = useCyan
            ? AppColors.interestGlowCyan
            : AppColors.interestGlowPink;
        final fillColor = useCyan
            ? AppColors.interestFillCyan
            : AppColors.interestFillPink;
        final highlighted = highlightIndex != null && index == highlightIndex;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: highlighted
                ? glowColor.withValues(alpha: 0.2)
                : fillColor.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: glowColor.withValues(alpha: highlighted ? 0.9 : 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            e.value,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlack,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: AppColors.glassLightGrey.withValues(alpha: 0.8),
    );
  }
}

/// شريط سفلي: زر X (تخطي) وزر قلب (تواصل) عند الزاويتين فقط.
class _CornerActionBar extends StatelessWidget {
  const _CornerActionBar({
    required this.onPass,
    required this.onLike,
    required this.isSendingLike,
  });

  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool isSendingLike;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + safeBottom),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CornerIconButton(
            icon: Icons.close,
            onPressed: isSendingLike ? null : onPass,
            isLike: false,
          ),
          _CornerIconButton(
            icon: Icons.favorite,
            onPressed: isSendingLike ? null : onLike,
            isLike: true,
          ),
        ],
      ),
    );
  }
}

/// زر دائري في الزاوية — قلب نابض أو X بأناقة وحياة.
class _CornerIconButton extends StatefulWidget {
  const _CornerIconButton({
    required this.icon,
    required this.onPressed,
    required this.isLike,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLike;

  @override
  State<_CornerIconButton> createState() => _CornerIconButtonState();
}

class _CornerIconButtonState extends State<_CornerIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
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
    final isLike = widget.isLike;
    final color = isLike ? AppColors.connectGradientStart : AppColors.darkBlack;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        customBorder: const CircleBorder(),
        child: AnimatedBuilder(
          animation: isLike
              ? _pulseAnimation
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            final scale = isLike ? _pulseAnimation.value : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: isLike
                    ? AppColors.connectGradientEnd.withValues(alpha: 0.5)
                    : color.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
                if (isLike) ...[
                  BoxShadow(
                    color: AppColors.connectGradientStart.withValues(
                      alpha: 0.45,
                    ),
                    blurRadius: 18,
                    spreadRadius: -2,
                    offset: const Offset(0, 2),
                  ),
                  BoxShadow(
                    color: AppColors.connectGradientEnd.withValues(alpha: 0.25),
                    blurRadius: 22,
                    spreadRadius: -4,
                  ),
                ] else
                  BoxShadow(
                    color: Colors.grey.shade400.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Icon(
              widget.icon,
              size: 30,
              color: widget.onPressed == null
                  ? Colors.grey.shade400
                  : (isLike
                        ? AppColors.connectGradientStart
                        : AppColors.darkBlack),
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة زجاجية واحدة: زرّا «تواصل» و«تجاوز» عمودياً مع لمعان قزحي على الحواف.
// ignore: unused_element
class _GlassConnectPassCard extends StatelessWidget {
  const _GlassConnectPassCard({
    required this.connectLabel,
    required this.passLabel,
    this.onLike,
    this.onPass,
  });

  final String connectLabel;
  final String passLabel;
  final VoidCallback? onLike;
  final VoidCallback? onPass;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.iridescentPink.withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: -2,
              ),
              BoxShadow(
                color: AppColors.iridescentBlue.withValues(alpha: 0.2),
                blurRadius: 24,
                spreadRadius: -4,
              ),
              BoxShadow(
                color: AppColors.iridescentGreen.withValues(alpha: 0.2),
                blurRadius: 22,
                spreadRadius: -3,
              ),
              BoxShadow(
                color: AppColors.iridescentYellow.withValues(alpha: 0.18),
                blurRadius: 18,
                spreadRadius: -2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GlassCardButton(label: connectLabel, onPressed: onLike),
              const SizedBox(height: 12),
              _GlassCardButton(label: passLabel, onPressed: onPass),
            ],
          ),
        ),
      ),
    );
  }
}

/// زر داخل البطاقة الزجاجية — خلفية بيضاء شفافة ولمعة خفيفة.
class _GlassCardButton extends StatelessWidget {
  const _GlassCardButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed != null
            ? () {
                HapticFeedback.lightImpact();
                onPressed!();
              }
            : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.darkBlack,
            ),
          ),
        ),
      ),
    );
  }
}

enum _ActionStyle { skip, like }

/// شريط سفلي: حقل رسالة + زر هدية + أزرار تخطي وإعجاب.
// ignore: unused_element
class _DiscoveryBottomBar extends StatelessWidget {
  const _DiscoveryBottomBar({
    required this.onPass,
    required this.onLike,
    required this.isSendingLike,
    this.profileOwnerId,
    this.onSendGiftWithMessage,
    this.giftMessageHint,
  });

  final VoidCallback? onPass;
  final VoidCallback? onLike;
  final bool isSendingLike;
  final String? profileOwnerId;
  final Future<void> Function(
    String profileId,
    String message,
    String giftType,
  )?
  onSendGiftWithMessage;
  final String? giftMessageHint;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + safeBottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (profileOwnerId != null && onSendGiftWithMessage != null)
            _GiftMessageBar(
              profileOwnerId: profileOwnerId!,
              onSendGiftWithMessage: onSendGiftWithMessage!,
              giftMessageHint: giftMessageHint,
            ),
          if (profileOwnerId != null && onSendGiftWithMessage != null)
            const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StickyActionButton(
                icon: Icons.close,
                onPressed: isSendingLike ? null : onPass,
                style: _ActionStyle.skip,
              ),
              _StickyActionButton(
                icon: Icons.favorite,
                onPressed: isSendingLike ? null : onLike,
                style: _ActionStyle.like,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// حقل رسالة + زر إرسال هدية.
class _GiftMessageBar extends StatefulWidget {
  const _GiftMessageBar({
    required this.profileOwnerId,
    required this.onSendGiftWithMessage,
    this.giftMessageHint,
  });

  final String profileOwnerId;
  final Future<void> Function(String profileId, String message, String giftType)
  onSendGiftWithMessage;
  final String? giftMessageHint;

  @override
  State<_GiftMessageBar> createState() => _GiftMessageBarState();
}

class _GiftMessageBarState extends State<_GiftMessageBar> {
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openGiftPicker() {
    if (_sending) return;
    final l10n = AppLocalizations.of(context);
    String? selectedGiftType;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.sendGift,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack,
                  ),
                ),
                if (selectedGiftType == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.selectGiftToSend,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.hingePurple,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _GiftPickerOption(
                      icon: CinematicRoseWidget(
                        size: 40,
                        color: null,
                        withGlow: true,
                      ),
                      label: l10n.giftRose,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.rosePriceCents)}',
                      selected: selectedGiftType == 'rose_gift',
                      onTap: () => setSheetState(
                          () => selectedGiftType = selectedGiftType == 'rose_gift' ? null : 'rose_gift'),
                    ),
                    _GiftPickerOption(
                      icon: Icon(
                        Icons.diamond_rounded,
                        size: 32,
                        color: AppColors.ringGold,
                      ),
                      label: l10n.giftRing,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.ringPriceCents)}',
                      selected: selectedGiftType == 'ring_gift',
                      onTap: () => setSheetState(
                          () => selectedGiftType = selectedGiftType == 'ring_gift' ? null : 'ring_gift'),
                    ),
                    _GiftPickerOption(
                      icon: CoffeeIconWidget(size: 40, color: null, withGlow: true),
                      label: l10n.giftCoffee,
                      price:
                          '€${GiftPricing.formatCents(GiftPricing.coffeePriceCents)}',
                      selected: selectedGiftType == 'coffee_gift',
                      onTap: () => setSheetState(
                          () => selectedGiftType = selectedGiftType == 'coffee_gift' ? null : 'coffee_gift'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: selectedGiftType != null
                        ? () {
                            if (_controller.text.trim().isEmpty) {
                              FlyingGiftMessageOverlay.show(
                                context,
                                l10n.writeMessageToSendWithGift,
                              );
                              return;
                            }
                            _sendGift(selectedGiftType!, ctx);
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF37474F),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(l10n.sendNiceMessageButton),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _sendGift(String giftType, BuildContext sheetContext) async {
    final msg = _controller.text.trim();
    if (msg.isEmpty) {
      Navigator.pop(sheetContext);
      if (mounted) {
        FlyingGiftMessageOverlay.show(
          context,
          AppLocalizations.of(context).writeMessageToSendWithGift,
        );
      }
      return;
    }
    setState(() => _sending = true);
    Navigator.pop(sheetContext);
    final message = msg;
    try {
      await widget.onSendGiftWithMessage(
        widget.profileOwnerId,
        message,
        giftType,
      );
      if (mounted) {
        _controller.clear();
        FlyingGiftMessageOverlay.show(
          context,
          AppLocalizations.of(context).giftSentSuccess,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).errorOccurred),
            backgroundColor: Colors.red,
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
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            enabled: !_sending,
            maxLines: 1,
            decoration: InputDecoration(
              hintText: widget.giftMessageHint ?? l10n.giftMessagePlaceholder,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.rosePink.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.rosePink.withValues(alpha: 0.3),
                ),
              ),
              filled: true,
              fillColor: AppColors.rosePink.withValues(alpha: 0.06),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.montserrat(fontSize: 14),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.rosePink,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: _sending ? null : _openGiftPicker,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.sendGiftFromDiscovery,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GiftPickerOption extends StatelessWidget {
  const _GiftPickerOption({
    required this.icon,
    required this.label,
    required this.price,
    required this.onTap,
    this.selected = false,
  });

  final Widget icon;
  final String label;
  final String price;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? const Color(0xFF37474F) : const Color(0xFFE0E0E0),
              width: selected ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            color: selected ? const Color(0xFFECEFF1) : const Color(0xFFFAFAFA),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.darkBlack.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: AppColors.darkBlack,
                ),
              ),
              Text(
                price,
                style: GoogleFonts.montserrat(
                  fontSize: 11,
                  color: const Color(0xFF37474F),
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

/// Sticky circular action: X (left) or Heart (right).
class _StickyActionButton extends StatelessWidget {
  const _StickyActionButton({
    required this.icon,
    required this.onPressed,
    required this.style,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final _ActionStyle style;

  @override
  Widget build(BuildContext context) {
    final isLike = style == _ActionStyle.like;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: isLike ? AppColors.rosePink : Colors.grey.shade400,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              if (isLike)
                BoxShadow(
                  color: AppColors.rosePink.withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(
            icon,
            size: 36,
            color: isLike ? AppColors.rosePink : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
