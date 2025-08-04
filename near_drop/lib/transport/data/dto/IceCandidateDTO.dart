class IceCandidateDTO
{
    String sender;
    int connectionId;
    String candidate;
    String? sdpMid;
    int? sdpMLineIndex;

    IceCandidateDTO(this.sender, this.connectionId, this.candidate, this.sdpMid, this.sdpMLineIndex);

    static IceCandidateDTO fromMap(Map<String, dynamic> map)
    {
        return IceCandidateDTO(
            map["sender"],
            map["connectionId"],
            map["candidate"],
            map["sdpMid"],
            map["sdpMLineIndex"]
        );
    }
}