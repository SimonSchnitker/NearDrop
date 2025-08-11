import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import '../l10n/gen/app_localizations.dart';

/// Definiert eine Auflistung von MIME-Typ-Gruppen.
enum MimeTypeGroup
{
  mixed,
  images,
  videos,
  audios,
  media, // Bilder, Videos und Audios
  documents,
}

class MimeTypeHelper
{
  /// Gibt den MIME-Typ-String basierend auf der Gruppe und der Anzahl der Dateien zurück.
  static String getMimeTypeString(BuildContext context, MimeTypeGroup mimeTypeGroup, int filesCount)
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

  /// Bestimmt die Gruppe der MIME-Typen basierend auf den übergebenen Dateien.
  static MimeTypeGroup getMimeTypeGroup(List<File> files)
  {
    List<String> mimeTypes = [];
    for (File file in files)
    {
      String mimeType = lookupMimeType(file.path) ?? "";
      mimeTypes.add(mimeType);
    }

    if (mimeTypes.every((element) => element.startsWith("image/")))
    {
      return MimeTypeGroup.images;
    }
    else if (mimeTypes.every((element) => element.startsWith("video/")))
    {
      return MimeTypeGroup.videos;
    }
    else if (mimeTypes.every((element) => element.startsWith("audio/")))
    {
      return MimeTypeGroup.audios;
    }
    else if (mimeTypes.every((element) => element.startsWith("image/") || element.startsWith("video/") || element.startsWith("audio/")))
    {
      return MimeTypeGroup.media;
    }

    return MimeTypeGroup.mixed;
  }
}