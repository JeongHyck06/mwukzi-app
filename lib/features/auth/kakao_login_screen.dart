import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class KakaoLoginScreen extends StatelessWidget {
  const KakaoLoginScreen({super.key});

  Future<void> _loginWithKakao(BuildContext context) async {
    try {
      // 카카오톡 설치 여부 확인
      if (await isKakaoTalkInstalled()) {
        try {
          // 카카오톡으로 로그인
          await UserApi.instance.loginWithKakaoTalk();
        } catch (error) {
          print('카카오톡 로그인 실패 $error');
          
          // 카카오톡 로그인 실패 시 카카오 계정으로 로그인
          try {
            await UserApi.instance.loginWithKakaoAccount();
          } catch (error) {
            print('카카오 계정 로그인 실패 $error');
          }
        }
      } else {
        // 카카오톡 미설치 시 카카오 계정으로 로그인
        try {
          await UserApi.instance.loginWithKakaoAccount();
        } catch (error) {
          print('카카오 계정 로그인 실패 $error');
        }
      }

      // 로그인 성공 후 사용자 정보 가져오기
      User user = await UserApi.instance.me();
      print('로그인 성공: ${user.kakaoAccount?.profile?.nickname}');
      
      // TODO: 방 로비 화면으로 이동
      if (context.mounted) {
        // Navigator.pushReplacement(context, ...);
      }
    } catch (error) {
      print('로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                            foregroundColor: AppColors.textPrimary.withOpacity(0.9),
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
                              color: AppColors.textPrimary.withOpacity(0.9),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

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
