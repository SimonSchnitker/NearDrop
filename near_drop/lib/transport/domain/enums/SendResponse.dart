/// Definiert eine Auflistung von möglichen Ergebnissen beim Senden von Dateien.
enum SendResponse
{
    ok,
    receiverDeclined,
    receiverNotFound,
    fileAccessError,
    connectionError,
    timeout,
}