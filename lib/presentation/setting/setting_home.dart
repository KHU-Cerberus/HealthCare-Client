import 'package:flutter/material.dart';
import 'package:health_care/presentation/report/health_report.dart';
import 'package:health_care/presentation/calendar/calendar.dart';
import 'package:health_care/presentation/home/home.dart';

class SettingHomePage extends StatefulWidget {
  final String baseUrl;
  final String jwt;

  const SettingHomePage({super.key, required this.baseUrl, required this.jwt});
  @override
  State<SettingHomePage> createState() => _SettingHomePageState();
}

class _SettingHomePageState extends State<SettingHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Center(
        child: Text('Settings Page - Base URL: $widget.baseUrl'),
      ),
    bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
      case 0:
        // 홈
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              baseUrl: widget.baseUrl,
              jwt: widget.jwt,
            ),
          ),
        );
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
        // 현재 페이지
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
}