/// Definiert Zustände für den Transport von Daten.
enum TransportFlag
{
    chunk, // Ein Chunk wird nun gesendet
    file, // Eine Datei wird gesendet
    fileSkip, // Eine Datei wird übersprungen
    ack, // Bestätigung, dass ein Chunk empfangen wurde
    cancel, // Sender oder Empfänger möchte den Transport abbrechen
}