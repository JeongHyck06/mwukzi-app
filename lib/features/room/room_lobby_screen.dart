import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'room_api.dart';

enum ParticipantStatus { completed, inProgress }

class RoomParticipant {
  final String name;
  final ParticipantStatus status;
  final bool isMe;

  const RoomParticipant({
    required this.name,
    required this.status,
    this.isMe = false,
  });
}

class RoomLobbyScreen extends StatefulWidget {
  final String roomId;
  final String inviteCode;
  final String displayName;
  final String roomStatus;
  final List<RoomParticipant> participants;
  final String? participantId;
  final String? accessToken;

  const RoomLobbyScreen({
    super.key,
    required this.roomId,
    required this.inviteCode,
    required this.displayName,
    required this.roomStatus,
    this.participants = const [],
    this.participantId,
    this.accessToken,
  });

  @override
  State<RoomLobbyScreen> createState() => _RoomLobbyScreenState();
}

class _RoomLobbyScreenState extends State<RoomLobbyScreen> {
  bool _isLeaving = false;

  bool get _isHost => widget.accessToken != null;

  Future<void> _handleLeave() async {
    if (_isLeaving) {
      return;
    }
    setState(() {
      _isLeaving = true;
    });
    try {
      if (_isHost) {
        await RoomApi().leaveRoomAsHost(
          roomId: widget.roomId,
          accessToken: widget.accessToken!,
        );
      } else if (widget.participantId != null) {
        await RoomApi().leaveRoomAsGuest(
          participantId: widget.participantId!,
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('방 나가기에 실패했습니다: $error')),
        );
      }
      return;
    } finally {
      if (mounted) {
        setState(() {
          _isLeaving = false;
        });
      }
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participantList = widget.participants.isNotEmpty
        ? widget.participants
        : [
            RoomParticipant(
              name: widget.displayName,
              status: ParticipantStatus.inProgress,
              isMe: true,
            ),
          ];
    return WillPopScope(
      onWillPop: () async {
        await _handleLeave();
        return !_isLeaving;
      },
      child: Scaffold(
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
                      onPressed: _handleLeave,
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
                      '방 로비',
                      style: AppTextStyles.headingM,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      _InviteCodeCard(
                        inviteCode: widget.inviteCode,
                      ),
                      const SizedBox(height: 20),
                      _SectionTitle(
                        title: '참여자 (${participantList.length}명)',
                      ),
                      const SizedBox(height: 12),
                      ...participantList.map(
                        (participant) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ParticipantCard(participant: participant),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: 취향 입력 화면으로 이동
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryMain,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            '취향 입력하기',
                            style: AppTextStyles.buttonText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(
                              color: AppColors.border,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            '모두 입력 완료 시 추천 시작',
                            style: AppTextStyles.bodyM.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final String inviteCode;

  const _InviteCodeCard({
    required this.inviteCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '초대 코드',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  inviteCode,
                  style: AppTextStyles.headingL.copyWith(
                    color: AppColors.primaryMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(text: inviteCode),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('초대 코드를 복사했습니다')),
                );
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '복사',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTextStyles.bodyM.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final RoomParticipant participant;

  const _ParticipantCard({
    required this.participant,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = participant.status == ParticipantStatus.completed
        ? AppColors.success
        : AppColors.textSecondary;
    final statusBackground = participant.status == ParticipantStatus.completed
        ? AppColors.success.withOpacity(0.12)
        : AppColors.surface;
    final statusText =
        participant.status == ParticipantStatus.completed ? '입력 완료' : '입력 중';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: participant.isMe
                ? AppColors.primaryMain.withOpacity(0.15)
                : AppColors.surface,
            child: Text(
              participant.name.isNotEmpty ? participant.name[0] : '?',
              style: AppTextStyles.bodyM.copyWith(
                color: participant.isMe
                    ? AppColors.primaryMain
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              participant.name,
              style: AppTextStyles.bodyM.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBackground,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
