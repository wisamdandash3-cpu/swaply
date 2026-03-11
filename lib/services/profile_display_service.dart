import '../models/profile_answer.dart';
import 'profile_answer_service.dart';
import 'user_settings_service.dart';

/// استخراج اسم وعرض صورة المستخدم من profile_answers (للعرض في الدردشة).
/// يتضمّن أيضاً حالة التحقق بالـ selfie (شارة التوثيق).
class ProfileDisplayService {
  ProfileDisplayService({
    ProfileAnswerService? answerService,
    UserSettingsService? userSettings,
  })  : _answerService = answerService ?? ProfileAnswerService(),
        _userSettings = userSettings ?? UserSettingsService();

  final ProfileAnswerService _answerService;
  final UserSettingsService _userSettings;

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// يُرجع (اسم العرض، رابط أول صورة بروفايل، هل الحساب موثّق).
  /// صورة البروفايل: نفس منطق شاشة البروفايل — أول صورة في نطاق sort_order 200–205، وإلا أول صورة بأي ترتيب.
  Future<({String displayName, String? avatarUrl, bool isVerified})> getDisplayInfo(
    String profileId,
  ) async {
    if (!_uuidRegex.hasMatch(profileId)) {
      return (displayName: 'User', avatarUrl: null, isVerified: false);
    }
    try {
      final answers = await _answerService.getByProfileId(profileId);
      final verificationStatus = await _userSettings.getSelfieVerificationStatus(profileId);
      final isVerified = verificationStatus == 'verified';
      String displayName = 'User';
      String? avatarUrl;

      final sorted = List<ProfileAnswer>.from(answers)
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      // أولاً: صورة البروفايل الرئيسية (نفس نطاق 200–205 المستخدم في شاشة البروفايل)
      final profilePhotoSlots = sorted
          .where((a) =>
              a.isImage &&
              a.content.trim().isNotEmpty &&
              a.sortOrder >= 200 &&
              a.sortOrder < 206)
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (profilePhotoSlots.isNotEmpty) {
        avatarUrl = profilePhotoSlots.first.content.trim();
      }
      if (avatarUrl == null) {
        for (final a in sorted) {
          if (a.isImage && a.content.trim().isNotEmpty) {
            avatarUrl = a.content.trim();
            break;
          }
        }
      }
      for (final a in sorted) {
        if (!a.isImage &&
            displayName == 'User' &&
            a.content.trim().length < 50 &&
            !_looksLikeDate(a.content.trim())) {
          displayName = a.content.trim();
          break;
        }
      }
      return (displayName: displayName, avatarUrl: avatarUrl, isVerified: isVerified);
    } catch (_) {
      return (displayName: 'User', avatarUrl: null, isVerified: false);
    }
  }

  static bool _looksLikeDate(String s) {
    final t = s.trim();
    if (t.length < 8) return false;
    return RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(t) ||
        RegExp(r'^\d{1,2}/\d{1,2}/\d{4}').hasMatch(t);
  }
}
