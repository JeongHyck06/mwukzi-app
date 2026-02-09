class JoinRoomResponse {
  final String roomId;
  final String inviteCode;
  final String participantId;
  final String displayName;
  final String roomStatus;

  JoinRoomResponse({
    required this.roomId,
    required this.inviteCode,
    required this.participantId,
    required this.displayName,
    required this.roomStatus,
  });

  factory JoinRoomResponse.fromJson(Map<String, dynamic> json) {
    return JoinRoomResponse(
      roomId: (json['room_id'] ?? json['roomId']) as String,
      inviteCode: (json['invite_code'] ?? json['inviteCode']) as String,
      participantId: (json['participant_id'] ?? json['participantId']) as String,
      displayName: (json['display_name'] ?? json['displayName']) as String,
      roomStatus: (json['room_status'] ?? json['roomStatus']) as String,
    );
  }
}
