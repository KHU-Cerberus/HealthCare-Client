import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class SleepTracker {
  static const platform = MethodChannel('com.example.health_care/tracker');

  // 권한 확인 및 요청
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  // Sleep API 구독 시작
  Future<bool> subscribeSleepData() async {
    try {
      final bool result = await platform.invokeMethod('subscribeSleep');
      return result;
    } on PlatformException catch (e) {
      print("Failed to subscribe: ${e.message}");
      return false;
    }
  }

  // Sleep API 구독 해제
  Future<bool> unsubscribeSleepData() async {
    try {
      final bool result = await platform.invokeMethod('unsubscribeSleep');
      return result;
    } on PlatformException catch (e) {
      print("Failed to unsubscribe: ${e.message}");
      return false;
    }
  }

  // 최근 수면 데이터 가져오기
  Future<List<SleepSegment>> getSleepData(int days) async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getSleepData', {'days': days});
      print("Received ${result.length} segments from native"); // 디버그 로그
      return result.map((data) => SleepSegment.fromMap(data)).toList();
    } on PlatformException catch (e) {
      print("Failed to get sleep data: ${e.message}");
      return [];
    }
  }
}

class SleepSegment {
  final DateTime startTime;
  final DateTime endTime;
  final int status; // 0: 깨어있음, 1: 수면중 (Google Sleep API 기준)

