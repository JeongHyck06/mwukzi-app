import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/place_detail_response.dart';
import 'models/place_search_response.dart';

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
}
