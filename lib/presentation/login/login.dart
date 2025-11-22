import 'package:flutter/material.dart';
import 'package:health_care/presentation/pages/home/home.dart';
import 'register.dart';
import 'package:health_care/feature/user/repository.dart';
import 'package:dio/dio.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl;

  LoginPage({super.key, required this.baseUrl});

  void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _login(BuildContext context) async {
    final userID = _userIDController.text.trim();
    final password = _passwordController.text.trim();
    
    if (userID.isEmpty || password.isEmpty) {
      _showSnackBar(context, 'ID와 비밀번호를 입력해주세요.', isError: true);
      return;
    }

    try {
      // Dio 인스턴스를 baseUrl로 초기화하여 생성
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      print('Login 요청 전송: $baseUrl/login');
      print('요청 데이터: user_id=$userID, password=***');
      
      final response = await UserRepo(dio, baseUrl: baseUrl).login({
        'user_id': userID,
        'password': password,
      });
      
      print('응답 상태 코드: ${response.response.statusCode}');
      print('응답 데이터: ${response.data}');
      print('응답 데이터 타입: ${response.data.runtimeType}');

      if (response.response.statusCode == 200) {
        // 서버 응답이 JSON 객체인 경우 {"token": "..."} 또는 JWT 문자열 자체인 경우 처리
        String jwt;
        if (response.data is Map && response.data.containsKey('token')) {
          jwt = response.data["token"] as String;
        } else if (response.data is String) {
          // JWT 문자열이 직접 반환되는 경우
          jwt = response.data as String;
        } else {
          _showSnackBar(context, '로그인 실패: 토큰을 받을 수 없습니다.', isError: true);
          return;
        }
        
        _showSnackBar(context, '로그인 성공!', isError: false);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(token: jwt),
          ),
        );
      } else {
        _showSnackBar(context, '로그인 실패: 알 수 없는 오류가 발생했습니다.', isError: true);
      }
    } on DioException catch (e) {
      // Dio 에러 처리 (네트워크 오류, 4xx, 5xx 등의 HTTP 에러)
      print('DioException 발생: ${e.type}');
      print('에러 메시지: ${e.message}');
      print('응답 상태: ${e.response?.statusCode}');
      print('응답 데이터: ${e.response?.data}');
      
      String errorMessage = '네트워크 오류가 발생했습니다.';
      
      // 서버에서 구체적인 에러 응답을 JSON 형태로 보낼 경우 처리
      if (e.response != null && e.response!.data != null) {
        if (e.response!.data is Map && e.response!.data.containsKey('error')) {
          errorMessage = e.response!.data['error'] as String;
        } else if (e.response!.data is Map && e.response!.data.containsKey('message')) {
          errorMessage = e.response!.data['message'] as String;
        } else if (e.response!.data is String) {
          errorMessage = e.response!.data as String;
        }
      } else if (e.type == DioExceptionType.connectionTimeout || 
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = '서버 연결 시간이 초과되었습니다. 서버가 실행 중인지 확인해주세요.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = '서버에 연결할 수 없습니다. baseUrl을 확인해주세요: $baseUrl';
      } else {
        errorMessage = '서버에 연결할 수 없습니다: ${e.message}';
      }

      _showSnackBar(context, errorMessage, isError: true);
    } catch (e, stackTrace) {
      // 기타 예상치 못한 에러 처리
      print('예상치 못한 오류: $e');
      print('스택 트레이스: $stackTrace');
      _showSnackBar(context, '예상치 못한 오류: $e', isError: true);
    }
  }

  void _register(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegisterPage(baseUrl: baseUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _userIDController,
              decoration: const InputDecoration(labelText: 'ID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _login(context),
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () => _register(context),
              child: const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}