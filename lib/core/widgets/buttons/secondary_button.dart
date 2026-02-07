import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryMain,
          backgroundColor: Colors.white,
          side: BorderSide(
            color: onPressed == null ? AppColors.border : AppColors.primaryMain,
            width: 1,
          ),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        child: Text(
          text,
          style: AppTextStyles.buttonText.copyWith(
            color: onPressed == null ? AppColors.textDisabled : AppColors.primaryMain,
          ),
        ),
      ),
    );
  }
}
