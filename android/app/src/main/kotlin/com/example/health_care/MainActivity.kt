package com.example.health_care

import android.Manifest
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.SleepSessionRecord
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import com.google.android.gms.common.ConnectionResult
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.SleepSegmentRequest
import com.google.android.gms.location.SleepClassifyEvent
import com.google.android.gms.location.SleepSegmentEvent
import com.google.gson.Gson
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.time.Instant
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.health_care/tracker"
    private val ACTIVITY_RECOGNITION_REQUEST_CODE = 100
    private val HEALTH_CONNECT_REQUEST_CODE = 101
    
    private lateinit var methodChannel: MethodChannel
    private var pendingResult: MethodChannel.Result? = null
    private var healthConnectClient: HealthConnectClient? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
       
        // Health Connect 클라이언트 초기화
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) { // API 34+
            try {
                // SDK 상태 확인
                val providerPackageName = HealthConnectClient.getSdkStatus(this, "com.google.android.apps.healthdata")
                if (providerPackageName == HealthConnectClient.SDK_AVAILABLE) {
                    healthConnectClient = HealthConnectClient.getOrCreate(this)
                    Log.d("SleepTracker", "Health Connect client initialized")
                } else {
                    Log.e("SleepTracker", "Health Connect SDK not available: $providerPackageName")
                }
            } catch (e: Exception) {
                Log.e("SleepTracker", "Failed to initialize Health Connect: ${e.message}")
            }
        }
       
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "subscribeSleep" -> {
                    subscribeSleepUpdates(result)
                }
                "unsubscribeSleep" -> {
                    unsubscribeSleepUpdates(result)
                }
                "getSleepData" -> {
                    val days = call.argument<Int>("days") ?: 7
                    getSleepData(days, result)
                }
                "checkPermissions" -> {
                    result.success(hasAllPermissions())
                }
                "requestPermissions" -> {
                    requestAllPermissions(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasActivityRecognitionPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACTIVITY_RECOGNITION
            ) == PackageManager.PERMISSION_GRANTED
        } else {
            true
        }
    }

    private fun hasAllPermissions(): Boolean {
        // Android 14+ (API 34+)는 Health Connect 권한만 체크
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Health Connect 권한은 런타임에 직접 체크 불가능
            // Health Connect SDK를 통해서만 확인 가능
            return healthConnectClient != null
        }
        
        // Android 13 이하는 Activity Recognition 권한만
        return hasActivityRecognitionPermission()
    }

    private fun requestAllPermissions(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+: Health Connect 권한 요청
            requestHealthConnectPermission(result)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10-13: Activity Recognition 권한 요청
            if (hasActivityRecognitionPermission()) {
                result.success(true)
            } else {
                pendingResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.ACTIVITY_RECOGNITION),
                    ACTIVITY_RECOGNITION_REQUEST_CODE
                )
            }
        } else {
            result.success(true)
        }
    }

    private fun requestHealthConnectPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            if (healthConnectClient == null) {
                result.error("HEALTH_CONNECT_UNAVAILABLE", 
                    "Health Connect is not available on this device", null)
                return
            }

            val permissions = setOf(
                HealthPermission.getReadPermission(SleepSessionRecord::class),
                HealthPermission.getWritePermission(SleepSessionRecord::class)
            )

            CoroutineScope(Dispatchers.Main).launch {
                try {
                    // Health Connect 권한 요청 Intent 생성
                    val intent = HealthConnectClient.getHealthConnectManageDataIntent(this@MainActivity)
                    pendingResult = result
                    startActivityForResult(intent, HEALTH_CONNECT_REQUEST_CODE)
                } catch (e: Exception) {
                    Log.e("SleepTracker", "Failed to request Health Connect permission: ${e.message}")
                    result.error("PERMISSION_REQUEST_FAILED", e.message, null)
                }
            }
        } else {
            result.success(false)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == ACTIVITY_RECOGNITION_REQUEST_CODE) {
            val granted = grantResults.isNotEmpty() && 
                         grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingResult?.success(granted)
            pendingResult = null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == HEALTH_CONNECT_REQUEST_CODE) {
            // Health Connect 권한 결과 - 항상 성공으로 처리 (실제 권한은 사용 시 확인)
            pendingResult?.success(true)
            pendingResult = null
        }
    }

    private fun checkGooglePlayServices(): Boolean {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = googleApiAvailability.isGooglePlayServicesAvailable(this)
        return resultCode == ConnectionResult.SUCCESS
    }

    private fun subscribeSleepUpdates(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+: Health Connect 사용 (백그라운드 구독 불필요)
            Log.d("SleepTracker", "Android 14+: Using Health Connect (no subscription needed)")
            result.success(true)
            return
        }

        // Android 13 이하: 기존 Sleep API 사용
        if (!checkGooglePlayServices()) {
            result.error("PLAY_SERVICES_UNAVAILABLE", 
                "Google Play Services is not available", null)
            return
        }

        if (!hasActivityRecognitionPermission()) {
            result.error("PERMISSION_DENIED", 
                "Activity Recognition permission is required", null)
            return
        }

        try {
            val intent = Intent(this, SleepReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )

            val task = ActivityRecognition.getClient(this)
                .requestSleepSegmentUpdates(
                    pendingIntent,
                    SleepSegmentRequest.getDefaultSleepSegmentRequest()
                )

            task.addOnSuccessListener {
                Log.d("SleepTracker", "Successfully subscribed to sleep updates (Android 13-)")
                result.success(true)
            }

            task.addOnFailureListener { exception ->
                Log.e("SleepTracker", "Failed to subscribe: ${exception.message}")
                result.error("SUBSCRIBE_FAILED", exception.message, null)
            }
        } catch (e: Exception) {
            Log.e("SleepTracker", "Exception during subscribe: ${e.message}")
            result.error("SUBSCRIBE_ERROR", e.message, null)
        }
    }

    private fun unsubscribeSleepUpdates(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+: Health Connect (구독 해제 불필요)
            result.success(true)
            return
        }

        try {
            val intent = Intent(this, SleepReceiver::class.java)
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )

            val task = ActivityRecognition.getClient(this)
                .removeSleepSegmentUpdates(pendingIntent)

            task.addOnSuccessListener {
                Log.d("SleepTracker", "Successfully unsubscribed from sleep updates")
                result.success(true)
            }

            task.addOnFailureListener { exception ->
                Log.e("SleepTracker", "Failed to unsubscribe: ${exception.message}")
                result.error("UNSUBSCRIBE_FAILED", exception.message, null)
            }
        } catch (e: Exception) {
            Log.e("SleepTracker", "Exception during unsubscribe: ${e.message}")
            result.error("UNSUBSCRIBE_ERROR", e.message, null)
        }
    }

    private fun getSleepData(days: Int, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // Android 14+: Health Connect에서 데이터 가져오기
            getSleepDataFromHealthConnect(days, result)
        } else {
            // Android 13 이하: SharedPreferences에서 가져오기
            getSleepDataFromSharedPreferences(days, result)
        }
    }

    private fun getSleepDataFromHealthConnect(days: Int, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            result.error("API_NOT_SUPPORTED", "Health Connect requires Android 14+", null)
            return
        }

        if (healthConnectClient == null) {
            result.error("HEALTH_CONNECT_UNAVAILABLE", 
                "Health Connect is not available", null)
            return
        }

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val endTime = Instant.now()
                val startTime = endTime.minusSeconds(TimeUnit.DAYS.toSeconds(days.toLong()))

                val request = ReadRecordsRequest(
                    recordType = SleepSessionRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(startTime, endTime)
                )

                val response = healthConnectClient!!.readRecords(request)
                val sleepSessions = response.records

                Log.d("SleepTracker", "Retrieved ${sleepSessions.size} sleep sessions from Health Connect")

                val segmentMaps = sleepSessions.map { session ->
                    val startMillis = session.startTime.toEpochMilli()
                    val endMillis = session.endTime.toEpochMilli()
                    
                    mapOf(
                        "startTime" to startMillis,
                        "endTime" to endMillis,
                        "status" to 1 // 수면 상태 (Health Connect는 모두 수면)
                    )
                }

                withContext(Dispatchers.Main) {
                    result.success(segmentMaps)
                }
            } catch (e: Exception) {
                Log.e("SleepTracker", "Failed to get Health Connect data: ${e.message}")
                e.printStackTrace()
                
                withContext(Dispatchers.Main) {
                    result.error("GET_DATA_FAILED", e.message, null)
                }
            }
        }
    }

    private fun getSleepDataFromSharedPreferences(days: Int, result: MethodChannel.Result) {
        try {
            val prefs = getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
            val sleepDataJson = prefs.getString("segments", "[]") ?: "[]"
           
            val gson = Gson()
            val segmentsArray = gson.fromJson(sleepDataJson, Array<SleepSegmentData>::class.java)
            val allSegments = segmentsArray?.toList() ?: emptyList()
           
            val cutoffTime = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(days.toLong())
            val filteredSegments = allSegments.filter { it.startTime >= cutoffTime }
           
            val segmentMaps = filteredSegments.map {
                mapOf(
                    "startTime" to it.startTime,
                    "endTime" to it.endTime,
                    "status" to it.status
                )
            }
           
            Log.d("SleepTracker", "Retrieved ${segmentMaps.size} sleep segments from SharedPreferences")
            result.success(segmentMaps)
        } catch (e: Exception) {
            Log.e("SleepTracker", "Failed to get sleep data: ${e.message}")
            e.printStackTrace()
            result.error("GET_DATA_FAILED", e.message, null)
        }
    }
}

