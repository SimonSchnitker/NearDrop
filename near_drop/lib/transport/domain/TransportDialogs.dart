import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:near_drop/tools/FileSizeHelper.dart';
import 'package:near_drop/transport/domain/TransportController.dart';
import 'package:open_app_file/open_app_file.dart';
import 'package:path/path.dart';
import '../../core/domain/entity/Device.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../main.dart';
import '../../nearby/presentation/pages/NearbyPage.dart';
import 'enums/MimeTypeGroup.dart';
import 'enums/SendRequestAnswer.dart';
import 'models/ReceivedFile.dart';

/// Gibt den MIME-Typ-String basierend auf der Gruppe und der Anzahl der Dateien zurück.
String getMimeTypeString(BuildContext context, MimeTypeGroup mimeTypeGroup, int filesCount)
{
    switch (mimeTypeGroup)
    {
        case MimeTypeGroup.images:
            return filesCount == 1
                ? AppLocalizations.of(context)!.mime_type_image
                : AppLocalizations.of(context)!.mime_type_images;
        case MimeTypeGroup.videos:
            return filesCount == 1
                ? AppLocalizations.of(context)!.mime_type_video
                : AppLocalizations.of(context)!.mime_type_videos;
        case MimeTypeGroup.audios:
            return filesCount == 1
                ? AppLocalizations.of(context)!.mime_type_audio
                : AppLocalizations.of(context)!.mime_type_audios;
        case MimeTypeGroup.media:
            return AppLocalizations.of(context)!.mime_type_media;
        default:
            return filesCount == 1
                ? AppLocalizations.of(context)!.mime_type_file
                : AppLocalizations.of(context)!.mime_type_files;
    }
}

Future<bool> showAskSkipFileDialog(File file) async
{
    if (NearbyPage.scaffoldKey.currentContext == null)
    {
        dprint("Fehler: ScaffoldContext ist null.");
        return false;
    }

    BuildContext context = NearbyPage.scaffoldKey.currentContext!;
    String filename = basename(file.path);

    bool skipFile = false;
    await showDialog(
        context: context,
        builder: (dialogContext) =>
            AlertDialog(
                title: Text(AppLocalizations.of(context)!.file_skip_dialog_title),
                content: Text(AppLocalizations.of(context)!.file_skip_dialog_content(filename)),
                actions: [
                    TextButton(onPressed: () {
                        skipFile = false;
                        Navigator.pop(dialogContext);
                    }, child: Text(AppLocalizations.of(context)!.file_skip_dialog_cancel_transport_button)),
                    TextButton(onPressed: () {
                        skipFile = true;
                        Navigator.pop(dialogContext);
                    }, child: Text(AppLocalizations.of(context)!.file_skip_dialog_skip_button)),
                ],
            )
    );

    return skipFile;
}

/// Zeigt ein Dialogfeld an, um die Sendeanfrage des Geräts zu akzeptieren oder abzulehnen.
Future<SendRequestAnswer> showSendRequestDialog(Device device, int filesCount, int totalSize, MimeTypeGroup mimeTypeGroup) async
{
    if (NearbyPage.scaffoldKey.currentContext == null)
    {
        dprint("Fehler: ScaffoldContext ist null.");
        return SendRequestAnswer.error;
    }

    BuildContext context = NearbyPage.scaffoldKey.currentContext!;
    String mimeTypeString = getMimeTypeString(context, mimeTypeGroup, filesCount);
    String dialogContentText = AppLocalizations.of(context)!.send_request_dialog_content(device.firstname, filesCount, mimeTypeString);

    // Wenn das Gerät keine WLAN- oder Ethernet-Verbindung hat und die Gesamtgröße einen bestimmten Wert übersteigt, Datenvolumen-Warnung anzeigen
    List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
    if (!connectivity.contains(ConnectivityResult.wifi) && !connectivity.contains(ConnectivityResult.ethernet) && totalSize >= TransportController.MIN_BYTES_FOR_DATA_VOLUME_WARNING)
    {
        String sizeString = getFileSizeString(totalSize);
        dialogContentText += "\n${AppLocalizations.of(context)!.data_volume_warning_dialog_content(sizeString)}";
    };

    SendRequestAnswer answer = SendRequestAnswer.declined;
    device.isSendRequestDialogOpen = true;
    await showDialog(barrierDismissible: false, context: context, builder: (dialogContext) =>
        AlertDialog(
            key: device.sendRequestDialogKey,
            actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
            title: Text(
                AppLocalizations.of(context)!.send_request_dialog_title,
                style: Theme.of(dialogContext).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.w500),
            ),
            content: Text(dialogContentText),
            actions: [
                TextButton(onPressed: () {
                    answer = SendRequestAnswer.declined;
                    Navigator.pop(dialogContext);
                }, child: Text(AppLocalizations.of(context)!.decline_button)),
                TextButton(onPressed: () {
                    answer = SendRequestAnswer.accepted;
                    Navigator.pop(dialogContext);
                }, child: Text(AppLocalizations.of(context)!.accept_button)),
            ],
        )
    );

    device.isSendRequestDialogOpen = false;
    return answer;
}

