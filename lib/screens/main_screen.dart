import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/friend_service.dart';
import 'chat_screen.dart';
import 'profile.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  bool _isLoading = false;

  // 중복 제거용: 안내 메시지 위젯
  Widget _sectionMessage(String text, {Color? color, double? fontSize}) {
    return Text(
      text,
      style: TextStyle(
        color: color ?? AppColors.textSecondary,
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
      ),
    );
  }

  // 중복 제거용: section 타이틀 위젯
  Widget _sectionTitle(String text, {double? fontSize}) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: fontSize ?? 16.sp,
        color: AppColors.textPrimary,
      ),
    );
  }

  // 중복 제거용: 친구 요청 카드 위젯
  Widget _friendRequestCard({
    required String email,
    required String uid,
    required VoidCallback onAccept,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4.h),
                Text(
                  'UID: $uid',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('수락'),
            ),
          ],
        ),
      ),
    );
  }

  // 중복 제거용: 친구 리스트 카드 위젯
  Widget _friendListCard(Map<String, dynamic> friend) {
    final friendUid = friend['uid'] ?? '';
    final friendEmail = friend['email'] ?? '이메일 없음';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        splashColor: AppColors.primary.withOpacity(0.1),
        onTap: () => _startChatWithFriend(friendUid, friendEmail),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryDark,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: FutureBuilder<String?>(
              future: FriendService.getUserName(friendUid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Text(
                    '로딩 중...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                }
                if (snapshot.hasError) {
                  return const Text(
                    '이름 없음',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  );
                }
                final name = snapshot.data ?? '이름 없음';
                return Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            subtitle: Text(friendEmail),
            trailing: Icon(
              Icons.chat_bubble_outline,
              color: AppColors.primary,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  // 친구와 채팅 시작 함수
  Future<void> _startChatWithFriend(
    String friendUid,
    String friendEmail,
  ) async {
    if (friendUid.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      setState(() => _isLoading = true);

      // 1. 두 사용자 사이의 채팅방이 이미 있는지 확인
      final chatsRef = FirebaseFirestore.instance.collection('chats');
      final chatQuery =
          await chatsRef.where('participants', arrayContains: user.uid).get();

      String? existingChatId;

      // 이미 있는 채팅방 확인
      for (final doc in chatQuery.docs) {
        final participants = List<String>.from(
          doc.data()['participants'] ?? [],
        );
        if (participants.contains(friendUid)) {
          existingChatId = doc.id;
          break;
        }
      }

      // 2. 채팅방 이름 가져오기
      final friendName = await FriendService.getUserName(friendUid) ?? '사용자';

      // 3. 채팅방 없으면 새로 생성
      if (existingChatId == null) {
        final newChatRef = await chatsRef.add({
          'participants': [user.uid, friendUid],
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });
        existingChatId = newChatRef.id;
      }

      // 4. 채팅방으로 이동
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ChatRoomScreen(
                chatId: existingChatId!,
                otherUserId: friendUid,
                otherUserName: friendName,
              ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅방 생성 오류: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // 탭 인덱스 변경 핸들러
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // 로그아웃 함수
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // 현재 사용자 정보 가져오기
    final User? user = _auth.currentUser;

    // 탭별 화면 리스트
    final List<Widget> pages = [
      _buildHomeTab(user),
      const ChatScreen(),
      const Profile(),
    ];

    return WillPopScope(
      onWillPop: () async => false, // 뒤로가기 차단
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          title: Text(
            'Arom Chat',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _signOut,
            ),
          ],
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: Colors.white,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
            unselectedLabelStyle: TextStyle(fontSize: 12.sp),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline),
                activeIcon: Icon(Icons.chat_bubble),
                label: '채팅',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: '프로필',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 홈 탭 UI
  // 친구 추가 입력 컨트롤러 및 안내 메시지 State
  final TextEditingController _friendController = TextEditingController();
  String? _friendAddMsg;

  // 친구 추가 요청 함수 (서비스 사용)
  Future<void> _sendFriendRequest(String input) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _friendAddMsg = null);
    final msg = await FriendService.sendFriendRequest(input, user);
    setState(() => _friendAddMsg = msg);
  }

  // 받은 요청 수락 (서비스 사용)
  Future<void> _acceptFriendRequest(String fromUid, String fromEmail) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FriendService.acceptFriendRequest(fromUid, fromEmail, user);
  }

  Widget _buildHomeTab(User? user) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // 친구 추가 입력창
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _friendController,
                    decoration: InputDecoration(
                      hintText: '친구 이메일 또는 UID 입력',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                ElevatedButton(
                  onPressed: () {
                    final input = _friendController.text.trim();
                    if (input.isNotEmpty) _sendFriendRequest(input);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: const Text('추가'),
                ),
              ],
            ),
          ),
          if (_friendAddMsg != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: _sectionMessage(_friendAddMsg!, color: AppColors.primary),
            ),
          // 받은 친구 요청 목록
          if (user != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _sectionTitle('받은 친구 요청', fontSize: 15.sp),
              ),
            ),
          if (user != null)
            SizedBox(
              height: 80.h,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: FriendService.receivedRequestsStream(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final requests = snapshot.data ?? [];
                  if (requests.isEmpty) {
                    return Center(child: _sectionMessage('받은 친구 요청이 없습니다.'));
                  }
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: requests.length,
                    separatorBuilder: (context, i) => SizedBox(width: 8.w),
                    itemBuilder: (context, i) {
                      final req = requests[i];
                      return _friendRequestCard(
                        email: req['email'] ?? req['uid'],
                        uid: req['uid'],
                        onAccept:
                            () => _acceptFriendRequest(
                              req['uid'],
                              req['email'] ?? '',
                            ),
                      );
                    },
                  );
                },
              ),
            ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            margin: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email != null ? '${user!.email}님, 환영합니다!' : '환영합니다!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  '오늘도 좋은 하루 되세요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/chat');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  child: Text('채팅 시작하기', style: TextStyle(fontSize: 14.sp)),
                ),
              ],
            ),
          ),
          // 친구 목록
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _sectionTitle('친구 목록'),
            ),
          ),
          Expanded(
            child:
                user == null
                    ? Center(
                      child: _sectionMessage('로그인 정보가 없습니다.', fontSize: 15.sp),
                    )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: FriendService.friendListStream(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: _sectionMessage(
                              '친구가 없습니다.',
                              fontSize: 15.sp,
                            ),
                          );
                        }
                        final friends = snapshot.data!;
                        return ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          itemCount: friends.length,
                          separatorBuilder:
                              (context, i) =>
                                  Divider(height: 1, color: AppColors.divider),
                          itemBuilder: (context, i) {
                            final friend = friends[i];
                            return _friendListCard(friend);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
