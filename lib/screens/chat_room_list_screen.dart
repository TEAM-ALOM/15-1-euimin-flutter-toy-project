import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes.dart';
import 'chat_screen.dart';

class ChatRoomListScreen extends StatefulWidget {
  const ChatRoomListScreen({super.key});

  @override
  State<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends State<ChatRoomListScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      body: Column(
        children: [
          // 채팅방 목록 타이틀
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '채팅 목록',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          // 채팅방 목록 스트림
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('chats')
                      .where('members', arrayContains: user.uid)
                      // orderBy 제거하고 단순 멤버 필터링만 적용
                      .snapshots(),
              builder: (context, snapshot) {
                // 연결 중 또는 로딩 상태 표시
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 오류 처리 추가
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48.sp,
                          color: Colors.red[300],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          '데이터를 불러오는 중 오류가 발생했습니다',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: Text(
                            '새로고침',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 채팅방 없음 상태 표시
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 48.sp,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          '채팅방이 없습니다',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '친구 목록에서 친구를 선택하여\n새로운 채팅을 시작해보세요!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // 스냅샷에서 채팅방 목록을 가져와 로컬에서 정렬(클라이언트 측 정렬)
                final chatRoomDocs = snapshot.data!.docs;
                final chatRoomList =
                    chatRoomDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final updatedAt = data['updatedAt'];
                      return {
                        'id': doc.id,
                        'data': data,
                        'timestamp': updatedAt is Timestamp ? updatedAt : null,
                      };
                    }).toList();

                // 타임스태프가 있는 것은 정렬, 없는 것은 마지막으로 배치
                chatRoomList.sort((a, b) {
                  final aTimestamp = a['timestamp'] as Timestamp?;
                  final bTimestamp = b['timestamp'] as Timestamp?;

                  // 둘 다 null이면 동결
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  // a가 null이고 b가 있으면 b가 앞으로
                  if (aTimestamp == null) return 1;
                  // b가 null이고 a가 있으면 a가 앞으로
                  if (bTimestamp == null) return -1;
                  // 둘 다 있으면 최신 순으로 정렬 (내림차순)
                  return bTimestamp.compareTo(aTimestamp);
                });

                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  itemCount: chatRoomList.length,
                  separatorBuilder:
                      (context, index) =>
                          Divider(color: AppColors.divider, height: 1),
                  itemBuilder: (context, index) {
                    final chatRoom = chatRoomList[index];
                    final chatData = chatRoom['data'] as Map<String, dynamic>;
                    final chatRoomId = chatRoom['id'] as String;

                    // 회원 목록 안전하게 처리
                    List<String> members;
                    try {
                      members = List<String>.from(chatData['members'] ?? []);
                    } catch (e) {
                      members = [];
                    }

                    final lastMessage = chatData['lastMessage'] ?? '';
                    final updatedAt = chatData['updatedAt'] as Timestamp?;

                    // 현재 사용자를 제외한 다른 멤버 (1:1 채팅인 경우)
                    final otherMembers =
                        members.where((id) => id != user.uid).toList();

                    return _buildChatRoomListTile(
                      context: context,
                      chatRoomId: chatRoomId,
                      otherMemberIds: otherMembers,
                      lastMessage: lastMessage,
                      updatedAt: updatedAt,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 채팅방 리스트 타일 위젯
  Widget _buildChatRoomListTile({
    required BuildContext context,
    required String chatRoomId,
    required List<String> otherMemberIds,
    required String lastMessage,
    required Timestamp? updatedAt,
  }) {
    // 1:1 채팅방인 경우 상대방 정보 가져오기
    return FutureBuilder<DocumentSnapshot>(
      future:
          otherMemberIds.isNotEmpty
              ? FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherMemberIds[0])
                  .get()
              : null,
      builder: (context, snapshot) {
        String name = '알 수 없는 대화상대';

        if (snapshot.hasData && snapshot.data != null) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          if (userData != null) {
            name = userData['name'] ?? (userData['email'] ?? '알 수 없는 대화상대');
          }
        }

        // 시간 포맷팅
        String timeText = '';
        if (updatedAt != null) {
          final now = DateTime.now();
          final updateTime = updatedAt.toDate();
          final difference = now.difference(updateTime);

          if (difference.inDays > 0) {
            timeText = '${difference.inDays}일 전';
          } else if (difference.inHours > 0) {
            timeText = '${difference.inHours}시간 전';
          } else if (difference.inMinutes > 0) {
            timeText = '${difference.inMinutes}분 전';
          } else {
            timeText = '방금 전';
          }
        }

        return ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
          leading: CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (timeText.isNotEmpty)
                Text(
                  timeText,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          subtitle: Text(
            lastMessage.isEmpty ? '새로운 채팅방입니다.' : lastMessage,
            style: TextStyle(
              fontSize: 14.sp,
              color: lastMessage.isEmpty ? Colors.grey : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(chatRoomId: chatRoomId),
              ),
            );
          },
        );
      },
    );
  }
}
