class RoomParticipantResponse {
  final String participantId;
  final String displayName;
  final String role;
  final bool hasSubmitted;

  RoomParticipantResponse({
    required this.participantId,
    required this.displayName,
    required this.role,
    required this.hasSubmitted,
  });

  factory RoomParticipantResponse.fromJson(Map<String, dynamic> json) {
    return RoomParticipantResponse(
      participantId: (json['participant_id'] ?? json['participantId']) as String,
      displayName: (json['display_name'] ?? json['displayName']) as String,
      role: (json['role']) as String,
      hasSubmitted: (json['has_submitted'] ?? json['hasSubmitted']) as bool,
    );
  }
}
