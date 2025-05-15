enum ErrorState
{
    none, // Standardzustand
    error, // Allgemeiner Fehler
    receiverDeclined, // Empfänger hat die Anfrage abgelehnt
    cancelled, // Transport wurde abgebrochen
}