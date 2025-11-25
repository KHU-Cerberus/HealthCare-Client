import 'package:flutter/material.dart';
import 'package:health_care/presentation/home/home.dart';
import 'package:health_care/presentation/login/register.dart';
import 'package:health_care/feature/user/repository.dart';
import 'package:health_care/presentation/style/colors.dart';
import 'package:health_care/presentation/login/sleeping_pattern.dart';
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
        
        if (response.data.containsKey('sleeping_pattern')){
          if (response.data['sleeping_pattern']) {
            // 수면 패턴이 이미 설정된 경우 홈 페이지로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(baseUrl: baseUrl, jwt: jwt),
              ),
            );
          } else {
            // 수면 패턴이 설정되지 않은 경우 수면 패턴 페이지로 이동
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SleepingPatternPage(baseUrl: baseUrl, jwt: jwt),
              ),
            );
          }
        }
        
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
      // AppBar 삭제 또는 변경 (이미지에는 AppBar가 보이지 않거나 타이틀만 있음)
      appBar: AppBar(
        title: const Text(
          "로그인",
          style: TextStyle(
            color: blackColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: whiteColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ID 입력 필드
            TextField(
              controller: _userIDController,
              decoration: const InputDecoration(
                labelText: '아이디',
                border: OutlineInputBorder(), 
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 16),
            // 비밀번호 입력 필드
            TextField(
              controller: _passwordController,
              obscureText: true, // 비밀번호 가리기
              decoration: const InputDecoration(
                labelText: '비밀번호',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
              ),
            ),
            const SizedBox(height: 24), // 간격 조정
            
            // 1. 로그인 버튼 (배경: 검은색, 텍스트: 흰색)
            ElevatedButton(
              onPressed: () => _login(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: blackColor, // 배경색 검은색
                foregroundColor: whiteColor, // 텍스트 색상 흰색
                minimumSize: const Size(double.infinity, 50), // 버튼 높이 설정 및 폭 최대화
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(4)), // 모서리 둥글기 제거 또는 조정
                ),
                elevation: 0, // 그림자 제거
              ),
              child: const Text(
                '로그인',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            
            // 2. 회원가입 버튼 (배경: 흰색, 테두리: 검은색, 텍스트: 검은색)
            ElevatedButton(
              onPressed: () => _register(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: whiteColor, // 배경색 흰색
                foregroundColor: blackColor, // 텍스트 색상 검은색
                minimumSize: const Size(double.infinity, 50), // 버튼 높이 설정 및 폭 최대화
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  side: BorderSide(color: blackColor, width: 1), // 검은색 테두리 추가
                ),
                elevation: 0, // 그림자 제거
              ),
              child: const Text(
                '회원가입',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}