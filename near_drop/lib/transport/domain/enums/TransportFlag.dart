/// Definiert Zustände für den Transport von Daten.
enum TransportFlag
{
    chunk, // Ein Chunk wird nun gesendet
    ack, // Bestätigung, dass ein Chunk empfangen wurde
    cancel, // Sender oder Empfänger möchte den Transport abbrechen
}