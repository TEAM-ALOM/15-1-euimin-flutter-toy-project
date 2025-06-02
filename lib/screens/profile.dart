import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../themes.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // 프로필 헤더
            Container(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48.r,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, size: 60.sp, color: Colors.white),
                  ),
                  SizedBox(height: 16.h),
                  // 이메일
                  _buildProfileRow('이메일', user?.email ?? '이메일 없음'),
                  SizedBox(height: 8.h),
                  // 이름 (Firestore에서 비동기로 가져오기)
                  FutureBuilder<String?>(
                    future: _fetchUserName(user?.uid),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildProfileRow('이름', '로딩 중...');
                      }
                      if (snapshot.hasError) {
                        return _buildProfileRow('이름', '오류');
                      }
                      return _buildProfileRow('이름', snapshot.data ?? '이름 없음');
                    },
                  ),
                  SizedBox(height: 8.h),
                  // UID
                  _buildProfileRow('UID', user?.uid ?? '정보 없음'),
                  SizedBox(height: 8.h),
                  Text(
                    '가입일: ${user?.metadata.creationTime?.toString().split(' ')[0] ?? '정보 없음'}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
            SizedBox(height: 24.h),
            // 설정 옵션 리스트
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
              ),
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.notifications_outlined,
                    title: '알림 설정',
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 56.w),
                  _buildSettingTile(
                    icon: Icons.lock_outline,
                    title: '개인정보 및 보안',
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 56.w),
                  _buildSettingTile(
                    icon: Icons.help_outline,
                    title: '도움말 및 피드백',
                    onTap: () {},
                  ),
                  Divider(height: 1, indent: 56.w),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: '앱 정보',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            SizedBox(height: 36.h),
            // 로그아웃 버튼
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  // 메인 진입점(로그인/온보딩)으로 이동
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
                icon: Icon(Icons.logout, color: Colors.red, size: 20.sp),
                label: Text(
                  '로그아웃',
                  style: TextStyle(fontSize: 16.sp, color: Colors.red),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16.sp,
        color: AppColors.textSecondary,
      ),
    );
  }

  // 이메일, 이름, UID를 한 줄에 보여주는 위젯
  Widget _buildProfileRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15.sp,
            color: AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15.sp,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // Firestore에서 name을 가져오는 함수
  Future<String?> _fetchUserName(String? uid) async {
    if (uid == null) return null;
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return doc.data()?['name'] as String?;
    } catch (e) {
      return null;
    }
  }
}
