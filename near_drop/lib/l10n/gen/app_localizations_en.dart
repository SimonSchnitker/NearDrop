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
  String get guest_login_title => 'Create profile';

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
  String get terms_info_text_1 => 'I have read and accept the ';

  @override
  String get terms_info_text_2 => 'Terms of Use';

  @override
  String get terms_info_text_3 => '.';

  @override
  String get nearby_page_menu_icon_tooltip => 'App information';

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
  String get account_page_title => 'My profile';

  @override
  String get account_page_change_firstname_label => 'Change firstname';

  @override
  String get account_page_change_firstname_dialog_title => 'Change firstname';

  @override
  String get account_page_change_firstname_textfield_label => 'New firstname';

  @override
  String get account_page_change_firstname_dialog_save_button => 'Save';

  @override
  String get account_page_show_my_data_label => 'Saved data';

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
  String get account_page_delete_account_error_message =>
      'An error occurred while deleting your data. Check your internet connection or try again later.';

  @override
  String get help_page_title => 'Help';

  @override
  String get help_page_installation_title => 'Installation';

  @override
  String get help_page_installation_description =>
      'Install Near Drop on other devices to send and receive files.';

  @override
  String get help_page_install_on_android_title => 'Near Drop for Android';

  @override
  String get help_page_install_on_android_content => 'Available on Play Store';

  @override
  String get help_page_install_on_apple_title => 'Near Drop for iOS and macOS';

  @override
  String get help_page_install_on_apple_content => 'Available on App Store';

  @override
  String get help_page_install_on_windows_title => 'Near Drop for Windows';

  @override
  String get help_page_install_on_windows_content =>
      'Available on Microsoft Store';

  @override
  String get help_page_faq_title => 'Answered questions';

  @override
  String get help_page_faq_received_files_question =>
      'Where can I find received files?';

  @override
  String get help_page_received_files_bottom_sheet_title => 'Received files';

  @override
  String get help_page_received_files_bottom_sheet_media_label =>
      'Photos & Videos';

  @override
  String get help_page_received_files_bottom_sheet_media_content =>
      'Received photos and videos can be found in your Photos app in the album \'Near Drop\'.';

  @override
  String get help_page_received_files_bottom_sheet_files_label => 'Other files';

  @override
  String get help_page_received_files_bottom_sheet_files_content =>
      'All other received files can be found in the Downloads folder of your device.';

  @override
  String get help_page_received_files_bottom_sheet_files_title_desktop =>
      'Files';

  @override
  String get help_page_received_files_bottom_sheet_files_content_desktop =>
      'All received files can be found in the Downloads folder.';

  @override
  String get nearby_page_help_button_tooltip => 'Help';

  @override
  String get snackbar_message_connection_error =>
      'An connection error occurred during the transfer.';

  @override
  String get snackbar_message_timeout =>
      'The connection to the device could not be established.';

  @override
  String get snackbar_message_file_access_error =>
      'It was not possible to access at least one file.';

  @override
  String get snackbar_message_receiver_error =>
      'An error occurred at the receiver.';

  @override
  String get snackbar_retry_action => 'Retry';

  @override
  String cancel_transport_title(String firstname) {
    return 'Stop transfer with $firstname?';
  }

  @override
  String get cancel_transport_confirm_dialog_button => 'Stop';

  @override
  String get cancel_transport_cancel_dialog_button => 'Continue';

  @override
  String get file_skip_dialog_title => 'No access to file';

  @override
  String file_skip_dialog_content(String filename) {
    return 'File $filename cannot be accessed. Do you want to skip it?';
  }

  @override
  String get file_skip_dialog_skip_button => 'Skip';

  @override
  String get file_skip_dialog_cancel_transport_button => 'Cancel transfer';

  @override
  String get core_initializing_loading_text => 'Initializing...';

  @override
  String get core_initializing_error_text =>
      'The initialization process has failed. Check your internet connection and try again.';

  @override
  String get core_initializing_error_retry_button => 'Retry';

  @override
  String get onboarding_title => 'First steps';

  @override
  String get nearby_permission_title => 'Nearby devices';

  @override
  String get nearby_permission_content =>
      'Grant the app permission to find nearby devices and determine their relative position. This allows us to detect nearby devices and establish a connection with them.';

  @override
  String get bluetooth_devices_permission_title => 'Bluetooth devices';

  @override
  String get bluetooth_devices_permission_content =>
      'Grant the app permission to find and connect to Bluetooth devices. This allows us to establish a connection with nearby devices.';

  @override
  String get ios_local_network_permission_title => 'Local network';

  @override
  String get ios_local_network_permission_content =>
      'Grant the app permission to access the local network. This allows us to find other devices in the network.';

  @override
  String get grant_permission_button => 'Grant permission';

  @override
  String get grant_permission_skip_button => 'Skip';

  @override
  String get files_directory_initializing_failed_title =>
      'No file reception possible';

  @override
  String get files_directory_initializing_failed_content =>
      'We cannot access the Downloads folder of your device.';

  @override
  String get saved_data_page_title => 'Saved data';

  @override
  String get saved_data_page_description =>
      'In the following you can fetch all your personal data that is stored on our server. For more information, see our privacy policy.';

  @override
  String get saved_data_page_fetch_data_button => 'Fetch data';

  @override
  String get saved_data_page_fetch_data_error_message =>
      'An error occurred while fetching your data. Check your internet connection or try again later.';

  @override
  String get saved_data_page_login_data_label => 'Login data';

  @override
  String get saved_data_page_user_id_label => 'User ID';

  @override
  String get saved_data_page_created_at_label => 'Profile created at';

  @override
  String get saved_data_page_updated_at_label => 'Profile updated at';

  @override
  String get saved_data_page_last_sign_in_at_label => 'Last sign in at';

  @override
  String get saved_data_page_sessions_label => 'Sessions';

  @override
  String get saved_data_page_sessions_ip_label => 'IP address';

  @override
  String get saved_data_page_privacy_policy_consents_label =>
      'Data policy consents';

  @override
  String saved_data_page_privacy_policy_consents_accepted_at_label(
    String acceptedAt,
  ) {
    return 'Accepted at $acceptedAt';
  }

  @override
  String get saved_data_page_terms_of_use_consents_label =>
      'Terms of Use consents';

  @override
  String saved_data_page_terms_of_use_consents_accepted_at_label(
    String acceptedAt,
  ) {
    return 'Accepted at $acceptedAt';
  }

  @override
  String incompatible_app_version_snackbar_content(String firstname) {
    return 'Your device is not compatible with the device of $firstname. Please update both Near Drop to the latest version.';
  }

  @override
  String get required_update_page_title => 'Update required';

  @override
  String get required_update_page_content =>
      'An update is required to continue using the app. Please update the app to the latest version.';

  @override
  String get required_update_page_button => 'Update now';

  @override
  String get account_deleted_snackbar_content =>
      'Your account has been successfully deleted.';

  @override
  String get account_delete_error_snackbar_content =>
      'An error occurred while deleting your account. Check your internet connection or try again later.';

  @override
  String get open_website_button => 'Visit website';
}
