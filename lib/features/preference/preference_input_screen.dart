import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

typedef PreferenceSubmitHandler = Future<void> Function(
  List<String> chips,
  String freeText,
);

class PreferenceInputScreen extends StatefulWidget {
  final String? roomId;
  final String? roomToken;
  final String? participantId;
  final PreferenceSubmitHandler? onSubmit;
  final List<String> initialSelectedTags;
  final String initialFreeText;

  const PreferenceInputScreen({
    super.key,
    this.roomId,
    this.roomToken,
    this.participantId,
    this.onSubmit,
    this.initialSelectedTags = const <String>[],
    this.initialFreeText = '',
  });

  @override
  State<PreferenceInputScreen> createState() => _PreferenceInputScreenState();
}

class _PreferenceInputScreenState extends State<PreferenceInputScreen> {
  static const List<String> _defaultTags = [
    '매콤',
    '한식',
    '면',
    '밥',
    '국물',
    '고기',
    '가볍게',
    '든든',
  ];

  static const Map<String, List<String>> _moreTagGroups = {
    '맛/자극 관련': [
      '매콤',
      '안 매움',
      '얼큰',
      '담백',
      '느끼함',
      '자극적',
      '깔끔',
      '달콤',
      '짭짤',
    ],
    '음식 타입/구성': [
      '면',
      '밥',
      '국물',
      '고기',
      '튀김',
      '구이',
      '볶음',
      '찜',
      '덮밥',
      '분식',
    ],
    '취향 제약': [
      '면 X',
      '매운 거 X',
      '밀가루 X',
      '기름짐 X',
      '냄새 적음',
      '조용한 곳',
      '웨이팅 적음',
    ],
  };

  final TextEditingController _freeTextController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTags.addAll(widget.initialSelectedTags);
    _freeTextController.text = widget.initialFreeText;
  }

  @override
  void dispose() {
    _freeTextController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      _toggleTagValue(tag);
    });
  }

  void _toggleTagValue(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
  }

  Future<void> _openMoreTagsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final maxSheetHeight = MediaQuery.of(context).size.height * 0.75;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SizedBox(
                  height: maxSheetHeight,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            '태그 더보기',
                            style: AppTextStyles.headingM,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _moreTagGroups.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: AppTextStyles.bodyM.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: entry.value
                                          .map(
                                            (tag) => _TagChip(
                                              label: tag,
                                              isSelected:
                                                  _selectedTags.contains(tag),
                                              onTap: () {
                                                setState(() {
                                                  _toggleTagValue(tag);
                                                });
                                                setModalState(() {});
                                              },
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    final freeText = _freeTextController.text.trim();
    if (_selectedTags.isEmpty && freeText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('태그 또는 자유 입력을 하나 이상 작성해 주세요')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formatted = _buildFormattedPreferenceText();
      if (widget.onSubmit != null) {
        await widget.onSubmit!(
          _selectedTags.toList(),
          freeText,
        );
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('취향 입력이 완료되었습니다')),
      );
      Navigator.pop(
        context,
        {
          'submitted': true,
          'chips': _selectedTags.toList(),
          'freeText': freeText,
          'formattedPreference': formatted,
        },
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('취향 입력에 실패했습니다: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedPreview = _buildFormattedPreferenceText();
    return Scaffold(
      backgroundColor: AppColors.backgroundTint,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 56,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Text(
                      '‹',
                      style: AppTextStyles.headingL.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '취향 입력',
                    style: AppTextStyles.headingM,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '태그 선택 (선택사항)',
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ..._defaultTags.map(
                                (tag) => _TagChip(
                                  label: tag,
                                  isSelected: _selectedTags.contains(tag),
                                  onTap: () => _toggleTag(tag),
                                ),
                              ),
                              _MoreTagChip(onTap: _openMoreTagsSheet),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '태그는 여러 개 선택해도 괜찮아요',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          if (_selectedTags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '선택됨: ${_selectedTags.join(', ')}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primaryMain,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '자유 입력',
                            style: AppTextStyles.bodyM.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _freeTextController,
                            minLines: 4,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: '예: 오늘은 면은 별로, 국물 있으면 좋겠어요',
                              hintStyle: AppTextStyles.bodyM.copyWith(
                                color: AppColors.textDisabled,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(16),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: AppColors.border,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: const BorderSide(
                                  color: AppColors.primaryMain,
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        formattedPreview,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryMain,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primaryMain.withValues(alpha: 0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                '입력 완료',
                                style: AppTextStyles.buttonText,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildFormattedPreferenceText() {
    final selected = _selectedTags.toList()..sort();
    final freeText = _freeTextController.text.trim();

    final chipPart = selected.isEmpty ? '없음' : selected.join(', ');
    final freeTextPart = freeText.isEmpty ? '없음' : freeText;

    return [
      '[취향 입력 요약]',
      '- 선택 태그: $chipPart',
      '- 자유 입력: $freeTextPart',
    ].join('\n');
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryMain : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.circular(999),
          border: isSelected
              ? null
              : Border.all(color: const Color(0x00000000), width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF333333),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreTagChip extends StatelessWidget {
  final VoidCallback onTap;

  const _MoreTagChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          '+ 더보기',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
