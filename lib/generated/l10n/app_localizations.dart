import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_af.dart';
import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_bg.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_ca.dart';
import 'app_localizations_cs.dart';
import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_el.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_eu.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fi.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gl.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_ha.dart';
import 'app_localizations_he.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_hr.dart';
import 'app_localizations_hu.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ig.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_kn.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_ml.dart';
import 'app_localizations_mr.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_no.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ro.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sk.dart';
import 'app_localizations_sr.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_sw.dart';
import 'app_localizations_ta.dart';
import 'app_localizations_te.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tl.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_yo.dart';
import 'app_localizations_zh.dart';
import 'app_localizations_zu.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('af'),
    Locale('am'),
    Locale('ar'),
    Locale('bg'),
    Locale('bn'),
    Locale('ca'),
    Locale('cs'),
    Locale('da'),
    Locale('de'),
    Locale('el'),
    Locale('en'),
    Locale('es'),
    Locale('eu'),
    Locale('fa'),
    Locale('fi'),
    Locale('fr'),
    Locale('gl'),
    Locale('gu'),
    Locale('ha'),
    Locale('he'),
    Locale('hi'),
    Locale('hr'),
    Locale('hu'),
    Locale('id'),
    Locale('ig'),
    Locale('it'),
    Locale('ja'),
    Locale('kn'),
    Locale('ko'),
    Locale('ml'),
    Locale('mr'),
    Locale('ms'),
    Locale('nl'),
    Locale('no'),
    Locale('pa'),
    Locale('pl'),
    Locale('pt'),
    Locale('ro'),
    Locale('ru'),
    Locale('sk'),
    Locale('sr'),
    Locale('sv'),
    Locale('sw'),
    Locale('ta'),
    Locale('te'),
    Locale('th'),
    Locale('tl'),
    Locale('tr'),
    Locale('uk'),
    Locale('ur'),
    Locale('vi'),
    Locale('yo'),
    Locale('zh'),
    Locale('zu'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Swaply'**
  String get appTitle;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @onboardingQuestion1.
  ///
  /// In en, this message translates to:
  /// **'What are you looking for?'**
  String get onboardingQuestion1;

  /// No description provided for @onboardingQuestion2.
  ///
  /// In en, this message translates to:
  /// **'How would you describe yourself?'**
  String get onboardingQuestion2;

  /// No description provided for @onboardingQuestion3.
  ///
  /// In en, this message translates to:
  /// **'What matters most to you?'**
  String get onboardingQuestion3;

  /// No description provided for @onboardingQ1Relationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get onboardingQ1Relationship;

  /// No description provided for @onboardingQ1Friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get onboardingQ1Friends;

  /// No description provided for @onboardingQ1NotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get onboardingQ1NotSure;

  /// No description provided for @onboardingQ2Adventurous.
  ///
  /// In en, this message translates to:
  /// **'Adventurous'**
  String get onboardingQ2Adventurous;

  /// No description provided for @onboardingQ2Thoughtful.
  ///
  /// In en, this message translates to:
  /// **'Thoughtful'**
  String get onboardingQ2Thoughtful;

  /// No description provided for @onboardingQ2Creative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get onboardingQ2Creative;

  /// No description provided for @onboardingQ2EasyGoing.
  ///
  /// In en, this message translates to:
  /// **'Easy-going'**
  String get onboardingQ2EasyGoing;

  /// No description provided for @onboardingQ3Honesty.
  ///
  /// In en, this message translates to:
  /// **'Honesty'**
  String get onboardingQ3Honesty;

  /// No description provided for @onboardingQ3Humor.
  ///
  /// In en, this message translates to:
  /// **'Humor'**
  String get onboardingQ3Humor;

  /// No description provided for @onboardingQ3Kindness.
  ///
  /// In en, this message translates to:
  /// **'Kindness'**
  String get onboardingQ3Kindness;

  /// No description provided for @onboardingQ3Ambition.
  ///
  /// In en, this message translates to:
  /// **'Ambition'**
  String get onboardingQ3Ambition;

  /// No description provided for @onboardingQuestion4.
  ///
  /// In en, this message translates to:
  /// **'Do you have children?'**
  String get onboardingQuestion4;

  /// No description provided for @onboardingQ4No.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get onboardingQ4No;

  /// No description provided for @onboardingQ4YesWithMe.
  ///
  /// In en, this message translates to:
  /// **'Yes, they live with me'**
  String get onboardingQ4YesWithMe;

  /// No description provided for @onboardingQ4YesNotWithMe.
  ///
  /// In en, this message translates to:
  /// **'Yes, they don\'t live with me'**
  String get onboardingQ4YesNotWithMe;

  /// No description provided for @onboardingQ4PreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get onboardingQ4PreferNot;

  /// No description provided for @onboardingQuestion5.
  ///
  /// In en, this message translates to:
  /// **'Are you a morning or night person?'**
  String get onboardingQuestion5;

  /// No description provided for @onboardingQ5Morning.
  ///
  /// In en, this message translates to:
  /// **'Morning person'**
  String get onboardingQ5Morning;

  /// No description provided for @onboardingQ5Night.
  ///
  /// In en, this message translates to:
  /// **'Night owl'**
  String get onboardingQ5Night;

  /// No description provided for @onboardingQ5Both.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get onboardingQ5Both;

  /// No description provided for @onboardingQuestion6.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke?'**
  String get onboardingQuestion6;

  /// No description provided for @onboardingQ6No.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get onboardingQ6No;

  /// No description provided for @onboardingQ6Yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get onboardingQ6Yes;

  /// No description provided for @onboardingQ6Sometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get onboardingQ6Sometimes;

  /// No description provided for @onboardingQuestion7.
  ///
  /// In en, this message translates to:
  /// **'What\'s your diet?'**
  String get onboardingQuestion7;

  /// No description provided for @onboardingQ7Regular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get onboardingQ7Regular;

  /// No description provided for @onboardingQ7Vegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get onboardingQ7Vegetarian;

  /// No description provided for @onboardingQ7Halal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get onboardingQ7Halal;

  /// No description provided for @onboardingQ7Vegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get onboardingQ7Vegan;

  /// No description provided for @onboardingQuestion8.
  ///
  /// In en, this message translates to:
  /// **'What\'s your relationship status?'**
  String get onboardingQuestion8;

  /// No description provided for @onboardingQ8Single.
  ///
  /// In en, this message translates to:
  /// **'Single'**
  String get onboardingQ8Single;

  /// No description provided for @onboardingQ8Divorced.
  ///
  /// In en, this message translates to:
  /// **'Divorced'**
  String get onboardingQ8Divorced;

  /// No description provided for @onboardingQ8Widowed.
  ///
  /// In en, this message translates to:
  /// **'Widowed'**
  String get onboardingQ8Widowed;

  /// No description provided for @onboardingQ8PreferNot.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get onboardingQ8PreferNot;

  /// No description provided for @onboardingQuestion9.
  ///
  /// In en, this message translates to:
  /// **'How do you like to spend your weekend?'**
  String get onboardingQuestion9;

  /// No description provided for @onboardingQ9Outdoors.
  ///
  /// In en, this message translates to:
  /// **'Outdoors'**
  String get onboardingQ9Outdoors;

  /// No description provided for @onboardingQ9AtHome.
  ///
  /// In en, this message translates to:
  /// **'At home'**
  String get onboardingQ9AtHome;

  /// No description provided for @onboardingQ9WithFriends.
  ///
  /// In en, this message translates to:
  /// **'With friends'**
  String get onboardingQ9WithFriends;

  /// No description provided for @onboardingQ9NewThings.
  ///
  /// In en, this message translates to:
  /// **'Trying something new'**
  String get onboardingQ9NewThings;

  /// No description provided for @onboardingQuestion10.
  ///
  /// In en, this message translates to:
  /// **'Favorite type of movie or series?'**
  String get onboardingQuestion10;

  /// No description provided for @onboardingQ10Comedy.
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get onboardingQ10Comedy;

  /// No description provided for @onboardingQ10Drama.
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get onboardingQ10Drama;

  /// No description provided for @onboardingQ10Action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get onboardingQ10Action;

  /// No description provided for @onboardingQ10Romance.
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get onboardingQ10Romance;

  /// No description provided for @onboardingQ10Documentary.
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get onboardingQ10Documentary;

  /// No description provided for @onboardingQuestion11.
  ///
  /// In en, this message translates to:
  /// **'One word that describes your personality?'**
  String get onboardingQuestion11;

  /// No description provided for @onboardingQ11Fun.
  ///
  /// In en, this message translates to:
  /// **'Fun'**
  String get onboardingQ11Fun;

  /// No description provided for @onboardingQ11Calm.
  ///
  /// In en, this message translates to:
  /// **'Calm'**
  String get onboardingQ11Calm;

  /// No description provided for @onboardingQ11Ambitious.
  ///
  /// In en, this message translates to:
  /// **'Ambitious'**
  String get onboardingQ11Ambitious;

  /// No description provided for @onboardingQ11Creative.
  ///
  /// In en, this message translates to:
  /// **'Creative'**
  String get onboardingQ11Creative;

  /// No description provided for @onboardingQ11Kind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get onboardingQ11Kind;

  /// No description provided for @onboardingQuestion12.
  ///
  /// In en, this message translates to:
  /// **'Where do you prefer to shop?'**
  String get onboardingQuestion12;

  /// No description provided for @onboardingQ12Local.
  ///
  /// In en, this message translates to:
  /// **'Local markets'**
  String get onboardingQ12Local;

  /// No description provided for @onboardingQ12Malls.
  ///
  /// In en, this message translates to:
  /// **'Malls'**
  String get onboardingQ12Malls;

  /// No description provided for @onboardingQ12Online.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get onboardingQ12Online;

  /// No description provided for @onboardingQ12Boutiques.
  ///
  /// In en, this message translates to:
  /// **'Boutiques'**
  String get onboardingQ12Boutiques;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUp;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to continue'**
  String get authWelcome;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// No description provided for @signUpButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// No description provided for @authError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authError;

  /// No description provided for @socialLoginSimulatorError.
  ///
  /// In en, this message translates to:
  /// **'Social login may not work in the simulator. Try on a real device or use email and password.'**
  String get socialLoginSimulatorError;

  /// No description provided for @checkEmailToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please check your email to confirm your account.'**
  String get checkEmailToConfirm;

  /// No description provided for @mustSignInFirst.
  ///
  /// In en, this message translates to:
  /// **'You must sign in first.'**
  String get mustSignInFirst;

  /// No description provided for @accountBanned.
  ///
  /// In en, this message translates to:
  /// **'Your account has been suspended. Please contact support if you believe this is an error.'**
  String get accountBanned;

  /// No description provided for @answerSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved successfully'**
  String get answerSaved;

  /// No description provided for @videoMaxDuration.
  ///
  /// In en, this message translates to:
  /// **'Video must not exceed {seconds} seconds.'**
  String videoMaxDuration(Object seconds);

  /// No description provided for @videoUploadHint.
  ///
  /// In en, this message translates to:
  /// **'Upload one video (max 15 seconds)'**
  String get videoUploadHint;

  /// No description provided for @cameraNotAvailableHint.
  ///
  /// In en, this message translates to:
  /// **'Camera not available (e.g. in simulator). Try «Choose from gallery» or run on a real device.'**
  String get cameraNotAvailableHint;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'You\'re in!'**
  String get homeWelcome;

  /// No description provided for @troubleLoggingIn.
  ///
  /// In en, this message translates to:
  /// **'Trouble logging in?'**
  String get troubleLoggingIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you a link to reset your password.'**
  String get forgotPasswordHint;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @resetLinkSent.
  ///
  /// In en, this message translates to:
  /// **'Check your email for the reset link.'**
  String get resetLinkSent;

  /// No description provided for @orLogInWith.
  ///
  /// In en, this message translates to:
  /// **'Or log in with'**
  String get orLogInWith;

  /// No description provided for @orSignUpWith.
  ///
  /// In en, this message translates to:
  /// **'Or sign up with'**
  String get orSignUpWith;

  /// No description provided for @createYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account in Swaply'**
  String get createYourAccount;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Do you already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @firstEnterEmail.
  ///
  /// In en, this message translates to:
  /// **'First, enter your email'**
  String get firstEnterEmail;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @bySigningUpAccept.
  ///
  /// In en, this message translates to:
  /// **'By signing up, you accept our {terms} and {privacy}.'**
  String bySigningUpAccept(Object terms, Object privacy);

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @entryAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By tapping Create account or Sign in, you agree to our {terms} and {privacy}.'**
  String entryAgreeTerms(Object terms, Object privacy);

  /// No description provided for @entryAgreeIntro.
  ///
  /// In en, this message translates to:
  /// **'By tapping Create account or Sign in, you agree to our '**
  String get entryAgreeIntro;

  /// No description provided for @entryAgreeAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get entryAgreeAnd;

  /// No description provided for @entryAgreeEnd.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get entryAgreeEnd;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @signInLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInLink;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Swaply.. to stay together.'**
  String get tagline;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabLikesYou.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get tabLikesYou;

  /// No description provided for @featuredEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No featured profiles yet. Featured users have 100% complete and verified profiles.'**
  String get featuredEmptyDescription;

  /// No description provided for @tabMatches.
  ///
  /// In en, this message translates to:
  /// **'Likes you'**
  String get tabMatches;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @chatEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.\nSend a message from any user\'s profile to start the conversation here.'**
  String get chatEmptyDescription;

  /// No description provided for @messagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messagePlaceholder;

  /// No description provided for @sendGift.
  ///
  /// In en, this message translates to:
  /// **'Don\'t hesitate.. Make their day brighter'**
  String get sendGift;

  /// No description provided for @writeMessageToSendWithGift.
  ///
  /// In en, this message translates to:
  /// **'Write a message to send with your gift'**
  String get writeMessageToSendWithGift;

  /// No description provided for @selectGiftToSend.
  ///
  /// In en, this message translates to:
  /// **'Please select a gift to send your message.'**
  String get selectGiftToSend;

  /// No description provided for @selectedGiftLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected gift: {gift}'**
  String selectedGiftLabel(Object gift);

  /// No description provided for @sendNiceMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting time is over — take the first step now.'**
  String get sendNiceMessageTitle;

  /// No description provided for @sendNiceMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get sendNiceMessageHint;

  /// No description provided for @sendNiceMessageButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendNiceMessageButton;

  /// No description provided for @messageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent'**
  String get messageSent;

  /// No description provided for @senderYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get senderYou;

  /// No description provided for @pass.
  ///
  /// In en, this message translates to:
  /// **'Pass'**
  String get pass;

  /// No description provided for @like.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get like;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @sharedInterests.
  ///
  /// In en, this message translates to:
  /// **'Shared Interests:'**
  String get sharedInterests;

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{distance} km away'**
  String distanceKm(Object distance);

  /// No description provided for @distanceMiles.
  ///
  /// In en, this message translates to:
  /// **'{distance} miles away'**
  String distanceMiles(Object distance);

  /// No description provided for @noMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'No one new around you. Check back later.'**
  String get noMoreProfiles;

  /// No description provided for @someoneLikedYou.
  ///
  /// In en, this message translates to:
  /// **'Someone liked your profile'**
  String get someoneLikedYou;

  /// No description provided for @likesYouPrompt.
  ///
  /// In en, this message translates to:
  /// **'Like people on the main screen — when you like someone who already liked you, the match screen will appear.'**
  String get likesYouPrompt;

  /// No description provided for @likesYouPromptWithCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people liked you. Go to the main screen and like people — when it\'s mutual, the match screen will appear.'**
  String likesYouPromptWithCount(Object count);

  /// No description provided for @goToHomeToMatch.
  ///
  /// In en, this message translates to:
  /// **'Back to discovery'**
  String get goToHomeToMatch;

  /// No description provided for @backToDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Back to discovery'**
  String get backToDiscovery;

  /// No description provided for @youMatched.
  ///
  /// In en, this message translates to:
  /// **'Swapped!'**
  String get youMatched;

  /// No description provided for @match.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get match;

  /// No description provided for @sendWithRose.
  ///
  /// In en, this message translates to:
  /// **'Send with rose'**
  String get sendWithRose;

  /// No description provided for @sendYourFeeling.
  ///
  /// In en, this message translates to:
  /// **'Send your feeling'**
  String get sendYourFeeling;

  /// No description provided for @matchRoseHint.
  ///
  /// In en, this message translates to:
  /// **'Write a message with the rose…'**
  String get matchRoseHint;

  /// No description provided for @matchGiftHint.
  ///
  /// In en, this message translates to:
  /// **'What will you whisper to them with this gift?'**
  String get matchGiftHint;

  /// No description provided for @giftMessageWhisperHint.
  ///
  /// In en, this message translates to:
  /// **'What will you whisper to {pronoun} with your gift?'**
  String giftMessageWhisperHint(Object pronoun);

  /// No description provided for @pronounHim.
  ///
  /// In en, this message translates to:
  /// **'him'**
  String get pronounHim;

  /// No description provided for @pronounHer.
  ///
  /// In en, this message translates to:
  /// **'her'**
  String get pronounHer;

  /// No description provided for @pronounSettingLabel.
  ///
  /// In en, this message translates to:
  /// **'Pronoun for gift messages'**
  String get pronounSettingLabel;

  /// No description provided for @pronounOptionMale.
  ///
  /// In en, this message translates to:
  /// **'Male (him)'**
  String get pronounOptionMale;

  /// No description provided for @pronounOptionFemale.
  ///
  /// In en, this message translates to:
  /// **'Female (her)'**
  String get pronounOptionFemale;

  /// No description provided for @matchContinue.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get matchContinue;

  /// No description provided for @matchSeriousPrompt.
  ///
  /// In en, this message translates to:
  /// **'Let\'s get serious..'**
  String get matchSeriousPrompt;

  /// No description provided for @matchConfirmAndSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get matchConfirmAndSend;

  /// No description provided for @sendTextOnly.
  ///
  /// In en, this message translates to:
  /// **'Send text only'**
  String get sendTextOnly;

  /// No description provided for @giftRose.
  ///
  /// In en, this message translates to:
  /// **'Rose'**
  String get giftRose;

  /// No description provided for @giftRing.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get giftRing;

  /// No description provided for @giftCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get giftCoffee;

  /// No description provided for @giftReceivedTitle.
  ///
  /// In en, this message translates to:
  /// **'You got a serious feeling from {senderName}'**
  String giftReceivedTitle(Object senderName);

  /// No description provided for @seriousMessageFrom.
  ///
  /// In en, this message translates to:
  /// **'Serious message from {senderName}'**
  String seriousMessageFrom(Object senderName);

  /// No description provided for @replySeriously.
  ///
  /// In en, this message translates to:
  /// **'Give a chance'**
  String get replySeriously;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @seriousGiftMessage.
  ///
  /// In en, this message translates to:
  /// **'Serious Gift Message'**
  String get seriousGiftMessage;

  /// No description provided for @giftSenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Sent a gift'**
  String get giftSenderLabel;

  /// No description provided for @pushGiftNotificationBody.
  ///
  /// In en, this message translates to:
  /// **'{senderName} sent you a gift ({gift}) with a private message.. Open to see what they said!'**
  String pushGiftNotificationBody(Object senderName, Object gift);

  /// No description provided for @seeProfile.
  ///
  /// In en, this message translates to:
  /// **'See profile'**
  String get seeProfile;

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signInWithPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Sign in with phone number'**
  String get signInWithPhoneNumber;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @orUseEmail.
  ///
  /// In en, this message translates to:
  /// **'Or use email'**
  String get orUseEmail;

  /// No description provided for @whatsYourPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'What\'s your phone number?'**
  String get whatsYourPhoneNumber;

  /// No description provided for @phoneVerificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Swaply will send you a text with a verification code. Message and data rates may apply.'**
  String get phoneVerificationMessage;

  /// No description provided for @whatIfNumberChanges.
  ///
  /// In en, this message translates to:
  /// **'What if my number changes?'**
  String get whatIfNumberChanges;

  /// No description provided for @enterVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to your phone'**
  String get enterVerificationCode;

  /// No description provided for @verify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @postPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'We value your privacy'**
  String get postPrivacyTitle;

  /// No description provided for @postPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'We use tools to measure the audience and use of our app, personalise ads, enhance our own marketing operations, enable social features and better understand how our services are used. These tools don\'t track you across apps and websites.'**
  String get postPrivacyBody;

  /// No description provided for @postPrivacyAccept.
  ///
  /// In en, this message translates to:
  /// **'I accept'**
  String get postPrivacyAccept;

  /// No description provided for @postPrivacyPersonalise.
  ///
  /// In en, this message translates to:
  /// **'Personalise my choices'**
  String get postPrivacyPersonalise;

  /// No description provided for @postQFamilyPlans.
  ///
  /// In en, this message translates to:
  /// **'What are your family plans?'**
  String get postQFamilyPlans;

  /// No description provided for @postFamilyDontWant.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want children'**
  String get postFamilyDontWant;

  /// No description provided for @postFamilyWant.
  ///
  /// In en, this message translates to:
  /// **'Want children'**
  String get postFamilyWant;

  /// No description provided for @postFamilyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open to children'**
  String get postFamilyOpen;

  /// No description provided for @postFamilyNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get postFamilyNotSure;

  /// No description provided for @postQHometown.
  ///
  /// In en, this message translates to:
  /// **'Where\'s your home town?'**
  String get postQHometown;

  /// No description provided for @postHometownPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Home town'**
  String get postHometownPlaceholder;

  /// No description provided for @postQName.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get postQName;

  /// No description provided for @postFirstNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'First name (required)'**
  String get postFirstNamePlaceholder;

  /// No description provided for @postLastNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get postLastNamePlaceholder;

  /// No description provided for @postLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Last name is optional, and only shared with matches.'**
  String get postLastNameHint;

  /// No description provided for @postWhy.
  ///
  /// In en, this message translates to:
  /// **'Why?'**
  String get postWhy;

  /// No description provided for @postQDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'What\'s your date of birth?'**
  String get postQDateOfBirth;

  /// No description provided for @postDobHint.
  ///
  /// In en, this message translates to:
  /// **'We use this to calculate the age on your profile.'**
  String get postDobHint;

  /// No description provided for @postDobDay.
  ///
  /// In en, this message translates to:
  /// **'DD'**
  String get postDobDay;

  /// No description provided for @postDobMonth.
  ///
  /// In en, this message translates to:
  /// **'MM'**
  String get postDobMonth;

  /// No description provided for @postDobYear.
  ///
  /// In en, this message translates to:
  /// **'YYYY'**
  String get postDobYear;

  /// No description provided for @postAgeConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re {age}'**
  String postAgeConfirmTitle(Object age);

  /// No description provided for @postAgeConfirmBorn.
  ///
  /// In en, this message translates to:
  /// **'Born {date}'**
  String postAgeConfirmBorn(Object date);

  /// No description provided for @postAgeConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirm your age is correct. Let\'s keep our community authentic.'**
  String get postAgeConfirmMessage;

  /// No description provided for @postEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get postEdit;

  /// No description provided for @postConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get postConfirm;

  /// No description provided for @postQLive.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get postQLive;

  /// No description provided for @postLiveHint.
  ///
  /// In en, this message translates to:
  /// **'Only the neighbourhood name will appear on your profile.'**
  String get postLiveHint;

  /// No description provided for @postZoomIntoArea.
  ///
  /// In en, this message translates to:
  /// **'Zoom into your area'**
  String get postZoomIntoArea;

  /// No description provided for @postEnterAddressPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your address, area or postcode'**
  String get postEnterAddressPlaceholder;

  /// No description provided for @postUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get postUseMyLocation;

  /// No description provided for @postQWorkplace.
  ///
  /// In en, this message translates to:
  /// **'Where do you work?'**
  String get postQWorkplace;

  /// No description provided for @postWorkplacePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Workplace'**
  String get postWorkplacePlaceholder;

  /// No description provided for @postQJobTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your job title?'**
  String get postQJobTitle;

  /// No description provided for @postJobTitlePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get postJobTitlePlaceholder;

  /// No description provided for @postQWhereStudied.
  ///
  /// In en, this message translates to:
  /// **'Where did you study?'**
  String get postQWhereStudied;

  /// No description provided for @postWhereStudiedPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a college or university'**
  String get postWhereStudiedPlaceholder;

  /// No description provided for @postQEducationLevel.
  ///
  /// In en, this message translates to:
  /// **'What\'s the highest level you attained?'**
  String get postQEducationLevel;

  /// No description provided for @postEduSecondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary school'**
  String get postEduSecondary;

  /// No description provided for @postEduUndergrad.
  ///
  /// In en, this message translates to:
  /// **'Undergrad'**
  String get postEduUndergrad;

  /// No description provided for @postEduPostgrad.
  ///
  /// In en, this message translates to:
  /// **'Postgrad'**
  String get postEduPostgrad;

  /// No description provided for @postQReligiousBeliefs.
  ///
  /// In en, this message translates to:
  /// **'What are your religious beliefs?'**
  String get postQReligiousBeliefs;

  /// No description provided for @postReligionAgnostic.
  ///
  /// In en, this message translates to:
  /// **'Agnostic'**
  String get postReligionAgnostic;

  /// No description provided for @postReligionAtheist.
  ///
  /// In en, this message translates to:
  /// **'Atheist'**
  String get postReligionAtheist;

  /// No description provided for @postReligionBuddhist.
  ///
  /// In en, this message translates to:
  /// **'Buddhist'**
  String get postReligionBuddhist;

  /// No description provided for @postReligionCatholic.
  ///
  /// In en, this message translates to:
  /// **'Catholic'**
  String get postReligionCatholic;

  /// No description provided for @postReligionChristian.
  ///
  /// In en, this message translates to:
  /// **'Christian'**
  String get postReligionChristian;

  /// No description provided for @postReligionHindu.
  ///
  /// In en, this message translates to:
  /// **'Hindu'**
  String get postReligionHindu;

  /// No description provided for @postReligionJewish.
  ///
  /// In en, this message translates to:
  /// **'Jewish'**
  String get postReligionJewish;

  /// No description provided for @postReligionMuslim.
  ///
  /// In en, this message translates to:
  /// **'Muslim'**
  String get postReligionMuslim;

  /// No description provided for @postReligionOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get postReligionOther;

  /// No description provided for @postQPoliticalBeliefs.
  ///
  /// In en, this message translates to:
  /// **'What are your political beliefs?'**
  String get postQPoliticalBeliefs;

  /// No description provided for @postPoliticalLiberal.
  ///
  /// In en, this message translates to:
  /// **'Liberal'**
  String get postPoliticalLiberal;

  /// No description provided for @postPoliticalModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get postPoliticalModerate;

  /// No description provided for @postPoliticalConservative.
  ///
  /// In en, this message translates to:
  /// **'Conservative'**
  String get postPoliticalConservative;

  /// No description provided for @postPoliticalNotPolitical.
  ///
  /// In en, this message translates to:
  /// **'Not political'**
  String get postPoliticalNotPolitical;

  /// No description provided for @postPoliticalOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get postPoliticalOther;

  /// No description provided for @postQDrink.
  ///
  /// In en, this message translates to:
  /// **'Do you drink?'**
  String get postQDrink;

  /// No description provided for @postQSmokeTobacco.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke tobacco?'**
  String get postQSmokeTobacco;

  /// No description provided for @postQSmokeWeed.
  ///
  /// In en, this message translates to:
  /// **'Do you smoke weed?'**
  String get postQSmokeWeed;

  /// No description provided for @postQUseDrugs.
  ///
  /// In en, this message translates to:
  /// **'Do you use drugs?'**
  String get postQUseDrugs;

  /// No description provided for @postYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get postYes;

  /// No description provided for @postSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get postSometimes;

  /// No description provided for @postNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get postNo;

  /// No description provided for @postPreferNotToSay.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get postPreferNotToSay;

  /// No description provided for @visibleOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Visible on profile'**
  String get visibleOnProfile;

  /// No description provided for @hiddenOnProfile.
  ///
  /// In en, this message translates to:
  /// **'Hidden on profile'**
  String get hiddenOnProfile;

  /// No description provided for @preferNotToSayLimits.
  ///
  /// In en, this message translates to:
  /// **'This will limit who sees your profile'**
  String get preferNotToSayLimits;

  /// No description provided for @learnMore.
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get learnMore;

  /// No description provided for @fillOutProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Show off the person behind the profile with pics, videos and Prompts.'**
  String get fillOutProfileTitle;

  /// No description provided for @fillOutProfileButton.
  ///
  /// In en, this message translates to:
  /// **'Fill out your profile'**
  String get fillOutProfileButton;

  /// No description provided for @pickPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your photos and videos'**
  String get pickPhotosTitle;

  /// No description provided for @addFourToSixPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add four to six photos'**
  String get addFourToSixPhotos;

  /// No description provided for @dragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get dragToReorder;

  /// No description provided for @notSureWhichPhotos.
  ///
  /// In en, this message translates to:
  /// **'Not sure which photos to use?'**
  String get notSureWhichPhotos;

  /// No description provided for @seeWhatWorks.
  ///
  /// In en, this message translates to:
  /// **'See what works based on research.'**
  String get seeWhatWorks;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhoto;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @postRequiredFieldsHint.
  ///
  /// In en, this message translates to:
  /// **'You must fill in your name and date of birth at least to continue.'**
  String get postRequiredFieldsHint;

  /// No description provided for @skipConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Sure you want to skip?'**
  String get skipConfirmTitle;

  /// No description provided for @skipConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Skipping means you won\'t be able to send or receive likes, message people or match.'**
  String get skipConfirmMessage;

  /// No description provided for @finishNow.
  ///
  /// In en, this message translates to:
  /// **'Finish now'**
  String get finishNow;

  /// No description provided for @yesIWantToSkip.
  ///
  /// In en, this message translates to:
  /// **'Yes, I want to skip'**
  String get yesIWantToSkip;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tabProfile;

  /// No description provided for @profileCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get profileCompleteTitle;

  /// No description provided for @profileCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re almost there – just a few more details to start matching.'**
  String get profileCompleteDesc;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @helpCentre.
  ///
  /// In en, this message translates to:
  /// **'Help Centre'**
  String get helpCentre;

  /// No description provided for @helpCentreDesc.
  ///
  /// In en, this message translates to:
  /// **'Safety, Security and more'**
  String get helpCentreDesc;

  /// No description provided for @whatWorks.
  ///
  /// In en, this message translates to:
  /// **'What Works'**
  String get whatWorks;

  /// No description provided for @whatWorksDesc.
  ///
  /// In en, this message translates to:
  /// **'Check out our expert dating tips'**
  String get whatWorksDesc;

  /// No description provided for @incompleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Incomplete profile'**
  String get incompleteProfile;

  /// No description provided for @tabGetMore.
  ///
  /// In en, this message translates to:
  /// **'Get more'**
  String get tabGetMore;

  /// No description provided for @tabSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get tabSafety;

  /// No description provided for @tabMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get tabMyProfile;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @settingsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get settingsPause;

  /// No description provided for @settingsPauseDesc.
  ///
  /// In en, this message translates to:
  /// **'Pausing prevents your profile from being shown to new people. You can still chat with your current matches.'**
  String get settingsPauseDesc;

  /// No description provided for @showLastActive.
  ///
  /// In en, this message translates to:
  /// **'Show Last Active Status'**
  String get showLastActive;

  /// No description provided for @showLastActiveDesc.
  ///
  /// In en, this message translates to:
  /// **'People viewing your profile can see your last active status, and you can see theirs. Your matches won\'t be shown your last active status.'**
  String get showLastActiveDesc;

  /// No description provided for @safetySection.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safetySection;

  /// No description provided for @selfieVerification.
  ///
  /// In en, this message translates to:
  /// **'Selfie verification'**
  String get selfieVerification;

  /// No description provided for @selfieVerificationDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'re not verified yet.'**
  String get selfieVerificationDesc;

  /// No description provided for @blockList.
  ///
  /// In en, this message translates to:
  /// **'Block List'**
  String get blockList;

  /// No description provided for @blockListDesc.
  ///
  /// In en, this message translates to:
  /// **'Block people you know. They won\'t see you and you won\'t see them on Swaply.'**
  String get blockListDesc;

  /// No description provided for @blockListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get blockListEmptyTitle;

  /// No description provided for @blockListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'When you block someone, they\'ll appear here. They won\'t see you and you won\'t see them on Swaply.'**
  String get blockListEmptySubtitle;

  /// No description provided for @goToFeaturedTab.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get goToFeaturedTab;

  /// No description provided for @goToFeaturedDesc.
  ///
  /// In en, this message translates to:
  /// **'Discover who liked you'**
  String get goToFeaturedDesc;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @commentFilter.
  ///
  /// In en, this message translates to:
  /// **'Comment Filter'**
  String get commentFilter;

  /// No description provided for @commentFilterDesc.
  ///
  /// In en, this message translates to:
  /// **'Hide likes from people who use disrespectful language in their comments.'**
  String get commentFilterDesc;

  /// No description provided for @phoneAndEmail.
  ///
  /// In en, this message translates to:
  /// **'Phone & email'**
  String get phoneAndEmail;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @notificationsSection.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSection;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailNotifications;

  /// No description provided for @subscriptionSection.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionSection;

  /// No description provided for @completeProfileMember.
  ///
  /// In en, this message translates to:
  /// **'Complete profile to become a member'**
  String get completeProfileMember;

  /// No description provided for @notSubscribed.
  ///
  /// In en, this message translates to:
  /// **'You\'re not currently subscribed.'**
  String get notSubscribed;

  /// No description provided for @subscribeToApp.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to Swaply'**
  String get subscribeToApp;

  /// No description provided for @restoreSubscription.
  ///
  /// In en, this message translates to:
  /// **'Restore subscription'**
  String get restoreSubscription;

  /// No description provided for @languageAndRegion.
  ///
  /// In en, this message translates to:
  /// **'Language & region'**
  String get languageAndRegion;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @audioTranscripts.
  ///
  /// In en, this message translates to:
  /// **'Audio Transcripts'**
  String get audioTranscripts;

  /// No description provided for @audioTranscriptsDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see text transcripts for audio content (like voice notes) so you can read what\'s being said.'**
  String get audioTranscriptsDesc;

  /// No description provided for @unitsOfMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Units of measurement'**
  String get unitsOfMeasurement;

  /// No description provided for @connectedAccounts.
  ///
  /// In en, this message translates to:
  /// **'Connected accounts'**
  String get connectedAccounts;

  /// No description provided for @legalSection.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalSection;

  /// No description provided for @privacyPreferences.
  ///
  /// In en, this message translates to:
  /// **'Privacy Preferences'**
  String get privacyPreferences;

  /// No description provided for @licences.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licences;

  /// No description provided for @downloadMyData.
  ///
  /// In en, this message translates to:
  /// **'Download my data'**
  String get downloadMyData;

  /// No description provided for @communitySection.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communitySection;

  /// No description provided for @safeDatingTips.
  ///
  /// In en, this message translates to:
  /// **'Safe Dating Tips'**
  String get safeDatingTips;

  /// No description provided for @memberPrinciples.
  ///
  /// In en, this message translates to:
  /// **'Member Principles'**
  String get memberPrinciples;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @deleteOrPauseAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete or pause account'**
  String get deleteOrPauseAccount;

  /// No description provided for @deleteOrPauseDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'You can pause your account temporarily (hide from new people, keep matches) or delete it permanently from this app. Deletion is immediate and cannot be undone.'**
  String get deleteOrPauseDialogDescription;

  /// No description provided for @deletePermanentWarning.
  ///
  /// In en, this message translates to:
  /// **'Your account and all your data will be permanently deleted. This cannot be undone. Continue?'**
  String get deletePermanentWarning;

  /// No description provided for @pauseAccount.
  ///
  /// In en, this message translates to:
  /// **'Pause account'**
  String get pauseAccount;

  /// No description provided for @loadMoreProfiles.
  ///
  /// In en, this message translates to:
  /// **'Load more profiles'**
  String get loadMoreProfiles;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your network and try again.'**
  String get noConnection;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @datingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dating preferences'**
  String get datingPreferences;

  /// No description provided for @memberPreferences.
  ///
  /// In en, this message translates to:
  /// **'Member preferences'**
  String get memberPreferences;

  /// No description provided for @subscriberPreferences.
  ///
  /// In en, this message translates to:
  /// **'Subscriber preferences'**
  String get subscriberPreferences;

  /// No description provided for @completeProfileToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to unlock'**
  String get completeProfileToUnlock;

  /// No description provided for @imInterestedIn.
  ///
  /// In en, this message translates to:
  /// **'I\'m interested in'**
  String get imInterestedIn;

  /// No description provided for @myNeighbourhood.
  ///
  /// In en, this message translates to:
  /// **'My neighbourhood'**
  String get myNeighbourhood;

  /// No description provided for @maximumDistance.
  ///
  /// In en, this message translates to:
  /// **'Maximum distance'**
  String get maximumDistance;

  /// No description provided for @ageRange.
  ///
  /// In en, this message translates to:
  /// **'Age range'**
  String get ageRange;

  /// No description provided for @ethnicity.
  ///
  /// In en, this message translates to:
  /// **'Ethnicity'**
  String get ethnicity;

  /// No description provided for @religion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get religion;

  /// No description provided for @relationshipType.
  ///
  /// In en, this message translates to:
  /// **'Relationship type'**
  String get relationshipType;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @datingIntentions.
  ///
  /// In en, this message translates to:
  /// **'Dating intentions'**
  String get datingIntentions;

  /// No description provided for @children.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get children;

  /// No description provided for @familyPlans.
  ///
  /// In en, this message translates to:
  /// **'Family plans'**
  String get familyPlans;

  /// No description provided for @drugs.
  ///
  /// In en, this message translates to:
  /// **'Drugs'**
  String get drugs;

  /// No description provided for @smoking.
  ///
  /// In en, this message translates to:
  /// **'Smoking'**
  String get smoking;

  /// No description provided for @marijuana.
  ///
  /// In en, this message translates to:
  /// **'Marijuana'**
  String get marijuana;

  /// No description provided for @drinking.
  ///
  /// In en, this message translates to:
  /// **'Drinking'**
  String get drinking;

  /// No description provided for @politics.
  ///
  /// In en, this message translates to:
  /// **'Politics'**
  String get politics;

  /// No description provided for @educationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education level'**
  String get educationLevel;

  /// No description provided for @openToAll.
  ///
  /// In en, this message translates to:
  /// **'Open to all'**
  String get openToAll;

  /// No description provided for @fineTuneWithSubscription.
  ///
  /// In en, this message translates to:
  /// **'Fine-tune your preferences with a subscription.'**
  String get fineTuneWithSubscription;

  /// No description provided for @men.
  ///
  /// In en, this message translates to:
  /// **'Men'**
  String get men;

  /// No description provided for @women.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get women;

  /// No description provided for @everyone.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get everyone;

  /// No description provided for @dealBreaker.
  ///
  /// In en, this message translates to:
  /// **'Deal-breaker'**
  String get dealBreaker;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @years.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get years;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @profileCompletePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String profileCompletePercent(Object percent);

  /// No description provided for @profileCompletionLikeBlockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to send a Like?'**
  String get profileCompletionLikeBlockedTitle;

  /// No description provided for @profileCompletionLikeBlockedDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a few more profile details – from 50% you can start liking!'**
  String get profileCompletionLikeBlockedDesc;

  /// No description provided for @profileCompletionFillNow.
  ///
  /// In en, this message translates to:
  /// **'Complete profile now'**
  String get profileCompletionFillNow;

  /// No description provided for @profileCompletionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get profileCompletionNotNow;

  /// No description provided for @profileCompletionGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {percent}%'**
  String profileCompletionGoal(Object percent);

  /// No description provided for @profileCompleteness.
  ///
  /// In en, this message translates to:
  /// **'Profile completeness'**
  String get profileCompleteness;

  /// No description provided for @profileCompletenessMotivation.
  ///
  /// In en, this message translates to:
  /// **'You\'ve made a start. But there are still profile details you can add to attract interest from others.'**
  String get profileCompletenessMotivation;

  /// No description provided for @visibilityPromptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get more visibility!'**
  String get visibilityPromptTitle;

  /// No description provided for @visibilityPromptDesc.
  ///
  /// In en, this message translates to:
  /// **'Answer some profile questions to be shown more often to others.'**
  String get visibilityPromptDesc;

  /// No description provided for @visibilityPromptButton.
  ///
  /// In en, this message translates to:
  /// **'Answer profile questions'**
  String get visibilityPromptButton;

  /// No description provided for @visibilityPromptLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get visibilityPromptLater;

  /// No description provided for @completionScore.
  ///
  /// In en, this message translates to:
  /// **'Completion score'**
  String get completionScore;

  /// No description provided for @attractMoreAttention.
  ///
  /// In en, this message translates to:
  /// **'Attract more attention'**
  String get attractMoreAttention;

  /// No description provided for @completeProfileCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Easily add the right info to create a top-notch profile that really stands out.'**
  String get completeProfileCardDesc;

  /// No description provided for @myPhotosAndVideos.
  ///
  /// In en, this message translates to:
  /// **'My photos & videos'**
  String get myPhotosAndVideos;

  /// No description provided for @topPhoto.
  ///
  /// In en, this message translates to:
  /// **'Top Photo'**
  String get topPhoto;

  /// No description provided for @topPhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll continuously test your profile pics and put the most popular one first.'**
  String get topPhotoDesc;

  /// No description provided for @writtenPrompts.
  ///
  /// In en, this message translates to:
  /// **'Written Prompts (3)'**
  String get writtenPrompts;

  /// No description provided for @selectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a Prompt'**
  String get selectPrompt;

  /// No description provided for @selectPromptAndWrite.
  ///
  /// In en, this message translates to:
  /// **'And write your own answer'**
  String get selectPromptAndWrite;

  /// No description provided for @writeYourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Write your question'**
  String get writeYourQuestion;

  /// No description provided for @writeYourAnswer.
  ///
  /// In en, this message translates to:
  /// **'Write your answer'**
  String get writeYourAnswer;

  /// No description provided for @selectPromptAndRecord.
  ///
  /// In en, this message translates to:
  /// **'And record your answer'**
  String get selectPromptAndRecord;

  /// No description provided for @createPoll.
  ///
  /// In en, this message translates to:
  /// **'Create a poll'**
  String get createPoll;

  /// No description provided for @addYourOptions.
  ///
  /// In en, this message translates to:
  /// **'And add your options'**
  String get addYourOptions;

  /// No description provided for @threeAnswersRequired.
  ///
  /// In en, this message translates to:
  /// **'3 answers required'**
  String get threeAnswersRequired;

  /// No description provided for @textPrompt.
  ///
  /// In en, this message translates to:
  /// **'Text Prompt'**
  String get textPrompt;

  /// No description provided for @videoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Video Prompt'**
  String get videoPrompt;

  /// No description provided for @promptPoll.
  ///
  /// In en, this message translates to:
  /// **'Prompt Poll'**
  String get promptPoll;

  /// No description provided for @voicePrompt.
  ///
  /// In en, this message translates to:
  /// **'Voice recording'**
  String get voicePrompt;

  /// No description provided for @voiceRecordFromMic.
  ///
  /// In en, this message translates to:
  /// **'Record from microphone'**
  String get voiceRecordFromMic;

  /// No description provided for @voiceUploadFromPhone.
  ///
  /// In en, this message translates to:
  /// **'Upload audio from phone'**
  String get voiceUploadFromPhone;

  /// No description provided for @voiceAddSpotifySong.
  ///
  /// In en, this message translates to:
  /// **'Add song from Spotify'**
  String get voiceAddSpotifySong;

  /// No description provided for @voiceSourceTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose audio source'**
  String get voiceSourceTitle;

  /// No description provided for @voiceAddOrEditText.
  ///
  /// In en, this message translates to:
  /// **'Add or edit text'**
  String get voiceAddOrEditText;

  /// No description provided for @voiceCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Write a caption for the recording'**
  String get voiceCaptionHint;

  /// No description provided for @voicePressStartToRecord.
  ///
  /// In en, this message translates to:
  /// **'Press start to begin recording.'**
  String get voicePressStartToRecord;

  /// No description provided for @voiceStartRecording.
  ///
  /// In en, this message translates to:
  /// **'Start recording'**
  String get voiceStartRecording;

  /// No description provided for @voiceRecordingInProgress.
  ///
  /// In en, this message translates to:
  /// **'Recording... Press Done to stop.'**
  String get voiceRecordingInProgress;

  /// No description provided for @microphonePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission was denied. Enable it in app settings and try again.'**
  String get microphonePermissionDenied;

  /// No description provided for @voicePlaybackFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not play the voice recording. Check your connection or try again later.'**
  String get voicePlaybackFailed;

  /// No description provided for @voiceUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'No file was selected or upload failed. Check file access and try again.'**
  String get voiceUploadFailed;

  /// No description provided for @spotifyUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Spotify song link'**
  String get spotifyUrlHint;

  /// No description provided for @voiceSpotifyInvalidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid Spotify song link (e.g. open.spotify.com/track/...).'**
  String get voiceSpotifyInvalidUrl;

  /// No description provided for @myFavoriteSong.
  ///
  /// In en, this message translates to:
  /// **'My favorite song'**
  String get myFavoriteSong;

  /// No description provided for @playFullSong.
  ///
  /// In en, this message translates to:
  /// **'Play full song'**
  String get playFullSong;

  /// No description provided for @mySong.
  ///
  /// In en, this message translates to:
  /// **'My Song'**
  String get mySong;

  /// No description provided for @searchOnSpotify.
  ///
  /// In en, this message translates to:
  /// **'Search on Spotify'**
  String get searchOnSpotify;

  /// No description provided for @whichSongLookingFor.
  ///
  /// In en, this message translates to:
  /// **'Which song are you looking for?'**
  String get whichSongLookingFor;

  /// No description provided for @songShownInProfile.
  ///
  /// In en, this message translates to:
  /// **'It will be shown on your profile.'**
  String get songShownInProfile;

  /// No description provided for @pasteLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste a Spotify link below'**
  String get pasteLinkHint;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results found. Try another search.'**
  String get noResults;

  /// No description provided for @searchError.
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection and try again.'**
  String get searchError;

  /// No description provided for @voiceRecording.
  ///
  /// In en, this message translates to:
  /// **'Voice recording'**
  String get voiceRecording;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @identity.
  ///
  /// In en, this message translates to:
  /// **'Identity'**
  String get identity;

  /// No description provided for @matchNote.
  ///
  /// In en, this message translates to:
  /// **'Match Note'**
  String get matchNote;

  /// No description provided for @myVirtues.
  ///
  /// In en, this message translates to:
  /// **'My Virtues'**
  String get myVirtues;

  /// No description provided for @myVitals.
  ///
  /// In en, this message translates to:
  /// **'My Vitals'**
  String get myVitals;

  /// No description provided for @myVices.
  ///
  /// In en, this message translates to:
  /// **'My vices'**
  String get myVices;

  /// No description provided for @pronouns.
  ///
  /// In en, this message translates to:
  /// **'Pronouns'**
  String get pronouns;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @sexuality.
  ///
  /// In en, this message translates to:
  /// **'Sexuality'**
  String get sexuality;

  /// No description provided for @work.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get work;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @collegeOrUniversity.
  ///
  /// In en, this message translates to:
  /// **'College or university'**
  String get collegeOrUniversity;

  /// No description provided for @religiousBeliefs.
  ///
  /// In en, this message translates to:
  /// **'Religious beliefs'**
  String get religiousBeliefs;

  /// No description provided for @homeTown.
  ///
  /// In en, this message translates to:
  /// **'Home town'**
  String get homeTown;

  /// No description provided for @languagesSpoken.
  ///
  /// In en, this message translates to:
  /// **'Languages spoken'**
  String get languagesSpoken;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @pets.
  ///
  /// In en, this message translates to:
  /// **'Pets'**
  String get pets;

  /// No description provided for @covidVaccine.
  ///
  /// In en, this message translates to:
  /// **'Covid vaccine'**
  String get covidVaccine;

  /// No description provided for @zodiacSign.
  ///
  /// In en, this message translates to:
  /// **'Zodiac sign'**
  String get zodiacSign;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @hidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hidden;

  /// No description provided for @visible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get visible;

  /// No description provided for @alwaysHidden.
  ///
  /// In en, this message translates to:
  /// **'Always Hidden'**
  String get alwaysHidden;

  /// No description provided for @alwaysVisible.
  ///
  /// In en, this message translates to:
  /// **'Always Visible'**
  String get alwaysVisible;

  /// No description provided for @fieldVisibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get fieldVisibility;

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @toLabel.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// No description provided for @heightRangeOption.
  ///
  /// In en, this message translates to:
  /// **'Specific range'**
  String get heightRangeOption;

  /// No description provided for @profileCompletionWrittenQuestions.
  ///
  /// In en, this message translates to:
  /// **'Written questions'**
  String get profileCompletionWrittenQuestions;

  /// No description provided for @profileCompletionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get profileCompletionPhotos;

  /// No description provided for @profileCompletionFields.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get profileCompletionFields;

  /// No description provided for @fieldSaveError.
  ///
  /// In en, this message translates to:
  /// **'Failed to save. Check connection or Supabase settings.'**
  String get fieldSaveError;

  /// No description provided for @ageMinimumError.
  ///
  /// In en, this message translates to:
  /// **'You must be at least 18 to use this app.'**
  String get ageMinimumError;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Swaply Premium'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features and fine-tune your preferences.'**
  String get subscriptionSubtitle;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionYearly;

  /// No description provided for @subscriptionYearlySave.
  ///
  /// In en, this message translates to:
  /// **'Save 50%'**
  String get subscriptionYearlySave;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get subscriptionPerMonth;

  /// No description provided for @subscriptionPerYear.
  ///
  /// In en, this message translates to:
  /// **'/year'**
  String get subscriptionPerYear;

  /// No description provided for @subscriptionFeatures.
  ///
  /// In en, this message translates to:
  /// **'Unlimited likes • Advanced filters • See who liked you • Priority support'**
  String get subscriptionFeatures;

  /// No description provided for @subscriptionRestoreSuccess.
  ///
  /// In en, this message translates to:
  /// **'Subscription restored successfully.'**
  String get subscriptionRestoreSuccess;

  /// No description provided for @subscriptionRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'No subscription found to restore.'**
  String get subscriptionRestoreFailed;

  /// No description provided for @subscriptionPurchaseSuccess.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Swaply Premium!'**
  String get subscriptionPurchaseSuccess;

  /// No description provided for @subscriptionPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get subscriptionPurchaseFailed;

  /// No description provided for @subscriptionStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store is unavailable. Please try again later.'**
  String get subscriptionStoreUnavailable;

  /// No description provided for @subscriptionLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get subscriptionLoading;

  /// No description provided for @paymentComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Payment methods coming soon. We\'re preparing the best experience for you.'**
  String get paymentComingSoon;

  /// No description provided for @planSwaplyPlus.
  ///
  /// In en, this message translates to:
  /// **'Swaply+'**
  String get planSwaplyPlus;

  /// No description provided for @planSwaplyUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Swaply UNLIMITED'**
  String get planSwaplyUnlimited;

  /// No description provided for @planRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get planRecommended;

  /// No description provided for @selectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectPlan;

  /// No description provided for @featureUnlimitedLikes.
  ///
  /// In en, this message translates to:
  /// **'Send likes to find matches'**
  String get featureUnlimitedLikes;

  /// No description provided for @featureUnlimitedChat.
  ///
  /// In en, this message translates to:
  /// **'Unlimited chat with ALL your matches'**
  String get featureUnlimitedChat;

  /// No description provided for @featureSeeAllPhotos.
  ///
  /// In en, this message translates to:
  /// **'See all photos'**
  String get featureSeeAllPhotos;

  /// No description provided for @featureSeeProfilePhotos.
  ///
  /// In en, this message translates to:
  /// **'See profile photos'**
  String get featureSeeProfilePhotos;

  /// No description provided for @featureAdvancedFilters.
  ///
  /// In en, this message translates to:
  /// **'Advanced search filters'**
  String get featureAdvancedFilters;

  /// No description provided for @featureSeeWhoLiked.
  ///
  /// In en, this message translates to:
  /// **'See who liked you'**
  String get featureSeeWhoLiked;

  /// No description provided for @featureSeeVisits.
  ///
  /// In en, this message translates to:
  /// **'See all profile visits'**
  String get featureSeeVisits;

  /// No description provided for @featureNewestFirst.
  ///
  /// In en, this message translates to:
  /// **'Sort by newest members'**
  String get featureNewestFirst;

  /// No description provided for @featurePersonalityAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Relationship personality analysis'**
  String get featurePersonalityAnalysis;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/month'**
  String get perMonth;

  /// No description provided for @featureChatLimited.
  ///
  /// In en, this message translates to:
  /// **'15 chats with your matches'**
  String get featureChatLimited;

  /// No description provided for @featureGiftRoses.
  ///
  /// In en, this message translates to:
  /// **'Roses'**
  String get featureGiftRoses;

  /// No description provided for @featureGiftRings.
  ///
  /// In en, this message translates to:
  /// **'Rings'**
  String get featureGiftRings;

  /// No description provided for @featureGiftBooks.
  ///
  /// In en, this message translates to:
  /// **'Books'**
  String get featureGiftBooks;

  /// No description provided for @featureGiftCoffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee cup'**
  String get featureGiftCoffee;

  /// No description provided for @swaplySubscription.
  ///
  /// In en, this message translates to:
  /// **'Swaply Subscription'**
  String get swaplySubscription;

  /// No description provided for @featureSendGifts.
  ///
  /// In en, this message translates to:
  /// **'Send gifts'**
  String get featureSendGifts;

  /// No description provided for @tapToViewConversation.
  ///
  /// In en, this message translates to:
  /// **'Tap to view conversation'**
  String get tapToViewConversation;

  /// No description provided for @chatFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter conversations'**
  String get chatFilterTitle;

  /// No description provided for @chatFilterNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get chatFilterNewest;

  /// No description provided for @chatFilterOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get chatFilterOldest;

  /// No description provided for @chatFilterGiftsOnly.
  ///
  /// In en, this message translates to:
  /// **'Who sent gifts'**
  String get chatFilterGiftsOnly;

  /// No description provided for @chatFilterUnreadOnly.
  ///
  /// In en, this message translates to:
  /// **'Unread messages'**
  String get chatFilterUnreadOnly;

  /// No description provided for @newMatchLabel.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get newMatchLabel;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @sendReport.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendReport;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @reportAbuse.
  ///
  /// In en, this message translates to:
  /// **'Report abuse'**
  String get reportAbuse;

  /// No description provided for @blockConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Do you want to block {name}? They won\'t be able to send messages or see your profile.'**
  String blockConfirmMessage(Object name);

  /// No description provided for @reportConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'The report will be reviewed. Do you want to report abuse from {name}?'**
  String reportConfirmMessage(Object name);

  /// No description provided for @blockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Blocked successfully'**
  String get blockedSuccess;

  /// No description provided for @blockedCannotSend.
  ///
  /// In en, this message translates to:
  /// **'You can\'t send messages; you\'ve been blocked by the other person.'**
  String get blockedCannotSend;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSent;

  /// No description provided for @complaintReason.
  ///
  /// In en, this message translates to:
  /// **'Reason for complaint'**
  String get complaintReason;

  /// No description provided for @complaintEvidence.
  ///
  /// In en, this message translates to:
  /// **'Evidence (screenshot of abuse)'**
  String get complaintEvidence;

  /// No description provided for @complaintReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what happened...'**
  String get complaintReasonHint;

  /// No description provided for @complaintAddEvidence.
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get complaintAddEvidence;

  /// No description provided for @complaintReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter the reason'**
  String get complaintReasonRequired;

  /// No description provided for @complaintEvidenceRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add an image as evidence'**
  String get complaintEvidenceRequired;

  /// No description provided for @submitComplaint.
  ///
  /// In en, this message translates to:
  /// **'Submit a complaint'**
  String get submitComplaint;

  /// No description provided for @submitComplaintDescription.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue and attach a screenshot. We will review it.'**
  String get submitComplaintDescription;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get profileLoadFailed;

  /// No description provided for @noProfileData.
  ///
  /// In en, this message translates to:
  /// **'No profile data available'**
  String get noProfileData;

  /// No description provided for @pollVoteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to register vote'**
  String get pollVoteFailed;

  /// No description provided for @phoneNumberInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get phoneNumberInvalid;

  /// No description provided for @enterCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit code'**
  String get enterCodeHint;

  /// No description provided for @yourBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// No description provided for @rosesBalance.
  ///
  /// In en, this message translates to:
  /// **'{count} roses'**
  String rosesBalance(Object count);

  /// No description provided for @buyRoses.
  ///
  /// In en, this message translates to:
  /// **'Buy roses'**
  String get buyRoses;

  /// No description provided for @insufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance. Buy more to send this gift.'**
  String get insufficientBalance;

  /// No description provided for @buyRosesBundle.
  ///
  /// In en, this message translates to:
  /// **'Buy {count} roses for {price}'**
  String buyRosesBundle(Object count, Object price);

  /// No description provided for @paymentComingSoonGifts.
  ///
  /// In en, this message translates to:
  /// **'Payment coming soon. For now you have demo balance.'**
  String get paymentComingSoonGifts;

  /// No description provided for @giftSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Gift sent!'**
  String get giftSentSuccess;

  /// No description provided for @rosesAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} roses added to your balance'**
  String rosesAdded(Object count);

  /// No description provided for @bestValue.
  ///
  /// In en, this message translates to:
  /// **'Best value'**
  String get bestValue;

  /// No description provided for @perRose.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String perRose(Object price);

  /// No description provided for @giftMessagePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Message with your gift'**
  String get giftMessagePlaceholder;

  /// No description provided for @sendGiftFromDiscovery.
  ///
  /// In en, this message translates to:
  /// **'Don\'t hesitate.. Make their day brighter'**
  String get sendGiftFromDiscovery;

  /// No description provided for @giftsAvailableWithRealProfiles.
  ///
  /// In en, this message translates to:
  /// **'Send gifts with real profiles'**
  String get giftsAvailableWithRealProfiles;

  /// No description provided for @buyRings.
  ///
  /// In en, this message translates to:
  /// **'Buy rings'**
  String get buyRings;

  /// No description provided for @buyCoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy coffee'**
  String get buyCoffee;

  /// No description provided for @buyNow.
  ///
  /// In en, this message translates to:
  /// **'Buy now'**
  String get buyNow;

  /// No description provided for @ringsAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} rings added'**
  String ringsAdded(Object count);

  /// No description provided for @coffeeAdded.
  ///
  /// In en, this message translates to:
  /// **'+{count} coffee added'**
  String coffeeAdded(Object count);

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'{price} each'**
  String perUnit(Object price);

  /// No description provided for @lifestyle.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get lifestyle;

  /// No description provided for @interestsSelected.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get interestsSelected;

  /// No description provided for @retryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again in a moment.'**
  String get retryAgain;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @spotifyBrand.
  ///
  /// In en, this message translates to:
  /// **'Spotify'**
  String get spotifyBrand;

  /// No description provided for @exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get exercise;

  /// No description provided for @likeLimitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your like limit'**
  String get likeLimitReachedTitle;

  /// No description provided for @likeLimitReachedMessage.
  ///
  /// In en, this message translates to:
  /// **'You can like again in:'**
  String get likeLimitReachedMessage;

  /// No description provided for @likeLimitSubscribeCta.
  ///
  /// In en, this message translates to:
  /// **'Subscribe for unlimited likes'**
  String get likeLimitSubscribeCta;

  /// No description provided for @likeLimitOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get likeLimitOk;

  /// No description provided for @likesRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} likes remaining'**
  String likesRemaining(Object count);

  /// No description provided for @filterEthnicityAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get filterEthnicityAsian;

  /// No description provided for @filterEthnicityBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get filterEthnicityBlack;

  /// No description provided for @filterEthnicityWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get filterEthnicityWhite;

  /// No description provided for @filterEthnicityLatino.
  ///
  /// In en, this message translates to:
  /// **'Latino'**
  String get filterEthnicityLatino;

  /// No description provided for @filterEthnicityMiddleEastern.
  ///
  /// In en, this message translates to:
  /// **'Middle Eastern'**
  String get filterEthnicityMiddleEastern;

  /// No description provided for @filterEthnicityOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get filterEthnicityOther;

  /// No description provided for @filterRelationshipMonogamy.
  ///
  /// In en, this message translates to:
  /// **'Monogamy'**
  String get filterRelationshipMonogamy;

  /// No description provided for @filterRelationshipNonMonogamy.
  ///
  /// In en, this message translates to:
  /// **'Non-monogamy'**
  String get filterRelationshipNonMonogamy;

  /// No description provided for @filterRelationshipOpenToBoth.
  ///
  /// In en, this message translates to:
  /// **'Open to both'**
  String get filterRelationshipOpenToBoth;

  /// No description provided for @filterDatingRelationship.
  ///
  /// In en, this message translates to:
  /// **'Relationship'**
  String get filterDatingRelationship;

  /// No description provided for @filterDatingCasual.
  ///
  /// In en, this message translates to:
  /// **'Something casual'**
  String get filterDatingCasual;

  /// No description provided for @filterDatingNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet'**
  String get filterDatingNotSure;

  /// No description provided for @filterChildrenHaveKids.
  ///
  /// In en, this message translates to:
  /// **'Have kids'**
  String get filterChildrenHaveKids;

  /// No description provided for @filterChildrenWantKids.
  ///
  /// In en, this message translates to:
  /// **'Want kids'**
  String get filterChildrenWantKids;

  /// No description provided for @filterChildrenDontWant.
  ///
  /// In en, this message translates to:
  /// **'Don\'t want kids'**
  String get filterChildrenDontWant;

  /// No description provided for @filterChildrenNotSure.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get filterChildrenNotSure;

  /// No description provided for @zodiacNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get zodiacNone;

  /// No description provided for @zodiacAries.
  ///
  /// In en, this message translates to:
  /// **'Aries'**
  String get zodiacAries;

  /// No description provided for @zodiacTaurus.
  ///
  /// In en, this message translates to:
  /// **'Taurus'**
  String get zodiacTaurus;

  /// No description provided for @zodiacGemini.
  ///
  /// In en, this message translates to:
  /// **'Gemini'**
  String get zodiacGemini;

  /// No description provided for @zodiacCancer.
  ///
  /// In en, this message translates to:
  /// **'Cancer'**
  String get zodiacCancer;

  /// No description provided for @zodiacLeo.
  ///
  /// In en, this message translates to:
  /// **'Leo'**
  String get zodiacLeo;

  /// No description provided for @zodiacVirgo.
  ///
  /// In en, this message translates to:
  /// **'Virgo'**
  String get zodiacVirgo;

  /// No description provided for @zodiacLibra.
  ///
  /// In en, this message translates to:
  /// **'Libra'**
  String get zodiacLibra;

  /// No description provided for @zodiacScorpio.
  ///
  /// In en, this message translates to:
  /// **'Scorpio'**
  String get zodiacScorpio;

  /// No description provided for @zodiacSagittarius.
  ///
  /// In en, this message translates to:
  /// **'Sagittarius'**
  String get zodiacSagittarius;

  /// No description provided for @zodiacCapricorn.
  ///
  /// In en, this message translates to:
  /// **'Capricorn'**
  String get zodiacCapricorn;

  /// No description provided for @zodiacAquarius.
  ///
  /// In en, this message translates to:
  /// **'Aquarius'**
  String get zodiacAquarius;

  /// No description provided for @zodiacPisces.
  ///
  /// In en, this message translates to:
  /// **'Pisces'**
  String get zodiacPisces;

  /// No description provided for @petNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get petNone;

  /// No description provided for @petCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petCat;

  /// No description provided for @petDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get petDog;

  /// No description provided for @petFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get petFish;

  /// No description provided for @petRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get petRabbit;

  /// No description provided for @petBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get petBird;

  /// No description provided for @petHamster.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get petHamster;

  /// No description provided for @petOther.
  ///
  /// In en, this message translates to:
  /// **'Other pets'**
  String get petOther;

  /// No description provided for @messageActionReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get messageActionReply;

  /// No description provided for @messageActionReact.
  ///
  /// In en, this message translates to:
  /// **'React'**
  String get messageActionReact;

  /// No description provided for @messageActionCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get messageActionCopy;

  /// No description provided for @messageActionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get messageActionDelete;

  /// No description provided for @messageDeletedForBoth.
  ///
  /// In en, this message translates to:
  /// **'Message deleted for both'**
  String get messageDeletedForBoth;

  /// No description provided for @messageCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get messageCopied;

  /// No description provided for @youCrushedWithSwaply.
  ///
  /// In en, this message translates to:
  /// **'You Crushed\nwith Swaply'**
  String get youCrushedWithSwaply;

  /// No description provided for @swaplyTeam.
  ///
  /// In en, this message translates to:
  /// **'The Swaply team'**
  String get swaplyTeam;

  /// No description provided for @swaplyWelcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Swaply. Your safety and satisfaction are our priority. We work every day for a secure and enjoyable experience. Start the conversation and find your match.'**
  String get swaplyWelcomeMessage;

  /// No description provided for @swaplyWelcomeMessageWithName.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}, to the Swaply community!\n\nWe are thrilled to have you. We are here to ensure you have a fun and completely safe experience, with your privacy and satisfaction at the heart of everything we do in the app.\n\nOur team works hard behind the scenes to provide an interactive environment that matches your aspirations and helps you build real, successful connections. Feel free to explore the features and start your first conversation—the perfect Match is waiting for you!\n\nBest regards,\nThe Swaply team'**
  String swaplyWelcomeMessageWithName(String userName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'af',
    'am',
    'ar',
    'bg',
    'bn',
    'ca',
    'cs',
    'da',
    'de',
    'el',
    'en',
    'es',
    'eu',
    'fa',
    'fi',
    'fr',
    'gl',
    'gu',
    'ha',
    'he',
    'hi',
    'hr',
    'hu',
    'id',
    'ig',
    'it',
    'ja',
    'kn',
    'ko',
    'ml',
    'mr',
    'ms',
    'nl',
    'no',
    'pa',
    'pl',
    'pt',
    'ro',
    'ru',
    'sk',
    'sr',
    'sv',
    'sw',
    'ta',
    'te',
    'th',
    'tl',
    'tr',
    'uk',
    'ur',
    'vi',
    'yo',
    'zh',
    'zu',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'af':
      return AppLocalizationsAf();
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'bg':
      return AppLocalizationsBg();
    case 'bn':
      return AppLocalizationsBn();
    case 'ca':
      return AppLocalizationsCa();
    case 'cs':
      return AppLocalizationsCs();
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'el':
      return AppLocalizationsEl();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'eu':
      return AppLocalizationsEu();
    case 'fa':
      return AppLocalizationsFa();
    case 'fi':
      return AppLocalizationsFi();
    case 'fr':
      return AppLocalizationsFr();
    case 'gl':
      return AppLocalizationsGl();
    case 'gu':
      return AppLocalizationsGu();
    case 'ha':
      return AppLocalizationsHa();
    case 'he':
      return AppLocalizationsHe();
    case 'hi':
      return AppLocalizationsHi();
    case 'hr':
      return AppLocalizationsHr();
    case 'hu':
      return AppLocalizationsHu();
    case 'id':
      return AppLocalizationsId();
    case 'ig':
      return AppLocalizationsIg();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'kn':
      return AppLocalizationsKn();
    case 'ko':
      return AppLocalizationsKo();
    case 'ml':
      return AppLocalizationsMl();
    case 'mr':
      return AppLocalizationsMr();
    case 'ms':
      return AppLocalizationsMs();
    case 'nl':
      return AppLocalizationsNl();
    case 'no':
      return AppLocalizationsNo();
    case 'pa':
      return AppLocalizationsPa();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'ro':
      return AppLocalizationsRo();
    case 'ru':
      return AppLocalizationsRu();
    case 'sk':
      return AppLocalizationsSk();
    case 'sr':
      return AppLocalizationsSr();
    case 'sv':
      return AppLocalizationsSv();
    case 'sw':
      return AppLocalizationsSw();
    case 'ta':
      return AppLocalizationsTa();
    case 'te':
      return AppLocalizationsTe();
    case 'th':
      return AppLocalizationsTh();
    case 'tl':
      return AppLocalizationsTl();
    case 'tr':
      return AppLocalizationsTr();
    case 'uk':
      return AppLocalizationsUk();
    case 'ur':
      return AppLocalizationsUr();
    case 'vi':
      return AppLocalizationsVi();
    case 'yo':
      return AppLocalizationsYo();
    case 'zh':
      return AppLocalizationsZh();
    case 'zu':
      return AppLocalizationsZu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
