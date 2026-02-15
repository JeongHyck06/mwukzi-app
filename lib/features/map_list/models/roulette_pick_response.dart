class RoulettePickResponse {
  final String selectedPlaceName;
  final int totalTicketCount;
  final List<String> candidateNames;

  const RoulettePickResponse({
    required this.selectedPlaceName,
    required this.totalTicketCount,
    required this.candidateNames,
  });

  factory RoulettePickResponse.fromJson(Map<String, dynamic> json) {
    final rawCandidates =
        (json['candidate_names'] as List<dynamic>?) ??
        (json['candidateNames'] as List<dynamic>?) ??
        const [];

    return RoulettePickResponse(
      selectedPlaceName:
          (json['selected_place_name'] ?? json['selectedPlaceName'])
              ?.toString() ??
          '',
      totalTicketCount:
          _toInt(json['total_ticket_count'] ?? json['totalTicketCount']) ?? 0,
      candidateNames:
          rawCandidates
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
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
