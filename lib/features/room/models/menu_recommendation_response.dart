class MenuRecommendationResponse {
  final String summary;
  final String commonGround;
  final String compromise;
  final List<MenuRecommendationItem> menus;

  const MenuRecommendationResponse({
    required this.summary,
    required this.commonGround,
    required this.compromise,
    required this.menus,
  });

  factory MenuRecommendationResponse.fromJson(Map<String, dynamic> json) {
    final menuList = (json['menus'] as List<dynamic>? ?? const [])
        .map(
          (item) => MenuRecommendationItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
    final commonGroundRaw =
        (json['common_ground'] ?? json['commonGround'])?.toString() ?? '';

    return MenuRecommendationResponse(
      summary: (json['summary'] as String?)?.trim().isNotEmpty == true
          ? json['summary'] as String
          : '취향을 반영한 메뉴 추천입니다.',
      commonGround: commonGroundRaw.trim().isNotEmpty
          ? commonGroundRaw
          : '참여자 공통분모를 정리했습니다.',
      compromise: (json['compromise'] as String?)?.trim().isNotEmpty == true
          ? json['compromise'] as String
          : '취향 차이를 반영한 타협안을 제안합니다.',
      menus: menuList,
    );
  }
}

class MenuRecommendationItem {
  final String name;
  final String reason;

  const MenuRecommendationItem({
    required this.name,
    required this.reason,
  });

  factory MenuRecommendationItem.fromJson(Map<String, dynamic> json) {
    return MenuRecommendationItem(
      name: (json['name'] as String?) ?? '',
      reason: (json['reason'] as String?) ?? '',
    );
  }
}
