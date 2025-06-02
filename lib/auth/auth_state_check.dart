import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import 'login_screen.dart';

/// 로그인 상태 확인 위젯
/// 
/// 앱 시작 시 Firebase Auth를 통해 사용자가 이미 로그인되어 있는지 확인하고
/// 로그인되어 있으면 MainScreen으로, 아니면 LoginScreen으로 리다이렉트합니다.
class AuthStateCheck extends StatelessWidget {
  const AuthStateCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 연결 중일 때 로딩 표시
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // 사용자가 로그인되어 있으면 MainScreen으로 이동
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();
        }
        
        // 로그인되어 있지 않으면 LoginScreen으로 이동
        return const LoginScreen();
      },
    );
  }
}
