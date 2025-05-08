enum CommunicationState
{
    none, // Standardzustand
    connecting, // Verbindung zu einem Gerät wird hergestellt
    requesting, // Anfrage an ein Gerät wird gesendet
    sending, // Dateien werden an ein Gerät gesendet
    receiving, // Dateien werden von einem Gerät empfangen
    cancelling, // Kommunikation wird abgebrochen
}