// 수면 세그먼트 데이터 클래스
data class SleepSegmentData(
    val startTime: Long,
    val endTime: Long,
    val status: Int
)

// BroadcastReceiver - Sleep API 이벤트 수신 (Android 13 이하만 사용)
class SleepReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) {
            Log.e("SleepTracker", "Context or Intent is null")
            return
        }

        try {
            if (SleepSegmentEvent.hasEvents(intent)) {
                val sleepSegmentEvents = SleepSegmentEvent.extractEvents(intent)
                Log.d("SleepTracker", "Received ${sleepSegmentEvents.size} sleep segment events")
                saveSleepSegments(context, sleepSegmentEvents)
            }

            if (SleepClassifyEvent.hasEvents(intent)) {
                val sleepClassifyEvents = SleepClassifyEvent.extractEvents(intent)
                Log.d("SleepTracker", "Received ${sleepClassifyEvents.size} sleep classify events")
            }
        } catch (e: Exception) {
            Log.e("SleepTracker", "Error processing sleep events: ${e.message}")
        }
    }

    private fun saveSleepSegments(context: Context, events: List<SleepSegmentEvent>) {
        try {
            val prefs = context.getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
            val gson = Gson()
           
            val existingDataJson = prefs.getString("segments", "[]") ?: "[]"
            val segmentsArray = gson.fromJson(existingDataJson, Array<SleepSegmentData>::class.java)
            val segments: MutableList<SleepSegmentData> = segmentsArray?.toMutableList() 
                ?: mutableListOf()
           
            events.forEach { event ->
                val newSegment = SleepSegmentData(
                    startTime = event.startTimeMillis,
                    endTime = event.endTimeMillis,
                    status = event.status
                )
                segments.add(newSegment)
            }
           
            val uniqueSegments = segments
                .distinctBy { it.startTime }
                .sortedBy { it.startTime }
           
            val editor = prefs.edit()
            editor.putString("segments", gson.toJson(uniqueSegments))
            editor.apply()
           
            Log.d("SleepTracker", "Saved ${events.size} new sleep segments. Total: ${uniqueSegments.size}")
        } catch (e: Exception) {
            Log.e("SleepTracker", "Error saving sleep segments: ${e.message}")
            e.printStackTrace()
        }
    }
}