enum ErrorState
{
    none, // Standardzustand
    connectionTimeout, // Verbindung zum Gerät konnte nicht hergestellt werden
    receiverNotFound, // Empfängergerät nicht gefunden
    receiverDeclined, // Empfängergerät hat die Anfrage abgelehnt
    fileAccessError, // Zugriff auf die Datei nicht möglich
    sendingCancelled, // Senden wurde abgebrochen
    receivingCancelled, // Fehler beim Empfängergerät
}