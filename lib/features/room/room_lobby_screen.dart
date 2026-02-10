import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../preference/preference_input_screen.dart';
import 'room_api.dart';
import 'room_sse_client.dart';
import 'models/room_participant_response.dart';

enum ParticipantStatus { completed, inProgress }

class RoomParticipant {
  final String? participantId;
  final String name;
  final ParticipantStatus status;
  final bool isMe;

  const RoomParticipant({
    required this.participantId,
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
  bool _isConnecting = false;
  List<RoomParticipant> _participants = [];
  final Map<String, String> _preferenceByParticipantId = {};
  RoomSseClient? _sseClient;
  StreamSubscription<String>? _sseSubscription;

  bool get _isHost => widget.accessToken != null;

  String _participantKey(RoomParticipant participant) {
    final id = participant.participantId?.trim();
    if (id != null && id.isNotEmpty) {
      return id;
    }
    return participant.isMe ? 'me' : 'name:${participant.name}';
  }

  @override
  void initState() {
    super.initState();
    _connectSse();
  }

  @override
  void dispose() {
    _sseSubscription?.cancel();
    _sseClient?.close();
    super.dispose();
  }

  void _connectSse() {
    setState(() {
      _isConnecting = true;
    });
    final url = RoomApi().buildSseUrl(inviteCode: widget.inviteCode);
    _sseClient = createRoomSseClient(url);
    _sseSubscription = _sseClient!.messages.listen((data) {
      if (data.trim().isEmpty) {
        return;
      }
      final decoded = jsonDecode(data);
      if (decoded is List) {
        final response = decoded
            .map((item) => RoomParticipantResponse.fromJson(
                item as Map<String, dynamic>))
            .toList();
        _updateParticipants(response);
      }
    }, onError: (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('실시간 연결 오류: $error')),
        );
      }
    }, onDone: () {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    });
  }

  void _updateParticipants(List<RoomParticipantResponse> response) {
    final mapped = response
        .map(
          (participant) => RoomParticipant(
            participantId: participant.participantId,
            name: participant.displayName,
            status: participant.hasSubmitted
                ? ParticipantStatus.completed
                : ParticipantStatus.inProgress,
            isMe: participant.displayName == widget.displayName,
          ),
        )
        .toList();

    final hasMe = mapped.any((item) => item.isMe);
    if (!hasMe && widget.displayName.isNotEmpty) {
      mapped.add(
        RoomParticipant(
          participantId: 'me',
          name: widget.displayName,
          status: ParticipantStatus.inProgress,
          isMe: true,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _participants = mapped;
        _isConnecting = false;
      });
    }
  }

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
    final participantList = _participants.isNotEmpty
        ? _participants
        : widget.participants.isNotEmpty
            ? widget.participants
            : [
                RoomParticipant(
                  participantId: widget.participantId ?? 'me',
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
                    const Spacer(),
                    if (_isConnecting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
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
                          child: _ParticipantCard(
                            participant: participant,
                            onTap: () =>
                                _showParticipantPreferenceModal(participant),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PreferenceInputScreen(
                                  roomId: widget.roomId,
                                  participantId: widget.participantId,
                                ),
                              ),
                            );
                            if (result is Map<String, dynamic> &&
                                result['formattedPreference'] is String &&
                                mounted) {
                              final id = widget.participantId ?? 'me';
                              setState(() {
                                _preferenceByParticipantId[id] =
                                    result['formattedPreference'] as String;
                                _participants = _participants
                                    .map(
                                      (p) => p.participantId == id
                                          ? RoomParticipant(
                                              participantId: p.participantId,
                                              name: p.name,
                                              status: ParticipantStatus.completed,
                                              isMe: p.isMe,
                                            )
                                          : (p.isMe && id == 'me')
                                              ? RoomParticipant(
                                                  participantId: p.participantId,
                                                  name: p.name,
                                                  status: ParticipantStatus.completed,
                                                  isMe: p.isMe,
                                                )
                                          : p,
                                    )
                                    .toList();
                              });
                            }
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

  void _showParticipantPreferenceModal(RoomParticipant participant) {
    final participantKey = _participantKey(participant);
    final preferenceText = _preferenceByParticipantId[participantKey];
    final hasPreference = preferenceText != null && preferenceText.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${participant.name} 취향',
                      style: AppTextStyles.headingM.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text(
                    hasPreference
                        ? preferenceText
                        : participant.status == ParticipantStatus.completed
                            ? '입력 완료 상태입니다.\n서버 연동 후 상세 취향을 불러올 수 있어요.'
                            : '아직 취향을 입력하지 않았어요.',
                    style: AppTextStyles.bodyM.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryMain,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('닫기', style: AppTextStyles.buttonText),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
  final VoidCallback onTap;

  const _ParticipantCard({
    required this.participant,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = participant.status == ParticipantStatus.completed
        ? AppColors.success
        : AppColors.textSecondary;
    final statusBackground = participant.status == ParticipantStatus.completed
        ? AppColors.success.withValues(alpha: 0.12)
        : AppColors.surface;
    final statusText =
        participant.status == ParticipantStatus.completed ? '입력 완료' : '입력 중';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                    ? AppColors.primaryMain.withValues(alpha: 0.15)
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
        ),
      ),
    );
  }
}
