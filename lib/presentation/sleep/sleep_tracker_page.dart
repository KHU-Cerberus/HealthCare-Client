import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class SleepTracker {
  static const platform = MethodChannel('com.example.health_care/tracker');

  // 권한 확인 및 요청 (Android 버전별 처리)
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        
        // Android 14+ (API 34+)는 Health Connect 권한 필요
        if (androidInfo.version.sdkInt >= 34) {
          print("Android ${androidInfo.version.sdkInt} detected (Android 14+)");
          print("Health Connect permission required");
          
          // Health Connect 권한은 네이티브에서 처리
          try {
            final bool result = await platform.invokeMethod('requestPermissions');
            return result;
          } catch (e) {
            print("Failed to request Health Connect permission: $e");
            return false;
          }
        } else {
          // Android 13 이하는 Activity Recognition만 필요
          print("Android ${androidInfo.version.sdkInt} detected");
          final status = await Permission.activityRecognition.request();
          return status.isGranted;
        }
      } catch (e) {
        print("Error checking Android version: $e");
        // 에러 발생시 일반 권한 요청
        final status = await Permission.activityRecognition.request();
        return status.isGranted;
      }
    }
    
    return false;
  }

  // 권한 상태 확인
  Future<bool> checkPermission() async {
    if (Platform.isAndroid) {
      try {
        final bool result = await platform.invokeMethod('checkPermissions');
        return result;
      } catch (e) {
        print("Failed to check permissions: $e");
        return false;
      }
    }
    return false;
  }

  // Android 버전 확인
  Future<int> getAndroidVersion() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        return androidInfo.version.sdkInt;
      } catch (e) {
        print("Error getting Android version: $e");
        return 0;
      }
    }
    return 0;
  }

  // Sleep API 구독 시작 (Android 13 이하만 필요)
  Future<bool> subscribeSleepData() async {
    try {
      final bool result = await platform.invokeMethod('subscribeSleep');
      return result;
    } on PlatformException catch (e) {
      print("Failed to subscribe: ${e.message}");
      return false;
    }
  }

  // Sleep API 구독 해제 (Android 13 이하만 필요)
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
      print("Received ${result.length} segments from native");
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
  final int status; // 0: 깨어있음, 1: 수면중

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

  String get statusText => status == 1 ? '수면' : '깨어있음';
  bool get isSleeping => status == 1;
  
  Duration get duration => endTime.difference(startTime);
  
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

