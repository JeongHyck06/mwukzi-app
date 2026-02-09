class CreateRoomResponse {
  final String roomId;
  final String inviteCode;
  final String roomStatus;

  CreateRoomResponse({
    required this.roomId,
    required this.inviteCode,
    required this.roomStatus,
  });

  factory CreateRoomResponse.fromJson(Map<String, dynamic> json) {
    return CreateRoomResponse(
      roomId: (json['room_id'] ?? json['roomId']) as String,
      inviteCode: (json['invite_code'] ?? json['inviteCode']) as String,
      roomStatus: (json['room_status'] ?? json['roomStatus']) as String,
    );
  }
}
