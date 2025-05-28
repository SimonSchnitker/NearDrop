// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_name => 'Near Drop';

  @override
  String get welcome_subtitle => 'Share files nearby';

  @override
  String get welcome_preview_info_text => 'Preview version';

  @override
  String get app_info_button => 'App information';

  @override
  String get continue_button => 'Next';

  @override
  String get app_info_title => 'App information';

  @override
  String get imprint_title => 'Imprint';

  @override
  String get imprint_subtitle => 'About the developer';

  @override
  String get data_privacy_title => 'Data protection';

  @override
  String get data_privacy_subtitle => 'About the data processing';

  @override
  String get licenses_title => 'Licences';

  @override
  String get licenses_subtitle => 'About used licenses';

  @override
  String get version_title => 'Version';

  @override
  String get guest_login_title => 'Login as guest';

  @override
  String get firstname_textfield_label => 'Firstname';

  @override
  String get firstname_textfield_helper_text =>
      'Other devices nearby will see this name.';

  @override
  String get guest_login_error_message =>
      'An error occurred while logging in. Please try again later.';

  @override
  String get data_protection_info_text_1 => 'I have read and accept the ';

  @override
  String get data_protection_info_text_2 => 'data protection regulations';

  @override
  String get data_protection_info_text_3 => '.';

  @override
  String get nearby_page_menu_icon_tooltip => 'Menu';

  @override
  String get nearby_page_account_icon_tooltip => 'My account';

  @override
  String get nearby_page_manual_connection_tooltip => 'Connect manually';

  @override
  String get nearby_page_visibility_info_prefix => 'You are visible as ';

  @override
  String get nearby_page_devices_label => 'Nearby devices';

  @override
  String get nearby_page_no_devices_found_balloon_title => 'Device not found?';

  @override
  String get nearby_page_no_devices_found_balloon_subtitle =>
      'Connect you device via qr code.';

  @override
  String send_dialog_title(String firstname) {
    return 'Send to $firstname';
  }

  @override
  String get send_dialog_files_label => 'Files';

  @override
  String get send_dialog_media_label => 'Photos & Videos';

  @override
  String get cancel_button => 'Cancel';

  @override
  String get send_request_dialog_title => 'Send request';

  @override
  String send_request_dialog_content(
    String firstname,
    int filesCount,
    String mimeType,
  ) {
    return '$firstname wants to send you $filesCount $mimeType.';
  }

  @override
  String get mime_type_image => 'image';

  @override
  String get mime_type_images => 'images';

  @override
  String get mime_type_video => 'video';

  @override
  String get mime_type_videos => 'videos';

  @override
  String get mime_type_audio => 'audio';

  @override
  String get mime_type_audios => 'audios';

  @override
  String get mime_type_media => 'media files';

  @override
  String get mime_type_file => 'file';

  @override
  String get mime_type_files => 'files';

  @override
  String get accept_button => 'Accept';

  @override
  String get decline_button => 'Decline';

  @override
  String get communication_state_connecting => 'Connecting...';

  @override
  String get communication_state_requesting => 'Requesting...';

  @override
  String get communication_state_sending => 'Sending...';

  @override
  String get communication_state_receiving => 'Receiving...';

  @override
  String get communication_state_canceling => 'Canceling...';

  @override
  String get success_state_sended => 'Sent!';

  @override
  String get success_state_received => 'Received!';

  @override
  String get error_state_error => 'Error';

  @override
  String get error_state_receiver_declined => 'Declined';

  @override
  String get error_state_canceled => 'Aborted';

  @override
  String get dialog_close_button => 'Close';

  @override
  String get received_files_dialog_show_files_button => 'Show';

  @override
  String received_files_dialog_title(
    int filesCount,
    String mimeType,
    String firstname,
  ) {
    return '$filesCount $mimeType received from $firstname';
  }

  @override
  String received_files_dialog_more_files_text(int filesCount) {
    return '+ $filesCount more file(s)';
  }

  @override
  String get data_volume_warning_dialog_title => 'Send?';

  @override
  String data_volume_warning_dialog_content(String sizeText) {
    return 'This occurrence needs minimum $sizeText of your data volume.';
  }

  @override
  String get data_volume_warning_dialog_accept_button => 'Send';

  @override
  String get manually_connecting_sheet_title => 'Manually connect';

  @override
  String get manually_connecting_sheet_scan_button => 'Scan';

  @override
  String get qr_code_text =>
      'Tell an other person to scan this QR code with their device.';

  @override
  String get scan_qr_code => 'Scan the QR code of another device.';

  @override
  String get qr_code_error_no_permission =>
      'Grant camera permission in settings.';

  @override
  String get qr_code_error_invalid => 'Invalid QR code';

  @override
  String get qr_code_error_device_already_added => 'Device already found';

  @override
  String get qr_code_error_device_request =>
      'Device could not be contacted. Check your internet connection.';

  @override
  String get no_internet_connection_info_bar_title => 'No internet connection';

  @override
  String get no_internet_connection_info_bar_subtitle =>
      'Connect to a network to send and receive files.';

  @override
  String get bluetooth_not_supported_info_bar_title =>
      'Bluetooth not supported';

  @override
  String get bluetooth_not_supported_info_bar_subtitle =>
      'Your device does not have a Bluetooth component. Devices nearby cannot be found.';

  @override
  String get bluetooth_no_permission_info_bar_title =>
      'Bluetooth permission missing';

  @override
  String get bluetooth_no_permission_info_bar_subtitle =>
      'Grant the app access to Bluetooth in the settings to find devices nearby.';

  @override
  String get bluetooth_disabled_info_bar_title => 'Bluetooth disabled';

  @override
  String get bluetooth_disabled_info_bar_subtitle =>
      'Enable Bluetooth to find devices nearby.';

  @override
  String get bluetooth_error_info_bar_title => 'Bluetooth error';

  @override
  String get bluetooth_error_info_bar_subtitle =>
      'Schaue in der Hilfe nach für Problemlösungen. Some Bluetooth processes have failed. Check the help for troubleshooting.';

  @override
  String get drawer_close => 'Close';

  @override
  String get account_page_title => 'My data';

  @override
  String get account_page_change_firstname_label => 'Change firstname';

  @override
  String get account_page_change_firstname_dialog_title => 'Change firstname';

  @override
  String get account_page_change_firstname_textfield_label => 'New firstname';

  @override
  String get account_page_change_firstname_dialog_save_button => 'Save';

  @override
  String get account_page_show_my_data_label => 'Show my data';

  @override
  String get account_page_delete_account_label => 'Delete all data';

  @override
  String get account_page_delete_account_dialog_title => 'Delete all data';

  @override
  String get account_page_delete_account_dialog_content =>
      'Are you sure you want to delete all your data? This action cannot be undone.';

  @override
  String get account_page_delete_account_dialog_delete_button => 'Delete';

  @override
  String get help_page_title => 'Help';

  @override
  String get help_page_installation_title =>
      'Install Near Drop on other devices to send and receive files.';

  @override
  String get help_page_install_on_android_title => 'Near Drop for Android';

  @override
  String get help_page_install_on_android_content =>
      'Available on Google Play Store';

  @override
  String get help_page_install_on_apple_title => 'Near Drop for iOS and macOS';

  @override
  String get help_page_install_on_apple_content =>
      'Available on Apple App Store';

  @override
  String get help_page_install_on_windows_title => 'Near Drop for Windows';

  @override
  String get help_page_install_on_windows_content =>
      'Available on Microsoft Store';

  @override
  String get nearby_page_help_button_tooltip => 'Help';
}
