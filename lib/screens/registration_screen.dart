import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../themes.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // 회원가입 처리 함수
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      if (_passwordController.text != _confirmController.text) {
        setState(() {
          _errorMessage = '비밀번호가 일치하지 않습니다.';
          _isLoading = false;
        });
        return;
      }
      // Firebase Auth 회원가입
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      // Firestore에 사용자 정보 저장 (예시)
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      // 회원가입 성공 시 로그인 화면으로 이동
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '알 수 없는 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('회원가입', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          // ScreenUtil을 활용한 반응형 padding
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: '이메일',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력하세요.';
                    }
                    if (!value.contains('@')) {
                      return '유효한 이메일을 입력하세요.';
                    }
                    return null;
                  },
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '비밀번호',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력하세요.';
                    }
                    if (value.length < 6) {
                      return '비밀번호는 6자 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  decoration: InputDecoration(
                    labelText: '비밀번호 확인',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.r),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호 확인을 입력하세요.';
                    }
                    if (value != _passwordController.text) {
                      return '비밀번호가 일치하지 않습니다.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),
                if (_errorMessage != null)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: 48.h, // 버튼 높이도 반응형
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    onPressed:
                        _isLoading
                            ? null
                            : () {
                              if (_formKey.currentState!.validate()) {
                                _register();
                              }
                            },
                    child: _isLoading
                        ? SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                              '회원가입',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