// 수면 추적 페이지
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
  int _androidVersion = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionAndLoad();
  }

  Future<void> _checkPermissionAndLoad() async {
    setState(() => _isLoading = true);
    
    _androidVersion = await _sleepTracker.getAndroidVersion();
    _hasPermission = await _sleepTracker.checkPermission();
    
    print("Android version: $_androidVersion");
    print("Has permission: $_hasPermission");
    
    if (_hasPermission) {
      await _loadSleepData();
    } else {
      setState(() => _isLoading = false);
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('권한 필요'),
        content: _androidVersion >= 34
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('수면 추적을 위해 다음 권한이 필요합니다:'),
                  const SizedBox(height: 12),
                  const Text('• Health Connect 수면 데이터 접근'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⚠️ Health Connect 권한 화면이 표시됩니다.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              )
            : const Text('수면 추적을 위해서는 활동 인식 권한이 필요합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 페이지도 닫기
            },
            child: const Text('취소'),
          ),
          if (_androidVersion >= 34)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showHealthConnectGuide();
              },
              child: const Text('설정 방법 보기'),
            ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestPermissionAndRetry();
            },
            child: const Text('권한 허용'),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermissionAndRetry() async {
    setState(() => _isLoading = true);
    
    final granted = await _sleepTracker.requestPermission();
    
    if (granted) {
      setState(() => _hasPermission = true);
      await _loadSleepData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한이 허용되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('권한이 거부되었습니다. 설정에서 권한을 허용해주세요.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        
        // 다시 다이얼로그 표시
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _showPermissionDialog();
        });
      }
    }
  }

  void _showHealthConnectGuide() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Health Connect 설정'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Health Connect 권한 허용 방법:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _buildGuideStep('1', '"권한 허용" 버튼을 누르면 Health Connect 화면이 열립니다'),
              _buildGuideStep('2', '수면 데이터 읽기/쓰기 권한을 모두 허용합니다'),
              _buildGuideStep('3', '권한 허용 후 앱으로 돌아옵니다'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Connect가 설치되어 있지 않다면 Play 스토어에서 설치해야 합니다.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissionAndRetry();
            },
            child: const Text('권한 허용하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSleepData() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    try {
      final data = await _sleepTracker.getSleepData(7);
      print("Loaded ${data.length} sleep segments");
      
      // 각 세그먼트 정보 출력
      for (var segment in data) {
        print("Segment: ${segment.statusText}, Start: ${segment.startTime}, Duration: ${segment.duration}");
      }
      
      final stats = _calculateDailyStats(data);
      print("Calculated ${stats.length} daily stats");
      
      if (mounted) {
        setState(() {
          _sleepData = data;
          _dailyStats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading sleep data: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<DailySleepStats> _calculateDailyStats(List<SleepSegment> segments) {
    final Map<String, List<SleepSegment>> groupedByDate = {};
    
    for (var segment in segments) {
      if (segment.status == 1) {
        final dateKey = '${segment.startTime.year}-${segment.startTime.month}-${segment.startTime.day}';
        groupedByDate.putIfAbsent(dateKey, () => []);
        groupedByDate[dateKey]!.add(segment);
      }
    }
    
    print("Grouped into ${groupedByDate.length} days");
    
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

    // Android 14+는 Health Connect 사용 (백그라운드 구독 불필요)
    if (_androidVersion >= 34) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health Connect에서 자동으로 수면 데이터를 수집합니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      setState(() {
        _isSubscribed = true;
        _isLoading = false;
      });
      return;
    }

    // Android 13 이하는 기존 로직 사용
    try {
      if (_isSubscribed) {
        final success = await _sleepTracker.unsubscribeSleepData();
        if (success) {
          setState(() => _isSubscribed = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('수면 추적이 중지되었습니다')),
            );
          }
        }
      } else {
        final success = await _sleepTracker.subscribeSleepData();
        if (success) {
          setState(() => _isSubscribed = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('수면 추적이 시작되었습니다'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('수면 추적 시작에 실패했습니다'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      print("Error toggling subscription: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('수면 추적'),
        actions: [
          if (_androidVersion >= 34)
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showHealthConnectGuide,
              tooltip: 'Health Connect 설정 방법',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadSleepData,
          ),
        ],
      ),
      body: Column(
        children: [
          // Android 14+ Health Connect 안내
          if (_androidVersion >= 34)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Connect 사용 중',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Android 14+에서는 Health Connect를 통해 수면 데이터를 자동으로 수집합니다',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // 권한이 없을 때 권한 요청 버튼
          if (!_hasPermission)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requestPermissionAndRetry,
                  icon: const Icon(Icons.lock_open),
                  label: const Text('권한 허용하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ),
            ),

          // 추적 시작/중지 버튼 (Android 13 이하만 표시)
          if (_hasPermission && _androidVersion < 34)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _toggleSubscription,
                  icon: Icon(_isSubscribed ? Icons.stop : Icons.play_arrow),
                  label: Text(_isSubscribed ? '추적 중지' : '추적 시작'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _isSubscribed ? Colors.red : Colors.green,
                  ),
                ),
              ),
            ),

          // 디버그 정보 표시
          if (_sleepData.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '총 ${_sleepData.length}개 세그먼트 (수면: ${_sleepData.where((s) => s.status == 1).length}, 깨어있음: ${_sleepData.where((s) => s.status == 0).length})',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),

          // 로딩 또는 데이터 표시
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_hasPermission
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text(
                              '권한이 필요합니다',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '수면 추적을 위해서는\n권한을 허용해주세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _sleepData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bedtime, size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                const Text(
                                  '수면 데이터가 없습니다',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _androidVersion >= 34
                                      ? 'Health Connect에서\n수면 데이터가 수집되면\n여기에 표시됩니다'
                                      : '추적을 시작하고 잠들면\n데이터가 수집됩니다',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          )
                        : _dailyStats.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.info_outline, size: 64, color: Colors.orange),
                                    const SizedBox(height: 16),
                                    Text(
                                      '${_sleepData.length}개의 세그먼트가 있지만',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const Text(
                                      '수면 데이터가 없습니다',
                                      style: TextStyle(fontSize: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 16),
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
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(Icons.bedtime),
                                      ),
                                      title: Text(
                                        '${stat.date.month}월 ${stat.date.day}일',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text('총 수면: ${stat.formattedSleepTime}'),
                                          if (stat.firstSleepTime != null)
                                            Text(
                                              '취침: ${stat.firstSleepTime!.hour}:${stat.firstSleepTime!.minute.toString().padLeft(2, '0')}',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                        ],
                                      ),
                                      trailing: Text(
                                        '${stat.sleepSegmentCount}회',
                                        style: const TextStyle(color: Colors.grey),
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