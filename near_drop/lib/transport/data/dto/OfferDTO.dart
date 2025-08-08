/// Definiert die Struktur eines Angebots (Offer) für WebRTC-Verbindungen.
class OfferDTO
{
    String nearbyUuid;
    String connectionId;
    String sdp;
    String sdpType;

    OfferDTO(this.nearbyUuid, this.connectionId, this.sdp, this.sdpType);

    static OfferDTO fromMap(Map<String, dynamic> map)
    {
        return OfferDTO(
            map['nearby-uuid'] as String,
            map['connectionId'] as String,
            map['sdp'] as String,
            map['sdp-type'] as String
        );
    }
}