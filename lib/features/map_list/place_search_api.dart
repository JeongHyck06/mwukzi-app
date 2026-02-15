import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/place_detail_response.dart';
import 'models/place_selection_summary_response.dart';
import 'models/place_search_response.dart';
import 'models/roulette_pick_response.dart';

class PlaceSearchApi {
  Future<PlaceSearchResponse> searchPlaces({
    required String roomId,
    double? latitude,
    double? longitude,
    required List<String> keywords,
    int? radiusMeters,
    int sizePerKeyword = 5,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/places/search');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'size_per_keyword': sizePerKeyword,
        'keywords': keywords,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PlaceSearchResponse.fromJson(data);
    }

    throw Exception('식당 검색 실패 (${response.statusCode}): ${response.body}');
  }

  Future<PlaceDetailResponse> getPlaceDetail({
    required String roomId,
    required String placeName,
    required String providerPlaceId,
    double? latitude,
    double? longitude,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/places/detail');
    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'place_name': placeName,
        'provider_place_id': providerPlaceId,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PlaceDetailResponse.fromJson(data);
    }

    throw Exception('식당 상세 조회 실패 (${response.statusCode}): ${response.body}');
  }

  Future<PlaceSelectionSummaryResponse> submitSelections({
    required String roomId,
    required List<Map<String, String>> places,
    String? participantId,
    String? accessToken,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/places/selections');
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({'participant_id': participantId, 'places': places}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PlaceSelectionSummaryResponse.fromJson(data);
    }

    throw Exception('식당 선택 제출 실패 (${response.statusCode}): ${response.body}');
  }

  Future<PlaceSelectionSummaryResponse> getSelectionSummary({
    required String roomId,
    String? participantId,
    String? accessToken,
  }) async {
    final summaryPath =
        (participantId != null && participantId.isNotEmpty)
            ? '/api/v1/rooms/$roomId/places/selections/summary?participantId=$participantId'
            : '/api/v1/rooms/$roomId/places/selections/summary';
    final uri = ApiConfig.buildUri(summaryPath);
    final headers = <String, String>{};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.get(uri, headers: headers);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return PlaceSelectionSummaryResponse.fromJson(data);
    }

    throw Exception(
      '식당 선택 현황 조회 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<RoulettePickResponse> spinRoulette({
    required String roomId,
    required String accessToken,
  }) async {
    final uri = ApiConfig.buildUri(
      '/api/v1/rooms/$roomId/places/roulette/spin',
    );
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RoulettePickResponse.fromJson(data);
    }

    throw Exception('룰렛 추첨 실패 (${response.statusCode}): ${response.body}');
  }
}
