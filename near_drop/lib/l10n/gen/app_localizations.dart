import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Near Drop'**
  String get app_name;

  /// No description provided for @welcome_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share files nearby'**
  String get welcome_subtitle;

  /// No description provided for @welcome_preview_info_text.
  ///
  /// In en, this message translates to:
  /// **'Preview version'**
  String get welcome_preview_info_text;

  /// No description provided for @app_info_button.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get app_info_button;

  /// No description provided for @continue_button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get continue_button;

  /// No description provided for @app_info_title.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get app_info_title;

  /// No description provided for @imprint_title.
  ///
  /// In en, this message translates to:
  /// **'Imprint'**
  String get imprint_title;

  /// No description provided for @imprint_subtitle.
  ///
  /// In en, this message translates to:
  /// **'About the developer'**
  String get imprint_subtitle;

  /// No description provided for @data_privacy_title.
  ///
  /// In en, this message translates to:
  /// **'Data protection'**
  String get data_privacy_title;

  /// No description provided for @data_privacy_subtitle.
  ///
  /// In en, this message translates to:
  /// **'About the data processing'**
  String get data_privacy_subtitle;

  /// No description provided for @licenses_title.
  ///
  /// In en, this message translates to:
  /// **'Licences'**
  String get licenses_title;

  /// No description provided for @licenses_subtitle.
  ///
  /// In en, this message translates to:
  /// **'About used licenses'**
  String get licenses_subtitle;

  /// No description provided for @version_title.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version_title;

  /// No description provided for @guest_login_title.
  ///
  /// In en, this message translates to:
  /// **'Create profile'**
  String get guest_login_title;

  /// No description provided for @firstname_textfield_label.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstname_textfield_label;

  /// No description provided for @firstname_textfield_helper_text.
  ///
  /// In en, this message translates to:
  /// **'Other devices nearby will see this name.'**
  String get firstname_textfield_helper_text;

  /// No description provided for @guest_login_error_message.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while logging in. Please try again later.'**
  String get guest_login_error_message;

  /// No description provided for @data_protection_info_text_1.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get data_protection_info_text_1;

  /// No description provided for @data_protection_info_text_2.
  ///
  /// In en, this message translates to:
  /// **'data protection regulations'**
  String get data_protection_info_text_2;

  /// No description provided for @data_protection_info_text_3.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get data_protection_info_text_3;

  /// No description provided for @terms_info_text_1.
  ///
  /// In en, this message translates to:
  /// **'I have read and accept the '**
  String get terms_info_text_1;

  /// No description provided for @terms_info_text_2.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get terms_info_text_2;

  /// No description provided for @terms_info_text_3.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get terms_info_text_3;

  /// No description provided for @nearby_page_menu_icon_tooltip.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get nearby_page_menu_icon_tooltip;

  /// No description provided for @nearby_page_account_icon_tooltip.
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get nearby_page_account_icon_tooltip;

  /// No description provided for @nearby_page_manual_connection_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Connect manually'**
  String get nearby_page_manual_connection_tooltip;

  /// No description provided for @nearby_page_visibility_info_prefix.
  ///
  /// In en, this message translates to:
  /// **'You are visible as '**
  String get nearby_page_visibility_info_prefix;

  /// No description provided for @nearby_page_devices_label.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get nearby_page_devices_label;

  /// No description provided for @nearby_page_no_devices_found_balloon_title.
  ///
  /// In en, this message translates to:
  /// **'Device not found?'**
  String get nearby_page_no_devices_found_balloon_title;

  /// No description provided for @nearby_page_no_devices_found_balloon_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect you device via qr code.'**
  String get nearby_page_no_devices_found_balloon_subtitle;

  /// No description provided for @send_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Send to {firstname}'**
  String send_dialog_title(String firstname);

  /// No description provided for @send_dialog_files_label.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get send_dialog_files_label;

  /// No description provided for @send_dialog_media_label.
  ///
  /// In en, this message translates to:
  /// **'Photos & Videos'**
  String get send_dialog_media_label;

  /// No description provided for @cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel_button;

  /// No description provided for @send_request_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get send_request_dialog_title;

  /// No description provided for @send_request_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'{firstname} wants to send you {filesCount} {mimeType}.'**
  String send_request_dialog_content(
    String firstname,
    int filesCount,
    String mimeType,
  );

  /// No description provided for @mime_type_image.
  ///
  /// In en, this message translates to:
  /// **'image'**
  String get mime_type_image;

  /// No description provided for @mime_type_images.
  ///
  /// In en, this message translates to:
  /// **'images'**
  String get mime_type_images;

  /// No description provided for @mime_type_video.
  ///
  /// In en, this message translates to:
  /// **'video'**
  String get mime_type_video;

  /// No description provided for @mime_type_videos.
  ///
  /// In en, this message translates to:
  /// **'videos'**
  String get mime_type_videos;

  /// No description provided for @mime_type_audio.
  ///
  /// In en, this message translates to:
  /// **'audio'**
  String get mime_type_audio;

  /// No description provided for @mime_type_audios.
  ///
  /// In en, this message translates to:
  /// **'audios'**
  String get mime_type_audios;

  /// No description provided for @mime_type_media.
  ///
  /// In en, this message translates to:
  /// **'media files'**
  String get mime_type_media;

  /// No description provided for @mime_type_file.
  ///
  /// In en, this message translates to:
  /// **'file'**
  String get mime_type_file;

  /// No description provided for @mime_type_files.
  ///
  /// In en, this message translates to:
  /// **'files'**
  String get mime_type_files;

  /// No description provided for @accept_button.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept_button;

  /// No description provided for @decline_button.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline_button;

  /// No description provided for @communication_state_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting...'**
  String get communication_state_connecting;

  /// No description provided for @communication_state_requesting.
  ///
  /// In en, this message translates to:
  /// **'Requesting...'**
  String get communication_state_requesting;

  /// No description provided for @communication_state_sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get communication_state_sending;

  /// No description provided for @communication_state_receiving.
  ///
  /// In en, this message translates to:
  /// **'Receiving...'**
  String get communication_state_receiving;

  /// No description provided for @communication_state_canceling.
  ///
  /// In en, this message translates to:
  /// **'Canceling...'**
  String get communication_state_canceling;

  /// No description provided for @success_state_sended.
  ///
  /// In en, this message translates to:
  /// **'Sent!'**
  String get success_state_sended;

  /// No description provided for @success_state_received.
  ///
  /// In en, this message translates to:
  /// **'Received!'**
  String get success_state_received;

  /// No description provided for @error_state_error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error_state_error;

  /// No description provided for @error_state_receiver_declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get error_state_receiver_declined;

  /// No description provided for @error_state_canceled.
  ///
  /// In en, this message translates to:
  /// **'Aborted'**
  String get error_state_canceled;

  /// No description provided for @dialog_close_button.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialog_close_button;

  /// No description provided for @received_files_dialog_show_files_button.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get received_files_dialog_show_files_button;

  /// No description provided for @received_files_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'{filesCount} {mimeType} received from {firstname}'**
  String received_files_dialog_title(
    int filesCount,
    String mimeType,
    String firstname,
  );

  /// No description provided for @received_files_dialog_more_files_text.
  ///
  /// In en, this message translates to:
  /// **'+ {filesCount} more file(s)'**
  String received_files_dialog_more_files_text(int filesCount);

  /// No description provided for @data_volume_warning_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Send?'**
  String get data_volume_warning_dialog_title;

  /// No description provided for @data_volume_warning_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'This occurrence needs minimum {sizeText} of your data volume.'**
  String data_volume_warning_dialog_content(String sizeText);

  /// No description provided for @data_volume_warning_dialog_accept_button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get data_volume_warning_dialog_accept_button;

  /// No description provided for @manually_connecting_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Connect manually'**
  String get manually_connecting_sheet_title;

  /// No description provided for @manually_connecting_sheet_scan_button.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get manually_connecting_sheet_scan_button;

  /// No description provided for @qr_code_text.
  ///
  /// In en, this message translates to:
  /// **'Tell another person to scan this QR code with their device.'**
  String get qr_code_text;

  /// No description provided for @scan_qr_code.
  ///
  /// In en, this message translates to:
  /// **'Scan the QR code of another device.'**
  String get scan_qr_code;

  /// No description provided for @qr_code_error_no_permission.
  ///
  /// In en, this message translates to:
  /// **'Grant camera permission in settings.'**
  String get qr_code_error_no_permission;

  /// No description provided for @qr_code_error_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid QR code'**
  String get qr_code_error_invalid;

  /// No description provided for @qr_code_error_device_already_added.
  ///
  /// In en, this message translates to:
  /// **'Device already found'**
  String get qr_code_error_device_already_added;

  /// No description provided for @qr_code_error_device_request.
  ///
  /// In en, this message translates to:
  /// **'Device could not be contacted. Check your internet connection.'**
  String get qr_code_error_device_request;

  /// No description provided for @no_internet_connection_info_bar_title.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get no_internet_connection_info_bar_title;

  /// No description provided for @no_internet_connection_info_bar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to a network to send and receive files.'**
  String get no_internet_connection_info_bar_subtitle;

  /// No description provided for @bluetooth_not_supported_info_bar_title.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth not supported'**
  String get bluetooth_not_supported_info_bar_title;

  /// No description provided for @bluetooth_not_supported_info_bar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your device does not have a Bluetooth component. Devices nearby cannot be found.'**
  String get bluetooth_not_supported_info_bar_subtitle;

  /// No description provided for @bluetooth_no_permission_info_bar_title.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth permission missing'**
  String get bluetooth_no_permission_info_bar_title;

  /// No description provided for @bluetooth_no_permission_info_bar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Grant the app access to Bluetooth in the settings to find devices nearby.'**
  String get bluetooth_no_permission_info_bar_subtitle;

  /// No description provided for @bluetooth_disabled_info_bar_title.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth disabled'**
  String get bluetooth_disabled_info_bar_title;

  /// No description provided for @bluetooth_disabled_info_bar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable Bluetooth to find devices nearby.'**
  String get bluetooth_disabled_info_bar_subtitle;

  /// No description provided for @bluetooth_error_info_bar_title.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth error'**
  String get bluetooth_error_info_bar_title;

  /// No description provided for @bluetooth_error_info_bar_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Schaue in der Hilfe nach für Problemlösungen. Some Bluetooth processes have failed. Check the help for troubleshooting.'**
  String get bluetooth_error_info_bar_subtitle;

  /// No description provided for @drawer_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get drawer_close;

  /// No description provided for @account_page_title.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get account_page_title;

  /// No description provided for @account_page_change_firstname_label.
  ///
  /// In en, this message translates to:
  /// **'Change first name'**
  String get account_page_change_firstname_label;

  /// No description provided for @account_page_change_firstname_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Change first name'**
  String get account_page_change_firstname_dialog_title;

  /// No description provided for @account_page_change_firstname_textfield_label.
  ///
  /// In en, this message translates to:
  /// **'New first name'**
  String get account_page_change_firstname_textfield_label;

  /// No description provided for @account_page_change_firstname_dialog_save_button.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get account_page_change_firstname_dialog_save_button;

  /// No description provided for @account_page_show_my_data_label.
  ///
  /// In en, this message translates to:
  /// **'Saved data'**
  String get account_page_show_my_data_label;

  /// No description provided for @account_page_delete_account_label.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get account_page_delete_account_label;

  /// No description provided for @account_page_delete_account_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Delete all data'**
  String get account_page_delete_account_dialog_title;

  /// No description provided for @account_page_delete_account_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all your data? This action cannot be undone.'**
  String get account_page_delete_account_dialog_content;

  /// No description provided for @account_page_delete_account_dialog_delete_button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get account_page_delete_account_dialog_delete_button;

  /// No description provided for @account_page_delete_account_error_message.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting your data. Check your internet connection or try again later.'**
  String get account_page_delete_account_error_message;

  /// No description provided for @help_page_title.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help_page_title;

  /// No description provided for @help_page_installation_title.
  ///
  /// In en, this message translates to:
  /// **'Installation'**
  String get help_page_installation_title;

  /// No description provided for @help_page_installation_description.
  ///
  /// In en, this message translates to:
  /// **'Install Near Drop on other devices to send and receive files.'**
  String get help_page_installation_description;

  /// No description provided for @help_page_install_on_android_title.
  ///
  /// In en, this message translates to:
  /// **'Near Drop for Android'**
  String get help_page_install_on_android_title;

  /// No description provided for @help_page_install_on_android_content.
  ///
  /// In en, this message translates to:
  /// **'Available on Play Store'**
  String get help_page_install_on_android_content;

  /// No description provided for @help_page_install_on_apple_title.
  ///
  /// In en, this message translates to:
  /// **'Near Drop for iOS and macOS'**
  String get help_page_install_on_apple_title;

  /// No description provided for @help_page_install_on_apple_content.
  ///
  /// In en, this message translates to:
  /// **'Available on App Store'**
  String get help_page_install_on_apple_content;

  /// No description provided for @help_page_install_on_windows_title.
  ///
  /// In en, this message translates to:
  /// **'Near Drop for Windows'**
  String get help_page_install_on_windows_title;

  /// No description provided for @help_page_install_on_windows_content.
  ///
  /// In en, this message translates to:
  /// **'Available on Microsoft Store'**
  String get help_page_install_on_windows_content;

  /// No description provided for @help_page_faq_title.
  ///
  /// In en, this message translates to:
  /// **'Answered questions'**
  String get help_page_faq_title;

  /// No description provided for @help_page_faq_received_files_question.
  ///
  /// In en, this message translates to:
  /// **'Where can I find received files?'**
  String get help_page_faq_received_files_question;

  /// No description provided for @help_page_received_files_bottom_sheet_title.
  ///
  /// In en, this message translates to:
  /// **'Received files'**
  String get help_page_received_files_bottom_sheet_title;

  /// No description provided for @help_page_received_files_bottom_sheet_media_label.
  ///
  /// In en, this message translates to:
  /// **'Photos & Videos'**
  String get help_page_received_files_bottom_sheet_media_label;

  /// No description provided for @help_page_received_files_bottom_sheet_media_content.
  ///
  /// In en, this message translates to:
  /// **'Received photos and videos can be found in your Photos app in the album \'Near Drop\'.'**
  String get help_page_received_files_bottom_sheet_media_content;

  /// No description provided for @help_page_received_files_bottom_sheet_files_label.
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get help_page_received_files_bottom_sheet_files_label;

  /// No description provided for @help_page_received_files_bottom_sheet_files_content.
  ///
  /// In en, this message translates to:
  /// **'All other received files can be found in the Downloads folder of your device.'**
  String get help_page_received_files_bottom_sheet_files_content;

  /// No description provided for @help_page_received_files_bottom_sheet_files_title_desktop.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get help_page_received_files_bottom_sheet_files_title_desktop;

  /// No description provided for @help_page_received_files_bottom_sheet_files_content_desktop.
  ///
  /// In en, this message translates to:
  /// **'All received files can be found in the Downloads folder.'**
  String get help_page_received_files_bottom_sheet_files_content_desktop;

  /// No description provided for @nearby_page_help_button_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get nearby_page_help_button_tooltip;

  /// No description provided for @snackbar_message_connection_error.
  ///
  /// In en, this message translates to:
  /// **'An connection error occurred during the transfer.'**
  String get snackbar_message_connection_error;

  /// No description provided for @snackbar_message_timeout.
  ///
  /// In en, this message translates to:
  /// **'The connection to the device could not be established.'**
  String get snackbar_message_timeout;

  /// No description provided for @snackbar_message_file_access_error.
  ///
  /// In en, this message translates to:
  /// **'It was not possible to access at least one file.'**
  String get snackbar_message_file_access_error;

  /// No description provided for @snackbar_message_receiver_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred at the receiver.'**
  String get snackbar_message_receiver_error;

  /// No description provided for @snackbar_retry_action.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get snackbar_retry_action;

  /// No description provided for @cancel_transport_title.
  ///
  /// In en, this message translates to:
  /// **'Stop transfer with {firstname}?'**
  String cancel_transport_title(String firstname);

  /// No description provided for @cancel_transport_confirm_dialog_button.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get cancel_transport_confirm_dialog_button;

  /// No description provided for @cancel_transport_cancel_dialog_button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get cancel_transport_cancel_dialog_button;

  /// No description provided for @file_skip_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'No access to file'**
  String get file_skip_dialog_title;

  /// No description provided for @file_skip_dialog_content.
  ///
  /// In en, this message translates to:
  /// **'File {filename} cannot be accessed. Do you want to skip it?'**
  String file_skip_dialog_content(String filename);

  /// No description provided for @file_skip_dialog_skip_button.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get file_skip_dialog_skip_button;

  /// No description provided for @file_skip_dialog_cancel_transport_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel transfer'**
  String get file_skip_dialog_cancel_transport_button;

  /// No description provided for @core_initializing_loading_text.
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get core_initializing_loading_text;

  /// No description provided for @core_initializing_error_text.
  ///
  /// In en, this message translates to:
  /// **'The initialization process has failed. Check your internet connection and try again.'**
  String get core_initializing_error_text;

  /// No description provided for @core_initializing_error_retry_button.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get core_initializing_error_retry_button;

  /// No description provided for @onboarding_title.
  ///
  /// In en, this message translates to:
  /// **'First steps'**
  String get onboarding_title;

  /// No description provided for @nearby_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Nearby devices'**
  String get nearby_permission_title;

  /// No description provided for @nearby_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Grant the app permission to find nearby devices and determine their relative position. This allows us to detect nearby devices and establish a connection with them.'**
  String get nearby_permission_content;

  /// No description provided for @bluetooth_devices_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth devices'**
  String get bluetooth_devices_permission_title;

  /// No description provided for @bluetooth_devices_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Grant the app permission to find and connect to Bluetooth devices. This allows us to establish a connection with nearby devices.'**
  String get bluetooth_devices_permission_content;

  /// No description provided for @ios_local_network_permission_title.
  ///
  /// In en, this message translates to:
  /// **'Local network'**
  String get ios_local_network_permission_title;

  /// No description provided for @ios_local_network_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Grant the app permission to access the local network. This allows us to find other devices in the network.'**
  String get ios_local_network_permission_content;

  /// No description provided for @grant_permission_button.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get grant_permission_button;

  /// No description provided for @grant_permission_skip_button.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get grant_permission_skip_button;

  /// No description provided for @files_directory_initializing_failed_title.
  ///
  /// In en, this message translates to:
  /// **'No file reception possible'**
  String get files_directory_initializing_failed_title;

  /// No description provided for @files_directory_initializing_failed_content.
  ///
  /// In en, this message translates to:
  /// **'We cannot access the Downloads folder of your device. Please check the app permissions in the settings.'**
  String get files_directory_initializing_failed_content;

  /// No description provided for @saved_data_page_title.
  ///
  /// In en, this message translates to:
  /// **'Saved data'**
  String get saved_data_page_title;

  /// No description provided for @saved_data_page_description.
  ///
  /// In en, this message translates to:
  /// **'In the following you can fetch all your personal data that is stored on our server. For more information, see our privacy policy.'**
  String get saved_data_page_description;

  /// No description provided for @saved_data_page_fetch_data_button.
  ///
  /// In en, this message translates to:
  /// **'Fetch data'**
  String get saved_data_page_fetch_data_button;

  /// No description provided for @saved_data_page_fetch_data_error_message.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while fetching your data. Check your internet connection or try again later.'**
  String get saved_data_page_fetch_data_error_message;

  /// No description provided for @saved_data_page_login_data_label.
  ///
  /// In en, this message translates to:
  /// **'Login data'**
  String get saved_data_page_login_data_label;

  /// No description provided for @saved_data_page_user_id_label.
  ///
  /// In en, this message translates to:
  /// **'User ID'**
  String get saved_data_page_user_id_label;

  /// No description provided for @saved_data_page_created_at_label.
  ///
  /// In en, this message translates to:
  /// **'Profile created at'**
  String get saved_data_page_created_at_label;

  /// No description provided for @saved_data_page_updated_at_label.
  ///
  /// In en, this message translates to:
  /// **'Profile updated at'**
  String get saved_data_page_updated_at_label;

  /// No description provided for @saved_data_page_last_sign_in_at_label.
  ///
  /// In en, this message translates to:
  /// **'Last sign in at'**
  String get saved_data_page_last_sign_in_at_label;

  /// No description provided for @saved_data_page_sessions_label.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get saved_data_page_sessions_label;

  /// No description provided for @saved_data_page_sessions_ip_label.
  ///
  /// In en, this message translates to:
  /// **'IP address'**
  String get saved_data_page_sessions_ip_label;

  /// No description provided for @saved_data_page_privacy_policy_consents_label.
  ///
  /// In en, this message translates to:
  /// **'Data policy consents'**
  String get saved_data_page_privacy_policy_consents_label;

  /// No description provided for @saved_data_page_privacy_policy_consents_accepted_at_label.
  ///
  /// In en, this message translates to:
  /// **'Accepted at {acceptedAt}'**
  String saved_data_page_privacy_policy_consents_accepted_at_label(
    String acceptedAt,
  );

  /// No description provided for @saved_data_page_terms_of_use_consents_label.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use consents'**
  String get saved_data_page_terms_of_use_consents_label;

  /// No description provided for @saved_data_page_terms_of_use_consents_accepted_at_label.
  ///
  /// In en, this message translates to:
  /// **'Accepted at {acceptedAt}'**
  String saved_data_page_terms_of_use_consents_accepted_at_label(
    String acceptedAt,
  );

  /// No description provided for @incompatible_app_version_snackbar_content.
  ///
  /// In en, this message translates to:
  /// **'Your device is not compatible with the device of {firstname}. Please update both Near Drop to the latest version.'**
  String incompatible_app_version_snackbar_content(String firstname);

  /// No description provided for @required_update_page_title.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get required_update_page_title;

  /// No description provided for @required_update_page_content.
  ///
  /// In en, this message translates to:
  /// **'An update is required to continue using the app. Please update the app to the latest version.'**
  String get required_update_page_content;

  /// No description provided for @required_update_page_button.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get required_update_page_button;

  /// No description provided for @account_deleted_snackbar_content.
  ///
  /// In en, this message translates to:
  /// **'Your account has been successfully deleted.'**
  String get account_deleted_snackbar_content;

  /// No description provided for @account_delete_error_snackbar_content.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while deleting your account. Check your internet connection or try again later.'**
  String get account_delete_error_snackbar_content;

  /// No description provided for @open_website_button.
  ///
  /// In en, this message translates to:
  /// **'Visit website'**
  String get open_website_button;

  /// No description provided for @onboarding_external_storage_permission_title.
  ///
  /// In en, this message translates to:
  /// **'External storage'**
  String get onboarding_external_storage_permission_title;

  /// No description provided for @onboarding_external_storage_permission_content.
  ///
  /// In en, this message translates to:
  /// **'Allow the app to access the external storage of your device. This allows us to save received files.'**
  String get onboarding_external_storage_permission_content;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
