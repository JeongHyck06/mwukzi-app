class PlaceSelectionSummaryResponse {
  final bool allCompleted;
  final bool myCompleted;
  final int totalSelectedCount;
  final List<String> candidateNames;
  final List<PlaceSelectionParticipantStatus> participants;

  const PlaceSelectionSummaryResponse({
    required this.allCompleted,
    required this.myCompleted,
    required this.totalSelectedCount,
    required this.candidateNames,
    required this.participants,
  });

  factory PlaceSelectionSummaryResponse.fromJson(Map<String, dynamic> json) {
    final rawCandidates =
        (json['candidate_names'] as List<dynamic>?) ??
        (json['candidateNames'] as List<dynamic>?) ??
        const [];
    final rawParticipants =
        (json['participants'] as List<dynamic>?) ?? const [];

    return PlaceSelectionSummaryResponse(
      allCompleted:
          (json['all_completed'] as bool?) ??
          (json['allCompleted'] as bool?) ??
          false,
      myCompleted:
          (json['my_completed'] as bool?) ??
          (json['myCompleted'] as bool?) ??
          false,
      totalSelectedCount:
          _toInt(json['total_selected_count'] ?? json['totalSelectedCount']) ??
          0,
      candidateNames:
          rawCandidates
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList(),
      participants:
          rawParticipants
              .map(
                (item) => PlaceSelectionParticipantStatus.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
    return int.tryParse(value.toString());
  }
}

class PlaceSelectionParticipantStatus {
  final String participantId;
  final String displayName;
  final bool completed;

  const PlaceSelectionParticipantStatus({
    required this.participantId,
    required this.displayName,
    required this.completed,
  });

  factory PlaceSelectionParticipantStatus.fromJson(Map<String, dynamic> json) {
    return PlaceSelectionParticipantStatus(
      participantId:
          (json['participant_id'] ?? json['participantId'])?.toString() ?? '',
      displayName:
          (json['display_name'] ?? json['displayName'])?.toString() ?? '',
      completed:
          (json['completed'] as bool?) ??
          (json['is_completed'] as bool?) ??
          false,
    );
  }
}
