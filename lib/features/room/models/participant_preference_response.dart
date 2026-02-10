class ParticipantPreferenceResponse {
  final String participantId;
  final String displayName;
  final bool hasSubmitted;
  final String preferenceText;

  const ParticipantPreferenceResponse({
    required this.participantId,
    required this.displayName,
    required this.hasSubmitted,
    required this.preferenceText,
  });

  factory ParticipantPreferenceResponse.fromJson(Map<String, dynamic> json) {
    return ParticipantPreferenceResponse(
      participantId: (json['participant_id'] ?? json['participantId'] ?? '')
          .toString(),
      displayName: (json['display_name'] ?? json['displayName'] ?? '')
          .toString(),
      hasSubmitted: (json['has_submitted'] ?? json['hasSubmitted']) == true,
      preferenceText:
          (json['preference_text'] ?? json['preferenceText'] ?? '').toString(),
    );
  }
}