  SleepSegment({
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory SleepSegment.fromMap(Map<dynamic, dynamic> map) {
    return SleepSegment(
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime']),
      status: map['status'],
    );
  }

  // Google Sleep API: status 1 = 수면 중, status 0 = 깨어있음
  String get statusText => status == 1 ? '수면' : '깨어있음';
  bool get isSleeping => status == 1;
  
  Duration get duration => endTime.difference(startTime);
  
  // 하루별 총 수면 시간 계산을 위한 도우미
  bool isSameDayAs(DateTime date) {
    return startTime.year == date.year &&
           startTime.month == date.month &&
           startTime.day == date.day;
  }
}

// 하루 수면 통계
class DailySleepStats {
  final DateTime date;
  final Duration totalSleepTime;
  final int sleepSegmentCount;
  final DateTime? firstSleepTime;
  final DateTime? lastWakeTime;

  DailySleepStats({
    required this.date,
    required this.totalSleepTime,
    required this.sleepSegmentCount,
    this.firstSleepTime,
    this.lastWakeTime,
  });

  String get formattedSleepTime {
    final hours = totalSleepTime.inHours;
    final minutes = totalSleepTime.inMinutes % 60;
    return '$hours시간 $minutes분';
  }
}

// 사용 예시 - 개선된 UI
class SleepTrackerPage extends StatefulWidget {
  final String baseUrl;
  final String jwt;
  const SleepTrackerPage({super.key, required this.baseUrl, required this.jwt});
  
  @override
  _SleepTrackerPageState createState() => _SleepTrackerPageState();
}

class _SleepTrackerPageState extends State<SleepTrackerPage> {
  final SleepTracker _sleepTracker = SleepTracker();
  List<SleepSegment> _sleepData = [];
  List<DailySleepStats> _dailyStats = [];
  bool _isSubscribed = false;
  bool _isLoading = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    _hasPermission = await _sleepTracker.requestPermission();
    if (_hasPermission) {
      await _loadSleepData();
    } else {
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('권한 필요'),
        content: Text('수면 추적을 위해서는 활동 인식 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text('설정으로 이동'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSleepData() async {
    setState(() => _isLoading = true);
    
    final data = await _sleepTracker.getSleepData(7);
    print("Loaded ${data.length} sleep segments"); // 디버그 로그
    
    // 각 세그먼트 정보 출력
    for (var segment in data) {
      print("Segment: ${segment.statusText}, Start: ${segment.startTime}, Duration: ${segment.duration}");
    }
    
    final stats = _calculateDailyStats(data);
    print("Calculated ${stats.length} daily stats"); // 디버그 로그
    
    setState(() {
      _sleepData = data;
      _dailyStats = stats;
      _isLoading = false;
    });
  }

  List<DailySleepStats> _calculateDailyStats(List<SleepSegment> segments) {
    final Map<String, List<SleepSegment>> groupedByDate = {};
    
    for (var segment in segments) {
      // Google Sleep API: status 1 = 수면 중
      if (segment.status == 1) {
        final dateKey = '${segment.startTime.year}-${segment.startTime.month}-${segment.startTime.day}';
        groupedByDate.putIfAbsent(dateKey, () => []);
        groupedByDate[dateKey]!.add(segment);
      }
    }
    
    print("Grouped into ${groupedByDate.length} days"); // 디버그 로그
    
    return groupedByDate.entries.map((entry) {
      final segments = entry.value;
      final totalDuration = segments.fold<Duration>(
        Duration.zero,
        (sum, segment) => sum + segment.duration,
      );
      
      return DailySleepStats(
        date: segments.first.startTime,
        totalSleepTime: totalDuration,
        sleepSegmentCount: segments.length,
        firstSleepTime: segments.first.startTime,
        lastWakeTime: segments.last.endTime,
      );
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> _toggleSubscription() async {
    if (!_hasPermission) {
      _showPermissionDialog();
      return;
    }

    setState(() => _isLoading = true);

    if (_isSubscribed) {
      final success = await _sleepTracker.unsubscribeSleepData();
      if (success) {
        setState(() => _isSubscribed = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수면 추적이 중지되었습니다')),
        );
      }
    } else {
      final success = await _sleepTracker.subscribeSleepData();
      if (success) {
        setState(() => _isSubscribed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('수면 추적이 시작되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('수면 추적'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSleepData,
          ),
        ],
      ),
      body: Column(
        children: [
          // 추적 시작/중지 버튼
          Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _toggleSubscription,
                icon: Icon(_isSubscribed ? Icons.stop : Icons.play_arrow),
                label: Text(_isSubscribed ? '추적 중지' : '추적 시작'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _isSubscribed ? Colors.red : Colors.green,
                ),
              ),
            ),
          ),

          // 디버그 정보 표시
          if (_sleepData.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '총 ${_sleepData.length}개 세그먼트 (수면: ${_sleepData.where((s) => s.status == 1).length}, 깨어있음: ${_sleepData.where((s) => s.status == 0).length})',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          // 로딩 또는 데이터 표시
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _sleepData.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bedtime, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '수면 데이터가 없습니다',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '추적을 시작하고 잠들면\n데이터가 수집됩니다',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _dailyStats.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline, size: 64, color: Colors.orange),
                                SizedBox(height: 16),
                                Text(
                                  '${_sleepData.length}개의 세그먼트가 있지만',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '수면 데이터가 없습니다',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                SizedBox(height: 16),
                                // 모든 세그먼트 표시 (디버깅용)
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: _sleepData.length,
                                    itemBuilder: (context, index) {
                                      final segment = _sleepData[index];
                                      return ListTile(
                                        leading: Icon(
                                          segment.isSleeping ? Icons.bedtime : Icons.wb_sunny,
                                          color: segment.isSleeping ? Colors.blue : Colors.orange,
                                        ),
                                        title: Text(segment.statusText),
                                        subtitle: Text(
                                          '${segment.startTime.month}/${segment.startTime.day} '
                                          '${segment.startTime.hour}:${segment.startTime.minute.toString().padLeft(2, '0')} - '
                                          '${segment.endTime.hour}:${segment.endTime.minute.toString().padLeft(2, '0')}\n'
                                          '기간: ${segment.duration.inHours}시간 ${segment.duration.inMinutes % 60}분',
                                        ),
                                        trailing: Text('Status: ${segment.status}'),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _dailyStats.length,
                            itemBuilder: (context, index) {
                              final stat = _dailyStats[index];
                              return Card(
                                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.bedtime),
                                  ),
                                  title: Text(
                                    '${stat.date.month}월 ${stat.date.day}일',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 4),
                                      Text('총 수면: ${stat.formattedSleepTime}'),
                                      if (stat.firstSleepTime != null)
                                        Text(
                                          '취침: ${stat.firstSleepTime!.hour}:${stat.firstSleepTime!.minute.toString().padLeft(2, '0')}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                    ],
                                  ),
                                  trailing: Text(
                                    '${stat.sleepSegmentCount}회',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}