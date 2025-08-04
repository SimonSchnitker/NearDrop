class AnswerDTO
{
    String sender;
    int connectionId;
    String sdp;
    String sdpType;

    AnswerDTO(this.sender, this.connectionId, this.sdp, this.sdpType);

    static AnswerDTO fromMap(Map<String, dynamic> map)
    {
        return AnswerDTO(
            map['sender'] as String,
            map['connectionId'] as int,
            map['sdp'] as String,
            map['sdp-type'] as String
        );
    }
}