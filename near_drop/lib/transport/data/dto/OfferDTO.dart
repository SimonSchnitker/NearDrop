/// Definiert die Struktur eines Angebots (Offer) für WebRTC-Verbindungen.
class OfferDTO
{
    String sender;
    int connectionId;
    String sdp;
    String sdpType;

    OfferDTO(this.sender, this.connectionId, this.sdp, this.sdpType);

    static OfferDTO fromMap(Map<String, dynamic> map)
    {
        return OfferDTO(
            map['sender'] as String,
            map['connectionId'] as int,
            map['sdp'] as String,
            map['sdp-type'] as String
        );
    }
}