/// Zeigt einen Warnhinweis an, wenn die Gesamtgröße der Dateien einen bestimmten Wert überschreitet.
Future<bool> showVolumeDataWarningDialog(int totalSize) async
{
    BuildContext? context = NearbyPage.scaffoldKey.currentContext;
    if (context == null)
    {
        dprint("Fehler: ScaffoldContext ist null.");
        return false;
    }

    String sizeString = getFileSizeString(totalSize);
    bool result = false;
    await showDialog(
        context: context,
        builder: (dialogContext) =>
            AlertDialog(
                title: Text(AppLocalizations.of(context)!.data_volume_warning_dialog_title),
                content: Text(AppLocalizations.of(context)!.data_volume_warning_dialog_content(sizeString)),
                actions: [
                    TextButton(onPressed: () {
                        result = false;
                        Navigator.pop(dialogContext);
                    }, child: Text(AppLocalizations.of(context)!.cancel_button)),
                    TextButton(
                        onPressed: () {
                            result = true;
                            Navigator.pop(dialogContext);
                        },
                        child: Text(AppLocalizations.of(context)!.data_volume_warning_dialog_accept_button),
                    ),
                ],
            )
    );

    return result;
}

/// Zeigt einen Dialog an, um eine Vorschau der empfangenen Dateien anzuzeigen.
Future<void> showImagePreviewDialog({
    required BuildContext context,
    required List<ReceivedFile> allFiles, // Umbenannt von files zu allFiles für Klarheit
    required Device device,
    required Directory? targetDirectory, // Für "Anzeigen"-Button
    required MimeTypeGroup mimeTypeGroup
}) async {
    const double spacing = 8.0;
    const double borderRadius = 8.0;
    const double desktopDialogMaxWidth = 400.0;
    const int fadeInDurationMs = 400;

    // Dateitypen klassifizieren
    final List<ReceivedFile> imageFiles = allFiles.where((file) => file.mimeType.startsWith('image/')).toList();
    final List<ReceivedFile> otherFiles = allFiles.where((file) => !file.mimeType.startsWith('image/')).toList();

    bool onlyImages = imageFiles.isNotEmpty && otherFiles.isEmpty;
    bool noImages = imageFiles.isEmpty && otherFiles.isNotEmpty;
    bool mixedContent = imageFiles.isNotEmpty && otherFiles.isNotEmpty;
    // Der Fall, dass allFiles leer ist, wird laut Anforderung nicht mehr explizit behandelt,
    // aber die Logik sollte nicht abstürzen, wenn es doch passiert.
    // Wenn allFiles leer ist, wird noImages als true interpretiert, wenn imageFiles leer ist.

    // Hilfsfunktion zum Erstellen eines einzelnen Bild-Widgets
    Widget buildImageItem(BuildContext itemContext, ReceivedFile file) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Image.file(
                File(file.path),
                fit: BoxFit.cover,
                errorBuilder: (ctx, error, stackTrace) {
                    return Container(
                        decoration: BoxDecoration(
                            color: Theme.of(itemContext).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(borderRadius),
                        ),
                        child: Center(
                            child: Icon(
                                Icons.error_outline,
                                color: Theme.of(itemContext).colorScheme.onErrorContainer,
                                size: 30,
                            ),
                        ),
                    );
                },
                frameBuilder: (ctx, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) {
                        return child;
                    }
                    return AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: const Duration(milliseconds: fadeInDurationMs),
                        curve: Curves.easeOut,
                        child: child,
                    );
                },
            ),
        );
    }

    // Hilfsfunktion zum Erstellen des Überlauf-Indikators für Bilder
    Widget buildOverflowIndicator(BuildContext itemContext, int count) {
        return Container(
            decoration: BoxDecoration(
                color: Theme.of(itemContext).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: Theme.of(itemContext).colorScheme.outline, width: 1)
            ),
            child: Center(
                child: Text(
                    "+$count",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(itemContext).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                ),
            ),
        );
    }

    // Hilfsfunktion zum Erstellen des Bild-Grids
    Widget buildImageGridWidget(BuildContext gridContext, List<ReceivedFile> currentImageFiles) {
        final int totalImageCount = currentImageFiles.length;

        // Da wir jetzt wissen, dass currentImageFiles nicht leer ist, wenn diese Funktion aufgerufen wird
        // (außer im Fall "noImages", wo sie nicht aufgerufen wird), ist die Prüfung auf 0 nicht mehr nötig.

        if (totalImageCount == 1) {
            return Padding(
                padding: const EdgeInsets.all(4.0),
                child: AspectRatio(
                    aspectRatio: 1.0,
                    child: buildImageItem(gridContext, currentImageFiles[0]),
                ),
            );
        }

        List<Widget> gridItems = [];
        int crossAxisCountValue;

        if (totalImageCount <= 6) {
            for (int i = 0; i < totalImageCount; i++) {
                gridItems.add(buildImageItem(gridContext, currentImageFiles[i]));
            }
            if (totalImageCount == 2) crossAxisCountValue = 2;
            else if (totalImageCount == 3) crossAxisCountValue = 3;
            else if (totalImageCount == 4) crossAxisCountValue = 2;
            else crossAxisCountValue = 3;
        } else {
            for (int i = 0; i < 5; i++) {
                gridItems.add(buildImageItem(gridContext, currentImageFiles[i]));
            }
            gridItems.add(buildOverflowIndicator(gridContext, totalImageCount - 5));
            crossAxisCountValue = 3;
        }

        return GridView.count(
            crossAxisCount: crossAxisCountValue,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: gridItems,
        );
    }

    // Hilfsfunktion zum Erstellen der Liste anderer Dateien
    Widget buildOtherFilesListWidget(BuildContext listContext, List<ReceivedFile> currentOtherFiles) {
        return ListView.builder(
            shrinkWrap: true,
            itemCount: currentOtherFiles.length,
            itemBuilder: (ctx, index) {
                final file = currentOtherFiles[index];
                return ListTile(
                    leading: Icon(Icons.insert_drive_file_outlined),
                    title: Text(file.name, overflow: TextOverflow.ellipsis),
                    subtitle: Text(getFileSizeString(file.size), style: TextStyle(fontSize: 12)),
                    onTap: () => OpenAppFile.open(file.path),
                );
            },
        );
    }

    // Hilfsfunktion für den Footer bei gemischtem Inhalt
    Widget buildMixedContentFooter(BuildContext footerContext, int count) {
        return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4.0),
            child: Text(AppLocalizations.of(context)!.received_files_dialog_more_files_text(count),),
        );
    }

    // Hilfsfunktion zum Öffnen der Galerie (Platzhalter)
    Future<void> _openFilesLocation(Directory? directory) async {
        if (directory == null) {
            dprint("Kein Zielverzeichnis für Galerie angegeben.");
            return;
        }

        OpenResult result = await OpenAppFile.open(directory.path);
    }

    bool isDesktop = Platform.isMacOS || Platform.isWindows || Platform.isLinux;

    return showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
            String mimeTypeString = getMimeTypeString(dialogContext, mimeTypeGroup, allFiles.length);
            String titleText = AppLocalizations.of(context)!.received_files_dialog_title(allFiles.length, mimeTypeString, device.firstname);

            Widget contentWidget = SizedBox();
            List<Widget> actions = [];

            if (onlyImages) {
                contentWidget = buildImageGridWidget(dialogContext, imageFiles);
            } else if (noImages) {
                contentWidget = buildOtherFilesListWidget(dialogContext, otherFiles);
            } else if (mixedContent) {
                contentWidget = SingleChildScrollView( // Stellt Scrollbarkeit sicher, falls Grid + Footer zu hoch
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            buildImageGridWidget(dialogContext, imageFiles),
                            buildMixedContentFooter(dialogContext, otherFiles.length),
                        ],
                    ),
                );
            }

            actions.add(TextButton(child: Text(AppLocalizations.of(context)!.dialog_close_button), onPressed: () => Navigator.of(dialogContext).pop()));

            // Anzeigen-Button hinzufügen, wenn wir auf Desktop sind
            if (isDesktop) {
                actions.add(TextButton(child: Text(AppLocalizations.of(context)!.received_files_dialog_show_files_button), onPressed: () => _openFilesLocation(targetDirectory)));
            }

            return AlertDialog(
                title: Text(titleText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                content: Container(
                    width: isDesktop ? desktopDialogMaxWidth : double.maxFinite,
                    constraints: isDesktop ? BoxConstraints(maxWidth: desktopDialogMaxWidth) : null,
                    child: contentWidget,
                ),
                actions: actions,
                actionsPadding: EdgeInsets.only(left: 24, right: 24, bottom: 16),
            );
        },
    );
}