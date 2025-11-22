import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:health_care/feature/user/repository.dart';
import 'package:health_care/presentation/login/login.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _userIDController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final String baseUrl;
  
  RegisterPage({super.key, required this.baseUrl});

  // error : red, success : green
  // for testing
  void _showSnackBar(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  void _register(BuildContext context) async {
    final username = _usernameController.text.trim();
    final userID = _userIDController.text.trim();
    final password = _passwordController.text.trim();

    // 모든 필드가 채워져야 로그인 버튼이 활성화되게 변경 예정
    if (userID.isEmpty || password.isEmpty || username.isEmpty) {
      _showSnackBar(context, 'please fill every field', isError: true);
      return;
    }

    try {
      // Dio instance setup
      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));
      
      // for debug
      print('Register 요청 전송: $baseUrl/register');
      print('요청 데이터: username=$username, user_id=$userID, password=$password');
      
      // register API call(POST)
      final response = await UserRepo(dio, baseUrl: baseUrl).register({
        'username': username,
        'user_id': userID,
        'password': password,
      });
      
      // for debug
      print('응답 상태 코드: ${response.response.statusCode}');
      print('응답 데이터: ${response.data}');

      if (response.response.statusCode == 200) {
        // successed to register
        _showSnackBar(context, '등록 성공! 로그인 페이지로 이동합니다.', isError: false);
        
        // Push Replacement를 사용하여 등록 페이지를 스택에서 제거
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(baseUrl: baseUrl),
          ),
        );
      } else {
        // 200이 아닌 다른 상태 코드 처리
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
        // 서버에서 'message'나 'error' 키로 에러 메시지를 보낸다고 가정
        if (e.response!.data is Map && e.response!.data.containsKey('error')) {
          errorMessage = e.response!.data['error'] as String;
        } else if (e.response!.data is Map && e.response!.data.containsKey('message')) {
          errorMessage = e.response!.data['message'] as String;
        } else if (e.response!.data is String) {
          // 응답 본문이 문자열인 경우 (예: "User ID already exists")
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

  // testing UI only
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('회원가입', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '사용자 이름',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _userIDController,
              decoration: const InputDecoration(
                labelText: '아이디 (로그인 ID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _register(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}