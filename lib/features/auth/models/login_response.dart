class LoginResponse {
  final String accessToken;
  final UserInfo user;

  const LoginResponse({
    required this.accessToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final accessTokenValue =
        (json['access_token'] ?? json['accessToken']) as String?;
    final userJson = json['user'] as Map<String, dynamic>?;
    if (accessTokenValue == null || userJson == null) {
      throw Exception('로그인 응답 형식이 올바르지 않습니다');
    }

    return LoginResponse(
      accessToken: accessTokenValue,
      user: UserInfo.fromJson(userJson),
    );
  }
}

class UserInfo {
  final String userId;
  final String provider;
  final String nickname;
  final String? email;

  const UserInfo({
    required this.userId,
    required this.provider,
    required this.nickname,
    this.email,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    final userIdValue = (json['user_id'] ?? json['userId']) as String?;
    final providerValue = (json['provider']) as String?;
    final nicknameValue = (json['nickname']) as String?;
    if (userIdValue == null || providerValue == null || nicknameValue == null) {
      throw Exception('사용자 정보 응답 형식이 올바르지 않습니다');
    }

    return UserInfo(
      userId: userIdValue,
      provider: providerValue,
      nickname: nicknameValue,
      email: json['email'] as String?,
    );
  }
}
