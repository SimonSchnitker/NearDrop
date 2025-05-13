/// Definiert eine Auflistung von Antworten auf eine Anfrage, um Dateien zu senden.
enum SendRequestAnswer
{
    accepted, // Anfrage wurde akzeptiert
    declined, // Anfrage wurde abgelehnt
    error, // Fehler bei der Anfrage
}