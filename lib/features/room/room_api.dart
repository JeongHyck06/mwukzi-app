import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/create_room_response.dart';

class RoomApi {
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
}
