// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get app_name => 'Near Drop';

  @override
  String get welcome_subtitle =>
      'Dateien schnell & drahtlos in der Nähe teilen';

  @override
  String get welcome_preview_info_text => 'Vorschauversion';

  @override
  String get app_info_button => 'App-Info';

  @override
  String get continue_button => 'Weiter';

  @override
  String get app_info_title => 'App-Info';

  @override
  String get imprint_title => 'Impressum';

  @override
  String get imprint_subtitle => 'Über den Entwickler';

  @override
  String get data_privacy_title => 'Datenschutz';

  @override
  String get data_privacy_subtitle => 'Über die Datenverarbeitung';

  @override
  String get licenses_title => 'Lizenzen';

  @override
  String get licenses_subtitle => 'Über die verwendeten Lizenzen';

  @override
  String get version_title => 'Version';

  @override
  String get guest_login_title => 'Profil anlegen';

  @override
  String get firstname_textfield_label => 'Vorname';

  @override
  String get firstname_textfield_helper_text =>
      'Diesen Namen sehen andere Geräte in der Nähe.';

  @override
  String get guest_login_error_message =>
      'Beim Anmelden ist ein Fehler aufgetreten. Versuche es später erneut.';

  @override
  String get data_protection_info_text_1 => 'Ich habe die ';

  @override
  String get data_protection_info_text_2 => 'Datenschutzrichtlinien';

  @override
  String get data_protection_info_text_3 => ' gelesen und akzeptiere diese.';

  @override
  String get nearby_page_menu_icon_tooltip => 'App-Info';

  @override
  String get nearby_page_account_icon_tooltip => 'Mein Account';

  @override
  String get nearby_page_manual_connection_tooltip => 'Manuell verbinden';

  @override
  String get nearby_page_visibility_info_prefix => 'Du bist sichtbar als ';

  @override
  String get nearby_page_devices_label => 'Geräte in der Nähe';

  @override
  String get nearby_page_no_devices_found_balloon_title =>
      'Gerät wird nicht gefunden?';

  @override
  String get nearby_page_no_devices_found_balloon_subtitle =>
      'Verbinde dein Gerät per QR-Code.';

  @override
  String send_dialog_title(String firstname) {
    return 'An $firstname senden';
  }

  @override
  String get send_dialog_files_label => 'Dateien';

  @override
  String get send_dialog_media_label => 'Fotos & Videos';

  @override
  String get cancel_button => 'Abbrechen';

  @override
  String get send_request_dialog_title => 'Sendeanfrage';

  @override
  String send_request_dialog_content(
    String firstname,
    int filesCount,
    String mimeType,
  ) {
    return '$firstname möchte dir $filesCount $mimeType senden.';
  }

  @override
  String get mime_type_image => 'Bild';

  @override
  String get mime_type_images => 'Bilder';

  @override
  String get mime_type_video => 'Video';

  @override
  String get mime_type_videos => 'Videos';

  @override
  String get mime_type_audio => 'Audio';

  @override
  String get mime_type_audios => 'Audios';

  @override
  String get mime_type_media => 'Mediendateien';

  @override
  String get mime_type_file => 'Datei';

  @override
  String get mime_type_files => 'Dateien';

  @override
  String get accept_button => 'Akzeptieren';

  @override
  String get decline_button => 'Ablehnen';

  @override
  String get communication_state_connecting => 'Verbinden...';

  @override
  String get communication_state_requesting => 'Anfragen...';

  @override
  String get communication_state_sending => 'Senden...';

  @override
  String get communication_state_receiving => 'Empfangen...';

  @override
  String get communication_state_canceling => 'Abbrechen...';

  @override
  String get success_state_sended => 'Gesendet!';

  @override
  String get success_state_received => 'Empfangen!';

  @override
  String get error_state_error => 'Fehler';

  @override
  String get error_state_receiver_declined => 'Abgelehnt';

  @override
  String get error_state_canceled => 'Abgebrochen';

  @override
  String get dialog_close_button => 'Schließen';

  @override
  String get received_files_dialog_show_files_button => 'Anzeigen';

  @override
  String received_files_dialog_title(
    int filesCount,
    String mimeType,
    String firstname,
  ) {
    return '$filesCount $mimeType von $firstname empfangen';
  }

  @override
  String received_files_dialog_more_files_text(int filesCount) {
    return '+ $filesCount weitere Datei(en)';
  }

  @override
  String get data_volume_warning_dialog_title => 'Senden?';

  @override
  String data_volume_warning_dialog_content(String sizeText) {
    return 'Dieser Vorgang benötigt mindestens $sizeText deines Datenvolumens.';
  }

  @override
  String get data_volume_warning_dialog_accept_button => 'Senden';

  @override
  String get manually_connecting_sheet_title => 'Manuell verbinden';

  @override
  String get manually_connecting_sheet_scan_button => 'Scannen';

  @override
  String get qr_code_text =>
      'Bitte die andere Person, diesen QR-Code mit ihrem Gerät zu scannen.';

  @override
  String get scan_qr_code => 'Scanne den QR-Code eines anderen Gerätes.';

  @override
  String get qr_code_error_no_permission =>
      'Erteile die Kamera-Berechtigung in den Einstellungen';

  @override
  String get qr_code_error_invalid => 'Ungültiger QR-Code';

  @override
  String get qr_code_error_device_already_added => 'Gerät bereits gefunden';

  @override
  String get qr_code_error_device_request =>
      'Gerät konnte nicht kontaktiert werden. Prüfe deine Internetverbindung.';

  @override
  String get no_internet_connection_info_bar_title =>
      'Keine Internetverbindung';

  @override
  String get no_internet_connection_info_bar_subtitle =>
      'Verbinde dich mit einem Netzwerk, um Dateien zu senden und zu empfangen.';

  @override
  String get bluetooth_not_supported_info_bar_title =>
      'Bluetooth wird nicht unterstützt';

  @override
  String get bluetooth_not_supported_info_bar_subtitle =>
      'Dein Gerät besitzt keine Bluetooth-Komponente. Geräte in der Nähe können daher nicht gefunden werden.';

  @override
  String get bluetooth_no_permission_info_bar_title =>
      'Fehlende Bluetooth-Berechtigung';

  @override
  String get bluetooth_no_permission_info_bar_subtitle =>
      'Erteile der App in den Einstellungen Zugriff auf Bluetooth, um Geräte in der Nähe zu finden.';

  @override
  String get bluetooth_disabled_info_bar_title => 'Bluetooth deaktiviert';

  @override
  String get bluetooth_disabled_info_bar_subtitle =>
      'Aktiviere Bluetooth, um Geräte in der Nähe zu finden.';

  @override
  String get bluetooth_error_info_bar_title => 'Bluetooth-Probleme';

  @override
  String get bluetooth_error_info_bar_subtitle =>
      'Einige Bluetooth-Prozesse sind fehlgeschlagen. Schaue in der Hilfe nach für Problemlösungen.';

  @override
  String get drawer_close => 'Schließen';

  @override
  String get account_page_title => 'Mein Profil';

  @override
  String get account_page_change_firstname_label => 'Vorname ändern';

  @override
  String get account_page_change_firstname_dialog_title => 'Vorname ändern';

  @override
  String get account_page_change_firstname_textfield_label => 'Neuer Vorname';

  @override
  String get account_page_change_firstname_dialog_save_button => 'Speichern';

  @override
  String get account_page_show_my_data_label => 'Gespeicherte Daten';

  @override
  String get account_page_delete_account_label => 'Alle Daten löschen';

  @override
  String get account_page_delete_account_dialog_title => 'Alle Daten löschen';

  @override
  String get account_page_delete_account_dialog_content =>
      'Bist du sicher, dass du alle deine Daten löschen möchtest? Dieser Vorgang kann nicht rückgängig gemacht werden.';

  @override
  String get account_page_delete_account_dialog_delete_button => 'Löschen';

  @override
  String get account_page_delete_account_error_message =>
      'Beim Löschen deiner Daten ist ein Fehler aufgetreten. Prüfe deine Internetverbindung oder versuche es später erneut.';

  @override
  String get help_page_title => 'Hilfe';

  @override
  String get help_page_installation_title => 'Installation';

  @override
  String get help_page_installation_description =>
      'Installiere Near Drop auf anderen Geräten, um Dateien zu senden und zu empfangen.';

  @override
  String get help_page_install_on_android_title => 'Near Drop für Android';

  @override
  String get help_page_install_on_android_content =>
      'Im Play Store herunterladen';

  @override
  String get help_page_install_on_apple_title => 'Near Drop für iOS & macOS';

  @override
  String get help_page_install_on_apple_content => 'Im App Store herunterladen';

  @override
  String get help_page_install_on_windows_title => 'Near Drop für Windows';

  @override
  String get help_page_install_on_windows_content =>
      'Im Microsoft Store herunterladen';

  @override
  String get help_page_faq_title => 'Fragen & Antworten';

  @override
  String get help_page_faq_received_files_question =>
      'Wo finde ich empfangene Dateien?';

  @override
  String get help_page_received_files_bottom_sheet_title =>
      'Empfangene Dateien';

  @override
  String get help_page_received_files_bottom_sheet_media_label =>
      'Fotos & Videos';

  @override
  String get help_page_received_files_bottom_sheet_media_content =>
      'Empfangene Fotos & Videos findest du in deiner Fotos-App im Album \'Near Drop\'.';

  @override
  String get help_page_received_files_bottom_sheet_files_label =>
      'Andere Dateien';

  @override
  String get help_page_received_files_bottom_sheet_files_content =>
      'Alle anderen empfangene Dateien findest du im Downloads-Ordner deines Geräts.';

  @override
  String get help_page_received_files_bottom_sheet_files_title_desktop =>
      'Dateien';

  @override
  String get help_page_received_files_bottom_sheet_files_content_desktop =>
      'Alle empfangene Dateien findest du im Downloads-Ordner.';

  @override
  String get nearby_page_help_button_tooltip => 'Hilfe';

  @override
  String get snackbar_message_connection_error =>
      'Während der Übertragung ist ein Verbindungsfehler aufgetreten.';

  @override
  String get snackbar_message_timeout =>
      'Es konnte keine Verbindung zum Gerät hergestellt werden.';

  @override
  String get snackbar_message_file_access_error =>
      'Es konnte auf mindestens eine Datei nicht zugegriffen werden.';

  @override
  String get snackbar_message_receiver_error =>
      'Beim Empfänger ist ein Fehler aufgetreten.';

  @override
  String get snackbar_retry_action => 'Erneut versuchen';

  @override
  String cancel_transport_title(String firstname) {
    return 'Übertragung mit $firstname beenden?';
  }

  @override
  String get cancel_transport_confirm_dialog_button => 'Beenden';

  @override
  String get cancel_transport_cancel_dialog_button => 'Fortsetzen';

  @override
  String get file_skip_dialog_title => 'Kein Zugriff auf Datei';

  @override
  String file_skip_dialog_content(String filename) {
    return 'Auf die Datei $filename kann nicht zugegriffen werden. Möchtest du sie überspringen?';
  }

  @override
  String get file_skip_dialog_skip_button => 'Überspringen';

  @override
  String get file_skip_dialog_cancel_transport_button =>
      'Übertragung abbrechen';

  @override
  String get core_initializing_loading_text => 'Initialisierung...';

  @override
  String get core_initializing_error_text =>
      'Der Initialisierungsprozess ist fehlgeschlagen. Prüfe deine Internetverbindung und versuche es erneut.';

  @override
  String get core_initializing_error_retry_button => 'Erneut versuchen';

  @override
  String get onboarding_title => 'Erste Schritte';

  @override
  String get nearby_permission_title => 'Geräte in der Nähe';

  @override
  String get nearby_permission_content =>
      'Erteile der App die Berechtigung, Geräte in der Nähe zu finden und ihre relative Position zu bestimmen. Dadurch können wir Geräte in der Nähe erkennen und eine Verbindung zu ihnen herstellen.';

  @override
  String get bluetooth_devices_permission_title => 'Bluetooth-Geräte';

  @override
  String get bluetooth_devices_permission_content =>
      'Erteile der App die Berechtigung, Bluetooth-Geräte zu erkennen und eine Verbindung zu ihnen herzustellen. Dadurch können wir Geräte in der Nähe finden und eine Verbindung zu ihnen herstellen.';

  @override
  String get ios_local_network_permission_title => 'Lokales Netzwerk';

  @override
  String get ios_local_network_permission_content =>
      'Erteile der App die Berechtigung auf das lokale Netzwerk zuzugreifen. Dadurch können wir andere Geräte im Netzwerk finden.';

  @override
  String get grant_permission_button => 'Berechtigung erteilen';

  @override
  String get grant_permission_skip_button => 'Überspringen';

  @override
  String get files_directory_initializing_failed_title =>
      'Kein Dateiempfang möglich';

  @override
  String get files_directory_initializing_failed_content =>
      'Wir können nicht auf den Downloads-Ordner deines Geräts zugreifen.';

  @override
  String get saved_data_page_title => 'Gespeicherte Daten';

  @override
  String get saved_data_page_description =>
      'Im Folgenden siehst du alle deine personenbezogenen Daten, die auf unserem Server gespeichert sind. Für weitere Informationen, schaue in unsere Datenschutzerklärung.';

  @override
  String get saved_data_page_login_data_label => 'Anmeldedaten';

  @override
  String get saved_data_page_created_at_label => 'Profil erstellt am';

  @override
  String get saved_data_page_updated_at_label => 'Profil aktualisiert am';

  @override
  String get saved_data_page_last_sign_in_at_label => 'Zuletzt angemeldet am';

  @override
  String incompatible_app_version_snackbar_content(String firstname) {
    return 'Dein Gerät ist nicht kompatibel mit dem Gerät von $firstname. Bitte aktualisiert beide Near Drop auf die neueste Version.';
  }
}
