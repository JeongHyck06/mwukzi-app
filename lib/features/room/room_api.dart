import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/create_room_response.dart';
import 'models/participant_preference_response.dart';
import 'models/room_participant_response.dart';

class RoomApi {
  String buildSseUrl({required String inviteCode}) {
    return ApiConfig.buildUri(
      '/api/v1/rooms/participants/stream?inviteCode=$inviteCode',
    ).toString();
  }

  Future<CreateRoomResponse> createRoom({
    required String accessToken,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms');
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
      return CreateRoomResponse.fromJson(data);
    }

    throw Exception(
      '방 생성 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> leaveRoomAsHost({
    required String roomId,
    required String accessToken,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/leave');
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'room_id': roomId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      '방 나가기 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> leaveRoomAsGuest({
    required String participantId,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/leave');
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'participant_id': participantId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      '방 나가기 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<List<RoomParticipantResponse>> getParticipantsByInviteCode({
    required String inviteCode,
  }) async {
    final uri =
        ApiConfig.buildUri('/api/v1/rooms/participants?inviteCode=$inviteCode');
    final response = await http.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .map((item) =>
              RoomParticipantResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception(
      '참여자 조회 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<RoomParticipantResponse> joinAsHost({
    required String roomId,
    required String accessToken,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/participants/host');
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
      return RoomParticipantResponse.fromJson(data);
    }

    throw Exception(
      '방장 참여 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<RoomParticipantResponse> submitPreference({
    required String roomId,
    String? participantId,
    String? accessToken,
    List<String> chips = const [],
    String freeText = '',
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/$roomId/preferences/submit');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode({
        'participant_id': participantId,
        'chips': chips,
        'free_text': freeText,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return RoomParticipantResponse.fromJson(data);
    }

    throw Exception(
      '취향 제출 실패 (${response.statusCode}): ${response.body}',
    );
  }

  Future<ParticipantPreferenceResponse> getParticipantPreference({
    required String roomId,
    required String participantId,
  }) async {
    final uri =
        ApiConfig.buildUri('/api/v1/rooms/$roomId/preferences/$participantId');
    final response = await http.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ParticipantPreferenceResponse.fromJson(data);
    }

    throw Exception(
      '취향 상세 조회 실패 (${response.statusCode}): ${response.body}',
    );
  }
}
