import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/join_room_response.dart';

class JoinRoomApi {
  Future<JoinRoomResponse> joinRoom({
    required String inviteCode,
    required String displayName,
  }) async {
    final uri = ApiConfig.buildUri('/api/v1/rooms/join');
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'invite_code': inviteCode,
        'display_name': displayName,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return JoinRoomResponse.fromJson(data);
    }

    throw Exception(
      '코드 참여 실패 (${response.statusCode}): ${response.body}',
    );
  }
}
