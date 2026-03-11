import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

import '../app_colors.dart';
import '../generated/l10n/app_localizations.dart';
import '../services/user_settings_service.dart';
import '../widgets/verified_badge.dart';

/// تدفق التحقق بالفيديو: مقدمة → قائمة التحقق → تعليمات → تسجيل → مراجعة → نجاح.
/// يُفتح من البروفايل (أيقونة التوثيق) أو من الإعدادات (التحقق بالـ selfie).
class VerificationFlowScreen extends StatefulWidget {
  const VerificationFlowScreen({super.key});

  @override
  State<VerificationFlowScreen> createState() => _VerificationFlowScreenState();
}

class _VerificationFlowScreenState extends State<VerificationFlowScreen>
    with SingleTickerProviderStateMixin {
  final UserSettingsService _userSettings = UserSettingsService();
  final ImagePicker _picker = ImagePicker();

  AnimationController? _successAnimController;
  Animation<double>? _successFadeAnim;
  Animation<double>? _successScaleAnim;

  int _step = 0;
  bool _loading = false;
  String? _statusMessage;
  bool _alreadySubmitted = false;
  File? _recordedVideoFile;
  VideoPlayerController? _previewController;
  VideoPlayerController? _explanationVideoController;
  bool _explanationVideoError = false;
  CameraController? _recordingCameraController;
  bool _isRecordingVideo = false;
  bool _cameraInitError = false;

  static const int _stepIntro = 0;

  /// مسار الفيديو الشرحي (بدون مسافات لضمان التحميل على iOS).
  static const String _kExplanationVideoAsset = 'assets/videos/0309_1.mp4';

  /// خطوة التعليمات (سجّل فيديو لوجهك) تظهر قبل قائمة "قبل البدء".
  static const int _stepInstructions = 1;
  static const int _stepChecklist = 2;
  static const int _stepRecording = 3;
  static const int _stepReview = 4;
  static const int _stepSuccess = 5;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _successFadeAnim = CurvedAnimation(
      parent: _successAnimController!,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _successScaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _successAnimController!,
        curve: const Interval(0.05, 0.6, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _successAnimController?.dispose();
    _previewController?.dispose();
    _explanationVideoController?.dispose();
    _recordingCameraController?.dispose();
    super.dispose();
  }

  Future<void> _initRecordingCameraIfNeeded() async {
    if (_recordingCameraController != null || _cameraInitError) return;
    if (!mounted) return;
    final camStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!camStatus.isGranted || !micStatus.isGranted) {
      if (mounted) _showCameraPermissionDialog();
      setState(() => _cameraInitError = true);
      return;
    }
    try {
      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: true,
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _recordingCameraController = controller;
      setState(() {});
    } catch (e) {
      debugPrint('VerificationFlow: camera init error: $e');
      if (mounted) {
        _cameraInitError = true;
        setState(() {});
      }
    }
  }

  Future<void> _toggleRecording() async {
    final ctrl = _recordingCameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (_isRecordingVideo) {
      setState(() => _loading = true);
      try {
        final xfile = await ctrl.stopVideoRecording();
        if (mounted && xfile.path.isNotEmpty) {
          _previewController?.dispose();
          _previewController = VideoPlayerController.file(File(xfile.path))
            ..initialize().then((_) {
              if (mounted) setState(() {});
            });
          _previewController?.play();
          _previewController?.setLooping(true);
          setState(() {
            _recordedVideoFile = File(xfile.path);
            _loading = false;
            _isRecordingVideo = false;
            _step = _stepReview;
          });
        } else {
          if (mounted) setState(() => _loading = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).error}: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      try {
        await ctrl.startVideoRecording();
        if (mounted) setState(() => _isRecordingVideo = true);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${AppLocalizations.of(context).error}: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _initExplanationVideoIfNeeded() async {
    if (_explanationVideoController != null || _explanationVideoError) return;

    VideoPlayerController? controller;

    // 1) محاولة التحميل من asset مباشرة
    try {
      controller = VideoPlayerController.asset(_kExplanationVideoAsset);
      _explanationVideoController = controller;
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('فيديو الشرح'),
      );
    } catch (e) {
      debugPrint('VerificationFlow: asset video failed: $e');
      _explanationVideoController?.dispose();
      _explanationVideoController = null;
      controller = null;
    }

    // 2) إن فشل: نسخ الـ asset لملف مؤقت والتشغيل من الملف (غالباً يعمل على iOS)
    if (controller == null && mounted) {
      try {
        final data = await rootBundle.load(_kExplanationVideoAsset);
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/verification_intro.mp4');
        await file.writeAsBytes(data.buffer.asUint8List());
        controller = VideoPlayerController.file(file);
        _explanationVideoController = controller;
        await controller.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw TimeoutException('فيديو الشرح'),
        );
      } catch (e2) {
        debugPrint('VerificationFlow: file video failed: $e2');
        _explanationVideoController?.dispose();
        _explanationVideoController = null;
        if (mounted) {
          _explanationVideoError = true;
          setState(() {});
        }
        return;
      }
    }

    if (!mounted || controller == null) return;
    try {
      await controller.play();
      controller.setLooping(true);
      setState(() {});
    } catch (e) {
      if (mounted) {
        _explanationVideoError = true;
        _explanationVideoController?.dispose();
        _explanationVideoController = null;
        setState(() {});
      }
    }
  }

  Future<void> _loadStatus() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final status = await _userSettings.getSelfieVerificationStatus(userId);
    if (mounted) {
      setState(() {
        _alreadySubmitted = status == 'submitted' || status == 'verified';
        _statusMessage = status;
      });
    }
  }

  bool get _isArabic => Localizations.localeOf(context).languageCode == 'ar';

  void _nextStep() {
    if (_step < _stepSuccess) {
      final nextStep = _step + 1;
      setState(() {
        _step = nextStep;
        if (nextStep == _stepRecording) _cameraInitError = false;
      });
    }
  }

  void _prevStep() {
    if (_step > 0) {
      if (_step == _stepRecording) {
        _recordingCameraController?.dispose();
        _recordingCameraController = null;
        _isRecordingVideo = false;
      }
      setState(() => _step--);
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step);
  }

  Future<void> _startRecording() async {
    if (!mounted) return;
    final status = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();
    if (!status.isGranted || !micStatus.isGranted) {
      if (mounted) _showCameraPermissionDialog();
      return;
    }

    setState(() => _loading = true);
    try {
      final xfile = await _picker.pickVideo(source: ImageSource.camera);
      if (xfile != null && mounted) {
        _previewController?.dispose();
        _previewController = VideoPlayerController.file(File(xfile.path))
          ..initialize().then((_) {
            if (mounted) setState(() {});
          });
        setState(() {
          _recordedVideoFile = File(xfile.path);
          _loading = false;
          _step = _stepReview;
        });
        _previewController?.play();
        _previewController?.setLooping(true);
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showCameraPermissionDialog() {
    final isAr = _isArabic;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isAr ? 'إذن الكاميرا' : 'Camera access',
          textAlign: isAr ? TextAlign.right : TextAlign.left,
        ),
        content: Text(
          isAr
              ? 'يحتاج التطبيق إلى الكاميرا والميكروفون لتسجيل فيديو التوثيق. يُرجى السماح من الإعدادات ثم المحاولة مرة أخرى.'
              : 'Swaply needs camera and microphone to record your verification video. Please allow access in settings and try again.',
          textAlign: isAr ? TextAlign.right : TextAlign.left,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            child: Text(isAr ? 'فتح الإعدادات' : 'Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitVideo() async {
    if (_recordedVideoFile == null) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      await _userSettings.submitVerificationVideo(userId, _recordedVideoFile!);
      if (mounted) {
        _previewController?.dispose();
        _previewController = null;
        setState(() {
          _loading = false;
          _recordedVideoFile = null;
          _step = _stepSuccess;
          _alreadySubmitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).error}: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_alreadySubmitted && _step == 0) {
      return _buildStatusScreen();
    }
    const Color beigeBg = Color(0xFFF5F2ED);
    const Color darkBg = Color(0xFF0D0D0F);
    final bool useIntroStyle = _step == 0;
    final bool useInstructionsStyle = _step == _stepInstructions;
    final bool useChecklistDarkStyle = _step == _stepChecklist;
    final bool useRecordingFullScreen = _step == _stepRecording;
    final bool useSuccessStyle = _step == _stepSuccess;
    final bool hideAppBar =
        useIntroStyle ||
        useChecklistDarkStyle ||
        useRecordingFullScreen ||
        useSuccessStyle;
    return Scaffold(
      backgroundColor: useRecordingFullScreen
          ? Colors.black
          : (useChecklistDarkStyle
                ? darkBg
                : (useSuccessStyle
                      ? const Color(0xFFF5F5F5)
                      : (useIntroStyle || useInstructionsStyle
                            ? beigeBg
                            : Colors.white))),
      appBar: hideAppBar
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.darkBlack,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_step > 0) {
                    _prevStep();
                  } else {
                    Navigator.of(context).pop();
                  }
                },
              ),
              title: Text(
                _stepTitle(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.darkBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.hingePurple),
              )
            : _buildStepContent(),
      ),
    );
  }

  String _stepTitle() {
    if (_isArabic) {
      switch (_step) {
        case _stepChecklist:
          return 'قبل البدء تأكد من';
        case _stepInstructions:
          return 'سجّل فيديو لوجهك';
        case _stepRecording:
          return 'تسجيل الفيديو';
        case _stepReview:
          return 'تأكد مرة أخرى';
        case _stepSuccess:
          return 'تم الإرسال';
        default:
          return '';
      }
    }
    switch (_step) {
      case _stepChecklist:
        return 'Before you start, make sure:';
      case _stepInstructions:
        return 'Record a video of your face';
      case _stepRecording:
        return 'Record video';
      case _stepReview:
        return 'Double check to make sure';
      case _stepSuccess:
        return 'Done';
      default:
        return '';
    }
  }

  Widget _buildStatusScreen() {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.darkBlack,
        elevation: 0,
        title: Text(
          l10n.selfieVerification,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.darkBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _statusMessage == 'verified'
                ? const SizedBox(
                    width: 80,
                    height: 80,
                    child: VerifiedBadge(size: 80),
                  )
                : Icon(Icons.schedule, size: 80, color: AppColors.hingePurple),
            const SizedBox(height: 16),
            Text(
              _statusMessage == 'verified'
                  ? (_isArabic
                        ? 'تم التحقق من بروفايلك.'
                        : 'Your profile is verified.')
                  : (_isArabic
                        ? 'تم إرسال فيديو التحقق. سنراجعه ونعلمك قريباً.'
                        : 'Your verification video has been submitted. We will review it and let you know.'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.darkBlack.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusMessage == 'verified'
                  ? (_isArabic ? 'موثّق' : 'Verified')
                  : (_isArabic ? 'بانتظار المراجعة' : 'Pending verification'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.hingePurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_step) {
      case _stepIntro:
        return _buildIntro();
      case _stepChecklist:
        return _buildChecklist();
      case _stepInstructions:
        return _buildInstructions();
      case _stepRecording:
        return _buildRecording();
      case _stepReview:
        return _buildReview();
      case _stepSuccess:
        return _buildSuccess();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIntro() {
    final isAr = _isArabic;
    const Color beigeBg = Color(0xFFF5F2ED);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final imageHeight = (screenHeight * 0.48).clamp(260.0, 380.0);

    return Stack(
      children: [
        Container(color: beigeBg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: MediaQuery.paddingOf(context).top + 12),
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipPath(
                    clipper: _IntroImageClipper(),
                    child: Image.asset(
                      'assets/0.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.hingePurple.withValues(alpha: 0.15),
                        child: Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppColors.hingePurple.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.darkBlack,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: ClipOval(
                            child: Image.asset(
                              kVerificationBadgeAsset,
                              fit: BoxFit.cover,
                              width: 56,
                              height: 56,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.verified,
                                size: 56,
                                color: Color(0xFF1DA1F2),
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
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                isAr
                    ? 'البروفايلات الموثّقة تبني الثقة'
                    : 'Verified profiles create trust',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBlack,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isAr
                    ? 'البروفايلات الموثّقة تحصل على إعجابات أكثر وتساعد الآخرين على الشعور بالأمان.'
                    : 'Verified profiles receive 2x more Likes and allow others to feel safe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.darkBlack.withValues(alpha: 0.75),
                  height: 1.4,
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _nextStep(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.darkBlack,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isAr ? 'توثيق بروفايلي' : 'Verify my profile',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          right: 12,
          child: Material(
            color: Colors.grey.shade200,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.close, size: 22, color: AppColors.darkBlack),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklist() {
    final isAr = _isArabic;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initExplanationVideoIfNeeded(),
    );

    const Color darkBg = Color(0xFF0D0D0F);
    const Color modalBg = Color(0xFF1C1C1E);
    final topPadding = MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Container(color: darkBg),
        // Back arrow top-left
        Positioned(
          top: topPadding + 8,
          left: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _prevStep(),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
              ),
            ),
          ),
        ),
        // Video preview top-right (like second image)
        Positioned(
          top: topPadding + 8,
          right: 12,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 130,
              child: _explanationVideoError
                  ? Container(
                      color: modalBg,
                      child: const Center(
                        child: Icon(
                          Icons.videocam_off_outlined,
                          size: 32,
                          color: Colors.white54,
                        ),
                      ),
                    )
                  : _explanationVideoController != null &&
                        _explanationVideoController!.value.isInitialized
                  ? FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _explanationVideoController!.value.size.width,
                        height: _explanationVideoController!.value.size.height,
                        child: VideoPlayer(_explanationVideoController!),
                      ),
                    )
                  : Container(
                      color: modalBg,
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
        // Bottom sheet style modal
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: modalBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 40),
                        Expanded(
                          child: Text(
                            isAr
                                ? 'قبل البدء، تأكد من:'
                                : 'Before you start, make sure:',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.close,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _checkItemDark(
                      icon: Icons.face_retouching_natural,
                      text: isAr
                          ? 'وجهك واضح في الإطار'
                          : 'Your face is clearly visible',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _checkItemDark(
                      icon: Icons.person_outline,
                      text: isAr
                          ? 'لا يوجد شخص آخر في اللقطة'
                          : "There's no one else in the shot",
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _checkItemDark(
                      icon: Icons.wb_sunny_outlined,
                      text: isAr ? 'الإضاءة كافية' : "There's enough light",
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _nextStep(),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.darkBlack,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          isAr ? 'متابعة' : 'Continue',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }

  Widget _checkItemDark({required IconData icon, required String text}) {
    final isAr = _isArabic;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isAr) ...[
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: isAr ? TextAlign.right : TextAlign.left,
          ),
        ),
        if (isAr) ...[
          const SizedBox(width: 14),
          Icon(icon, size: 24, color: Colors.white),
        ],
      ],
    );
  }

  Widget _buildInstructions() {
    final isAr = _isArabic;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initExplanationVideoIfNeeded(),
    );
    final videoReady =
        _explanationVideoController != null &&
        _explanationVideoController!.value.isInitialized;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'سجّل فيديو لوجهك' : 'Record a video of your face',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isAr
                ? 'أدر رأسك من اليسار إلى اليمين وحافظ على نظرك نحو الشاشة.'
                : 'Just turn your head from left to right and keep your eyes on the screen.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.darkBlack.withValues(alpha: 0.75),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: AppColors.darkWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.darkBlack.withValues(alpha: 0.08),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: videoReady
                ? FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _explanationVideoController!.value.size.width,
                      height: _explanationVideoController!.value.size.height,
                      child: VideoPlayer(_explanationVideoController!),
                    ),
                  )
                : Center(
                    child: _explanationVideoError
                        ? Icon(
                            Icons.videocam_off_outlined,
                            size: 64,
                            color: AppColors.hingePurple.withValues(alpha: 0.5),
                          )
                        : const SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.hingePurple,
                            ),
                          ),
                  ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isAr
                      ? 'لا تقلق، الفيديو لن يُعرض على بروفايلك أبداً.'
                      : "Don't worry, the video will never be displayed on your profile.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton.icon(
              onPressed: () => _nextStep(),
              icon: Icon(
                _isArabic ? Icons.arrow_back : Icons.arrow_forward,
                size: 20,
              ),
              label: Text(isAr ? 'التالي' : 'Next'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.darkBlack,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecording() {
    final isAr = _isArabic;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _initRecordingCameraIfNeeded(),
    );

    final cameraReady =
        _recordingCameraController != null &&
        _recordingCameraController!.value.isInitialized;

    if (_cameraInitError) {
      return _buildRecordingFallback(isAr: isAr);
    }
    if (!cameraReady) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isAr ? 'جاري تحضير الكاميرا...' : 'Preparing camera...',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    final ctrl = _recordingCameraController!;
    final size = MediaQuery.sizeOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: CameraPreview(ctrl),
          ),
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 8,
          left: 12,
          child: Material(
            color: Colors.black45,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: _isRecordingVideo ? null : () => _prevStep(),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
              ),
            ),
          ),
        ),
        if (_explanationVideoController != null &&
            _explanationVideoController!.value.isInitialized)
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            right: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 96,
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _explanationVideoController!.value.size.width,
                    height: _explanationVideoController!.value.size.height,
                    child: VideoPlayer(_explanationVideoController!),
                  ),
                ),
              ),
            ),
          ),
        Positioned(
          left: 24,
          right: 24,
          bottom: MediaQuery.paddingOf(context).bottom + 100,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isAr
                  ? 'ابدأ تسجيل الفيديو وكرّر الحركة من جانب لآخر'
                  : 'Start recording the video and repeat the movement from side to side',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.paddingOf(context).bottom + 24,
          child: Center(
            child: GestureDetector(
              onTap: _loading ? null : _toggleRecording,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _isRecordingVideo ? Colors.red : Colors.black,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _isRecordingVideo
                      ? const Icon(Icons.stop, color: Colors.white, size: 40)
                      : Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingFallback({required bool isAr}) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_cameraInitError)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  isAr
                      ? 'يُرجى السماح للكاميرا والميكروفون من الإعدادات.'
                      : 'Please allow camera and microphone in settings.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                isAr
                    ? 'ابدأ تسجيل الفيديو وكرّر الحركة من جانب لآخر'
                    : 'Start recording the video and repeat the movement from side to side',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _loading ? null : _startRecording,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.black,
                ),
                child: const Center(
                  child: Icon(Icons.videocam, color: Colors.white, size: 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReview() {
    final isAr = _isArabic;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isAr ? 'تأكد مرة أخرى' : 'Double check to make sure',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.darkBlack,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAr
                ? 'لتوثيق بروفايلك، أدر رأسك من جهة لأخرى وتأكد أن وجهك واضح.'
                : 'To verify your profile, turn your head from one side to the other and make sure your face is clearly visible.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.darkBlack.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          if (_previewController != null &&
              _previewController!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _previewController!.value.aspectRatio,
                child: VideoPlayer(_previewController!),
              ),
            )
          else
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.darkWhite,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.hingePurple),
              ),
            ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _loading ? null : _submitVideo,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkBlack,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(isAr ? 'تأكيد' : 'Validate'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loading ? null : () => _goToStep(_stepRecording),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkBlack,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(
                color: AppColors.darkBlack.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(isAr ? 'تسجيل مرة أخرى' : 'Record again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    final isAr = _isArabic;
    if (_step == _stepSuccess &&
        _successAnimController != null &&
        !_successAnimController!.isAnimating &&
        !_successAnimController!.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _successAnimController?.forward();
      });
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        FadeTransition(
          opacity: _successFadeAnim ?? const AlwaysStoppedAnimation(1.0),
          child: const CustomPaint(painter: _SuccessBlobPainter()),
        ),
        FadeTransition(
          opacity: _successFadeAnim ?? const AlwaysStoppedAnimation(1.0),
          child: ScaleTransition(
            scale: _successScaleAnim ?? const AlwaysStoppedAnimation(1.0),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isAr ? 'ممتاز' : 'Perfect',
                      style: GoogleFonts.montserrat(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkBlack,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAr
                          ? 'سنعلمك فور التحقق من بروفايلك.'
                          : "We'll let you know as soon as your profile is verified.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        color: AppColors.darkBlack.withValues(alpha: 0.85),
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 48),
                    FadeTransition(
                      opacity:
                          _successFadeAnim ?? const AlwaysStoppedAnimation(1.0),
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.darkBlack,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isAr ? 'إغلاق' : 'Close',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
      ],
    );
  }
}

/// خلفية بأشكال عضوية أبيض وأسود للشاشة الناجحة.
class _SuccessBlobPainter extends CustomPainter {
  const _SuccessBlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final lightGray = const Color(0xFFE8E8E8);
    final midGray = const Color(0xFFB8B8B8);
    final darkGray = const Color(0xFF505050);
    const bg = Color(0xFFF5F5F5);

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = bg,
    );

    void drawBlob(Path path, Color color) {
      canvas.drawPath(path, Paint()..color = color);
    }

    final blob1 = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 0.2,
        size.width * 0.7,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 1.1,
        size.height * 0.6,
        size.width * 0.6,
        size.height,
      )
      ..quadraticBezierTo(
        size.width * 0.2,
        size.height * 1.05,
        0,
        size.height * 0.75,
      )
      ..close();
    drawBlob(blob1, lightGray);

    final blob2 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.25,
        size.width,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 1.05,
        size.height * 0.85,
        size.width * 0.7,
        size.height,
      )
      ..lineTo(size.width * 0.3, size.height)
      ..quadraticBezierTo(
        -size.width * 0.1,
        size.height * 0.7,
        size.width * 0.3,
        0,
      )
      ..close();
    drawBlob(blob2, midGray);

    final blob3 = Path()
      ..moveTo(size.width * 0.75, 0)
      ..quadraticBezierTo(
        size.width * 1.1,
        size.height * 0.3,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.5, size.height)
      ..quadraticBezierTo(
        size.width * 0.6,
        size.height * 0.4,
        size.width * 0.6,
        0,
      )
      ..close();
    drawBlob(blob3, darkGray);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// قصة عضوية للصورة: تقص من اليسار والأسفل بشكل منحنٍ (قلب/سحابة) لظهور الخلفية البيج.
class _IntroImageClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width * 0.65, size.height);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.75,
      size.width * 0.08,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      -size.width * 0.05,
      size.height * 0.2,
      0,
      size.height * 0.35,
    );
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
