import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../models/profile_answer.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_fields_service.dart';
import '../services/profile_photo_storage_service.dart';
import '../services/profile_video_storage_service.dart';
import '../services/profile_audio_storage_service.dart';
import '../services/profile_service.dart';
import '../services/prompt_service.dart';
import '../widgets/languages_editor_sheet.dart';
import '../data/lifestyle_interests.dart';
import '../widgets/lifestyle_interests_sheet.dart';
import '../widgets/profile_field_editor_sheet.dart';
import '../widgets/prompt_selection_sheet.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'location_picker_screen.dart';
import 'post_registration_onboarding_screen.dart';
import 'spotify_song_picker_screen.dart';
import 'spotify_embed_screen.dart';
import '../services/spotify_search_service.dart';

/// sort_order للأسئلة المكتوبة (3 slots).
const int _writtenPromptSortBase = 100;

/// sort_order لصور البروفايل (6 slots): 200–205.
const int _photoSortBase = 200;

/// sort_order لفيديو البروفايل (سؤال فيديو واحد).
const int _videoSortOrder = 110;

/// sort_order لتسجيل الصوت (واحد).
const int _voiceSortOrder = 103;

/// أقصى مدة للفيديو بالثواني.
const int _maxVideoDurationSeconds = 15;

/// مفاتيح ثابتة للبرج والحيوانات (تُحفظ في DB؛ العرض من l10n).
const List<String> _zodiacKeys = [
  'none',
  'aries',
  'taurus',
  'gemini',
  'cancer',
  'leo',
  'virgo',
  'libra',
  'scorpio',
  'sagittarius',
  'capricorn',
  'aquarius',
  'pisces',
];
const List<String> _zodiacSymbols = [
  '',
  '♈',
  '♉',
  '♊',
  '♋',
  '♌',
  '♍',
  '♎',
  '♏',
  '♐',
  '♑',
  '♒',
  '♓',
];
const List<String> _petKeys = [
  'none',
  'cat',
  'dog',
  'fish',
  'rabbit',
  'bird',
  'hamster',
  'other',
];
const List<String> _petEmojis = ['', '🐱', '🐕', '🐟', '🐰', '🐦', '🐹', ''];

List<String> _zodiacLabels(AppLocalizations l10n) {
  final labels = [
    l10n.zodiacNone,
    l10n.zodiacAries,
    l10n.zodiacTaurus,
    l10n.zodiacGemini,
    l10n.zodiacCancer,
    l10n.zodiacLeo,
    l10n.zodiacVirgo,
    l10n.zodiacLibra,
    l10n.zodiacScorpio,
    l10n.zodiacSagittarius,
    l10n.zodiacCapricorn,
    l10n.zodiacAquarius,
    l10n.zodiacPisces,
  ];
  return List.generate(
    _zodiacKeys.length,
    (i) => _zodiacSymbols[i].isEmpty
        ? labels[i]
        : '${_zodiacSymbols[i]} ${labels[i]}',
  );
}

List<String> _petLabels(AppLocalizations l10n) {
  final labels = [
    l10n.petNone,
    l10n.petCat,
    l10n.petDog,
    l10n.petFish,
    l10n.petRabbit,
    l10n.petBird,
    l10n.petHamster,
    l10n.petOther,
  ];
  return List.generate(
    _petKeys.length,
    (i) => _petEmojis[i].isEmpty ? labels[i] : '${_petEmojis[i]} ${labels[i]}',
  );
}

String _getZodiacDisplay(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.none;
  final i = _zodiacKeys.indexOf(value);
  if (i >= 0) return _zodiacLabels(l10n)[i];
  return value;
}

String _getPetDisplay(String? value, AppLocalizations l10n) {
  if (value == null || value.isEmpty) return l10n.none;
  final i = _petKeys.indexOf(value);
  if (i >= 0) return _petLabels(l10n)[i];
  return value;
}

/// بيانات slot واحد للأسئلة المكتوبة.
class _WrittenPromptSlotData {
  _WrittenPromptSlotData({
    this.profileAnswerId,
    this.promptId,
    this.promptText,
    this.answer = '',
  });

  final String? profileAnswerId;
  final String? promptId;
  final String? promptText;
  final String answer;

  _WrittenPromptSlotData copyWith({
    String? profileAnswerId,
    String? promptId,
    String? promptText,
    String? answer,
  }) {
    return _WrittenPromptSlotData(
      profileAnswerId: profileAnswerId ?? this.profileAnswerId,
      promptId: promptId ?? this.promptId,
      promptText: promptText ?? this.promptText,
      answer: answer ?? this.answer,
    );
  }
}

