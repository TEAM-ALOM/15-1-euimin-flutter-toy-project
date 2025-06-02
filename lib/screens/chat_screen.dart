import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../themes.dart';

/// 채팅방 목록 화면
/// 친구와의 채팅방 목록을 보여주고 클릭하면 상세 채팅방으로 이동
///
/// 사용자 아이디에 해당하는 채팅방들을 Firestore에서 불러온다
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // 로딩 상태 추가

  // 채팅방 삭제 기능
  Future<void> _deleteChat(String chatId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 확인 다이얼로그 표시
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('채팅방 삭제'),
                  content: const Text(
                    '이 채팅방을 삭제하시겠습니까? 모든 대화 내용이 영구적으로 삭제됩니다.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        '취소',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        '삭제',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirmed) return;

      setState(() => _isLoading = true);

      // 메시지와 채팅방 삭제
      final chatRef = _firestore.collection('chats').doc(chatId);
      final batch = _firestore.batch();

      // 메시지 삭제
      final messages = await chatRef.collection('messages').get();
      for (final doc in messages.docs) {
        batch.delete(doc.reference);
      }

      // 채팅방 삭제
      batch.delete(chatRef);
      await batch.commit();

      // 삭제 완료 알림
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방이 삭제되었습니다')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방 삭제 오류: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            _firestore
                .collection('chats')
                .where('participants', arrayContains: user.uid)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          final chatRooms = snapshot.data?.docs ?? [];

          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '아직 채팅방이 없습니다',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '친구 목록에서 친구를 클릭하여 채팅을 시작하세요',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            padding: EdgeInsets.all(16.r),
            itemBuilder: (context, index) {
              final chatData = chatRooms[index].data() as Map<String, dynamic>;
              final chatId = chatRooms[index].id;
              // 다른 참가자 ID 찾기 (비어있을 수 있음)
              final otherUserId = (chatData['participants'] as List).firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );

              // 다른 참가자가 없는 경우 (나갔거나 삭제됨)
              if (otherUserId.isEmpty) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 1,
                  margin: EdgeInsets.only(bottom: 8.h),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[300],
                      child: Icon(Icons.person_off, color: Colors.grey[600]),
                    ),
                    title: const Text(
                      '더 이상 사용할 수 없는 채팅방',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      chatData['lastMessage'] as String? ?? '상대방이 채팅방을 나갔습니다',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: AppColors.error),
                      onPressed: () => _deleteChat(chatId),
                    ),
                  ),
                );
              }

              // 정상적인 채팅방이면 사용자 정보 로드
              return FutureBuilder<DocumentSnapshot>(
                future: _firestore.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  final userName =
                      userSnapshot.data?.get('name') as String? ?? '사용자';
                  final lastMessage = chatData['lastMessage'] as String? ?? '';
                  final lastMessageTime =
                      chatData['lastMessageTime'] as Timestamp? ??
                      Timestamp.now();
                  final unreadCount = chatData['unreadCount'] as int? ?? 0;

                  // 최종 메시지 시간 포맷팅
                  final now = DateTime.now();
                  final messageDate = lastMessageTime.toDate();
                  final diff = now.difference(messageDate);
                  String timeText;

                  if (diff.inDays > 0) {
                    timeText = '${diff.inDays}일 전';
                  } else if (diff.inHours > 0) {
                    timeText = '${diff.inHours}시간 전';
                  } else if (diff.inMinutes > 0) {
                    timeText = '${diff.inMinutes}분 전';
                  } else {
                    timeText = '방금';
                  }

                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 1,
                    margin: EdgeInsets.only(bottom: 8.h),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12.r),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ChatRoomScreen(
                                  chatId: chatId,
                                  otherUserId: otherUserId,
                                  otherUserName: userName,
                                ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryDark,
                              radius: 24.r,
                              child: Text(
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                      Text(
                                        timeText,
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          lastMessage.isEmpty
                                              ? '새로운 채팅방입니다'
                                              : lastMessage,
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 14.sp,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 8.w,
                                            vertical: 2.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(
                                              10.r,
                                            ),
                                          ),
                                          child: Text(
                                            '$unreadCount',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
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
        },
      ),
    );
  }
}

