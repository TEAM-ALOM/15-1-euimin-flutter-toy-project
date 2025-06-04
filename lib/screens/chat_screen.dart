import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatScreen extends StatefulWidget {
  final String? chatRoomId;
  final String? friendUid; // 1:1 채팅방 생성용

  const ChatScreen({this.chatRoomId, this.friendUid, super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _chatRoomId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  // 채팅방 초기화: 기존 채팅방ID 사용 또는 새로 생성
  Future<void> _initChatRoom() async {
    if (widget.chatRoomId != null) {
      _chatRoomId = widget.chatRoomId;
      return;
    }

    // friendUid가 있고 chatRoomId가 없는 경우, 새 채팅방 생성 또는 기존 채팅방 찾기
    if (widget.friendUid != null) {
      setState(() => _isLoading = true);
      _chatRoomId = await _getOrCreateChatRoom(widget.friendUid!);
      setState(() => _isLoading = false);
    }
  }

  // 1:1 채팅방 찾기 또는 생성
  Future<String> _getOrCreateChatRoom(String friendUid) async {
    final user = _auth.currentUser;
    if (user == null) return '';
    final myUid = user.uid;
    
    final chats = FirebaseFirestore.instance.collection('chats');
    final query = await chats
      .where('members', arrayContains: myUid)
      .get();

    for (var doc in query.docs) {
      final members = List<String>.from(doc['members']);
      if (members.length == 2 && members.contains(friendUid)) {
        return doc.id;
      }
    }
    
    // 없으면 새로 생성
    final newChat = await chats.add({
      'members': [myUid, friendUid],
      'createdAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    return newChat.id;
  }

  // 메시지 전송 함수
  Future<void> _sendMessage() async {
    if (_chatRoomId == null || _chatRoomId!.isEmpty) return;
    
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    final user = _auth.currentUser;
    if (user == null) return;
    
    // 메시지 저장
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .collection('messages')
        .add({
          'text': text,
          'senderId': user.uid,
          'senderEmail': user.email,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
    // 채팅방 lastMessage 업데이트
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(_chatRoomId)
        .update({
          'lastMessage': text,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('채팅방 준비중...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_chatRoomId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('오류')),
        body: Center(child: Text('채팅방을 찾을 수 없습니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('채팅', style: TextStyle(fontSize: 18.sp)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 실시간 메시지 스트림
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(_chatRoomId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text('메시지가 없습니다', 
                      style: TextStyle(color: Colors.grey, fontSize: 16.sp)),
                  );
                }
                
                final docs = snapshot.data!.docs;
                final currentUser = _auth.currentUser;
                
                return ListView.builder(
                  reverse: true,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = currentUser != null && 
                              data['senderId'] == currentUser.uid;
                    
                    // 보낸 시간 포맷팅
                    String timeText = '';
                    if (data['createdAt'] != null) {
                      final timestamp = data['createdAt'] as Timestamp;
                      final dateTime = timestamp.toDate();
                      final hour = dateTime.hour.toString().padLeft(2, '0');
                      final minute = dateTime.minute.toString().padLeft(2, '0');
                      timeText = '$hour:$minute';
                    }
                    
                    return Padding(
                      padding: EdgeInsets.only(
                        top: 6.h,
                        bottom: 6.h,
                        left: isMe ? 60.w : 0,
                        right: isMe ? 0 : 60.w,
                      ),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                vertical: 10.h,
                                horizontal: 14.w,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.blue[100] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!isMe)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.h),
                                      child: Text(
                                        data['senderEmail'] ?? '알 수 없음',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ),
                                  Text(
                                    data['text'] ?? '',
                                    style: TextStyle(fontSize: 15.sp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          // 보낸 시간 표시
                          if (timeText.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                timeText,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // 메시지 입력창
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(fontSize: 14.sp),
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 10.h,
                        horizontal: 12.w,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  icon: Icon(Icons.send, size: 24.sp),
                  onPressed: _sendMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