/// شاشة تعديل البروفايل بتصميم Hinge: Cancel/Done، تبويبي Edit و View.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.userId, this.onComplete});

  final String userId;
  final VoidCallback? onComplete;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _topPhotoEnabled = false;
  final ProfileFieldsService _profileFields = ProfileFieldsService();
  final ProfileAnswerService _answerService = ProfileAnswerService();
  final ProfileService _profileService = ProfileService();
  final PromptService _promptService = PromptService();
  final Map<String, String> _values = {};
  final Map<String, String> _visibility = {};
  final List<_WrittenPromptSlotData> _writtenPromptSlots = [
    _WrittenPromptSlotData(),
    _WrittenPromptSlotData(),
    _WrittenPromptSlotData(),
  ];

  /// عدد الصور المعبّاة (من profile_answers نوع image) — يُحدَّث عند _loadProfile.
  int _filledPhotosCount = 0;

  /// 6 slots: كل عنصر (id للمسجل، url للعرض). ترتيب sort_order: 200–205.
  List<({String? id, String? url})> _profilePhotoSlots = List.generate(
    6,
    (_) => (id: null, url: null),
  );

  /// فيديو البروفايل (سؤال فيديو واحد، sort_order 110). يتضمّن caption وصف عن الفيديو.
  ({String? id, String? url, String caption}) _profileVideoSlot = (
    id: null,
    url: null,
    caption: '',
  );

  /// تسجيل صوتي (واحد، sort_order 103). answer نص، audioUrl أو spotifyUrl.
  ({
    String? id,
    String answer,
    String? audioUrl,
    String? spotifyUrl,
    String? spotifyImageUrl,
    String? spotifyTitle,
    String? spotifyArtist,
    int? durationSeconds,
  })
  _profileVoiceSlot = (
    id: null,
    answer: '',
    audioUrl: null,
    spotifyUrl: null,
    spotifyImageUrl: null,
    spotifyTitle: null,
    spotifyArtist: null,
    durationSeconds: null,
  );

  /// استطلاع البروفايل (واحد، sort_order 111). المحتوى: question + options.
  /// إجابات البروفايل الكاملة (لعرضها في تبويب "عرض" كما يظهر للآخرين).
  List<ProfileAnswer> _profileAnswers = [];
  bool _loading = true;
  bool _isLoadingProfile = false;

  /// منع طلب تسجيل صوتي ثانٍ قبل انتهاء الأول (تجنب PlatformException multiple_request).
  bool _isVoiceRecordingInProgress = false;

  /// بعد خطأ multiple_request نمنع المحاولة مجدداً لعدة ثوانٍ.
  DateTime? _lastVoiceMultipleRequestTime;

  /// رسالة خطأ للمستخدم: لا نعرض نص PlatformException الخام لـ multiple_request.
  String _voiceErrorDisplayMessage(Object e, AppLocalizations l10n) {
    final s = e.toString().toLowerCase();
    if (s.contains('multiple_request') ||
        s.contains('cancelled by a second request')) {
      return l10n.retryAgain;
    }
    return l10n.errorOccurred;
  }

  final ImagePicker _imagePicker = ImagePicker();
  final ProfilePhotoStorageService _photoStorage = ProfilePhotoStorageService();
  final ProfileVideoStorageService _videoStorage = ProfileVideoStorageService();
  final ProfileAudioStorageService _audioStorage = ProfileAudioStorageService();
  final TextEditingController _videoCaptionController = TextEditingController();

  /// أقصى عدد صور تدخل في نسبة الإكتمال (كل صورة 10%).
  static const int _maxPhotosForCompletion = 6;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    if (_isLoadingProfile) return;
    _isLoadingProfile = true;
    try {
      // مهلة شاملة 10 ثوانٍ — إن تجاوزها نعرض النموذج الفارغ (تجنب التجمّد).
      await Future.any([
        _loadProfileData(),
        Future.delayed(
          const Duration(seconds: 10),
          () => throw TimeoutException('_loadProfile'),
        ),
      ]);
    } on TimeoutException catch (_) {
      if (mounted) setState(() => _loading = false);
    } catch (e, st) {
      debugPrint('_loadProfile error: $e');
      debugPrint('Stack: $st');
      if (mounted) setState(() => _loading = false);
    } finally {
      _isLoadingProfile = false;
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final fields = await _profileFields
          .getFields(widget.userId)
          .timeout(const Duration(seconds: 6));
      final answers = await _answerService
          .getByProfileId(widget.userId)
          .timeout(const Duration(seconds: 6));
      if (!mounted) return;

      final locale = Localizations.localeOf(context).languageCode;

      // Written Prompts: sort_order 100, 101, 102. Content format: {"prompt_id": "...", "answer": "..."}
      final writtenPromptAnswers =
          answers
              .where(
                (a) =>
                    a.itemType == 'text' &&
                    a.sortOrder >= _writtenPromptSortBase &&
                    a.sortOrder < _writtenPromptSortBase + 3 &&
                    _isWrittenPromptContent(a.content),
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

      final writtenSlots = <_WrittenPromptSlotData>[];
      for (var i = 0; i < 3; i++) {
        final idx = writtenPromptAnswers.indexWhere(
          (a) => a.sortOrder == _writtenPromptSortBase + i,
        );
        if (idx >= 0) {
          final a = writtenPromptAnswers[idx];
          final parsed = _parseWrittenPromptContent(a.content, a.id, locale);
          writtenSlots.add(parsed ?? _WrittenPromptSlotData());
        } else {
          writtenSlots.add(_WrittenPromptSlotData());
        }
      }

      // عدد الصور: profile_answers من نوع image ومحتواها غير فارغ (حد أقصى 6).
      final imageAnswers =
          answers
              .where((a) => a.isImage)
              .where(
                (a) =>
                    a.sortOrder >= _photoSortBase &&
                    a.sortOrder < _photoSortBase + 6,
              )
              .toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final photoSlots = List<({String? id, String? url})>.generate(6, (i) {
        final idx = imageAnswers.indexWhere(
          (a) => a.sortOrder == _photoSortBase + i,
        );
        if (idx >= 0) {
          final a = imageAnswers[idx];
          final url = a.content.trim().isEmpty ? null : a.content.trim();
          return (id: a.id, url: url);
        }
        return (id: null, url: null);
      });
      final photoCount = photoSlots
          .where((s) => s.url != null && s.url!.isNotEmpty)
          .length;

      // فيديو البروفايل (سؤال فيديو واحد، sort_order 110، item_type video).
      // المحتوى: إما URL فقط أو JSON {"url":"...","caption":"..."}.
      ({String? id, String? url, String caption}) videoSlot = (
        id: null,
        url: null,
        caption: '',
      );
      final videoAnswers = answers
          .where((a) => a.itemType == 'video' && a.sortOrder == _videoSortOrder)
          .toList();
      if (videoAnswers.isNotEmpty) {
        final a = videoAnswers.first;
        final c = a.content.trim();
        if (c.isNotEmpty) {
          String url = c;
          String caption = '';
          if (c.startsWith('{')) {
            try {
              final decoded = jsonDecode(c) as Map<String, dynamic>?;
              if (decoded != null) {
                url = (decoded['url'] ?? '').toString().trim();
                caption = (decoded['caption'] ?? '').toString().trim();
              }
            } catch (_) {}
          }
          if (url.isNotEmpty) {
            videoSlot = (id: a.id, url: url, caption: caption);
          }
        }
      }

      // تسجيل صوتي (واحد، sort_order 103؛ question_id في DB = UUID فنستخدم null).
      ({
        String? id,
        String answer,
        String? audioUrl,
        String? spotifyUrl,
        String? spotifyImageUrl,
        String? spotifyTitle,
        String? spotifyArtist,
        int? durationSeconds,
      })
      voiceSlot = (
        id: null,
        answer: '',
        audioUrl: null,
        spotifyUrl: null,
        spotifyImageUrl: null,
        spotifyTitle: null,
        spotifyArtist: null,
        durationSeconds: null,
      );
      final voiceAnswers = answers
          .where((a) => a.itemType == 'text' && a.sortOrder == _voiceSortOrder)
          .toList();
      if (voiceAnswers.isNotEmpty) {
        final a = voiceAnswers.first;
        final c = a.content.trim();
        if (c.isNotEmpty && c.startsWith('{')) {
          try {
            final decoded = jsonDecode(c) as Map<String, dynamic>?;
            if (decoded != null) {
              final answer = (decoded['answer'] ?? '').toString().trim();
              final audioUrl = (decoded['audio_url'] ?? '').toString().trim();
              final spotifyUrl = (decoded['spotify_url'] ?? '')
                  .toString()
                  .trim();
              final spotifyImageUrl = (decoded['spotify_image_url'] ?? '')
                  .toString()
                  .trim();
              final spotifyTitle = (decoded['spotify_title'] ?? '')
                  .toString()
                  .trim();
              final spotifyArtist = (decoded['spotify_artist'] ?? '')
                  .toString()
                  .trim();
              final dur = decoded['duration_seconds'];
              final durationSeconds = dur is int
                  ? dur
                  : (dur is num ? dur.toInt() : null);
              voiceSlot = (
                id: a.id,
                answer: answer,
                audioUrl: audioUrl.isEmpty ? null : audioUrl,
                spotifyUrl: spotifyUrl.isEmpty ? null : spotifyUrl,
                spotifyImageUrl: spotifyImageUrl.isEmpty
                    ? null
                    : spotifyImageUrl,
                spotifyTitle: spotifyTitle.isEmpty ? null : spotifyTitle,
                spotifyArtist: spotifyArtist.isEmpty ? null : spotifyArtist,
                durationSeconds: durationSeconds,
              );
            }
          } catch (_) {}
        }
      }

      if (mounted) {
        setState(() {
          for (final e in fields.entries) {
            _values[e.key] = e.value.value;
            _visibility[e.key] = e.value.visibility;
          }
          if (fields.isEmpty) {
            _populateValuesFromAnswers(answers);
          }
          _topPhotoEnabled = _values['top_photo_enabled'] == 'true';
          _writtenPromptSlots
            ..clear()
            ..addAll(writtenSlots);
          _profilePhotoSlots = photoSlots;
          _filledPhotosCount = photoCount;
          _profileVideoSlot = videoSlot;
          _videoCaptionController.text = videoSlot.caption;
          _profileVoiceSlot = voiceSlot;
          _profileAnswers = answers;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('_loadProfile error: $e');
      debugPrint('Stack: $st');
      if (mounted) setState(() => _loading = false);
    } finally {
      _isLoadingProfile = false;
    }
  }

  /// Fallback: populate _values from profile_answers when user_profile_fields is empty.
  /// Onboarding saves to profile_answers with sort_order 0=name, 1=birthdate, 2=location, etc.
  void _populateValuesFromAnswers(List<ProfileAnswer> answers) {
    final sorted = List<ProfileAnswer>.from(answers)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    for (final a in sorted) {
      if (a.itemType != 'text' || a.content.trim().isEmpty) continue;
      if (a.sortOrder >= _writtenPromptSortBase &&
          a.sortOrder < _writtenPromptSortBase + 3) {
        continue;
      }
      switch (a.sortOrder) {
        case 0:
          _values['name'] = a.content.trim();
          break;
        case 1:
          _values['age'] = a.content.trim();
          break;
        case 2:
          _values['location'] = a.content.trim();
          break;
        default:
          break;
      }
    }
  }

  /// Checks if content is valid Written Prompt JSON: {"prompt_id": "...", "answer": "..."}.
  static bool _isWrittenPromptContent(String content) {
    if (content.trim().isEmpty) return false;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded.containsKey('prompt_id') &&
          decoded['prompt_id'] != null &&
          decoded['prompt_id'].toString().isNotEmpty;
    } catch (e) {
      debugPrint('_isWrittenPromptContent parse error: $e');
      return false;
    }
  }

  /// Parses Written Prompt JSON. Supports both snake_case (prompt_id, answer) and camelCase (promptId).
  _WrittenPromptSlotData? _parseWrittenPromptContent(
    String content,
    String profileAnswerId,
    String locale,
  ) {
    if (content.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      final promptId = (decoded['prompt_id'] ?? decoded['promptId'])
          ?.toString()
          .trim();
      final answer = (decoded['answer'])?.toString() ?? '';
      if (promptId == null || promptId.isEmpty) return null;
      final prompt = _promptService.getPromptById(promptId);
      final promptText = prompt?.textForLocale(locale);
      return _WrittenPromptSlotData(
        profileAnswerId: profileAnswerId,
        promptId: promptId,
        promptText: promptText,
        answer: answer,
      );
    } catch (e) {
      debugPrint('_parseWrittenPromptContent error: $e');
      return null;
    }
  }

  /// حفظ كل التغييرات في Supabase: الأسئلة المكتوبة + الصورة الرئيسية + الحقول.
  /// Returns true only if ALL operations succeed, false otherwise.
  Future<bool> _saveAllToSupabase() async {
    String? lastError;
    try {
      // 1. الأسئلة المكتوبة (sort_order 100-102) → profile_answers
      // Content format: {"prompt_id": "...", "answer": "..."}
      for (var i = 0; i < 3; i++) {
        final slot = _writtenPromptSlots[i];
        if (slot.promptId == null) continue;

        final content = jsonEncode({
          'prompt_id': slot.promptId,
          'answer': slot.answer,
        });

        if (slot.profileAnswerId != null) {
          await _answerService.updateAnswer(
            id: slot.profileAnswerId!,
            content: content,
          );
        } else {
          final created = await _answerService.insertAnswer(
            profileId: widget.userId,
            questionId: null,
            content: content,
            sortOrder: _writtenPromptSortBase + i,
          );
          if (mounted && i < _writtenPromptSlots.length) {
            setState(() {
              _writtenPromptSlots[i] = slot.copyWith(
                profileAnswerId: created.id,
              );
            });
          }
        }
      }

      // 2. الصورة الرئيسية + كل الحقول → user_profile_fields
      debugPrint('_saveAllToSupabase: saving to user_id=${widget.userId}');
      var topOk = await _profileFields.saveField(
        userId: widget.userId,
        fieldKey: 'top_photo_enabled',
        value: _topPhotoEnabled ? 'true' : 'false',
        visibility: 'visible',
      );
      if (!topOk) {
        debugPrint(
          '_saveAllToSupabase: saveField failed for top_photo_enabled',
        );
        throw Exception(AppLocalizations.of(context).fieldSaveError);
      }
      for (final e in _values.entries) {
        if (e.key == 'top_photo_enabled') continue;
        debugPrint('_saveAllToSupabase: field_key=${e.key}, value=${e.value}');
        final result = await _profileFields.saveFieldWithMessage(
          userId: widget.userId,
          fieldKey: e.key,
          value: e.value,
          visibility: _visibility[e.key] ?? 'hidden',
        );
        if (!result.success) {
          debugPrint('_saveAllToSupabase: saveField failed for ${e.key}: ${result.errorMessage}');
          final msg = result.errorMessage == 'age_minimum_18'
              ? AppLocalizations.of(context).ageMinimumError
              : AppLocalizations.of(context).fieldSaveError;
          throw Exception(msg);
        }
      }

      // 3. مزامنة اللغات مع profile_answers و profiles (question_id في DB = UUID فنستخدم null و sort_order 54)
      final languagesValue = _values['languages_spoken']?.trim() ?? '';
      if (languagesValue.isNotEmpty) {
        await _profileService.updateLanguages(widget.userId, languagesValue);
        final answers = await _answerService.getByProfileId(widget.userId);
        final existing = answers.where((a) => a.sortOrder == 54).toList();
        if (existing.isNotEmpty) {
          await _answerService.updateAnswer(
            id: existing.first.id,
            content: languagesValue,
          );
        } else {
          await _answerService.insertAnswer(
            profileId: widget.userId,
            questionId: null,
            content: languagesValue,
            sortOrder: 54,
          );
        }
      }
      return true;
    } catch (e, st) {
      lastError = e.toString();
      debugPrint('_saveAllToSupabase error: $e');
      debugPrint('Stack: $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).authError} $lastError',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _displayName {
    final fromProfile = _values['name'];
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final user = Supabase.instance.client.auth.currentUser;
    return user?.userMetadata?['full_name'] as String? ??
        user?.email?.split('@').first ??
        'Profile';
  }

  /// كل حقول البروفايل المعروضة في التعديل (تدخل في نسبة الإكتمال).
  static const List<String> _completionFieldKeys = [
    'pronouns',
    'gender',
    'sexuality',
    'im_interested_in',
    'match_note',
    'work',
    'job_title',
    'college_or_university',
    'education_level',
    'religious_beliefs',
    'home_town',
    'politics',
    'languages_spoken',
    'dating_intentions',
    'relationship_type',
    'name',
    'age',
    'height',
    'location',
    'ethnicity',
    'children',
    'family_plans',
    'covid_vaccine',
    'pets',
    'zodiac_sign',
    'drinking',
    'smoking',
    'marijuana',
    'drugs',
  ];

  /// عدد الأسئلة المكتوبة المعبّاة (0–3).
  int get _filledQuestionsCount {
    var n = 0;
    for (final slot in _writtenPromptSlots) {
      if (slot.promptId != null && (slot.answer).trim().isNotEmpty) n++;
    }
    return n;
  }

  /// عدد الحقول المعبّاة من القائمة الأساسية (الخيارات).
  int get _filledFieldsCount {
    var n = 0;
    for (final key in _completionFieldKeys) {
      if ((_values[key] ?? '').trim().isNotEmpty) n++;
    }
    return n;
  }

  /// نسبة الإكتمال: 25% أسئلة مكتوبة (3) + 10% لكل صورة (حد أقصى 6 = 60%) + 15% الحقول (29).
  int get _completionPercent {
    const questionsTotal = 3;
    const questionsWeight = 25; // 25% للأسئلة
    const perPhotoPercent = 10; // 10% لكل صورة
    const photosMax = _maxPhotosForCompletion; // 6 صور = 60% كحد أقصى
    const fieldsWeight = 15; // 15% للحقول
    final fieldsTotal = _completionFieldKeys.length;
    final q = _filledQuestionsCount;
    final photos = _filledPhotosCount.clamp(0, photosMax);
    final f = _filledFieldsCount;
    final questionsPart = questionsTotal > 0
        ? (q / questionsTotal) * questionsWeight
        : 0.0;
    final photosPart = photos * perPhotoPercent;
    final fieldsPart = fieldsTotal > 0 ? (f / fieldsTotal) * fieldsWeight : 0.0;
    return (questionsPart + photosPart + fieldsPart).round().clamp(0, 100);
  }

  /// تفصيل نسبة كل خيار: الأسئلة (25%)، الصور (10% لكل صورة)، الحقول (15%).
  List<({String name, int filled, int total, int percent})>
  _getCompletionBreakdown(AppLocalizations l10n) {
    const questionsTotal = 3;
    final fieldsTotal = _completionFieldKeys.length;
    final q = _filledQuestionsCount;
    final photos = _filledPhotosCount.clamp(0, _maxPhotosForCompletion);
    final f = _filledFieldsCount;
    return [
      (
        name: l10n.profileCompletionWrittenQuestions,
        filled: q,
        total: questionsTotal,
        percent: questionsTotal > 0
            ? ((q / questionsTotal) * 100).round().clamp(0, 100)
            : 0,
      ),
      (
        name: l10n.profileCompletionPhotos,
        filled: photos,
        total: _maxPhotosForCompletion,
        percent: _maxPhotosForCompletion > 0
            ? ((photos / _maxPhotosForCompletion) * 100).round().clamp(0, 100)
            : 0,
      ),
      (
        name: l10n.profileCompletionFields,
        filled: f,
        total: fieldsTotal,
        percent: fieldsTotal > 0
            ? ((f / fieldsTotal) * 100).round().clamp(0, 100)
            : 0,
      ),
    ];
  }

  String _v(String key, String fallback) => _values[key] ?? fallback;
  String _vis(String key, String fallback) => _visibility[key] ?? fallback;

  String _visDisplay(AppLocalizations l10n, String vis) {
    switch (vis) {
      case 'visible':
        return l10n.visible;
      case 'always_visible':
        return l10n.alwaysVisible;
      case 'always_hidden':
        return l10n.alwaysHidden;
      default:
        return l10n.hidden;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.cancel,
            style: const TextStyle(
              color: AppColors.hingePurple,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.darkBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.profileCompletePercent('$_completionPercent'),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.hingePurple,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_getCompletionBreakdown(l10n).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _getCompletionBreakdown(
                  l10n,
                ).map((e) => '${e.name} ${e.percent}%').join(' · '),
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.darkBlack.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () async {
              final ok = await _saveAllToSupabase();
              if (!mounted) return;
              if (ok) {
                await _loadProfile();
                if (!mounted) return;
                setState(() {}); // Ensure UI reflects reloaded data
                _tabController.animateTo(
                  1,
                ); // Switch to View tab so user sees saved data
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.answerSaved),
                    backgroundColor: AppColors.forestGreen,
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Pop after a short delay so user can see the refreshed View tab
                await Future<void>.delayed(const Duration(milliseconds: 800));
                if (!mounted) return;
                if (widget.onComplete != null) {
                  widget.onComplete!();
                } else {
                  Navigator.of(context).pop();
                }
              }
            },
            child: Text(
              l10n.done,
              style: const TextStyle(
                color: AppColors.hingePurple,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.hingePurple,
          unselectedLabelColor: AppColors.darkBlack.withValues(alpha: 0.5),
          indicatorColor: AppColors.hingePurple,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n.edit),
            Tab(text: l10n.view),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.hingePurple),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _EditTabContent(
                  userId: widget.userId,
                  topPhotoEnabled: _topPhotoEnabled,
                  onTopPhotoChanged: (v) =>
                      setState(() => _topPhotoEnabled = v),
                  onOpenFullOnboarding: () => _openFullOnboarding(context),
                  profilePhotoSlots: _profilePhotoSlots,
                  onProfilePhotoTap: (i) => _onProfilePhotoTap(context, i),
                  onProfilePhotoRemove: (i) =>
                      _onProfilePhotoRemove(context, i),
                  profileVideoSlot: _profileVideoSlot,
                  onProfileVideoTap: () => _onProfileVideoTap(context),
                  onProfileVideoRemove: () => _onProfileVideoRemove(context),
                  onProfileVideoCaptionChanged: (text) => setState(
                    () => _profileVideoSlot = (
                      id: _profileVideoSlot.id,
                      url: _profileVideoSlot.url,
                      caption: text,
                    ),
                  ),
                  videoCaptionController: _videoCaptionController,
                  profileVoiceSlot: _profileVoiceSlot,
                  onFavoriteSongTap: () => _onFavoriteSongTap(context),
                  onVoiceRecordingTap: () => _onVoiceRecordingTap(context),
                  onRemoveFavoriteSong: () => _onRemoveFavoriteSong(context),
                  onRemoveVoiceRecording: () =>
                      _onRemoveVoiceRecording(context),
                  writtenPromptSlots: _writtenPromptSlots,
                  onSlotTap: (i) => _onWrittenPromptSlotTap(context, i),
                  onSlotAnswerChanged: (i, text) {
                    setState(() {
                      if (i < _writtenPromptSlots.length) {
                        _writtenPromptSlots[i] = _writtenPromptSlots[i]
                            .copyWith(answer: text);
                      }
                    });
                  },
                  values: _values,
                  visibility: _visibility,
                  visDisplay: _visDisplay,
                  v: _v,
                  vis: _vis,
                  displayName: _displayName,
                  onFieldTap: _showFieldEditor,
                  onFieldUpdated: _onFieldUpdated,
                  lifestyleInterestsCount: parseLifestyleInterestsIds(
                    _values['lifestyle_interests'],
                  ).length,
                  onLifestyleInterestsTap: () =>
                      _onLifestyleInterestsTap(context),
                  getFieldDisplayValue: (key, raw, l10n) {
                    if (key == 'zodiac_sign') {
                      return _getZodiacDisplay(raw, l10n);
                    }
                    if (key == 'pets') return _getPetDisplay(raw, l10n);
                    return raw;
                  },
                ),
                _ViewTabContent(
                  key: ValueKey(
                    '${_writtenPromptSlots.map((s) => '${s.promptId}:${s.answer}').join('|')}|voice:${_profileVoiceSlot.audioUrl ?? ''}:${_profileVoiceSlot.spotifyUrl ?? ''}:${_profileVoiceSlot.durationSeconds ?? 0}',
                  ),
                  tabController: _tabController,
                  displayName: _displayName,
                  values: _values,
                  writtenPromptSlots: List.from(_writtenPromptSlots),
                  profilePhotoSlots: _profilePhotoSlots,
                  profileAnswers: _profileAnswers,
                  profileVoiceSlot: _profileVoiceSlot,
                  topPhotoEnabled: _topPhotoEnabled,
                  v: _v,
                  currentUserId: Supabase.instance.client.auth.currentUser?.id,
                  getFieldDisplayValue: (key, raw, l10n) {
                    if (key == 'zodiac_sign') {
                      return _getZodiacDisplay(raw, l10n);
                    }
                    if (key == 'pets') return _getPetDisplay(raw, l10n);
                    return raw;
                  },
                ),
              ],
            ),
    );
  }

  void _openFullOnboarding(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => PostRegistrationOnboardingScreen(
          userId: widget.userId,
          onComplete: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _onProfilePhotoTap(BuildContext context, int index) async {
    if (index < 0 || index >= 6) return;
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;
      // رفع إلى Storage ثم حفظ الرابط في profile_answers
      final url = await _photoStorage.uploadPhoto(
        userId: widget.userId,
        filePath: picked.path,
        slotIndex: index,
      );
      final slot = _profilePhotoSlots[index];
      final updated = await _answerService.upsertImageAnswer(
        profileId: widget.userId,
        sortOrder: _photoSortBase + index,
        content: url,
        existingId: slot.id,
      );
      if (!mounted) return;
      setState(() {
        _profilePhotoSlots = List.from(_profilePhotoSlots);
        _profilePhotoSlots[index] = (id: updated.id, url: url);
        _filledPhotosCount = _profilePhotoSlots
            .where((s) => s.url != null && s.url!.isNotEmpty)
            .length;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.answerSaved),
            backgroundColor: AppColors.hingePurple,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('_onProfilePhotoTap error: $e');
      debugPrint('_onProfilePhotoTap stack: $st');
      if (mounted) {
        final err = e.toString().toLowerCase();
        String msg;
        if (err.contains('bucket not found') || err.contains('404')) {
          msg =
              'مجلد التخزين غير موجود. أنشئ bucket باسم profile-photos من Supabase → Storage → New bucket (Public: ON).';
        } else if (err.contains('camera') || err.contains('not available')) {
          msg = l10n.cameraNotAvailableHint;
        } else {
          msg = '${l10n.error}: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _onProfilePhotoRemove(BuildContext context, int index) async {
    if (index < 0 || index >= 6) return;
    final slot = _profilePhotoSlots[index];
    if (slot.id != null) {
      try {
        await _answerService.deleteAnswer(slot.id!);
        await _photoStorage.deletePhoto(
          userId: widget.userId,
          slotIndex: index,
        );
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _profilePhotoSlots = List.from(_profilePhotoSlots);
      _profilePhotoSlots[index] = (id: null, url: null);
      _filledPhotosCount = _profilePhotoSlots
          .where((s) => s.url != null && s.url!.isNotEmpty)
          .length;
    });
  }

  /// تحميل فيديو واحد للبروفايل (حد أقصى 15 ثانية).
  Future<void> _onProfileVideoTap(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(l10n.chooseFromGallery),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: Text(l10n.takePhoto),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    try {
      final picked = await _imagePicker.pickVideo(source: source);
      if (picked == null || !mounted) return;
      final path = picked.path;
      if (path.isEmpty) return;
      // عرض مؤشر تحميل لتجنب تجمّد الواجهة أثناء تهيئة الفيديو
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
            child: CircularProgressIndicator(color: AppColors.hingePurple),
          ),
        );
      }
      await Future.delayed(Duration.zero); // إفساح المجال للواجهة لرسم المؤشر
      VideoPlayerController? controller;
      try {
        controller = VideoPlayerController.file(File(path));
        await controller.initialize();
        final duration = controller.value.duration;
        if (duration.inSeconds > _maxVideoDurationSeconds) {
          if (mounted) {
            Navigator.of(context, rootNavigator: true).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.videoMaxDuration(_maxVideoDurationSeconds)),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      } finally {
        controller?.dispose();
      }
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      final url = await _videoStorage.uploadVideo(
        userId: widget.userId,
        filePath: path,
      );
      final caption = _videoCaptionController.text.trim();
      final content = caption.isNotEmpty
          ? jsonEncode({'url': url, 'caption': caption})
          : url;
      final updated = await _answerService.upsertVideoAnswer(
        profileId: widget.userId,
        sortOrder: _videoSortOrder,
        content: content,
        existingId: _profileVideoSlot.id,
      );
      if (!mounted) return;
      setState(
        () => _profileVideoSlot = (id: updated.id, url: url, caption: caption),
      );
      _videoCaptionController.text = caption;
      unawaited(_loadProfile()); // تحديث في الخلفية دون تجميد الواجهة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.answerSaved),
            backgroundColor: AppColors.hingePurple,
          ),
        );
      }
    } catch (e, st) {
      debugPrint('_onProfileVideoTap error: $e');
      debugPrint('_onProfileVideoTap stack: $st');
      if (mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (_) {}
        final err = e.toString().toLowerCase();
        String msg;
        if (err.contains('bucket not found') || err.contains('404')) {
          msg =
              'مجلد التخزين غير موجود. أنشئ bucket باسم profile-videos من Supabase → Storage.';
        } else if (err.contains('camera') || err.contains('not available')) {
          msg = l10n.cameraNotAvailableHint;
        } else {
          msg = '${l10n.error}: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _onProfileVideoRemove(BuildContext context) async {
    if (_profileVideoSlot.id != null) {
      try {
        await _answerService.deleteAnswer(_profileVideoSlot.id!);
        await _videoStorage.deleteVideo(userId: widget.userId);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _profileVideoSlot = (id: null, url: null, caption: ''));
    _videoCaptionController.clear();
    unawaited(_loadProfile());
  }

  /// حوار إضافة أو تعديل النص المرافق للتسجيل الصوتي.
  Future<void> _showVoiceCaptionDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: _profileVoiceSlot.answer);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.voiceAddOrEditText),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.voiceCaptionHint,
            border: const OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 3,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.hingePurple,
            ),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    await _saveVoiceAnswerText(context, result);
  }

  /// حفظ النص المرافق للتسجيل (تحديث content مع الإبقاء على audio_url و duration_seconds).
  Future<void> _saveVoiceAnswerText(
    BuildContext context,
    String answerText,
  ) async {
    final l10n = AppLocalizations.of(context);
    if (_profileVoiceSlot.id == null) return;
    try {
      final contentMap = <String, dynamic>{
        'prompt_id': 'voice_recording',
        'answer': answerText,
      };
      if (_profileVoiceSlot.audioUrl != null &&
          _profileVoiceSlot.audioUrl!.isNotEmpty) {
        contentMap['audio_url'] = _profileVoiceSlot.audioUrl;
      }
      if (_profileVoiceSlot.spotifyUrl != null &&
          _profileVoiceSlot.spotifyUrl!.isNotEmpty) {
        contentMap['spotify_url'] = _profileVoiceSlot.spotifyUrl;
        if (_profileVoiceSlot.spotifyImageUrl != null) {
          contentMap['spotify_image_url'] = _profileVoiceSlot.spotifyImageUrl;
        }
        if (_profileVoiceSlot.spotifyTitle != null) {
          contentMap['spotify_title'] = _profileVoiceSlot.spotifyTitle;
        }
        if (_profileVoiceSlot.spotifyArtist != null) {
          contentMap['spotify_artist'] = _profileVoiceSlot.spotifyArtist;
        }
      }
      if (_profileVoiceSlot.durationSeconds != null) {
        contentMap['duration_seconds'] = _profileVoiceSlot.durationSeconds;
      }
      final content = jsonEncode(contentMap);
      await _answerService.updateAnswer(
        id: _profileVoiceSlot.id!,
        content: content,
      );
      if (!mounted) return;
      setState(
        () => _profileVoiceSlot = (
          id: _profileVoiceSlot.id,
          answer: answerText,
          audioUrl: _profileVoiceSlot.audioUrl,
          spotifyUrl: _profileVoiceSlot.spotifyUrl,
          spotifyImageUrl: _profileVoiceSlot.spotifyImageUrl,
          spotifyTitle: _profileVoiceSlot.spotifyTitle,
          spotifyArtist: _profileVoiceSlot.spotifyArtist,
          durationSeconds: _profileVoiceSlot.durationSeconds,
        ),
      );
      unawaited(_loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.answerSaved),
          backgroundColor: AppColors.hingePurple,
        ),
      );
    } catch (e, st) {
      debugPrint('_saveVoiceAnswerText: $e $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_voiceErrorDisplayMessage(e, l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _doVoiceRecordFromMic(BuildContext context) async {
    if (_isVoiceRecordingInProgress) return;
    final l10n = AppLocalizations.of(context);
    if (_lastVoiceMultipleRequestTime != null &&
        DateTime.now().difference(_lastVoiceMultipleRequestTime!).inSeconds <
            3) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.retryAgain),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    _isVoiceRecordingInProgress = true;
    final recorder = AudioRecorder();
    try {
      final hasPermission = await recorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.microphonePermissionDenied),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      if (!mounted) return;
      final startRecording = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.voiceRecordFromMic),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 56, color: AppColors.hingePurple),
              const SizedBox(height: 16),
              Text(
                l10n.voicePressStartToRecord,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.hingePurple,
              ),
              child: Text(l10n.voiceStartRecording),
            ),
          ],
        ),
      );
      if (startRecording != true || !mounted) return;

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/swaply_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      if (!mounted) return;
      final durationSeconds = await showDialog<int>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.voiceRecordFromMic),
          content: _RecordingDialogContent(
            dialogContext: ctx,
            doneLabel: l10n.done,
          ),
        ),
      );
      if (durationSeconds == null) {
        await recorder.cancel();
        return;
      }
      final recordedPath = await recorder.stop();
      if (recordedPath == null || recordedPath.isEmpty || !mounted) return;
      await _uploadAndSaveVoice(
        context,
        recordedPath,
        '',
        durationSeconds: durationSeconds,
      );
    } on PlatformException catch (e, st) {
      debugPrint('_doVoiceRecordFromMic PlatformException: ${e.code} $e $st');
      final errStr = e.toString().toLowerCase();
      final isMultipleRequest =
          e.code == 'multiple_request' ||
          e.message?.toLowerCase().contains('cancelled by a second request') ==
              true ||
          errStr.contains('multiple_request') ||
          errStr.contains('cancelled by a second request');
      if (isMultipleRequest) _lastVoiceMultipleRequestTime = DateTime.now();
      if (mounted) {
        final displayMsg = isMultipleRequest
            ? l10n.retryAgain
            : l10n.voiceUploadFailed;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('_doVoiceRecordFromMic: $e $st');
      final msg = e.toString().toLowerCase();
      final isMultipleRequest =
          msg.contains('multiple_request') ||
          msg.contains('cancelled by a second request');
      if (isMultipleRequest) _lastVoiceMultipleRequestTime = DateTime.now();
      if (mounted) {
        final isBucketNotFound =
            msg.contains('bucket not found') || msg.contains('404');
        String displayMsg;
        if (isMultipleRequest) {
          displayMsg = l10n.retryAgain;
        } else if (isBucketNotFound) {
          displayMsg =
              'مجلد التخزين غير موجود. نفّذ supabase/storage_profile_audio.sql في SQL Editor.';
        } else {
          displayMsg = '${l10n.error}: حدث خطأ أثناء التسجيل. جرّب مرة أخرى.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(displayMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      recorder.dispose();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _isVoiceRecordingInProgress = false);
      });
    }
  }

  Future<void> _doVoiceUploadFromPhone(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    try {
      // Give the bottom sheet time to fully close before presenting the file picker (fixes picker not opening on iOS).
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.isNotEmpty == true
          ? result!.files.single
          : null;
      if (file == null || !mounted) return;

      String? path = file.path;
      if (path == null || path.isEmpty) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.error),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        final dir = await getTemporaryDirectory();
        final name = file.name.isNotEmpty
            ? file.name
            : 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final tempFile = File('${dir.path}/$name');
        await tempFile.writeAsBytes(bytes);
        path = tempFile.path;
      }
      await _uploadAndSaveVoice(context, path, '');
    } catch (e, st) {
      debugPrint('_doVoiceUploadFromPhone: $e $st');
      if (mounted) {
        final msg = _voiceErrorDisplayMessage(e, l10n);
        final isMultipleRequest = msg == l10n.retryAgain;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isMultipleRequest ? msg : l10n.voiceUploadFailed),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// حفظ بيانات Spotify من شاشة «أغنيتي».
  Future<void> _applySpotifyData(
    BuildContext context,
    SpotifyTrackData data,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      final contentMap = <String, dynamic>{
        'prompt_id': 'voice_recording',
        'answer': _profileVoiceSlot.answer,
        'spotify_url': data.url,
        if (data.imageUrl != null && data.imageUrl!.isNotEmpty)
          'spotify_image_url': data.imageUrl,
        if (data.name != null && data.name!.isNotEmpty)
          'spotify_title': data.name,
        if (data.artist != null && data.artist!.isNotEmpty)
          'spotify_artist': data.artist,
      };
      final content = jsonEncode(contentMap);
      ProfileAnswer updated;
      if (_profileVoiceSlot.id != null) {
        updated = await _answerService.updateAnswer(
          id: _profileVoiceSlot.id!,
          content: content,
        );
      } else {
        updated = await _answerService.insertAnswer(
          profileId: widget.userId,
          questionId: null,
          content: content,
          sortOrder: _voiceSortOrder,
        );
      }
      if (!mounted) return;
      setState(
        () => _profileVoiceSlot = (
          id: updated.id,
          answer: _profileVoiceSlot.answer,
          audioUrl: null,
          spotifyUrl: data.url,
          spotifyImageUrl: data.imageUrl,
          spotifyTitle: data.name,
          spotifyArtist: data.artist,
          durationSeconds: _profileVoiceSlot.durationSeconds,
        ),
      );
      unawaited(_loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.answerSaved),
          backgroundColor: AppColors.hingePurple,
        ),
      );
    } catch (e, st) {
      debugPrint('_applySpotifyData: $e $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_voiceErrorDisplayMessage(e, l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// فتح شاشة «أغنيتي» (Spotify فقط) ثم تطبيق البيانات عند الحفظ.
  Future<void> _onFavoriteSongTap(BuildContext context) async {
    final data = await Navigator.push<SpotifyTrackData>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SpotifySongPickerScreen(initialUrl: _profileVoiceSlot.spotifyUrl),
      ),
    );
    if (data != null && data.url.trim().isNotEmpty && mounted) {
      await _applySpotifyData(context, data);
    }
  }

  /// شيت «تسجيل صوتي» فقط: ميكروفون، رفع ملف، إضافة/تعديل نص (بدون Spotify).
  Future<void> _onVoiceRecordingTap(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final hasVoice = _profileVoiceSlot.id != null;
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.voiceSourceTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (hasVoice)
              ListTile(
                leading: const Icon(
                  Icons.text_fields,
                  color: AppColors.hingePurple,
                ),
                title: Text(l10n.voiceAddOrEditText),
                onTap: () => Navigator.pop(ctx, 'text'),
              ),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.hingePurple),
              title: Text(l10n.voiceRecordFromMic),
              onTap: () => Navigator.pop(ctx, 'mic'),
            ),
            ListTile(
              leading: const Icon(
                Icons.upload_file,
                color: AppColors.hingePurple,
              ),
              title: Text(l10n.voiceUploadFromPhone),
              onTap: () => Navigator.pop(ctx, 'file'),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    if (source == 'text') {
      await _showVoiceCaptionDialog(context);
    } else if (source == 'mic') {
      await _doVoiceRecordFromMic(context);
    } else if (source == 'file') {
      await _doVoiceUploadFromPhone(context);
    }
  }

  /// إزالة أغنية Spotify من السجل (الإبقاء على التسجيل الصوتي إن وُجد).
  Future<void> _onRemoveFavoriteSong(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_profileVoiceSlot.id == null) return;
    try {
      final contentMap = <String, dynamic>{
        'prompt_id': 'voice_recording',
        'answer': _profileVoiceSlot.answer,
        if (_profileVoiceSlot.audioUrl != null)
          'audio_url': _profileVoiceSlot.audioUrl,
        if (_profileVoiceSlot.durationSeconds != null)
          'duration_seconds': _profileVoiceSlot.durationSeconds,
      };
      final content = jsonEncode(contentMap);
      await _answerService.updateAnswer(
        id: _profileVoiceSlot.id!,
        content: content,
      );
      if (!mounted) return;
      setState(
        () => _profileVoiceSlot = (
          id: _profileVoiceSlot.id,
          answer: _profileVoiceSlot.answer,
          audioUrl: _profileVoiceSlot.audioUrl,
          spotifyUrl: null,
          spotifyImageUrl: null,
          spotifyTitle: null,
          spotifyArtist: null,
          durationSeconds: _profileVoiceSlot.durationSeconds,
        ),
      );
      unawaited(_loadProfile());
    } catch (e, st) {
      debugPrint('_onRemoveFavoriteSong: $e $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// إزالة التسجيل الصوتي من السجل (الإبقاء على Spotify إن وُجد).
  Future<void> _onRemoveVoiceRecording(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    if (_profileVoiceSlot.id == null) return;
    try {
      final contentMap = <String, dynamic>{
        'prompt_id': 'voice_recording',
        'answer': _profileVoiceSlot.answer,
        if (_profileVoiceSlot.spotifyUrl != null)
          'spotify_url': _profileVoiceSlot.spotifyUrl,
        if (_profileVoiceSlot.spotifyImageUrl != null)
          'spotify_image_url': _profileVoiceSlot.spotifyImageUrl,
        if (_profileVoiceSlot.spotifyTitle != null)
          'spotify_title': _profileVoiceSlot.spotifyTitle,
        if (_profileVoiceSlot.spotifyArtist != null)
          'spotify_artist': _profileVoiceSlot.spotifyArtist,
      };
      final content = jsonEncode(contentMap);
      await _answerService.updateAnswer(
        id: _profileVoiceSlot.id!,
        content: content,
      );
      if (!mounted) return;
      setState(
        () => _profileVoiceSlot = (
          id: _profileVoiceSlot.id,
          answer: _profileVoiceSlot.answer,
          audioUrl: null,
          spotifyUrl: _profileVoiceSlot.spotifyUrl,
          spotifyImageUrl: _profileVoiceSlot.spotifyImageUrl,
          spotifyTitle: _profileVoiceSlot.spotifyTitle,
          spotifyArtist: _profileVoiceSlot.spotifyArtist,
          durationSeconds: null,
        ),
      );
      unawaited(_loadProfile());
    } catch (e, st) {
      debugPrint('_onRemoveVoiceRecording: $e $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.error), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _uploadAndSaveVoice(
    BuildContext context,
    String filePath,
    String answerText, {
    int? durationSeconds,
  }) async {
    final l10n = AppLocalizations.of(context);
    final uploadUserId =
        Supabase.instance.client.auth.currentUser?.id ?? widget.userId;
    try {
      final url = await _audioStorage.uploadAudio(
        userId: uploadUserId,
        filePath: filePath,
      );
      final contentMap = <String, dynamic>{
        'prompt_id': 'voice_recording',
        'answer': answerText.isNotEmpty ? answerText : _profileVoiceSlot.answer,
        'audio_url': url,
      };
      if (durationSeconds != null) {
        contentMap['duration_seconds'] = durationSeconds;
      }
      final content = jsonEncode(contentMap);
      ProfileAnswer updated;
      if (_profileVoiceSlot.id != null) {
        updated = await _answerService.updateAnswer(
          id: _profileVoiceSlot.id!,
          content: content,
        );
      } else {
        updated = await _answerService.insertAnswer(
          profileId: widget.userId,
          questionId: null,
          content: content,
          sortOrder: _voiceSortOrder,
        );
      }
      if (!mounted) return;
      setState(
        () => _profileVoiceSlot = (
          id: updated.id,
          answer: answerText.isNotEmpty ? answerText : _profileVoiceSlot.answer,
          audioUrl: url,
          spotifyUrl: _profileVoiceSlot.spotifyUrl,
          spotifyImageUrl: _profileVoiceSlot.spotifyImageUrl,
          spotifyTitle: _profileVoiceSlot.spotifyTitle,
          spotifyArtist: _profileVoiceSlot.spotifyArtist,
          durationSeconds: durationSeconds ?? _profileVoiceSlot.durationSeconds,
        ),
      );
      unawaited(_loadProfile());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.answerSaved),
          backgroundColor: AppColors.hingePurple,
        ),
      );
    } catch (e, st) {
      debugPrint('_uploadAndSaveVoice: $e $st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_voiceErrorDisplayMessage(e, l10n)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _onWrittenPromptSlotTap(BuildContext context, int index) async {
    if (index < 0 || index >= _writtenPromptSlots.length) return;
    final selected = await showPromptSelectionSheet(context);
    if (selected == null || !mounted) return;
    setState(() {
      _writtenPromptSlots[index] = _WrittenPromptSlotData(
        profileAnswerId: _writtenPromptSlots[index].profileAnswerId,
        promptId: selected.id,
        promptText: selected.text,
        answer: _writtenPromptSlots[index].answer,
      );
    });
  }

  Future<void> _onFieldUpdated(String key, String value, String vis) async {
    debugPrint(
      '_onFieldUpdated: field_key=$key, value=$value, user_id=${widget.userId}',
    );
    if (key == 'name') {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'full_name': value}),
        );
      } catch (_) {}
    }
    final saved = await _profileFields.saveField(
      userId: widget.userId,
      fieldKey: key,
      value: value,
      visibility: vis,
    );
    if (!saved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).fieldSaveError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    setState(() {
      _values[key] = value;
      _visibility[key] = vis;
    });
    // Sync languages_spoken to profile_answers and profiles (question_id في DB = UUID فنستخدم null و sort_order 54)
    if (key == 'languages_spoken' && value.trim().isNotEmpty) {
      try {
        await _profileService.updateLanguages(widget.userId, value.trim());
        final answers = await _answerService.getByProfileId(widget.userId);
        final existing = answers.where((a) => a.sortOrder == 54).toList();
        if (existing.isNotEmpty) {
          await _answerService.updateAnswer(
            id: existing.first.id,
            content: value.trim(),
          );
        } else {
          await _answerService.insertAnswer(
            profileId: widget.userId,
            questionId: null,
            content: value.trim(),
            sortOrder: 54,
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _onLifestyleInterestsTap(BuildContext context) async {
    final locale = Localizations.localeOf(context);
    final isArabic = locale.languageCode == 'ar';
    final initialIds = parseLifestyleInterestsIds(
      _values['lifestyle_interests'],
    );
    final result = await showLifestyleInterestsSheet(
      context: context,
      initialSelectedIds: initialIds,
      isArabic: isArabic,
    );
    if (result != null && mounted) {
      final jsonValue = jsonEncode(result);
      await _onFieldUpdated(
        'lifestyle_interests',
        jsonValue,
        _visibility['lifestyle_interests'] ?? 'visible',
      );
    }
  }

  Future<void> _showFieldEditor(
    BuildContext context,
    String fieldKey,
    String fieldLabel,
    String currentValue,
    String currentVisKey,
  ) async {
    final l10n = AppLocalizations.of(context);

    if (fieldKey == 'location') {
      final result = await Navigator.of(context).push<LocationPickerResult>(
        MaterialPageRoute(
          builder: (ctx) => LocationPickerScreen(
            initialAddress: currentValue.isEmpty ? null : currentValue,
          ),
        ),
      );
      if (result != null && result.address.isNotEmpty) {
        await _onFieldUpdated(fieldKey, result.address, currentVisKey);
        if (result.lat != null && result.lng != null) {
          try {
            String? city;
            String? country;
            try {
              final placemarks = await geo.placemarkFromCoordinates(
                result.lat!,
                result.lng!,
              );
              if (placemarks.isNotEmpty) {
                final p = placemarks.first;
                city =
                    p.locality ??
                    p.subAdministrativeArea ??
                    p.administrativeArea;
                country = p.country;
              }
            } catch (_) {}
            await ProfileService().updateLocation(
              widget.userId,
              lat: result.lat!,
              lng: result.lng!,
              city: city,
              country: country,
            );
          } catch (_) {}
        }
      }
      return;
    }

    if (fieldKey == 'languages_spoken') {
      final result = await showLanguagesEditorSheet(
        context: context,
        title: l10n.languagesSpoken,
        currentValue: currentValue,
        currentVisibility: currentVisKey,
      );
      if (result != null) {
        await _onFieldUpdated(fieldKey, result.value, result.visibility);
      }
      return;
    }

    if (fieldKey == 'height') {
      final result = await showHeightPickerSheet(
        context: context,
        title: fieldLabel,
        currentValue: currentValue,
        currentVisibility: currentVisKey,
        allowAlwaysVisible: true,
        allowAlwaysHidden: false,
      );
      if (result != null) {
        await _onFieldUpdated(fieldKey, result.value, result.visibility);
      }
      return;
    }

    final config = _fieldConfig(l10n, fieldKey);
    String valueForSheet = currentValue;
    if (fieldKey == 'zodiac_sign') {
      valueForSheet = _getZodiacDisplay(currentValue, l10n);
    }
    if (fieldKey == 'pets') valueForSheet = _getPetDisplay(currentValue, l10n);

    final result = await showProfileFieldEditorSheet(
      context: context,
      title: fieldLabel,
      currentValue: valueForSheet,
      currentVisibility: currentVisKey,
      type: config.type,
      choices: config.choices,
      hint: config.hint,
      allowAlwaysVisible: config.allowAlwaysVisible,
      allowAlwaysHidden: config.allowAlwaysHidden,
    );

    if (result != null) {
      String valueToSave = result.value;
      if (fieldKey == 'zodiac_sign') {
        final labels = _zodiacLabels(l10n);
        final idx = labels.indexOf(result.value);
        if (idx >= 0) valueToSave = _zodiacKeys[idx];
      } else if (fieldKey == 'pets') {
        final labels = _petLabels(l10n);
        final idx = labels.indexOf(result.value);
        if (idx >= 0) valueToSave = _petKeys[idx];
      }
      await _onFieldUpdated(fieldKey, valueToSave, result.visibility);
    }
  }

  ({
    ProfileFieldType type,
    List<String>? choices,
    String? hint,
    bool allowAlwaysVisible,
    bool allowAlwaysHidden,
  })
  _fieldConfig(AppLocalizations l10n, String key) {
    switch (key) {
      case 'pronouns':
        return (
          type: ProfileFieldType.choice,
          choices: ['He/Him', 'She/Her', 'They/Them', l10n.none],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'gender':
        return (
          type: ProfileFieldType.choice,
          choices: ['Man', 'Woman', 'Non-binary', 'Other'],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'sexuality':
        return (
          type: ProfileFieldType.choice,
          choices: ['Straight', 'Gay', 'Lesbian', 'Bisexual', 'Other'],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'im_interested_in':
        return (
          type: ProfileFieldType.choice,
          choices: [l10n.men, l10n.women, l10n.everyone],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: true,
        );
      case 'work':
      case 'job_title':
      case 'college_or_university':
      case 'home_town':
      case 'match_note':
        return (
          type: ProfileFieldType.text,
          choices: null,
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'education_level':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Secondary school',
            'Undergraduate',
            'Postgraduate',
            l10n.none,
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: true,
        );
      case 'religious_beliefs':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Agnostic',
            'Atheist',
            'Buddhist',
            'Catholic',
            'Christian',
            'Hindu',
            'Jewish',
            'Muslim',
            'Other',
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'politics':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Liberal',
            'Moderate',
            'Conservative',
            'Not political',
            'Other',
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'languages_spoken':
        return (
          type: ProfileFieldType.text,
          choices: null,
          hint: 'e.g. Arabic, English',
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'dating_intentions':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Life partner',
            'Relationship',
            'Something casual',
            'Not sure yet',
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'relationship_type':
        return (
          type: ProfileFieldType.choice,
          choices: ['Monogamy', 'Non-monogamy', 'Open to both'],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'name':
        return (
          type: ProfileFieldType.text,
          choices: null,
          hint: null,
          allowAlwaysVisible: true,
          allowAlwaysHidden: false,
        );
      case 'age':
        return (
          type: ProfileFieldType.text,
          choices: null,
          hint: '18-100',
          allowAlwaysVisible: true,
          allowAlwaysHidden: false,
        );
      case 'height':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Short',
            'Average',
            'Tall',
            '150-160 cm',
            '161-170 cm',
            '171-180 cm',
            '181+ cm',
          ],
          hint: null,
          allowAlwaysVisible: true,
          allowAlwaysHidden: false,
        );
      case 'ethnicity':
        return (
          type: ProfileFieldType.choice,
          choices: [
            'Asian',
            'Black/African Descent',
            'White',
            'Latino',
            'Middle Eastern',
            'Other',
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'children':
        return (
          type: ProfileFieldType.choice,
          choices: [
            "Don't have children",
            'Have kids',
            'Want kids',
            "Don't want kids",
            'Not sure',
          ],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'family_plans':
        return (
          type: ProfileFieldType.choice,
          choices: ["Don't want children", 'Want', 'Open', 'Not sure'],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'covid_vaccine':
        return (
          type: ProfileFieldType.choice,
          choices: [l10n.none, l10n.postYes, l10n.postNo, l10n.postSometimes],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'pets':
        return (
          type: ProfileFieldType.choice,
          choices: _petLabels(l10n),
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'zodiac_sign':
        return (
          type: ProfileFieldType.choice,
          choices: _zodiacLabels(l10n),
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      case 'drinking':
      case 'smoking':
      case 'marijuana':
      case 'drugs':
        return (
          type: ProfileFieldType.choice,
          choices: [l10n.postYes, l10n.postSometimes, l10n.postNo],
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
      default:
        return (
          type: ProfileFieldType.text,
          choices: null,
          hint: null,
          allowAlwaysVisible: false,
          allowAlwaysHidden: false,
        );
    }
  }
}

class _EditTabContent extends StatelessWidget {
  const _EditTabContent({
    required this.userId,
    required this.topPhotoEnabled,
    required this.onTopPhotoChanged,
    required this.onOpenFullOnboarding,
    required this.profilePhotoSlots,
    required this.onProfilePhotoTap,
    required this.onProfilePhotoRemove,
    required this.profileVideoSlot,
    required this.onProfileVideoTap,
    required this.onProfileVideoRemove,
    required this.onProfileVideoCaptionChanged,
    required this.videoCaptionController,
    required this.profileVoiceSlot,
    required this.onFavoriteSongTap,
    required this.onVoiceRecordingTap,
    required this.onRemoveFavoriteSong,
    required this.onRemoveVoiceRecording,
    required this.writtenPromptSlots,
    required this.onSlotTap,
    required this.onSlotAnswerChanged,
    required this.values,
    required this.visibility,
    required this.visDisplay,
    required this.v,
    required this.vis,
    required this.displayName,
    required this.onFieldTap,
    required this.onFieldUpdated,
    required this.lifestyleInterestsCount,
    required this.onLifestyleInterestsTap,
    this.getFieldDisplayValue,
  });

  final String userId;
  final bool topPhotoEnabled;
  final ValueChanged<bool> onTopPhotoChanged;
  final VoidCallback onOpenFullOnboarding;
  final List<({String? id, String? url})> profilePhotoSlots;
  final ValueChanged<int> onProfilePhotoTap;
  final ValueChanged<int> onProfilePhotoRemove;
  final ({String? id, String? url, String caption}) profileVideoSlot;
  final VoidCallback onProfileVideoTap;
  final VoidCallback onProfileVideoRemove;
  final ValueChanged<String> onProfileVideoCaptionChanged;
  final TextEditingController videoCaptionController;
  final ({
    String? id,
    String answer,
    String? audioUrl,
    String? spotifyUrl,
    String? spotifyImageUrl,
    String? spotifyTitle,
    String? spotifyArtist,
    int? durationSeconds,
  })
  profileVoiceSlot;
  final VoidCallback onFavoriteSongTap;
  final VoidCallback onVoiceRecordingTap;
  final VoidCallback onRemoveFavoriteSong;
  final VoidCallback onRemoveVoiceRecording;
  final List<_WrittenPromptSlotData> writtenPromptSlots;
  final ValueChanged<int> onSlotTap;
  final void Function(int index, String text) onSlotAnswerChanged;
  final Map<String, String> values;
  final Map<String, String> visibility;
  final String Function(AppLocalizations, String) visDisplay;
  final String Function(String, String) v;
  final String Function(String, String) vis;
  final String displayName;
  final Future<void> Function(BuildContext, String, String, String, String)
  onFieldTap;
  final Future<void> Function(String, String, String) onFieldUpdated;
  final int lifestyleInterestsCount;
  final VoidCallback onLifestyleInterestsTap;
  final String Function(String key, String rawValue, AppLocalizations l10n)?
  getFieldDisplayValue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addFourToSixPhotos,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.hingePurple,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.dragToReorder,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 12),
          _photoGrid(
            context,
            profilePhotoSlots,
            onProfilePhotoTap,
            onProfilePhotoRemove,
          ),
          const SizedBox(height: 24),
          _sectionGray(l10n.topPhoto),
          const SizedBox(height: 6),
          Text(
            l10n.topPhotoDesc,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox.shrink(),
              Switch(
                value: topPhotoEnabled,
                onChanged: onTopPhotoChanged,
                activeTrackColor: AppColors.hingePurple.withValues(alpha: 0.5),
                activeThumbColor: AppColors.hingePurple,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _sectionGray('${l10n.videoPrompt} (1)'),
          const SizedBox(height: 4),
          Text(
            'سؤال اجباري — فيديو + وصف',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neonCoral,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          _videoSlotBox(context, l10n),
          const SizedBox(height: 24),
          _sectionGray(l10n.writtenPrompts),
          const SizedBox(height: 12),
          ...List.generate(3, (i) {
            final slot = i < writtenPromptSlots.length
                ? writtenPromptSlots[i]
                : _WrittenPromptSlotData();
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _WrittenPromptSlot(
                slot: slot,
                slotIndex: i,
                onTap: () => onSlotTap(i),
                onAnswerChanged: (text) => onSlotAnswerChanged(i, text),
                selectPromptHint: l10n.selectPrompt,
                writeHint: l10n.writeYourAnswer,
              ),
            );
          }),
          const SizedBox(height: 4),
          Text(
            l10n.threeAnswersRequired,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.neonCoral,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.myFavoriteSong,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCoral,
            ),
          ),
          const SizedBox(height: 8),
          _favoriteSongBox(context, l10n),
          const SizedBox(height: 24),
          Text(
            l10n.voiceRecording,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.neonCoral,
            ),
          ),
          const SizedBox(height: 8),
          _voiceRecordingBox(context, l10n),
          const SizedBox(height: 28),
          RepaintBoundary(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionGray(l10n.identity),
                _profileRow(context, l10n, 'pronouns', l10n.pronouns),
                _profileRow(context, l10n, 'gender', l10n.gender),
                _profileRow(context, l10n, 'sexuality', l10n.sexuality),
                _profileRow(
                  context,
                  l10n,
                  'im_interested_in',
                  l10n.imInterestedIn,
                ),
                const SizedBox(height: 20),
                _sectionPurple(l10n.matchNote),
                _profileRow(context, l10n, 'match_note', l10n.matchNote),
                const SizedBox(height: 20),
                _sectionGray(l10n.myVirtues),
                _profileRow(context, l10n, 'work', l10n.work),
                _profileRow(context, l10n, 'job_title', l10n.jobTitle),
                _profileRow(
                  context,
                  l10n,
                  'college_or_university',
                  l10n.collegeOrUniversity,
                ),
                _profileRow(
                  context,
                  l10n,
                  'education_level',
                  l10n.educationLevel,
                ),
                _profileRow(
                  context,
                  l10n,
                  'religious_beliefs',
                  l10n.religiousBeliefs,
                ),
                _profileRow(context, l10n, 'home_town', l10n.homeTown),
                _profileRow(context, l10n, 'politics', l10n.politics),
                _profileRow(
                  context,
                  l10n,
                  'languages_spoken',
                  l10n.languagesSpoken,
                ),
                _profileRow(
                  context,
                  l10n,
                  'dating_intentions',
                  l10n.datingIntentions,
                ),
                _profileRow(
                  context,
                  l10n,
                  'relationship_type',
                  l10n.relationshipType,
                ),
                const SizedBox(height: 20),
                _sectionGray(l10n.myVitals),
                _profileRow(
                  context,
                  l10n,
                  'name',
                  l10n.name,
                  defaultValue: displayName,
                ),
                _profileRow(context, l10n, 'age', l10n.age),
                _profileRow(context, l10n, 'height', l10n.height),
                _profileRow(context, l10n, 'location', l10n.location),
                _profileRow(context, l10n, 'ethnicity', l10n.ethnicity),
                _profileRow(context, l10n, 'children', l10n.children),
                _profileRow(context, l10n, 'family_plans', l10n.familyPlans),
                _profileRow(context, l10n, 'covid_vaccine', l10n.covidVaccine),
                _profileRow(context, l10n, 'pets', l10n.pets),
                _profileRow(context, l10n, 'zodiac_sign', l10n.zodiacSign),
                const SizedBox(height: 20),
                _sectionGray(l10n.myVices),
                _profileRow(context, l10n, 'drinking', l10n.drinking),
                _profileRow(context, l10n, 'smoking', l10n.smoking),
                _profileRow(context, l10n, 'marijuana', l10n.marijuana),
                _profileRow(context, l10n, 'drugs', l10n.drugs),
                const SizedBox(height: 20),
                _sectionGray(l10n.lifestyle),
                _lifestyleInterestsRow(context, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _lifestyleInterestsRow(BuildContext context, AppLocalizations l10n) {
    final count = lifestyleInterestsCount;
    final selectedLabel = l10n.interestsSelected;
    final value = count == 0
        ? (l10n.none)
        : (count == 1 ? '1 $selectedLabel' : '$count $selectedLabel');
    return _ProfileRowWidget(
      icon: Icons.favorite_border,
      label: l10n.sharedInterests,
      value: value,
      onTap: onLifestyleInterestsTap,
    );
  }

  Widget _sectionGray(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.darkBlack.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _sectionPurple(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.hingePurple,
      ),
    );
  }

  Widget _videoSlotBox(BuildContext context, AppLocalizations l10n) {
    final hasVideo =
        profileVideoSlot.url != null && profileVideoSlot.url!.isNotEmpty;
    final color = AppColors.darkBlack.withValues(alpha: 0.2);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onProfileVideoTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      if (hasVideo)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 64,
                            height: 64,
                            color: AppColors.darkBlack.withValues(alpha: 0.08),
                            child: const Icon(
                              Icons.play_circle_fill,
                              size: 40,
                              color: AppColors.hingePurple,
                            ),
                          ),
                        ),
                      if (hasVideo) const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasVideo ? l10n.videoPrompt : l10n.selectPrompt,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkBlack.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasVideo
                                  ? l10n.videoUploadHint
                                  : l10n.videoUploadHint,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.darkBlack.withValues(
                                  alpha: 0.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasVideo)
                          IconButton(
                            onPressed: onProfileVideoRemove,
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.darkBlack.withValues(alpha: 0.6),
                            ),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        GestureDetector(
                          onTap: onProfileVideoTap,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppColors.hingePurple,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              hasVideo ? Icons.refresh : Icons.add,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          onChanged: onProfileVideoCaptionChanged,
          controller: videoCaptionController,
          decoration: InputDecoration(
            hintText: 'اكتب شيئاً عن فيديوك (إجباري)',
            hintStyle: TextStyle(
              color: AppColors.darkBlack.withValues(alpha: 0.4),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _favoriteSongBox(BuildContext context, AppLocalizations l10n) {
    const double cardRadius = 12;
    final hasSpotify =
        profileVoiceSlot.spotifyUrl != null &&
        profileVoiceSlot.spotifyUrl!.isNotEmpty;

    if (!hasSpotify) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onFavoriteSongTap,
              borderRadius: BorderRadius.circular(cardRadius),
              child: CustomPaint(
                painter: _DashedBorderPainter(
                  color: AppColors.darkBlack.withValues(alpha: 0.25),
                  strokeWidth: 2,
                  borderRadius: cardRadius,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 40,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: GestureDetector(
                      onTap: onFavoriteSongTap,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCoral,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.spotify,
                size: 22,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'Spotify',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      );
    }

    final songTitle =
        (profileVoiceSlot.spotifyTitle ?? profileVoiceSlot.answer)
            .trim()
            .isNotEmpty
        ? (profileVoiceSlot.spotifyTitle ?? profileVoiceSlot.answer).trim()
        : l10n.voiceAddSpotifySong;
    final artistTitle = profileVoiceSlot.spotifyArtist?.trim();
    final imageUrl = profileVoiceSlot.spotifyImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final url = profileVoiceSlot.spotifyUrl;
              if (url != null && url.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpotifyEmbedScreen(
                      spotifyUrl: url,
                      title: songTitle != l10n.voiceAddSpotifySong
                          ? songTitle
                          : null,
                      artist: artistTitle,
                    ),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(cardRadius),
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
                borderRadius: BorderRadius.circular(cardRadius),
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
                            placeholder: (_, __) => Container(
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
                            errorWidget: (_, __, ___) => Container(
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
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlack,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artistTitle != null && artistTitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            artistTitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.darkBlack.withValues(alpha: 0.6),
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
                                onTap: () {
                                  final url = profileVoiceSlot.spotifyUrl;
                                  if (url != null && url.isNotEmpty) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SpotifyEmbedScreen(
                                          spotifyUrl: url,
                                          title:
                                              songTitle !=
                                                  l10n.voiceAddSpotifySong
                                              ? songTitle
                                              : null,
                                          artist: artistTitle,
                                        ),
                                      ),
                                    );
                                  }
                                },
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
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green.shade700,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              Colors.green.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  final url = profileVoiceSlot.spotifyUrl;
                                  if (url != null && url.isNotEmpty) {
                                    final uri = Uri.tryParse(url);
                                    if (uri != null) {
                                      launchUrl(
                                        uri,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    l10n.spotifyBrand,
                                    style: TextStyle(
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
                  IconButton(
                    onPressed: onRemoveFavoriteSong,
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.hingePurple.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: AppColors.hingePurple,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.spotify,
              size: 20,
              color: Colors.green.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.spotifyBrand,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _voiceRecordingBox(BuildContext context, AppLocalizations l10n) {
    const double cardRadius = 12;
    final hasAudio =
        profileVoiceSlot.audioUrl != null &&
        profileVoiceSlot.audioUrl!.isNotEmpty;
    final hasDuration =
        profileVoiceSlot.durationSeconds != null &&
        profileVoiceSlot.durationSeconds! > 0;
    final hasVoiceContent =
        hasAudio || hasDuration || profileVoiceSlot.answer.trim().isNotEmpty;

    if (!hasVoiceContent) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onVoiceRecordingTap,
          borderRadius: BorderRadius.circular(cardRadius),
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: AppColors.darkBlack.withValues(alpha: 0.25),
              strokeWidth: 2,
              borderRadius: cardRadius,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
              child: Center(
                child: GestureDetector(
                  onTap: onVoiceRecordingTap,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: AppColors.hingePurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    final subtitle = profileVoiceSlot.answer.trim().isNotEmpty
        ? profileVoiceSlot.answer
        : (hasDuration
              ? _formatVoiceDuration(profileVoiceSlot.durationSeconds!)
              : l10n.voiceRecordFromMic);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.hingePurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(cardRadius),
        border: Border.all(color: AppColors.hingePurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.darkBlack.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic,
              size: 28,
              color: AppColors.hingePurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasDuration) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatVoiceDuration(profileVoiceSlot.durationSeconds!),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.darkBlack.withValues(alpha: 0.5),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: onRemoveVoiceRecording,
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.hingePurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.hingePurple,
              ),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _photoGrid(
    BuildContext context,
    List<({String? id, String? url})> photoSlots,
    ValueChanged<int> onPhotoTap,
    ValueChanged<int> onPhotoRemove,
  ) {
    // ترتيب العرض: الصور المعبأة أولاً جنب بعضها، ثم الخانات الفارغة.
    final filledIndices = <int>[];
    final emptyIndices = <int>[];
    for (int s = 0; s < 6 && s < photoSlots.length; s++) {
      final hasUrl = photoSlots[s].url != null && photoSlots[s].url!.isNotEmpty;
      if (hasUrl) {
        filledIndices.add(s);
      } else {
        emptyIndices.add(s);
      }
    }
    final displayOrder = filledIndices..addAll(emptyIndices);

    return RepaintBoundary(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
        children: List.generate(6, (i) {
          final slotIndex = i < displayOrder.length ? displayOrder[i] : i;
          final slot = slotIndex < photoSlots.length
              ? photoSlots[slotIndex]
              : (id: null, url: null);
          final hasImage = slot.url != null && slot.url!.isNotEmpty;
          final isPrimary = i < 4;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onPhotoTap(slotIndex),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isPrimary
                        ? AppColors.neonCoral.withValues(alpha: 0.7)
                        : AppColors.darkBlack.withValues(alpha: 0.2),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  fit: StackFit.expand,
                  children: [
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: slot.url!,
                          fit: BoxFit.cover,
                          memCacheWidth: 150,
                          memCacheHeight: 200,
                          fadeInDuration: Duration.zero,
                          placeholder: (_, __) => Icon(
                            Icons.image_outlined,
                            size: 36,
                            color: AppColors.darkBlack.withValues(alpha: 0.2),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            size: 36,
                            color: AppColors.darkBlack.withValues(alpha: 0.3),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.landscape_outlined,
                        size: 36,
                        color: AppColors.darkBlack.withValues(alpha: 0.3),
                      ),
                    if (!hasImage)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: AppColors.hingePurple,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 4,
                        left: 4,
                        child: GestureDetector(
                          onTap: () => onPhotoRemove(slotIndex),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  static IconData _iconForField(String key) {
    switch (key) {
      case 'pronouns':
        return Icons.badge_outlined;
      case 'gender':
        return Icons.wc_outlined;
      case 'sexuality':
        return Icons.favorite_border;
      case 'im_interested_in':
        return Icons.people_outline;
      case 'match_note':
        return Icons.note_outlined;
      case 'work':
        return Icons.work_outline;
      case 'job_title':
        return Icons.business_center_outlined;
      case 'college_or_university':
        return Icons.school_outlined;
      case 'education_level':
        return Icons.school_outlined;
      case 'religious_beliefs':
        return Icons.auto_awesome_outlined;
      case 'home_town':
        return Icons.location_city_outlined;
      case 'politics':
        return Icons.balance_outlined;
      case 'languages_spoken':
        return Icons.language;
      case 'dating_intentions':
        return Icons.favorite_outline;
      case 'relationship_type':
        return Icons.people_outline;
      case 'name':
        return Icons.person_outline;
      case 'age':
        return Icons.cake_outlined;
      case 'height':
        return Icons.height;
      case 'location':
        return Icons.location_on_outlined;
      case 'ethnicity':
        return Icons.groups_outlined;
      case 'children':
        return Icons.child_care_outlined;
      case 'family_plans':
        return Icons.family_restroom_outlined;
      case 'covid_vaccine':
        return Icons.medical_services_outlined;
      case 'pets':
        return Icons.pets;
      case 'zodiac_sign':
        return Icons.star_outline;
      case 'drinking':
        return Icons.local_bar_outlined;
      case 'smoking':
        return Icons.smoking_rooms_outlined;
      case 'marijuana':
        return Icons.eco_outlined;
      case 'drugs':
        return Icons.medication_outlined;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Widget _profileRow(
    BuildContext context,
    AppLocalizations l10n,
    String key,
    String label, {
    String? defaultValue,
  }) {
    final val = v(key, defaultValue ?? l10n.none);
    final visKey = vis(key, 'hidden');
    final displayVal = getFieldDisplayValue?.call(key, val, l10n) ?? val;
    return _ProfileRowWidget(
      icon: _iconForField(key),
      label: label,
      value: displayVal,
      onTap: () => onFieldTap(context, key, label, val, visKey),
    );
  }
}

class _ProfileRowWidget extends StatelessWidget {
  const _ProfileRowWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: AppColors.hingePurple.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                            color: AppColors.darkBlack.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkBlack,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    size: 22,
                    color: AppColors.darkBlack.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, color: AppColors.darkBlack.withValues(alpha: 0.08)),
      ],
    );
  }
}

class _ViewTabContent extends StatefulWidget {
  const _ViewTabContent({
    super.key,
    required this.tabController,
    required this.displayName,
    required this.values,
    required this.writtenPromptSlots,
    required this.profilePhotoSlots,
    required this.profileAnswers,
    required this.profileVoiceSlot,
    required this.topPhotoEnabled,
    required this.v,
    this.currentUserId,
    this.getFieldDisplayValue,
  });

  final TabController tabController;
  final String displayName;
  final Map<String, String> values;
  final List<_WrittenPromptSlotData> writtenPromptSlots;
  final List<({String? id, String? url})> profilePhotoSlots;
  final List<ProfileAnswer> profileAnswers;
  final ({
    String? id,
    String answer,
    String? audioUrl,
    String? spotifyUrl,
    String? spotifyImageUrl,
    String? spotifyTitle,
    String? spotifyArtist,
    int? durationSeconds,
  })
  profileVoiceSlot;
  final bool topPhotoEnabled;
  final String Function(String, String) v;
  final String? currentUserId;
  final String Function(String key, String rawValue, AppLocalizations l10n)?
  getFieldDisplayValue;

  @override
  State<_ViewTabContent> createState() => _ViewTabContentState();
}

class _ViewTabContentState extends State<_ViewTabContent> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.tabController.addListener(_onTabChanged);
    if (widget.tabController.index == 1) _scheduleBuild();
  }

  @override
  void dispose() {
    widget.tabController.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (widget.tabController.index == 1 && !_ready) _scheduleBuild();
  }

  void _scheduleBuild() {
    // عرض المحتوى في الإطار التالي مباشرة — بدون Future.delayed (تجنب التجمّد على iOS و Android).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_ready) setState(() => _ready = true);
    });
    // احتياطي: إن لم يُعرض بعد ثانية، أظهر المحتوى.
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_ready) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.hingePurple),
      );
    }
    final l10n = AppLocalizations.of(context);

    // عرض مبسّط للبروفايل (بدون VerticalProfileView الثقيل) لتجنب التجمّد
    final filledSlots = widget.writtenPromptSlots
        .where((s) => s.promptId != null)
        .toList();
    final hasContent =
        filledSlots.isNotEmpty ||
        widget.values.entries.any(
          (e) => e.key != 'top_photo_enabled' && e.value.isNotEmpty,
        );

    final photoUrls = widget.profilePhotoSlots
        .where((s) => s.url != null && s.url!.isNotEmpty)
        .map((s) => s.url!)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عرض الصور المختارة فقط بشكل مربعات (شبكة عمودين).
          if (photoUrls.isNotEmpty) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisCount = 2;
                const spacing = 10.0;
                final side = (constraints.maxWidth - spacing) / crossAxisCount;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  itemCount: photoUrls.length,
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: photoUrls[i],
                      width: side,
                      height: side,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: AppColors.darkBlack.withValues(alpha: 0.08),
                        child: const Icon(Icons.image_outlined, size: 40),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.darkBlack.withValues(alpha: 0.1),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                widget.displayName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.darkBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                hasContent ? l10n.tabProfile : l10n.incompleteProfile,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkBlack.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (photoUrls.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Text(
                      widget.displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.darkBlack,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasContent ? l10n.tabProfile : l10n.incompleteProfile,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (photoUrls.isEmpty) const SizedBox(height: 28),
          if (widget.topPhotoEnabled) ...[
            _sectionGray(l10n.topPhoto),
            const SizedBox(height: 4),
            Text(
              l10n.topPhotoDesc,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkBlack.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (filledSlots.isNotEmpty) ...[
            _sectionGray(l10n.writtenPrompts),
            const SizedBox(height: 12),
            ...filledSlots.map(
              (slot) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ViewPromptCard(
                  question: slot.promptText ?? '',
                  answer: slot.answer,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_hasVoiceContent(widget.profileVoiceSlot)) ...[
            Text(
              l10n.myFavoriteSong,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.neonCoral,
              ),
            ),
            const SizedBox(height: 12),
            _ViewVoiceCard(
              answer: widget.profileVoiceSlot.answer,
              audioUrl: widget.profileVoiceSlot.audioUrl,
              spotifyUrl: widget.profileVoiceSlot.spotifyUrl,
              spotifyImageUrl: widget.profileVoiceSlot.spotifyImageUrl,
              spotifyTitle: widget.profileVoiceSlot.spotifyTitle,
              spotifyArtist: widget.profileVoiceSlot.spotifyArtist,
              durationSeconds: widget.profileVoiceSlot.durationSeconds,
            ),
            const SizedBox(height: 20),
          ],
          _sectionGray(l10n.identity),
          _viewField(l10n.pronouns, widget.v('pronouns', l10n.none)),
          _viewField(l10n.gender, widget.v('gender', l10n.none)),
          _viewField(l10n.sexuality, widget.v('sexuality', l10n.none)),
          _viewField(
            l10n.imInterestedIn,
            widget.v('im_interested_in', l10n.none),
          ),
          const SizedBox(height: 20),
          _sectionPurple(l10n.matchNote),
          _viewField(l10n.matchNote, widget.v('match_note', l10n.none)),
          const SizedBox(height: 20),
          _sectionGray(l10n.myVirtues),
          _viewField(l10n.work, widget.v('work', l10n.none)),
          _viewField(l10n.jobTitle, widget.v('job_title', l10n.none)),
          _viewField(
            l10n.collegeOrUniversity,
            widget.v('college_or_university', l10n.none),
          ),
          _viewField(
            l10n.educationLevel,
            widget.v('education_level', l10n.none),
          ),
          _viewField(
            l10n.religiousBeliefs,
            widget.v('religious_beliefs', l10n.none),
          ),
          _viewField(l10n.homeTown, widget.v('home_town', l10n.none)),
          _viewField(l10n.politics, widget.v('politics', l10n.none)),
          _viewField(
            l10n.languagesSpoken,
            widget.v('languages_spoken', l10n.none),
          ),
          _viewField(
            l10n.datingIntentions,
            widget.v('dating_intentions', l10n.none),
          ),
          _viewField(
            l10n.relationshipType,
            widget.v('relationship_type', l10n.none),
          ),
          const SizedBox(height: 20),
          _sectionGray(l10n.myVitals),
          _viewField(l10n.name, widget.v('name', widget.displayName)),
          _viewField(l10n.age, widget.v('age', l10n.none)),
          _viewField(l10n.height, widget.v('height', l10n.none)),
          _viewField(l10n.location, widget.v('location', l10n.none)),
          _viewField(l10n.ethnicity, widget.v('ethnicity', l10n.none)),
          _viewField(l10n.children, widget.v('children', l10n.none)),
          _viewField(l10n.familyPlans, widget.v('family_plans', l10n.none)),
          _viewField(l10n.covidVaccine, widget.v('covid_vaccine', l10n.none)),
          _viewField(
            l10n.pets,
            widget.getFieldDisplayValue?.call(
                  'pets',
                  widget.v('pets', l10n.none),
                  l10n,
                ) ??
                widget.v('pets', l10n.none),
          ),
          _viewField(
            l10n.zodiacSign,
            widget.getFieldDisplayValue?.call(
                  'zodiac_sign',
                  widget.v('zodiac_sign', l10n.none),
                  l10n,
                ) ??
                widget.v('zodiac_sign', l10n.none),
          ),
          const SizedBox(height: 20),
          _sectionGray(l10n.myVices),
          _viewField(l10n.drinking, widget.v('drinking', l10n.none)),
          _viewField(l10n.smoking, widget.v('smoking', l10n.none)),
          _viewField(l10n.marijuana, widget.v('marijuana', l10n.none)),
          _viewField(l10n.drugs, widget.v('drugs', l10n.none)),
          const SizedBox(height: 20),
          _sectionGray(l10n.lifestyle),
          _viewField(
            l10n.sharedInterests,
            _lifestyleDisplayValue(context, l10n),
          ),
        ],
      ),
    );
  }

  bool _hasVoiceContent(
    ({
      String? id,
      String answer,
      String? audioUrl,
      String? spotifyUrl,
      String? spotifyImageUrl,
      String? spotifyTitle,
      String? spotifyArtist,
      int? durationSeconds,
    })
    slot,
  ) {
    return (slot.audioUrl != null && slot.audioUrl!.isNotEmpty) ||
        (slot.spotifyUrl != null && slot.spotifyUrl!.isNotEmpty) ||
        slot.answer.trim().isNotEmpty;
  }

  String _lifestyleDisplayValue(BuildContext context, AppLocalizations l10n) {
    final ids = parseLifestyleInterestsIds(
      widget.values['lifestyle_interests'],
    );
    if (ids.isEmpty) return l10n.none;
    final locale = Localizations.localeOf(context).languageCode;
    final labels = resolveLifestyleLabels(ids, locale);
    return labels.join(', ');
  }

  Widget _sectionGray(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.darkBlack.withValues(alpha: 0.6),
      ),
    );
  }

  Widget _sectionPurple(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.hingePurple,
      ),
    );
  }

  Widget _viewField(String label, String value) {
    final display = value.trim().isEmpty ? '-' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.darkBlack.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            display,
            style: TextStyle(
              fontSize: 16,
              color: display == '-'
                  ? AppColors.darkBlack.withValues(alpha: 0.4)
                  : AppColors.darkBlack,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewPromptCard extends StatelessWidget {
  const _ViewPromptCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBlack.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBlack.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.hingePurple,
            ),
          ),
          if (answer.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              answer,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.darkBlack.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// تنسيق المدة بصيغة 0:02
String _formatVoiceDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString()}:${s.toString().padLeft(2, '0')}';
}

/// ارتفاعات وهمية لموجة الصوت (شريط أفقي من أعمدة).
List<double> _placeholderWaveformBars([int count = 28]) {
  return List.generate(count, (i) {
    final t = i / count;
    return 0.25 + 0.75 * (0.5 + 0.5 * math.sin(t * math.pi * 2));
  });
}

/// بطاقة عرض التسجيل الصوتي في تبويب «عرض» — موجة + مدة + تشغيل.
class _ViewVoiceCard extends StatefulWidget {
  const _ViewVoiceCard({
    required this.answer,
    this.audioUrl,
    this.spotifyUrl,
    this.spotifyImageUrl,
    this.spotifyTitle,
    this.spotifyArtist,
    this.durationSeconds,
  });

  final String answer;
  final String? audioUrl;
  final String? spotifyUrl;
  final String? spotifyImageUrl;
  final String? spotifyTitle;
  final String? spotifyArtist;
  final int? durationSeconds;

  @override
  State<_ViewVoiceCard> createState() => _ViewVoiceCardState();
}

class _ViewVoiceCardState extends State<_ViewVoiceCard> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;
  StreamSubscription<void>? _completeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  static final List<double> _waveBars = _placeholderWaveformBars();

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
    final url = widget.audioUrl;
    if (url == null || url.isEmpty || _loading) return;
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
      await _player.play(UrlSource(url));
      if (mounted) {
        setState(() {
          _playing = true;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('_ViewVoiceCard._togglePlay error: $e');
      debugPrint('_ViewVoiceCard._togglePlay stack: $st');
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
    if (uri != null && await canLaunchUrl(uri)) {
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
        ? _formatVoiceDuration(totalSec)
        : null;
    final progress = (_duration.inMilliseconds > 0 && _playing)
        ? _position.inMilliseconds / _duration.inMilliseconds
        : 0.0;

    if (hasSpotify && !hasAudio) {
      final songTitle = (widget.spotifyTitle ?? widget.answer).trim().isNotEmpty
          ? (widget.spotifyTitle ?? widget.answer).trim()
          : l10n.voiceAddSpotifySong;
      final artistTitle = widget.spotifyArtist?.trim();
      final imageUrl = widget.spotifyImageUrl;

      return Column(
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
              borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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
                              placeholder: (_, __) => Container(
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
                              errorWidget: (_, __, ___) => Container(
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
                            style: const TextStyle(
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
                              style: TextStyle(
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
                                          style: TextStyle(
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
                                  onTap: () => _openSpotify(widget.spotifyUrl),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      l10n.spotifyBrand,
                                      style: TextStyle(
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.spotify,
                size: 20,
                color: Colors.green.shade700,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.spotifyBrand,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkBlack.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBlack.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (hasSpotify)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _openSpotify(widget.spotifyUrl),
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green.shade700.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.spotify,
                        size: 24,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ),
              if (hasSpotify && hasAudio) const SizedBox(width: 12),
              if (hasAudio)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _loading ? null : _togglePlay,
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.hingePurple.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _playing
                            ? Icons.stop_rounded
                            : Icons.play_arrow_rounded,
                        size: 32,
                        color: AppColors.hingePurple,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_waveBars.length, (i) {
                          final h = _waveBars[i];
                          final isPlayed =
                              progress > 0 && (i / _waveBars.length) < progress;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 3,
                            height: 6 + h * 16,
                            decoration: BoxDecoration(
                              color: isPlayed
                                  ? AppColors.hingePurple.withValues(alpha: 0.8)
                                  : AppColors.darkBlack.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      ),
                    ),
                    if (displayDuration != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        displayDuration,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.darkBlack.withValues(alpha: 0.6),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                    if (widget.answer.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.answer,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.darkBlack.withValues(alpha: 0.85),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Slot واحد للأسئلة المكتوبة: فارغ (حدود متقطعة + Select a Prompt + +) أو مملوء (نص السؤال + TextField).
class _WrittenPromptSlot extends StatefulWidget {
  const _WrittenPromptSlot({
    required this.slot,
    required this.slotIndex,
    required this.onTap,
    required this.onAnswerChanged,
    required this.selectPromptHint,
    required this.writeHint,
  });

  final _WrittenPromptSlotData slot;
  final int slotIndex;
  final VoidCallback onTap;
  final ValueChanged<String> onAnswerChanged;
  final String selectPromptHint;
  final String writeHint;

  @override
  State<_WrittenPromptSlot> createState() => _WrittenPromptSlotState();
}

class _WrittenPromptSlotState extends State<_WrittenPromptSlot> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.slot.answer);
  }

  @override
  void didUpdateWidget(_WrittenPromptSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.slot.answer != widget.slot.answer &&
        _controller.text != widget.slot.answer) {
      _controller.text = widget.slot.answer;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.slot.promptId == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _DashedBorderPainter(
            color: AppColors.neonCoral.withValues(alpha: 0.9),
            strokeWidth: 2,
            borderRadius: 12,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: isEmpty ? _buildEmptyState() : _buildFilledState(),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.selectPromptHint,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBlack.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 4),
            Icon(Icons.add, color: AppColors.neonCoral, size: 24),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.neonCoral,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilledState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.slot.promptText ?? '',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkBlack,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          onChanged: widget.onAnswerChanged,
          decoration: InputDecoration(
            hintText: widget.writeHint,
            border: const OutlineInputBorder(),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.hingePurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double borderRadius;
  static const double _dashLength = 6;
  static const double _dashGap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics();
    for (final metric in pathMetrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + _dashLength).clamp(0.0, metric.length);
        final extractPath = metric.extractPath(distance, next);
        canvas.drawPath(extractPath, paint);
        distance = next + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// محتوى حوار "جاري التسجيل" — أيقونة ميكروفون + مؤقت + زر تم.
class _RecordingDialogContent extends StatefulWidget {
  const _RecordingDialogContent({
    required this.dialogContext,
    required this.doneLabel,
  });

  final BuildContext dialogContext;
  final String doneLabel;

  @override
  State<_RecordingDialogContent> createState() =>
      _RecordingDialogContentState();
}

class _RecordingDialogContentState extends State<_RecordingDialogContent> {
  int _elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerText {
    final m = _elapsedSeconds ~/ 60;
    final s = _elapsedSeconds % 60;
    return '${m.toString().padLeft(1)}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(Icons.mic, size: 64, color: AppColors.hingePurple),
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _timerText,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'جاري التسجيل... اضغط تم للإيقاف.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () =>
                Navigator.pop(widget.dialogContext, _elapsedSeconds),
            icon: const Icon(Icons.stop_rounded, size: 22),
            label: Text(widget.doneLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.hingePurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
