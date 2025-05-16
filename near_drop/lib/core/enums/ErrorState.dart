enum ErrorState
{
    none, // Standardzustand
    error, // Allgemeiner Fehler
    receiverDeclined, // Empfänger hat die Anfrage abgelehnt
    userCanceled, // Transport wurde durch den Benutzer abgebrochen
    timeout, // Zeitüberschreitung
}