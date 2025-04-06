import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'messages_ar.dart';
import 'messages_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of S
/// returned by `S.of(context)`.
///
/// Applications need to include `S.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/messages.dart';
///
/// return MaterialApp(
///   localizationsDelegates: S.localizationsDelegates,
///   supportedLocales: S.supportedLocales,
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
/// be consistent with the languages listed in the S.supportedLocales
/// property.
abstract class S {
  S(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static S of(BuildContext context) {
    return Localizations.of<S>(context, S)!;
  }

  static const LocalizationsDelegate<S> delegate = _SDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Horse Wildness'**
  String get appName;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'SAR'**
  String get currency;

  /// No description provided for @you_are_offline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get you_are_offline;

  /// No description provided for @please_connect_to_the_internet_and_try_again.
  ///
  /// In en, this message translates to:
  /// **'Please connect to the internet and try again.'**
  String get please_connect_to_the_internet_and_try_again;

  /// No description provided for @try_again_please.
  ///
  /// In en, this message translates to:
  /// **'Try again please.'**
  String get try_again_please;

  /// No description provided for @pdf_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while downloading the file'**
  String get pdf_error;

  /// No description provided for @arabic_language.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic_language;

  /// No description provided for @english_language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english_language;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @continue_as_guest.
  ///
  /// In en, this message translates to:
  /// **'Continue as a guest'**
  String get continue_as_guest;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @unauthorized_login_to_continue.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to continue'**
  String get unauthorized_login_to_continue;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @open_store.
  ///
  /// In en, this message translates to:
  /// **'Open store'**
  String get open_store;

  /// No description provided for @registration_license.
  ///
  /// In en, this message translates to:
  /// **'Registration licenses'**
  String get registration_license;

  /// No description provided for @my_comments.
  ///
  /// In en, this message translates to:
  /// **'My comments'**
  String get my_comments;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @my_store.
  ///
  /// In en, this message translates to:
  /// **'My store'**
  String get my_store;

  /// No description provided for @store.
  ///
  /// In en, this message translates to:
  /// **'Store'**
  String get store;

  /// No description provided for @store_details.
  ///
  /// In en, this message translates to:
  /// **'Store details'**
  String get store_details;

  /// No description provided for @ad_count.
  ///
  /// In en, this message translates to:
  /// **'Ad count'**
  String get ad_count;

  /// No description provided for @product_count.
  ///
  /// In en, this message translates to:
  /// **'Product count'**
  String get product_count;

  /// No description provided for @stores.
  ///
  /// In en, this message translates to:
  /// **'Stores'**
  String get stores;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @my_transactions.
  ///
  /// In en, this message translates to:
  /// **'My transactions'**
  String get my_transactions;

  /// No description provided for @my_ads.
  ///
  /// In en, this message translates to:
  /// **'My ads'**
  String get my_ads;

  /// No description provided for @ads.
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get ads;

  /// No description provided for @promote_ad.
  ///
  /// In en, this message translates to:
  /// **'Promote ad'**
  String get promote_ad;

  /// No description provided for @pin_ad.
  ///
  /// In en, this message translates to:
  /// **'Pin ad'**
  String get pin_ad;

  /// No description provided for @unpin_ad.
  ///
  /// In en, this message translates to:
  /// **'Unpin ad'**
  String get unpin_ad;

  /// No description provided for @delete_ad.
  ///
  /// In en, this message translates to:
  /// **'Delete ad'**
  String get delete_ad;

  /// No description provided for @edit_ad.
  ///
  /// In en, this message translates to:
  /// **'Edit ad'**
  String get edit_ad;

  /// No description provided for @my_points.
  ///
  /// In en, this message translates to:
  /// **'My points'**
  String get my_points;

  /// No description provided for @points.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get points;

  /// No description provided for @promotion_options.
  ///
  /// In en, this message translates to:
  /// **'Promotion options'**
  String get promotion_options;

  /// No description provided for @favourite.
  ///
  /// In en, this message translates to:
  /// **'Favourite'**
  String get favourite;

  /// No description provided for @favourites.
  ///
  /// In en, this message translates to:
  /// **'Favourites'**
  String get favourites;

  /// No description provided for @my_favourites.
  ///
  /// In en, this message translates to:
  /// **'My favourites'**
  String get my_favourites;

  /// No description provided for @contact_us.
  ///
  /// In en, this message translates to:
  /// **'Contact us'**
  String get contact_us;

  /// No description provided for @about_us.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get about_us;

  /// No description provided for @terms_and_conditions.
  ///
  /// In en, this message translates to:
  /// **'Terms and conditions'**
  String get terms_and_conditions;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacy_policy;

  /// No description provided for @faq.
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @chat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'password'**
  String get password;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get full_name;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get last_name;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @choose_ad.
  ///
  /// In en, this message translates to:
  /// **'Choose ad'**
  String get choose_ad;

  /// No description provided for @similar_ads.
  ///
  /// In en, this message translates to:
  /// **'Similar ads'**
  String get similar_ads;

  /// No description provided for @commission.
  ///
  /// In en, this message translates to:
  /// **'Commission'**
  String get commission;

  /// No description provided for @promise_to_pay.
  ///
  /// In en, this message translates to:
  /// **'Promise to pay'**
  String get promise_to_pay;

  /// No description provided for @pay_commission.
  ///
  /// In en, this message translates to:
  /// **'Pay commission'**
  String get pay_commission;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Safety status'**
  String get health;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @mother.
  ///
  /// In en, this message translates to:
  /// **'Mother'**
  String get mother;

  /// No description provided for @father.
  ///
  /// In en, this message translates to:
  /// **'Father'**
  String get father;

  /// No description provided for @height.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// No description provided for @session_count.
  ///
  /// In en, this message translates to:
  /// **'Session count'**
  String get session_count;

  /// No description provided for @training_type.
  ///
  /// In en, this message translates to:
  /// **'Training type'**
  String get training_type;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @add_comment.
  ///
  /// In en, this message translates to:
  /// **'Add comment'**
  String get add_comment;

  /// No description provided for @whatsapp_url.
  ///
  /// In en, this message translates to:
  /// **'Whatsapp url'**
  String get whatsapp_url;

  /// No description provided for @facebook_url.
  ///
  /// In en, this message translates to:
  /// **'Facebook url'**
  String get facebook_url;

  /// No description provided for @tiktok_url.
  ///
  /// In en, this message translates to:
  /// **'Tiktok url'**
  String get tiktok_url;

  /// No description provided for @ad_title.
  ///
  /// In en, this message translates to:
  /// **'Ad title'**
  String get ad_title;

  /// No description provided for @ad_title_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Horse for sale'**
  String get ad_title_hint;

  /// No description provided for @mother_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Mohra Alshaqab'**
  String get mother_hint;

  /// No description provided for @father_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Marawan Alshaqab'**
  String get father_hint;

  /// No description provided for @height_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: 170cm'**
  String get height_hint;

  /// No description provided for @session_count_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: 10 sessions'**
  String get session_count_hint;

  /// No description provided for @training_type_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Individual training'**
  String get training_type_hint;

  /// No description provided for @description_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Horse description'**
  String get description_hint;

  /// No description provided for @upload_horse_panorama_image.
  ///
  /// In en, this message translates to:
  /// **'Upload horse panorama image'**
  String get upload_horse_panorama_image;

  /// No description provided for @upload_horse_images.
  ///
  /// In en, this message translates to:
  /// **'Upload horse images'**
  String get upload_horse_images;

  /// No description provided for @horse_panorama_image.
  ///
  /// In en, this message translates to:
  /// **'Horse panorama image'**
  String get horse_panorama_image;

  /// No description provided for @age_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: 4 years'**
  String get age_hint;

  /// No description provided for @health_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: Good'**
  String get health_hint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @personal_information.
  ///
  /// In en, this message translates to:
  /// **'Personal information'**
  String get personal_information;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @horse_images.
  ///
  /// In en, this message translates to:
  /// **'Horse images'**
  String get horse_images;

  /// No description provided for @whatsapp_num.
  ///
  /// In en, this message translates to:
  /// **'Whatsapp number'**
  String get whatsapp_num;

  /// No description provided for @whatsapp_num_hint.
  ///
  /// In en, this message translates to:
  /// **'ex: 0551234567'**
  String get whatsapp_num_hint;

  /// No description provided for @snapchat_url.
  ///
  /// In en, this message translates to:
  /// **'Snapchat url'**
  String get snapchat_url;

  /// No description provided for @instagram_url.
  ///
  /// In en, this message translates to:
  /// **'Instagram url'**
  String get instagram_url;

  /// No description provided for @youtube_url.
  ///
  /// In en, this message translates to:
  /// **'Youtube url'**
  String get youtube_url;

  /// No description provided for @contact_url.
  ///
  /// In en, this message translates to:
  /// **'Contact url'**
  String get contact_url;

  /// No description provided for @website_url.
  ///
  /// In en, this message translates to:
  /// **'Website url'**
  String get website_url;

  /// No description provided for @name_val.
  ///
  /// In en, this message translates to:
  /// **'Name should not be empty'**
  String get name_val;

  /// No description provided for @empty_val.
  ///
  /// In en, this message translates to:
  /// **'Value should not be empty'**
  String get empty_val;

  /// No description provided for @phone_empty_val.
  ///
  /// In en, this message translates to:
  /// **'The phone must not be empty'**
  String get phone_empty_val;

  /// No description provided for @phone_valid_val.
  ///
  /// In en, this message translates to:
  /// **'Phone number should be valid'**
  String get phone_valid_val;

  /// No description provided for @password_empty_val.
  ///
  /// In en, this message translates to:
  /// **'Password must not be empty'**
  String get password_empty_val;

  /// No description provided for @password_length_val.
  ///
  /// In en, this message translates to:
  /// **'Password must be more than 6 characters'**
  String get password_length_val;

  /// No description provided for @email_empty_val.
  ///
  /// In en, this message translates to:
  /// **'Email must not be empty'**
  String get email_empty_val;

  /// No description provided for @email_valid_val.
  ///
  /// In en, this message translates to:
  /// **'Email should be valid'**
  String get email_valid_val;

  /// No description provided for @confirm_password_empty_val.
  ///
  /// In en, this message translates to:
  /// **'Confirm password must not be empty'**
  String get confirm_password_empty_val;

  /// No description provided for @confirm_password_match_val.
  ///
  /// In en, this message translates to:
  /// **'Password and confirm password must match'**
  String get confirm_password_match_val;

  /// No description provided for @address_empty_val.
  ///
  /// In en, this message translates to:
  /// **'Address must not be empty'**
  String get address_empty_val;

  /// No description provided for @resend_code_in.
  ///
  /// In en, this message translates to:
  /// **'Resend code in'**
  String get resend_code_in;

  /// No description provided for @s.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get s;

  /// No description provided for @resend_code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resend_code;

  /// No description provided for @resend_code_title.
  ///
  /// In en, this message translates to:
  /// **'Didn’t get the code?  '**
  String get resend_code_title;

  /// No description provided for @change_password_success_title.
  ///
  /// In en, this message translates to:
  /// **'Password changed Successfully'**
  String get change_password_success_title;

  /// No description provided for @change_password_success_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, your Password has been changed. You can start using the new password'**
  String get change_password_success_subtitle;

  /// No description provided for @thank_you.
  ///
  /// In en, this message translates to:
  /// **'Thank You!'**
  String get thank_you;

  /// No description provided for @order_success_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed successfully. You will receive a confirmation email shortly.'**
  String get order_success_subtitle;

  /// No description provided for @verify_register_success_title.
  ///
  /// In en, this message translates to:
  /// **'Phone number verified successfully'**
  String get verify_register_success_title;

  /// No description provided for @verify_register_success_body.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, Phone number has been verified. You can start using the app'**
  String get verify_register_success_body;

  /// No description provided for @reset_password_success_title.
  ///
  /// In en, this message translates to:
  /// **'Reset password Successful'**
  String get reset_password_success_title;

  /// No description provided for @reset_password_success_body.
  ///
  /// In en, this message translates to:
  /// **'Congratulations, your password has been reset successfully. You can start using your new password'**
  String get reset_password_success_body;

  /// No description provided for @continue_title.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continue_title;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Please Try Again'**
  String get try_again;

  /// No description provided for @username_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your username.'**
  String get username_empty;

  /// No description provided for @username_short.
  ///
  /// In en, this message translates to:
  /// **'Your username must be at least 2 characters long.'**
  String get username_short;

  /// No description provided for @email_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get email_empty;

  /// No description provided for @email_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get email_invalid;

  /// No description provided for @password_empty.
  ///
  /// In en, this message translates to:
  /// **'Please create a password.'**
  String get password_empty;

  /// No description provided for @password_short.
  ///
  /// In en, this message translates to:
  /// **'Your password must be at least 8 characters long.'**
  String get password_short;

  /// No description provided for @password_complexity.
  ///
  /// In en, this message translates to:
  /// **'Your password must contain at least one uppercase letter, one lowercase letter, one number, and one special character.'**
  String get password_complexity;

  /// No description provided for @confirmPassword_empty.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get confirmPassword_empty;

  /// No description provided for @confirmPassword_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match. Please try again.'**
  String get confirmPassword_mismatch;

  /// No description provided for @phone_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number.'**
  String get phone_empty;

  /// No description provided for @phone_unsupported_country.
  ///
  /// In en, this message translates to:
  /// **'Unsupported country code. Please enter a valid country code.'**
  String get phone_unsupported_country;

  /// No description provided for @phone_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get phone_invalid;

  /// No description provided for @normalPhone_invalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get normalPhone_invalid;

  /// No description provided for @address_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address.'**
  String get address_empty;

  /// No description provided for @firstName_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name.'**
  String get firstName_empty;

  /// No description provided for @lastName_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name.'**
  String get lastName_empty;

  /// No description provided for @notEmpty_required.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get notEmpty_required;

  /// No description provided for @otp_empty.
  ///
  /// In en, this message translates to:
  /// **'Please enter your OTP.'**
  String get otp_empty;

  /// No description provided for @otp_4_digits.
  ///
  /// In en, this message translates to:
  /// **'Your OTP must be 4 digits.'**
  String get otp_4_digits;

  /// No description provided for @otp_valid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid OTP.'**
  String get otp_valid;

  /// No description provided for @location_val.
  ///
  /// In en, this message translates to:
  /// **'you must enable your location from settings until you can scan qr'**
  String get location_val;

  /// No description provided for @app_settings.
  ///
  /// In en, this message translates to:
  /// **'App settings'**
  String get app_settings;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone.'**
  String get delete_account_title;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancle'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @please_select_a_payment_method.
  ///
  /// In en, this message translates to:
  /// **'Please select a payment method'**
  String get please_select_a_payment_method;

  /// No description provided for @payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// No description provided for @an_error_occurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get an_error_occurred;

  /// No description provided for @login_title.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_title;

  /// No description provided for @login_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get login_subtitle;

  /// No description provided for @phone_hint.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone_hint;

  /// No description provided for @phone_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get phone_name;

  /// No description provided for @password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get password_hint;

  /// No description provided for @password_name.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_name;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @login_button.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login_button;

  /// No description provided for @no_account_title.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get no_account_title;

  /// No description provided for @full_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name_hint;

  /// No description provided for @full_name_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get full_name_name;

  /// No description provided for @email_hint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email_hint;

  /// No description provided for @email_name.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get email_name;

  /// No description provided for @confirm_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password_hint;

  /// No description provided for @confirm_password_name.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get confirm_password_name;

  /// No description provided for @already_have_account_title.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get already_have_account_title;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get create_account;

  /// No description provided for @forget_password_title.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forget_password_title;

  /// No description provided for @forget_password_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number or email associated with your account'**
  String get forget_password_subtitle;

  /// No description provided for @send_button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send_button;

  /// No description provided for @verification_title.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verification_title;

  /// No description provided for @verification_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter the 4-digit code sent to your phone number'**
  String get verification_subtitle;

  /// No description provided for @reset_password_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reset_password_title;

  /// No description provided for @new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password_hint;

  /// No description provided for @reset_button.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset_button;

  /// No description provided for @create_store.
  ///
  /// In en, this message translates to:
  /// **'Create Store'**
  String get create_store;

  /// No description provided for @store_image.
  ///
  /// In en, this message translates to:
  /// **'Store Image'**
  String get store_image;

  /// No description provided for @store_name.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get store_name;

  /// No description provided for @store_image_title.
  ///
  /// In en, this message translates to:
  /// **'Click to upload store image'**
  String get store_image_title;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @store_location.
  ///
  /// In en, this message translates to:
  /// **'Store Location'**
  String get store_location;

  /// No description provided for @working_hours.
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get working_hours;

  /// No description provided for @working_days.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get working_days;

  /// No description provided for @alwasy_open.
  ///
  /// In en, this message translates to:
  /// **'Always Open'**
  String get alwasy_open;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get sunday;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get friday;

  /// No description provided for @working_days_val.
  ///
  /// In en, this message translates to:
  /// **'You must select working days'**
  String get working_days_val;

  /// No description provided for @working_hours_val.
  ///
  /// In en, this message translates to:
  /// **'You must select working hours'**
  String get working_hours_val;

  /// No description provided for @open_time.
  ///
  /// In en, this message translates to:
  /// **'open Time'**
  String get open_time;

  /// No description provided for @close_time.
  ///
  /// In en, this message translates to:
  /// **'close Time'**
  String get close_time;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @add_licenses_title.
  ///
  /// In en, this message translates to:
  /// **'Add your store licenses to be authenticated'**
  String get add_licenses_title;

  /// No description provided for @commercial_register_photo.
  ///
  /// In en, this message translates to:
  /// **'Commercial Register Photo'**
  String get commercial_register_photo;

  /// No description provided for @commercial_register_from_official_documents.
  ///
  /// In en, this message translates to:
  /// **'Commercial Register from official documents'**
  String get commercial_register_from_official_documents;

  /// No description provided for @freelance_document_photo.
  ///
  /// In en, this message translates to:
  /// **'Freelance Document Photo'**
  String get freelance_document_photo;

  /// No description provided for @freelance_document_from_official_documents.
  ///
  /// In en, this message translates to:
  /// **'Freelance Document from official documents'**
  String get freelance_document_from_official_documents;

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @all_ads.
  ///
  /// In en, this message translates to:
  /// **'All advertisements'**
  String get all_ads;

  /// No description provided for @cars.
  ///
  /// In en, this message translates to:
  /// **'Cars'**
  String get cars;

  /// No description provided for @horse.
  ///
  /// In en, this message translates to:
  /// **'Horse'**
  String get horse;

  /// No description provided for @supplies.
  ///
  /// In en, this message translates to:
  /// **'Supplies'**
  String get supplies;

  /// No description provided for @stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stable;

  /// No description provided for @training.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get training;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'test'**
  String get test;

  /// No description provided for @rate.
  ///
  /// In en, this message translates to:
  /// **'Rate'**
  String get rate;

  /// No description provided for @who_we_are.
  ///
  /// In en, this message translates to:
  /// **'Who we are?'**
  String get who_we_are;

  /// No description provided for @no_title.
  ///
  /// In en, this message translates to:
  /// **'No title'**
  String get no_title;

  /// No description provided for @no_content.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get no_content;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @add_a_report.
  ///
  /// In en, this message translates to:
  /// **'Add a report'**
  String get add_a_report;

  /// No description provided for @stabilization.
  ///
  /// In en, this message translates to:
  /// **'Stabilization'**
  String get stabilization;

  /// No description provided for @ad_name.
  ///
  /// In en, this message translates to:
  /// **'Ad name'**
  String get ad_name;

  /// No description provided for @ad.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get ad;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period (days)'**
  String get period;

  /// No description provided for @stabilization_price_hint.
  ///
  /// In en, this message translates to:
  /// **'The stabilization price will be determined once the period is entered.'**
  String get stabilization_price_hint;

  /// No description provided for @stabilization_price.
  ///
  /// In en, this message translates to:
  /// **'Stabilization price'**
  String get stabilization_price;

  /// No description provided for @promotion.
  ///
  /// In en, this message translates to:
  /// **'Promotion'**
  String get promotion;

  /// No description provided for @promotion_price_hint.
  ///
  /// In en, this message translates to:
  /// **'The promotion price will be determined once the period is entered.'**
  String get promotion_price_hint;

  /// No description provided for @promotion_price.
  ///
  /// In en, this message translates to:
  /// **'Promotion price'**
  String get promotion_price;

  /// No description provided for @filter_results.
  ///
  /// In en, this message translates to:
  /// **'Filter results'**
  String get filter_results;

  /// No description provided for @price_range.
  ///
  /// In en, this message translates to:
  /// **'Price range'**
  String get price_range;

  /// No description provided for @min_price.
  ///
  /// In en, this message translates to:
  /// **'Min price'**
  String get min_price;

  /// No description provided for @max_price.
  ///
  /// In en, this message translates to:
  /// **'Max price'**
  String get max_price;

  /// No description provided for @min_rate.
  ///
  /// In en, this message translates to:
  /// **'Min rate'**
  String get min_rate;

  /// No description provided for @max_rate.
  ///
  /// In en, this message translates to:
  /// **'Max rate'**
  String get max_rate;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @no_chats.
  ///
  /// In en, this message translates to:
  /// **'No chats'**
  String get no_chats;

  /// No description provided for @confirm_reporting.
  ///
  /// In en, this message translates to:
  /// **'Confirm reporting'**
  String get confirm_reporting;

  /// No description provided for @chat_report_question.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this conversation?'**
  String get chat_report_question;

  /// No description provided for @report_reason.
  ///
  /// In en, this message translates to:
  /// **'Report reason'**
  String get report_reason;

  /// No description provided for @reported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reported;

  /// No description provided for @chat_was_reported.
  ///
  /// In en, this message translates to:
  /// **'Chat was reported'**
  String get chat_was_reported;

  /// No description provided for @confirm_delete.
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirm_delete;

  /// No description provided for @delete_chat_question.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the conversation?'**
  String get delete_chat_question;

  /// No description provided for @deleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get deleted;

  /// No description provided for @chat_was_deleted.
  ///
  /// In en, this message translates to:
  /// **'Chat was deleted'**
  String get chat_was_deleted;

  /// No description provided for @add_ad.
  ///
  /// In en, this message translates to:
  /// **'Add ad'**
  String get add_ad;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Loaction'**
  String get location;

  /// No description provided for @choose_location.
  ///
  /// In en, this message translates to:
  /// **'Choose location'**
  String get choose_location;

  /// No description provided for @price_type.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get price_type;

  /// No description provided for @view_price.
  ///
  /// In en, this message translates to:
  /// **'View price'**
  String get view_price;

  /// No description provided for @stabilized.
  ///
  /// In en, this message translates to:
  /// **'Stabilized'**
  String get stabilized;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @sale_rent.
  ///
  /// In en, this message translates to:
  /// **'Sale / Rent'**
  String get sale_rent;

  /// No description provided for @sale.
  ///
  /// In en, this message translates to:
  /// **'Sale'**
  String get sale;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @buying.
  ///
  /// In en, this message translates to:
  /// **'Buying'**
  String get buying;

  /// No description provided for @choose_classification.
  ///
  /// In en, this message translates to:
  /// **'Choose classification'**
  String get choose_classification;

  /// No description provided for @horses.
  ///
  /// In en, this message translates to:
  /// **'Horses'**
  String get horses;

  /// No description provided for @product_image.
  ///
  /// In en, this message translates to:
  /// **'Product image'**
  String get product_image;

  /// No description provided for @product_image_hint.
  ///
  /// In en, this message translates to:
  /// **'Upload a photo or video of the product'**
  String get product_image_hint;

  /// No description provided for @panorama_image.
  ///
  /// In en, this message translates to:
  /// **'Panorama image'**
  String get panorama_image;

  /// No description provided for @panorama_image_hint.
  ///
  /// In en, this message translates to:
  /// **'Upload panorama image'**
  String get panorama_image_hint;

  /// No description provided for @car_image.
  ///
  /// In en, this message translates to:
  /// **'Car image'**
  String get car_image;

  /// No description provided for @upload_car_image.
  ///
  /// In en, this message translates to:
  /// **'Upload car image'**
  String get upload_car_image;

  /// No description provided for @car_size_hint.
  ///
  /// In en, this message translates to:
  /// **'Car size (number of horses that can be transported in the Car)'**
  String get car_size_hint;

  /// No description provided for @car_size.
  ///
  /// In en, this message translates to:
  /// **'Car size'**
  String get car_size;

  /// No description provided for @product_name.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get product_name;

  /// No description provided for @product_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter product name'**
  String get product_name_hint;

  /// No description provided for @classification.
  ///
  /// In en, this message translates to:
  /// **'Classification'**
  String get classification;

  /// No description provided for @stable_image.
  ///
  /// In en, this message translates to:
  /// **'Stable image'**
  String get stable_image;

  /// No description provided for @stable_image_hint.
  ///
  /// In en, this message translates to:
  /// **'Uplaod stable image'**
  String get stable_image_hint;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @images_hint.
  ///
  /// In en, this message translates to:
  /// **'Upload images'**
  String get images_hint;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @sold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get sold;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @retweet.
  ///
  /// In en, this message translates to:
  /// **'Retweet'**
  String get retweet;

  /// No description provided for @my_payment.
  ///
  /// In en, this message translates to:
  /// **'My payment'**
  String get my_payment;

  /// No description provided for @payment_made.
  ///
  /// In en, this message translates to:
  /// **'Payment made via'**
  String get payment_made;

  /// No description provided for @success_payment.
  ///
  /// In en, this message translates to:
  /// **'Successful payment'**
  String get success_payment;

  /// No description provided for @days_count.
  ///
  /// In en, this message translates to:
  /// **'Days count'**
  String get days_count;

  /// No description provided for @points_count.
  ///
  /// In en, this message translates to:
  /// **'Points count'**
  String get points_count;

  /// No description provided for @replace_points.
  ///
  /// In en, this message translates to:
  /// **'Replace points'**
  String get replace_points;

  /// No description provided for @verification.
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get verification;

  /// No description provided for @commercial_register_images.
  ///
  /// In en, this message translates to:
  /// **'Commercial register images'**
  String get commercial_register_images;

  /// No description provided for @commission_payment.
  ///
  /// In en, this message translates to:
  /// **'Commission payment'**
  String get commission_payment;

  /// No description provided for @payment_value.
  ///
  /// In en, this message translates to:
  /// **'Payment value'**
  String get payment_value;

  /// No description provided for @payment_value_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter payment value'**
  String get payment_value_hint;

  /// No description provided for @enter_money_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter money amount'**
  String get enter_money_amount;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @payment_method.
  ///
  /// In en, this message translates to:
  /// **'Payment method'**
  String get payment_method;

  /// No description provided for @no_messages.
  ///
  /// In en, this message translates to:
  /// **'No messages'**
  String get no_messages;

  /// No description provided for @write_message.
  ///
  /// In en, this message translates to:
  /// **'Write your message here'**
  String get write_message;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get change_language;

  /// No description provided for @logout_hint.
  ///
  /// In en, this message translates to:
  /// **'You will need to enter your username and password the next time you want to log in.'**
  String get logout_hint;

  /// No description provided for @seller_details.
  ///
  /// In en, this message translates to:
  /// **'Seller details'**
  String get seller_details;

  /// No description provided for @recent_ads.
  ///
  /// In en, this message translates to:
  /// **'Recent ads'**
  String get recent_ads;

  /// No description provided for @store_rate.
  ///
  /// In en, this message translates to:
  /// **'Store rate'**
  String get store_rate;

  /// No description provided for @ad_number.
  ///
  /// In en, this message translates to:
  /// **'Ad ID'**
  String get ad_number;

  /// No description provided for @ad_id_was_copied.
  ///
  /// In en, this message translates to:
  /// **'Ad ID was copied'**
  String get ad_id_was_copied;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @watch_ad.
  ///
  /// In en, this message translates to:
  /// **'Watch ad '**
  String get watch_ad;

  /// No description provided for @on_jumoh.
  ///
  /// In en, this message translates to:
  /// **'On Jumoh Elkheil app'**
  String get on_jumoh;

  /// No description provided for @ad_rate.
  ///
  /// In en, this message translates to:
  /// **'Ad rate'**
  String get ad_rate;

  /// No description provided for @using_camera.
  ///
  /// In en, this message translates to:
  /// **'Using measuring camera'**
  String get using_camera;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @sales_count.
  ///
  /// In en, this message translates to:
  /// **'Sales count'**
  String get sales_count;

  /// No description provided for @pay_commission_hint.
  ///
  /// In en, this message translates to:
  /// **'Please pay 2.5% commission after completion of sale'**
  String get pay_commission_hint;

  /// No description provided for @individuals.
  ///
  /// In en, this message translates to:
  /// **'Individuals'**
  String get individuals;
}

class _SDelegate extends LocalizationsDelegate<S> {
  const _SDelegate();

  @override
  Future<S> load(Locale locale) {
    return SynchronousFuture<S>(lookupS(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_SDelegate old) => false;
}

S lookupS(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return SAr();
    case 'en': return SEn();
  }

  throw FlutterError(
    'S.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
