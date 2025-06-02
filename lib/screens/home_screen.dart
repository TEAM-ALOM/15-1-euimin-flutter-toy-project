import 'package:flutter/material.dart';
import '../themes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Arom Chat App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 1,
      ),
      body: Center(
        child: Padding(
          // ScreenUtil을 활용한 반응형 padding
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Text(
                'Welcome to Arom Chat App!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20.sp, // 화면 크기에 따라 자동 조절
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                '아래 버튼으로 이동해 다양한 기능을 체험해보세요.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(48.h), // 높이도 반응형
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r), // 반응형 radius
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(
                  '로그인',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/registration');
                },
                child: Text(
                  '회원가입',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  minimumSize: Size.fromHeight(48.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/chat');
                },
                child: Text(
                  '채팅방 바로가기',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
