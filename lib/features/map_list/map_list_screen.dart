import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../room/models/menu_recommendation_response.dart';

class MapListScreen extends StatefulWidget {
  final MenuRecommendationResponse recommendation;

  const MapListScreen({super.key, required this.recommendation});

  @override
  State<MapListScreen> createState() => _MapListScreenState();
}

class _MapListScreenState extends State<MapListScreen> {
  late final List<_RestaurantCardItem> _items;

  @override
  void initState() {
    super.initState();
    _items = _buildItems(widget.recommendation);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _items.where((item) => item.isSelected).length;

    return Scaffold(
      backgroundColor: AppColors.backgroundTint,
      body: Column(
        children: [
          Container(height: 44, color: const Color(0xFF212121)),
          Container(
            height: 300,
            width: double.infinity,
            color: const Color(0xFFEEEEEE),
            alignment: Alignment.center,
            child: Text(
              'MAP',
              style: AppTextStyles.headingXL.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.white,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _toggleSelection(index),
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color:
                              item.isSelected
                                  ? AppColors.primaryMain.withValues(alpha: 0.3)
                                  : AppColors.border,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.info,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            height: 100,
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedCount == 0
                        ? null
                        : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '룰렛 화면 연결 예정 ($selectedCount곳 선택됨)',
                              ),
                            ),
                          );
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryMain,
                  disabledBackgroundColor: AppColors.border,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  '룰렛 돌리기 ($selectedCount곳 선택됨)',
                  style: AppTextStyles.buttonText.copyWith(
                    color:
                        selectedCount == 0
                            ? AppColors.textSecondary
                            : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      final current = _items[index];
      _items[index] = current.copyWith(isSelected: !current.isSelected);
    });
  }

  List<_RestaurantCardItem> _buildItems(
    MenuRecommendationResponse recommendation,
  ) {
    final menus = recommendation.menus.take(6).toList();

    if (menus.isEmpty) {
      return [
        const _RestaurantCardItem(
          name: '매운 라멘집',
          info: '300m • AI 추천: 매콤한 국물 면 요리',
          isSelected: true,
        ),
        const _RestaurantCardItem(
          name: '한식당',
          info: '450m • 한식 메뉴 다양',
          isSelected: false,
        ),
      ];
    }

    return menus.asMap().entries.map((entry) {
      final index = entry.key;
      final menu = entry.value;
      final distance = 300 + (index * 120);
      return _RestaurantCardItem(
        name: '${menu.name} 맛집',
        info: '${distance}m • AI 추천: ${menu.reason}',
        isSelected: index < 2,
      );
    }).toList();
  }
}

class _RestaurantCardItem {
  final String name;
  final String info;
  final bool isSelected;

  const _RestaurantCardItem({
    required this.name,
    required this.info,
    required this.isSelected,
  });

  _RestaurantCardItem copyWith({bool? isSelected}) {
    return _RestaurantCardItem(
      name: name,
      info: info,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
