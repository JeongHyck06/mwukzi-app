import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../auth/kakao_login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            // Header (220px)
          Container(
            height: 220,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // App Name
                Text(
                  '뭑지',
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryMain,
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle
                Text(
                  '오늘 뭐 먹을지 고민 끝!',
                  style: AppTextStyles.bodyL.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                // Hero Visual (아이콘 + 타이틀)
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Circle (96x96)
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.primaryMain.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryMain.withOpacity(0.18),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMain.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                // TODO: 여기에 SVG 아이콘 추가
                                child: Icon(
                                  Icons.restaurant_menu,
                                  color: AppColors.primaryMain,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // App Title (큰 타이틀)
                      Text(
                        '뭑지',
                        style: GoogleFonts.inter(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Buttons Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 방 만들기 버튼
                _LargeButton(
                  title: '방 만들기',
                  description: '친구들과 함께 결정하기',
                  isPrimary: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const KakaoLoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // 코드로 참여 버튼
                _LargeButton(
                  title: '코드로 참여',
                  description: '초대 코드 입력하기',
                  isPrimary: false,
                  onTap: () {
                    // TODO: 코드 참여 화면으로 이동
                  },
                ),
                const SizedBox(height: 16),
                
                // 혼자 사용 버튼
                _LargeButton(
                  title: '혼자 사용',
                  description: '빠르게 추천받기',
                  isPrimary: false,
                  onTap: () {
                    // TODO: 취향 입력 화면으로 이동
                  },
                ),
              ],
            ),
          ),

            // Bottom Spacer (나머지 공간)
            Expanded(
              child: Container(
                color: AppColors.backgroundTint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 큰 버튼 위젯 (타이틀 + 설명)
class _LargeButton extends StatelessWidget {
  final String title;
  final String description;
  final bool isPrimary;
  final VoidCallback onTap;

  const _LargeButton({
    required this.title,
    required this.description,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryMain : Colors.white,
          border: isPrimary
              ? null
              : Border.all(color: AppColors.primaryMain, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.headingM.copyWith(
                color: isPrimary ? Colors.white : AppColors.primaryMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodyM.copyWith(
                color: isPrimary
                    ? Colors.white.withOpacity(0.8)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
