import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:health_care/feature/user/user_client.dart';
import 'package:health_care/presentation/style/colors.dart';
import 'package:health_care/presentation/sleep/sleep_log.dart';
import 'package:health_care/presentation/report/health_report.dart';
import 'package:health_care/presentation/setting/setting_home.dart';
import 'package:health_care/presentation/calendar/calendar.dart';

class HomePage extends StatefulWidget {
  final String jwt;
  final String baseUrl;

  const HomePage({super.key, required this.baseUrl, required this.jwt});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? homeData;
  String? advice;
  bool isLoadingHome = true;
  bool isLoadingAdvice = true;
  String selectedAdviceType = 'healing';
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
    _loadAdvice();
  }

  Future<void> _loadHomeData() async {
    try {
      final dio = Dio();
      final client = UserRepo(dio, baseUrl: widget.baseUrl);
      final response = await client.getUserHome('Bearer ${widget.jwt}');
      
      setState(() {
        homeData = response.data['data'];
        isLoadingHome = false;
        hasError = false;
      });
    } catch (e) {
      setState(() {
        isLoadingHome = false;
        hasError = true;
        // 404 에러 등으로 데이터를 불러오지 못하면 기본 화면만 표시
      });
    }
  }

  Future<void> _loadAdvice() async {
    setState(() {
      isLoadingAdvice = true;
    });
    
    try {
      final dio = Dio(BaseOptions(
        baseUrl: widget.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final client = UserRepo(dio, baseUrl: widget.baseUrl);
      final response = await client.getUserAdvice('Bearer ${widget.jwt}');
      
      setState(() {
        advice = response.data['data']['advice'];
        isLoadingAdvice = false;
      });
    } catch (e) {
      setState(() {
        advice = null;
        isLoadingAdvice = false;
      });
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'danger':
        return '위험';
      case 'caution':
        return '주의';
      case 'good':
        return '양호';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'danger':
        return const Color(0xFFFF3B30);
      case 'caution':
        return const Color(0xFFFFCC00);
      case 'good':
        return const Color(0xFF34C759);
      default:
        return grayColor;
    }
  }

  String _formatSleepTime(String time) {
    if (time.length == 4) {
      return '${time.substring(0, 1)}시간 ${time.substring(2, 4)}분';
    }
    return time;
  }

  void _checkSleepLog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SleepLogPage(baseUrl: widget.baseUrl, jwt: widget.jwt),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cerberus',
              style: TextStyle(
                color: Colors.black,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '바쁜 너를 위한 작은 건강 지키미',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '안녕하세요,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '${homeData?['nickname'] ?? 'Cerberus'}님',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Today',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bedtime_outlined, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '수면',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      homeData?['sleepStatus'] ?? 'good'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(
                                      homeData?['sleepStatus'] ?? 'good'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _formatSleepTime(
                                homeData?['sleepTime'] ?? '0437'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _checkSleepLog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('수면 기록 확인'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.restaurant_outlined,
                                  size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                '식사',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      homeData?['mealStatus'] ?? 'danger'),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(
                                      homeData?['mealStatus'] ?? 'danger'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${homeData?['mealTime'] ?? 0}끼',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: 식사 업로드 페이지로 이동
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade300,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('식사 업로드하기'),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_ios, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAdviceTypeButton('힐링형', 'healing'),
                  const SizedBox(width: 12),
                  _buildAdviceTypeButton('유머형', 'humor'),
                  const SizedBox(width: 12),
                  _buildAdviceTypeButton('코치형', 'coach'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isLoadingAdvice
                      ? '생각중...'
                      : advice ??
                          '${homeData?['nickname'] ?? 'Cerberus'}님, 오늘은 일찍 주무시는 거 어떨까요?😊',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/charactor.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '캐릭터 이미지\n삽입 예정',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
      case 0:
        // 홈 - 현재 페이지이므로 아무것도 안 함
        break;
      case 1:
        // 통계 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HealthReportPage(
              baseUrl: widget.baseUrl,
              jwt: widget.jwt,
            ),
          ),
        );
        break;
      case 2:
        // 캘린더 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CalendarPage(
              baseUrl: widget.baseUrl,
              jwt: widget.jwt,
            ),
          ),
        );
        break;
      case 3:
        // 설정 페이지로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SettingHomePage(
              baseUrl: widget.baseUrl,
              jwt: widget.jwt,
            ),
          ),
        );
        break;
    }
  
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '',
            
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '',
          ),
        ],
      ),
    );
  }

  Widget _buildAdviceTypeButton(String label, String type) {
    final isSelected = selectedAdviceType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedAdviceType = type;
        });
        _loadAdvice();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}