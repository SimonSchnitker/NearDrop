class AnswerDTO
{
    String nearbyUuid;
    String connectionId;
    String sdp;
    String sdpType;

    AnswerDTO(this.nearbyUuid, this.connectionId, this.sdp, this.sdpType);

    static AnswerDTO fromMap(Map<String, dynamic> map)
    {
        return AnswerDTO(
            map['nearby-uuid'] as String,
            map['connectionId'] as String,
            map['sdp'] as String,
            map['sdp-type'] as String
        );
    }
}