/// 채팅방 상세 화면
/// 특정 친구와의 채팅 메시지를 보여주고 메시지 전송 기능 제공
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    if (_isLoading) return;

    final messageText = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final timestamp = FieldValue.serverTimestamp();

      // 메시지 추가
      await _firestore
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .add({
            'text': messageText,
            'senderId': user.uid,
            'timestamp': timestamp,
          });

      // 채팅방 정보 업데이트
      await _firestore.collection('chats').doc(widget.chatId).set({
        'lastMessage': messageText,
        'lastMessageTime': timestamp,
        'participants': [user.uid, widget.otherUserId],
        'unreadCount': FieldValue.increment(1), // 상대방 읽지 않은 메시지 개수 증가
      }, SetOptions(merge: true));

      // 스크롤 바닥으로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('메시지 전송 오류: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 채팅방 나가기 함수
  Future<void> _leaveChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // 확인 다이얼로그 표시
      final confirmed =
          await showDialog<bool>(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('채팅방 나가기'),
                  content: const Text('정말 이 채팅방을 나가시겠습니까? 모든 대화 내용은 삭제됩니다.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        '취소',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        '나가기',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirmed) return;

      setState(() => _isLoading = true);

      // 참가자 목록에서 현재 사용자 제거
      final chatRef = _firestore.collection('chats').doc(widget.chatId);
      final chatDoc = await chatRef.get();

      if (chatDoc.exists) {
        final participants = List<String>.from(
          chatDoc.data()?['participants'] ?? [],
        );
        participants.remove(user.uid);

        if (participants.isEmpty) {
          // 남은 참가자가 없으면 채팅방과 메시지 모두 삭제
          final batch = _firestore.batch();

          // 메시지 삭제
          final messages = await chatRef.collection('messages').get();
          for (final doc in messages.docs) {
            batch.delete(doc.reference);
          }

          // 채팅방 삭제
          batch.delete(chatRef);
          await batch.commit();
        } else {
          // 참가자 목록 업데이트
          await chatRef.update({
            'participants': participants,
            'lastMessage': '${user.displayName ?? '사용자'}님이 채팅방을 나갔습니다.',
            'lastMessageTime': FieldValue.serverTimestamp(),
          });
        }

        if (!mounted) return;
        Navigator.of(context).pop(); // 채팅방 화면 닫기
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방 나가기 오류: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인이 필요합니다')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.otherUserName,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'leave') {
                _leaveChat();
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem<String>(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.exit_to_app, color: Colors.red),
                        SizedBox(width: 8),
                        Text('채팅방 나가기', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('chats')
                      .doc(widget.chatId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      '첫 메시지를 보내보세요! 😊',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16.sp,
                      ),
                    ),
                  );
                }

                // 메시지 읽음 상태 처리 (실제로는 각 메시지 아이템을 읽을 때마다 업데이트해야 함)
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _firestore.collection('chats').doc(widget.chatId).update({
                    'unreadCount': 0, // 내가 상대방 메시지를 읽었을 때
                  });
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(16.r),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final messageText = messageData['text'] as String? ?? '';
                    final senderId = messageData['senderId'] as String? ?? '';
                    final isMe = senderId == user.uid;
                    final timestamp =
                        messageData['timestamp'] as Timestamp? ??
                        Timestamp.now();
                    final time = timestamp.toDate();
                    final timeFormatted =
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}';

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 8.h,
                          left: isMe ? 64.w : 0,
                          right: isMe ? 0 : 64.w,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 8.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe
                                  ? AppColors.myMessage
                                  : AppColors.otherMessage,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              messageText,
                              style: TextStyle(
                                color:
                                    isMe ? Colors.white : AppColors.textPrimary,
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              timeFormatted,
                              style: TextStyle(
                                color:
                                    isMe
                                        ? Colors.white70
                                        : AppColors.textSecondary,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // 메시지 입력
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Icons.add_circle_outline,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지 입력...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.r),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: AppColors.primary,
                    size: 24.sp,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
