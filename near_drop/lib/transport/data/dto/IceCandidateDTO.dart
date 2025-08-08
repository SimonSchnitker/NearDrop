class IceCandidateDTO
{
    String nearbyUuid;
    String connectionId;
    String candidate;
    String? sdpMid;
    int? sdpMLineIndex;

    IceCandidateDTO(this.nearbyUuid, this.connectionId, this.candidate, this.sdpMid, this.sdpMLineIndex);

    static IceCandidateDTO fromMap(Map<String, dynamic> map)
    {
        return IceCandidateDTO(
            map["nearby-uuid"],
            map["connectionId"],
            map["candidate"],
            map["sdpMid"],
            map["sdpMLineIndex"]
        );
    }
}