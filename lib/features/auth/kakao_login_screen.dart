import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../room/room_api.dart';
import '../room/room_lobby_screen.dart';
import 'auth_api.dart' as backend_auth;
import 'models/login_response.dart';

class KakaoLoginScreen extends StatefulWidget {
  const KakaoLoginScreen({super.key});

  @override
  State<KakaoLoginScreen> createState() => _KakaoLoginScreenState();
}

class _KakaoLoginScreenState extends State<KakaoLoginScreen> {
  bool _isAutoLogin = false;
  bool _isCheckingLocation = false;
  String _locationStatusText = '위치 상태를 확인하는 중입니다...';
  String _locationCoordsText = '-';

  Future<_HostPositionResult> _resolveHostPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const _HostPositionResult(
          errorCode: _HostPositionErrorCode.serviceDisabled,
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const _HostPositionResult(
          errorCode: _HostPositionErrorCode.deniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const _HostPositionResult(
          errorCode: _HostPositionErrorCode.denied,
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return _HostPositionResult(position: position);
    } catch (_) {
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return _HostPositionResult(position: lastKnown);
        }
        return const _HostPositionResult(
          errorCode: _HostPositionErrorCode.unavailable,
        );
      } catch (_) {
        return const _HostPositionResult(
          errorCode: _HostPositionErrorCode.unavailable,
        );
      }
    }
  }

  Future<void> _showLocationGuide(_HostPositionErrorCode? errorCode) async {
    if (!mounted) {
      return;
    }
    String message = '방 생성에는 위치 권한이 필요합니다.';
    String actionLabel = '설정 열기';
    Future<bool> Function() action = Geolocator.openAppSettings;

    switch (errorCode) {
      case _HostPositionErrorCode.serviceDisabled:
        message = '위치 서비스가 꺼져 있어요. 위치 서비스를 켜주세요.';
        actionLabel = '위치 서비스 열기';
        action = Geolocator.openLocationSettings;
        break;
      case _HostPositionErrorCode.denied:
        message = '위치 권한이 거부되었습니다. 권한을 허용해 주세요.';
        break;
      case _HostPositionErrorCode.deniedForever:
        message = '위치 권한이 항상 거부 상태입니다. 설정에서 권한을 허용해 주세요.';
        break;
      case _HostPositionErrorCode.unavailable:
      case null:
        message = '위치를 확인할 수 없습니다. 잠시 후 다시 시도해 주세요.';
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () {
            action();
          },
        ),
      ),
    );
  }

  Future<OAuthToken?> _getKakaoToken({bool useCachedToken = true}) async {
    if (useCachedToken) {
      final cachedToken = await TokenManagerProvider.instance.manager.getToken();
      if (cachedToken != null) {
        return cachedToken;
      }
    }

    if (await isKakaoTalkInstalled()) {
      try {
        return await UserApi.instance.loginWithKakaoTalk();
      } catch (error) {
        print('카카오톡 로그인 실패 $error');
      }
    }

    try {
      return await UserApi.instance.loginWithKakaoAccount();
    } catch (error) {
      print('카카오 계정 로그인 실패 $error');
    }

    return null;
  }

  bool _isBackendConnectionError(Object error) {
    final message = error.toString();
    return message.contains('Connection refused') ||
        message.contains('SocketException');
  }

  bool _isBackendUnauthorizedError(Object error) {
    final message = error.toString();
    return message.contains('(401)') || message.contains('KAKAO_UNAUTHORIZED');
  }

  @override
  void initState() {
    super.initState();
    _refreshLocationDebugInfo();
    _tryAutoLogin();
  }

  Future<void> _refreshLocationDebugInfo() async {
    if (mounted) {
      setState(() {
        _isCheckingLocation = true;
      });
    }

    String statusText = '';
    String coordsText = '-';

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      statusText =
          '서비스: ${serviceEnabled ? 'ON' : 'OFF'} / 권한: ${_permissionLabel(permission)}';

      Position? position;
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        );
      } else {
        position = await Geolocator.getLastKnownPosition();
      }

      if (position != null) {
        coordsText =
            'lat: ${position.latitude.toStringAsFixed(6)}, lng: ${position.longitude.toStringAsFixed(6)}';
      } else {
        coordsText = '좌표 없음';
      }
    } catch (e) {
      statusText = '위치 확인 실패';
      coordsText = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _locationStatusText = statusText;
      _locationCoordsText = coordsText;
      _isCheckingLocation = false;
    });
  }

  String _permissionLabel(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
        return 'always';
      case LocationPermission.whileInUse:
        return 'whileInUse';
      case LocationPermission.denied:
        return 'denied';
      case LocationPermission.deniedForever:
        return 'deniedForever';
      case LocationPermission.unableToDetermine:
        return 'unableToDetermine';
    }
  }

  Future<void> _tryAutoLogin() async {
    final cachedToken = await TokenManagerProvider.instance.manager.getToken();
    if (cachedToken == null || !mounted) {
      return;
    }
    setState(() {
      _isAutoLogin = true;
    });
    await _loginWithKakao(context, silent: true);
  }

  Future<void> _loginWithKakao(
    BuildContext context, {
    bool silent = false,
  }) async {
    try {
      OAuthToken? token = await _getKakaoToken();
      if (token == null) {
        throw Exception('카카오 로그인 토큰을 가져오지 못했습니다');
      }

      final authApi = backend_auth.AuthApi();
      late LoginResponse loginResponse;
      try {
        loginResponse = await authApi.loginWithKakao(token.accessToken);
      } catch (error) {
        if (_isBackendUnauthorizedError(error)) {
          // 캐시 토큰이 만료/무효일 수 있어 토큰 초기화 후 1회 재시도
          await UserApi.instance.logout();
          token = await _getKakaoToken(useCachedToken: false);
          if (token == null) {
            throw Exception('카카오 로그인을 다시 시도해 주세요');
          }
          loginResponse = await authApi.loginWithKakao(token.accessToken);
        } else {
          rethrow;
        }
      }
      print('백엔드 로그인 성공: ${loginResponse.user.nickname}');

      final hostPositionResult = await _resolveHostPosition();
      final hostPosition = hostPositionResult.position;
      if (hostPosition == null) {
        if (!silent) {
          await _showLocationGuide(hostPositionResult.errorCode);
        }
        return;
      }
      final roomResponse = await RoomApi().createRoom(
        accessToken: loginResponse.accessToken,
        centerLat: hostPosition.latitude,
        centerLng: hostPosition.longitude,
        radiusMeters: 1500,
      );
      await RoomApi().joinAsHost(
        roomId: roomResponse.roomId,
        accessToken: loginResponse.accessToken,
      );

      if (context.mounted && !silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 성공했습니다')),
        );
      }

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RoomLobbyScreen(
              roomId: roomResponse.roomId,
              inviteCode: roomResponse.inviteCode,
              displayName: loginResponse.user.nickname,
              roomStatus: roomResponse.roomStatus,
              accessToken: loginResponse.accessToken,
            ),
          ),
        );
      }
    } catch (error) {
      print('로그인 실패: $error');
      if (context.mounted && !silent) {
        if (_isBackendConnectionError(error)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('백엔드 서버 연결에 실패했습니다. 서버 실행 상태를 확인해 주세요.')),
          );
          return;
        }
        if (_isBackendUnauthorizedError(error)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('카카오 인증이 만료되었거나 유효하지 않습니다. 다시 로그인해 주세요.')),
          );
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAutoLogin = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAutoLogin) {
      return Scaffold(
        backgroundColor: AppColors.backgroundTint,
        body: const SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.backgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar (56px)
            Container(
              height: 56,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  // Back 버튼
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Text(
                      '‹',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Text(
                    '로그인',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),

            // Content (중앙 정렬)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Login Guide Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '방을 만들려면 로그인이 필요해요',
                              style: AppTextStyles.headingM.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '친구들과 함께 결정하기 위해 간편하게 시작하세요',
                              style: AppTextStyles.bodyM.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Kakao Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _loginWithKakao(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kakaoYellow,
                            foregroundColor: AppColors.textPrimary.withValues(alpha: 0.9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          child: Text(
                            '카카오로 시작하기',
                            style: AppTextStyles.buttonText.copyWith(
                              color: AppColors.textPrimary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '위치 확인',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _locationStatusText,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _locationCoordsText,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 40,
                              child: OutlinedButton(
                                onPressed: _isCheckingLocation
                                    ? null
                                    : _refreshLocationDebugInfo,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _isCheckingLocation ? '확인 중...' : '현재 위치 다시 확인',
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Note Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundTint,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '방 만들기와 결과 저장에 필요해요',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '혼자 사용은 로그인 없이 가능해요',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostPositionResult {
  final Position? position;
  final _HostPositionErrorCode? errorCode;

  const _HostPositionResult({this.position, this.errorCode});
}

enum _HostPositionErrorCode {
  serviceDisabled,
  denied,
  deniedForever,
  unavailable,
}
