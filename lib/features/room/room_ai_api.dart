import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/menu_recommendation_response.dart';

class RoomAiApi {
  Future<MenuRecommendationResponse> recommendMenu({
    required String roomId,
    required List<Map<String, String>> participants,
    int count = 5,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/ai/recommend-menu');
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'participants': participants,
        'count': count,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MenuRecommendationResponse.fromJson(data);
    }

    throw Exception(
      '메뉴 추천 실패 (${response.statusCode}): ${response.body}',
    );
  }
}
