import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import 'models/login_response.dart';

class AuthApi {
  Future<LoginResponse> loginWithKakao(String kakaoAccessToken) async {
    final uri = ApiConfig.buildUri('/api/v1/auth/kakao');
    final response = await http.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'kakao_access_token': kakaoAccessToken,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return LoginResponse.fromJson(data);
    }

    throw Exception(
      '백엔드 로그인 실패 (${response.statusCode}): ${response.body}',
    );
  }
}
