import 'package:flutter/material.dart';

/// 모던 채팅앱에 사용할 주요 색상 팔레트
class AppColors {
  // Primary & Accent
  static const Color primary = Color(0xFF5568FE); // 메인 블루
  static const Color primaryDark = Color(0xFF2236B6); // 진한 블루
  static const Color accent = Color(0xFF00D1C1); // 포인트 민트

  // Backgrounds
  static const Color background = Color(0xFFF7F8FA); // 기본 배경
  static const Color surface = Color(0xFFFFFFFF); // 카드/채팅 버블 등
  static const Color surfaceDark = Color(0xFF23272F); // 다크 서피스

  // Text
  static const Color textPrimary = Color(0xFF23272F); // 진한 텍스트
  static const Color textSecondary = Color(0xFF8A8F98); // 서브 텍스트
  static const Color textOnPrimary = Color(0xFFFFFFFF); // 프라이머리 위 텍스트

  // Chat bubbles
  static const Color myMessage = Color(0xFF5568FE); // 내 채팅 버블
  static const Color otherMessage = Color(0xFFE6E9F4); // 상대 채팅 버블

  // State
  static const Color error = Color(0xFFF05454); // 에러
  static const Color success = Color(0xFF36D399); // 성공/완료
  static const Color warning = Color(0xFFFFC93C); // 경고

  // Divider, Border
  static const Color border = Color(0xFFE6E9F4);
  static const Color divider = Color(0xFFE6E9F4);

  // 아이콘 등 포인트
  static const Color icon = Color(0xFF5568FE);
}

/// MaterialColor로 프라이머리 컬러 정의 (ThemeData에 바로 사용 가능)
const MaterialColor primarySwatch = MaterialColor(0xFF5568FE, <int, Color>{
  50: Color(0xFFE6E9F4),
  100: Color(0xFFC7D0F9),
  200: Color(0xFFA3B1F7),
  300: Color(0xFF7D91F5),
  400: Color(0xFF6179F3),
  500: Color(0xFF5568FE), // 메인
  600: Color(0xFF4C5EE6),
  700: Color(0xFF4254CC),
  800: Color(0xFF374AB3),
  900: Color(0xFF2236B6),
});
