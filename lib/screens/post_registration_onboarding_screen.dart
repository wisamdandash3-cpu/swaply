import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/profile_answer_service.dart';
import '../services/profile_photo_storage_service.dart';
import '../services/profile_service.dart';

/// نوع الخطوة في الـ onboarding بعد التسجيل.
enum _StepType {
  consent,
  name,
  choice,
  text,
  birthdate,
  location,
  cta,
  photos,
}

/// خطوة واحدة: نوع + مفتاح السؤال (أو النص) + خيارات للنوع choice أو placeholder للنوع text.
class _PostOnboardingStep {
  const _PostOnboardingStep({
    required this.type,
    required this.questionKey,
    this.optionKeys,
    this.placeholderKey,
    this.defaultVisible = true,
  });

  final _StepType type;
  final String questionKey;
  final List<String>? optionKeys;
  final String? placeholderKey;
  final bool defaultVisible;
}

/// أسئلة ما بعد التسجيل (عائلة، مسقط رأس، عمل، دراسة، معتقدات، عادات، ثم CTA وصور).
/// تصميم مشابه للصور: مؤشر تقدم (نقاط + أيقونة)، سؤال بخط كبير، خيارات مع radio أو حقل نص،
/// "Visible on profile" وزر Next دائري بنفسجي.
class PostRegistrationOnboardingScreen extends StatefulWidget {
  const PostRegistrationOnboardingScreen({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  final String userId;
  final VoidCallback onComplete;

  @override
  State<PostRegistrationOnboardingScreen> createState() =>
      _PostRegistrationOnboardingScreenState();
}

class _PostRegistrationOnboardingScreenState
    extends State<PostRegistrationOnboardingScreen> {
  static const int _kFirstQuestionIndex = 1;
  static const int _kNameStepIndex = 1;
  static const int _kBirthdateStepIndex = 2;
  static const int _kLocationStepIndex = 3;
  static const int _kCtaIndex = 16;

  late List<_PostOnboardingStep> _steps;
  int _currentIndex = 0;
  final List<String?> _answers = [];
  final List<bool> _visibleOnProfile = [];
  final Map<int, TextEditingController> _textControllers = {};
  bool _isSaving = false;
  MapController? _mapController;
  LatLng? _locationLatLng;
  bool _locationRequested = false;
  bool _locationLoading = true;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _dobDayController = TextEditingController();
  final TextEditingController _dobMonthController = TextEditingController();
  final TextEditingController _dobYearController = TextEditingController();
  final List<String?> _selectedPhotoPaths = List.filled(6, null);
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _steps = _buildSteps();
    _mapController = MapController();
    for (var i = 0; i < _steps.length; i++) {
      _answers.add(null);
      final step = _steps[i];
      _visibleOnProfile.add(step.defaultVisible);
      if (step.type == _StepType.text || step.type == _StepType.location) {
        _textControllers[i] = TextEditingController();
      }
    }
  }

  List<_PostOnboardingStep> _buildSteps() {
    return [
      const _PostOnboardingStep(type: _StepType.consent, questionKey: ''),
      const _PostOnboardingStep(
        type: _StepType.name,
        questionKey: 'postQName',
      ),
      const _PostOnboardingStep(
        type: _StepType.birthdate,
        questionKey: 'postQDateOfBirth',
      ),
      const _PostOnboardingStep(
        type: _StepType.location,
        questionKey: 'postQLive',
        placeholderKey: 'postEnterAddressPlaceholder',
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQFamilyPlans',
        optionKeys: [
          'postFamilyDontWant',
          'postFamilyWant',
          'postFamilyOpen',
          'postFamilyNotSure',
          'postPreferNotToSay',
        ],
      ),
      const _PostOnboardingStep(
        type: _StepType.text,
        questionKey: 'postQWorkplace',
        placeholderKey: 'postWorkplacePlaceholder',
      ),
      const _PostOnboardingStep(
        type: _StepType.text,
        questionKey: 'postQJobTitle',
        placeholderKey: 'postJobTitlePlaceholder',
      ),
      const _PostOnboardingStep(
        type: _StepType.text,
        questionKey: 'postQWhereStudied',
        placeholderKey: 'postWhereStudiedPlaceholder',
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQEducationLevel',
        optionKeys: ['postEduSecondary', 'postEduUndergrad', 'postEduPostgrad', 'postPreferNotToSay'],
        defaultVisible: false,
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQReligiousBeliefs',
        optionKeys: [
          'postReligionAgnostic',
          'postReligionAtheist',
          'postReligionBuddhist',
          'postReligionCatholic',
          'postReligionChristian',
          'postReligionHindu',
          'postReligionJewish',
          'postReligionMuslim',
        ],
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQPoliticalBeliefs',
        optionKeys: [
          'postPoliticalLiberal',
          'postPoliticalModerate',
          'postPoliticalConservative',
          'postPoliticalNotPolitical',
          'postPoliticalOther',
          'postPreferNotToSay',
        ],
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQDrink',
        optionKeys: ['postYes', 'postSometimes', 'postNo', 'postPreferNotToSay'],
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQSmokeTobacco',
        optionKeys: ['postYes', 'postSometimes', 'postNo', 'postPreferNotToSay'],
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQSmokeWeed',
        optionKeys: ['postYes', 'postSometimes', 'postNo', 'postPreferNotToSay'],
      ),
      const _PostOnboardingStep(
        type: _StepType.choice,
        questionKey: 'postQUseDrugs',
        optionKeys: ['postYes', 'postSometimes', 'postNo', 'postPreferNotToSay'],
      ),
      const _PostOnboardingStep(type: _StepType.cta, questionKey: ''),
      const _PostOnboardingStep(type: _StepType.photos, questionKey: ''),
    ];
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobDayController.dispose();
    _dobMonthController.dispose();
    _dobYearController.dispose();
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _getL10n(String key, AppLocalizations l10n) {
    switch (key) {
      case 'postQFamilyPlans':
        return l10n.postQFamilyPlans;
      case 'postQHometown':
        return l10n.postQHometown;
      case 'postQWorkplace':
        return l10n.postQWorkplace;
      case 'postQJobTitle':
        return l10n.postQJobTitle;
      case 'postQWhereStudied':
        return l10n.postQWhereStudied;
      case 'postQEducationLevel':
        return l10n.postQEducationLevel;
      case 'postQReligiousBeliefs':
        return l10n.postQReligiousBeliefs;
      case 'postQPoliticalBeliefs':
        return l10n.postQPoliticalBeliefs;
      case 'postQDrink':
        return l10n.postQDrink;
      case 'postQSmokeTobacco':
        return l10n.postQSmokeTobacco;
      case 'postQSmokeWeed':
        return l10n.postQSmokeWeed;
      case 'postQUseDrugs':
        return l10n.postQUseDrugs;
      case 'postFamilyDontWant':
        return l10n.postFamilyDontWant;
      case 'postFamilyWant':
        return l10n.postFamilyWant;
      case 'postFamilyOpen':
        return l10n.postFamilyOpen;
      case 'postFamilyNotSure':
        return l10n.postFamilyNotSure;
      case 'postPreferNotToSay':
        return l10n.postPreferNotToSay;
      case 'postHometownPlaceholder':
        return l10n.postHometownPlaceholder;
      case 'postWorkplacePlaceholder':
        return l10n.postWorkplacePlaceholder;
      case 'postJobTitlePlaceholder':
        return l10n.postJobTitlePlaceholder;
      case 'postWhereStudiedPlaceholder':
        return l10n.postWhereStudiedPlaceholder;
      case 'postEduSecondary':
        return l10n.postEduSecondary;
      case 'postEduUndergrad':
        return l10n.postEduUndergrad;
      case 'postEduPostgrad':
        return l10n.postEduPostgrad;
      case 'postReligionAgnostic':
        return l10n.postReligionAgnostic;
      case 'postReligionAtheist':
        return l10n.postReligionAtheist;
      case 'postReligionBuddhist':
        return l10n.postReligionBuddhist;
      case 'postReligionCatholic':
        return l10n.postReligionCatholic;
      case 'postReligionChristian':
        return l10n.postReligionChristian;
      case 'postReligionHindu':
        return l10n.postReligionHindu;
      case 'postReligionJewish':
        return l10n.postReligionJewish;
      case 'postReligionMuslim':
        return l10n.postReligionMuslim;
      case 'postPoliticalLiberal':
        return l10n.postPoliticalLiberal;
      case 'postPoliticalModerate':
        return l10n.postPoliticalModerate;
      case 'postPoliticalConservative':
        return l10n.postPoliticalConservative;
      case 'postPoliticalNotPolitical':
        return l10n.postPoliticalNotPolitical;
      case 'postPoliticalOther':
        return l10n.postPoliticalOther;
      case 'postYes':
        return l10n.postYes;
      case 'postSometimes':
        return l10n.postSometimes;
      case 'postNo':
        return l10n.postNo;
      default:
        return key;
    }
  }

  Future<void> _saveAnswersAndComplete() async {
    if (_isSaving) return;
    if (!_hasMinimumRequiredData) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).postRequiredFieldsHint)),
        );
      }
      return;
    }
    setState(() => _isSaving = true);
    try {
      final answerService = ProfileAnswerService();
      var sortOrder = 0;
      for (var i = _kFirstQuestionIndex; i < _kCtaIndex; i++) {
        final answer = _answers[i];
        if (answer != null && answer.isNotEmpty) {
          await answerService.insertAnswer(
            profileId: widget.userId,
            content: answer,
            sortOrder: sortOrder++,
          );
        }
      }
      final displayName = _answers[_kNameStepIndex];
      if (displayName != null && displayName.isNotEmpty) {
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'full_name': displayName}),
          );
          await Supabase.instance.client.auth.refreshSession();
        } catch (_) {}
      }
      if (!kIsWeb) {
        const int photoSortBase = 200;
        final photoStorage = ProfilePhotoStorageService();
        for (var i = 0; i < _selectedPhotoPaths.length; i++) {
          final path = _selectedPhotoPaths[i];
          if (path == null || path.isEmpty) continue;
          try {
            final url = await photoStorage.uploadPhoto(
              userId: widget.userId,
              filePath: path,
              slotIndex: i,
            );
            await answerService.insertImageAnswer(
              profileId: widget.userId,
              content: url,
              sortOrder: photoSortBase + i,
            );
          } catch (e) {
            if (mounted) {
              debugPrint('Onboarding photo upload slot $i: $e');
            }
          }
        }
      }
      if (_locationLatLng != null) {
        try {
          await ProfileService().updateLocation(
            widget.userId,
            lat: _locationLatLng!.latitude,
            lng: _locationLatLng!.longitude,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      widget.onComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context).authError} $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goNext() {
    if (!_canProceed) return;
    final step = _steps[_currentIndex];
    if (step.type == _StepType.name) {
      final first = _firstNameController.text.trim();
      final last = _lastNameController.text.trim();
      if (first.isNotEmpty) {
        _answers[_kNameStepIndex] = last.isEmpty ? first : '$first $last';
      }
    } else if (step.type == _StepType.location) {
      final text = _textControllers[_currentIndex]?.text.trim() ?? '';
      if (text.isNotEmpty) _answers[_currentIndex] = text;
    }
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _saveAnswersAndComplete();
    }
  }

  bool get _canProceed {
    final step = _steps[_currentIndex];
    switch (step.type) {
      case _StepType.consent:
        return true;
      case _StepType.choice:
        return _answers[_currentIndex] != null;
      case _StepType.name:
        return _firstNameController.text.trim().isNotEmpty;
      case _StepType.text:
      case _StepType.location:
        final text = _textControllers[_currentIndex]?.text.trim() ?? '';
        return text.isNotEmpty;
      case _StepType.birthdate:
        return _parseBirthdate() != null;
      case _StepType.cta:
      case _StepType.photos:
        return true;
    }
  }

  /// الحد الأدنى للتقدّم: الاسم + تاريخ الميلاد (لا يُسمح بتخطي أو إنهاء بدونهما).
  bool get _hasMinimumRequiredData {
    final name = _firstNameController.text.trim();
    if (name.isEmpty) return false;
    return _parseBirthdate() != null;
  }

  /// يُرجع DateTime إذا كان التاريخ صالحاً، وإلا null.
  DateTime? _parseBirthdate() {
    final d = _dobDayController.text.trim();
    final m = _dobMonthController.text.trim();
    final y = _dobYearController.text.trim();
    if (d.isEmpty || m.isEmpty || y.isEmpty) return null;
    final day = int.tryParse(d);
    final month = int.tryParse(m);
    final year = int.tryParse(y);
    if (day == null || month == null || year == null) return null;
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    try {
      final dt = DateTime(year, month, day);
      if (dt.year != year || dt.month != month || dt.day != day) return null;
      if (dt.isAfter(DateTime.now())) return null;
      return dt;
    } catch (_) {
      return null;
    }
  }

  void _showBirthdateConfirmDialog(AppLocalizations l10n) {
    final dt = _parseBirthdate();
    if (dt == null) return;
    final now = DateTime.now();
    int age = now.year - dt.year;
    if (now.month < dt.month ||
        (now.month == dt.month && now.day < dt.day)) {
      age--;
    }
    final bornStr = '${dt.day}. ${_monthName(dt.month)} ${dt.year}';
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.postAgeConfirmTitle(age.toString()),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.postAgeConfirmBorn(bornStr),
              style: TextStyle(
                fontSize: 15,
                color: AppColors.darkBlack.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.postAgeConfirmMessage,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.darkBlack.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n.postEdit,
              style: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _answers[_kBirthdateStepIndex] =
                  '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
              _goNext();
            },
            child: Text(
              l10n.postConfirm,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.hingePurple,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const en = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return en[month - 1];
  }

  Future<void> _requestLocationAndUpdate() async {
    if (_locationRequested || !mounted) return;
    _locationRequested = true;
    setState(() => _locationLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        _locationRequested = false;
        setState(() => _locationLoading = false);
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          _locationRequested = false;
          setState(() => _locationLoading = false);
        }
        return;
      }
      // طلب الموقع الحالي بدقة عالية (الموقع الحقيقي وليس مخزناً)
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      _locationLatLng = latLng;
      // الانتظار قليلاً حتى تكون الخريطة جاهزة ثم نقل الكاميرا لموقعك
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      _mapController?.move(latLng, 15);
      final placemarks = await geo.placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      String area = '';
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        area = [p.locality, p.administrativeArea, p.subAdministrativeArea]
            .where((e) => e != null && e.isNotEmpty)
            .join(', ');
        if (area.isEmpty) area = p.country ?? '';
      }
      if (area.isNotEmpty) {
        _textControllers[_kLocationStepIndex]?.text = area;
        _answers[_kLocationStepIndex] = area;
      }
    } catch (_) {
      _locationRequested = false;
    }
    if (mounted) setState(() => _locationLoading = false);
  }


  void _onBack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else {
      _showSkipDialog();
    }
  }

  void _showSkipDialog() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.skipConfirmTitle,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.skipConfirmMessage),
            if (!_hasMinimumRequiredData) ...[
              const SizedBox(height: 12),
              Text(
                l10n.postRequiredFieldsHint,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.darkBlack.withValues(alpha: 0.8),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_hasMinimumRequiredData)
              GestureDetector(
                onTap: () {
                  Navigator.of(ctx).pop();
                  _saveAnswersAndComplete();
                },
                child: Text(
                  l10n.yesIWantToSkip,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppColors.darkBlack,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_hasMinimumRequiredData)
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _saveAnswersAndComplete();
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.hingePurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(l10n.finishNow),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.postEdit),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = _steps[_currentIndex];
    final total = _steps.length;
    final showVisibility = step.type == _StepType.choice;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.darkBlack),
            onPressed: _onBack,
          ),
          title: null,
          centerTitle: true,
          actions: [
            TextButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (!context.mounted) return;
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                l10n.signOut,
                style: const TextStyle(
                  color: AppColors.hingePurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgress(l10n, total),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step.type == _StepType.consent) _buildConsent(l10n),
                      if (step.type == _StepType.name) _buildName(l10n),
                      if (step.type == _StepType.choice)
                        _buildChoice(l10n, step),
                      if (step.type == _StepType.text) _buildText(l10n, step),
                      if (step.type == _StepType.birthdate)
                        _buildBirthdate(l10n),
                      if (step.type == _StepType.location)
                        _buildLocation(l10n),
                      if (step.type == _StepType.cta) _buildCta(l10n),
                      if (step.type == _StepType.photos) _buildPhotos(l10n),
                    ],
                  ),
                ),
              ),
              _buildFooter(l10n, showVisibility),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(AppLocalizations l10n, int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Row(
        children: [
          ...List.generate(total, (i) {
            if (i == _currentIndex) {
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.hingePurple,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i < _currentIndex
                      ? AppColors.hingePurple.withValues(alpha: 0.5)
                      : AppColors.darkBlack.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildConsent(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.hingePurple, size: 32),
              const SizedBox(width: 12),
              Text(
                l10n.postPrivacyTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.postPrivacyBody,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.darkBlack.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _goNext(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.darkBlack.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.postPrivacyAccept,
                style: const TextStyle(
                  color: AppColors.darkBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _goNext(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(color: AppColors.darkBlack.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n.postPrivacyPersonalise,
                style: const TextStyle(
                  color: AppColors.darkBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildName(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.postQName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _firstNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.postFirstNamePlaceholder,
              hintStyle: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.4),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.darkBlack.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.hingePurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _lastNameController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.postLastNamePlaceholder,
              hintStyle: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.4),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.darkBlack.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.hingePurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.postLastNameHint,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.darkBlack.withValues(alpha: 0.6),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: Text(
              l10n.postWhy,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.hingePurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoice(AppLocalizations l10n, _PostOnboardingStep step) {
    final options = step.optionKeys!
        .map((k) => _getL10n(k, l10n))
        .toList();
    final selected = _answers[_currentIndex];
    final hasPreferNot = step.optionKeys!.contains('postPreferNotToSay');

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getL10n(step.questionKey, l10n),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          ...options.map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () =>
                    setState(() => _answers[_currentIndex] = option),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.darkBlack,
                            ),
                          ),
                          if (hasPreferNot &&
                              option == l10n.postPreferNotToSay) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.preferNotToSayLimits,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.darkBlack.withValues(alpha: 0.6),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                l10n.learnMore,
                                style: const TextStyle(
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: option,
                      groupValue: selected,
                      onChanged: (v) =>
                          setState(() => _answers[_currentIndex] = v),
                      activeColor: AppColors.hingePurple,
                      fillColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return AppColors.hingePurple;
                        }
                        return AppColors.darkBlack.withValues(alpha: 0.3);
                      }),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildText(AppLocalizations l10n, _PostOnboardingStep step) {
    final controller = _textControllers[_currentIndex]!;
    final placeholder = step.placeholderKey != null
        ? _getL10n(step.placeholderKey!, l10n)
        : '';

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getL10n(step.questionKey, l10n),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.4),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.darkBlack.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.hingePurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthdate(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.postQDateOfBirth,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDobField(
                  controller: _dobDayController,
                  hint: l10n.postDobDay,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDobField(
                  controller: _dobMonthController,
                  hint: l10n.postDobMonth,
                  maxLength: 2,
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildDobField(
                  controller: _dobYearController,
                  hint: l10n.postDobYear,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              l10n.postDobHint,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkBlack.withValues(alpha: 0.6),
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobField({
    required TextEditingController controller,
    required String hint,
    required int maxLength,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => setState(() {}),
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.darkBlack.withValues(alpha: 0.4),
        ),
        counterText: '',
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.darkBlack.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: AppColors.hingePurple,
            width: 2,
          ),
        ),
      ),
      style: const TextStyle(fontSize: 18),
    );
  }

  Widget _buildLocation(AppLocalizations l10n) {
    final controller = _textControllers[_currentIndex]!;
    final center = _locationLatLng ?? const LatLng(52.52, 13.405);
    const double mapHeight = 220;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.postQLive,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.postLiveHint,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.75),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: mapHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _locationLatLng != null ? 15 : 12,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                      onMapReady: () {
                        if (!_locationRequested) _requestLocationAndUpdate();
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.swaply.swaply',
                      ),
                      if (_locationLatLng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _locationLatLng!,
                              width: 36,
                              height: 36,
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.blue,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white,
                      elevation: 2,
                      borderRadius: BorderRadius.circular(24),
                      child: IconButton(
                        icon: _locationLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        onPressed: _locationLoading
                            ? null
                            : () async {
                                _locationRequested = false;
                                await _requestLocationAndUpdate();
                              },
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x40000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 22,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.postZoomIntoArea,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
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
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.postEnterAddressPlaceholder,
              hintStyle: TextStyle(
                color: AppColors.darkBlack.withValues(alpha: 0.4),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.darkBlack.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.hingePurple,
                  width: 2,
                ),
              ),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCta(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fillOutProfileTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => _goNext(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.hingePurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l10n.fillOutProfileButton),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPhotoSlotTap(int index) async {
    final hasPhoto = _selectedPhotoPaths[index] != null &&
        _selectedPhotoPaths[index]!.isNotEmpty;
    if (hasPhoto) {
      final action = await showModalBottomSheet<String>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(AppLocalizations.of(context).changePhoto),
                onTap: () => Navigator.pop(ctx, 'change'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(AppLocalizations.of(context).removePhoto),
                onTap: () => Navigator.pop(ctx, 'remove'),
              ),
            ],
          ),
        ),
      );
      if (action == 'remove') {
        setState(() => _selectedPhotoPaths[index] = null);
      } else if (action == 'change') {
        await _pickImage(index);
      }
    } else {
      await _pickImage(index);
    }
  }

  Future<void> _pickImage(int index) async {
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
      if (picked != null && mounted) {
        setState(() => _selectedPhotoPaths[index] = picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    }
  }

  Widget _buildPhotos(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pickPhotosTitle,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.addFourToSixPhotos,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dragToReorder,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
            children: List.generate(6, (i) {
              final path = _selectedPhotoPaths[i];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _onPhotoSlotTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: i < 4
                            ? AppColors.hingePurple.withValues(alpha: 0.6)
                            : AppColors.darkBlack.withValues(alpha: 0.2),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: path != null && path.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              if (kIsWeb)
                                Image.network(path, fit: BoxFit.cover)
                              else
                                Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedPhotoPaths[i] = null);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: AppColors.darkBlack.withValues(alpha: 0.4),
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline,
                  size: 20, color: AppColors.darkBlack.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                l10n.notSureWhichPhotos,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.darkBlack.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: Text(
                l10n.seeWhatWorks,
                style: const TextStyle(
                  fontSize: 14,
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n, bool showVisibility) {
    final step = _steps[_currentIndex];
    final isChoice = step.type == _StepType.choice;
    final visible = _currentIndex < _visibleOnProfile.length
        ? _visibleOnProfile[_currentIndex]
        : true;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Row(
        children: [
          if (isChoice && showVisibility)
            Expanded(
              child: InkWell(
                onTap: () => setState(() {
                  _visibleOnProfile[_currentIndex] = !visible;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: visible,
                        onChanged: (v) => setState(() {
                          _visibleOnProfile[_currentIndex] = v ?? true;
                        }),
                        activeColor: AppColors.hingePurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      visible
                          ? l10n.visibleOnProfile
                          : l10n.hiddenOnProfile,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkBlack,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (isChoice && showVisibility) const SizedBox(width: 16),
          Material(
            color: _canProceed
                ? AppColors.hingePurple
                : AppColors.darkBlack.withValues(alpha: 0.25),
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _isSaving
                    ? null
                    : (_canProceed
                        ? () {
                            if (step.type == _StepType.birthdate) {
                              _showBirthdateConfirmDialog(l10n);
                            } else {
                              _goNext();
                            }
                          }
                        : null),
              child: const SizedBox(
                width: 56,
                height: 56,
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
