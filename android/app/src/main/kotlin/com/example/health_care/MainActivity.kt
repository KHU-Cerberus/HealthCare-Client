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
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.health_care/tracker"
    private val ACTIVITY_RECOGNITION_REQUEST_CODE = 100
    private lateinit var methodChannel: MethodChannel
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
       
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
                    result.success(hasActivityRecognitionPermission())
                }
                "requestPermissions" -> {
                    requestActivityRecognitionPermission(result)
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
            true // Permission not needed for Android 9 and below
        }
    }

    private fun requestActivityRecognitionPermission(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
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

    private fun checkGooglePlayServices(): Boolean {
        val googleApiAvailability = GoogleApiAvailability.getInstance()
        val resultCode = googleApiAvailability.isGooglePlayServicesAvailable(this)
        return resultCode == ConnectionResult.SUCCESS
    }

    private fun subscribeSleepUpdates(result: MethodChannel.Result) {
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
                Log.d("SleepTracker", "Successfully subscribed to sleep updates")
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
        try {
            val prefs = getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
            val sleepDataJson = prefs.getString("segments", "[]") ?: "[]"
           
            val gson = Gson()
            
            // TypeToken 대신 Array로 파싱 후 List로 변환 (ProGuard-safe)
            val segmentsArray = gson.fromJson(sleepDataJson, Array<SleepSegmentData>::class.java)
            val allSegments = segmentsArray?.toList() ?: emptyList()
           
            // 최근 N일 데이터만 필터링
            val cutoffTime = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(days.toLong())
            val filteredSegments = allSegments.filter { it.startTime >= cutoffTime }
           
            // Map으로 변환하여 Flutter에 전달
            val segmentMaps = filteredSegments.map {
                val start = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                    .format(java.util.Date(it.startTime))
                val end = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss", java.util.Locale.getDefault())
                    .format(java.util.Date(it.endTime))
                val durationHours = (it.endTime - it.startTime) / (1000 * 60 * 60.0)
                
                Log.d("SleepTracker", "Segment: status=${it.status}, start=$start, end=$end, duration=${String.format("%.2f", durationHours)}h")
                
                mapOf(
                    "startTime" to it.startTime,
                    "endTime" to it.endTime,
                    "status" to it.status
                )
            }
           
            Log.d("SleepTracker", "Retrieved ${segmentMaps.size} sleep segments")
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

// BroadcastReceiver - Sleep API 이벤트 수신
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
                processSleepClassifications(context, sleepClassifyEvents)
            }
        } catch (e: Exception) {
            Log.e("SleepTracker", "Error processing sleep events: ${e.message}")
        }
    }

    private fun saveSleepSegments(context: Context, events: List<SleepSegmentEvent>) {
        try {
            val prefs = context.getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
            val gson = Gson()
           
            // 기존 데이터 불러오기 - Array로 파싱 (ProGuard-safe)
            val existingDataJson = prefs.getString("segments", "[]") ?: "[]"
            val segmentsArray = gson.fromJson(existingDataJson, Array<SleepSegmentData>::class.java)
            val segments: MutableList<SleepSegmentData> = segmentsArray?.toMutableList() 
                ?: mutableListOf()
           
            // 새 이벤트 추가
            events.forEach { event ->
                val newSegment = SleepSegmentData(
                    startTime = event.startTimeMillis,
                    endTime = event.endTimeMillis,
                    status = event.status
                )
                segments.add(newSegment)
            }
           
            // 중복 제거 및 시간순 정렬
            val uniqueSegments = segments
                .distinctBy { it.startTime }
                .sortedBy { it.startTime }
           
            // 저장
            val editor = prefs.edit()
            editor.putString("segments", gson.toJson(uniqueSegments))
            editor.apply()
           
            Log.d("SleepTracker", "Saved ${events.size} new sleep segments. Total: ${uniqueSegments.size}")
        } catch (e: Exception) {
            Log.e("SleepTracker", "Error saving sleep segments: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun processSleepClassifications(context: Context, events: List<SleepClassifyEvent>) {
        try {
            events.forEach { event ->
                Log.d("SleepTracker",
                    "Sleep classification - Confidence: ${event.confidence}, " +
                    "Light: ${event.light}, Motion: ${event.motion}")
            }
        } catch (e: Exception) {
            Log.e("SleepTracker", "Error processing classifications: ${e.message}")
        }
    }
}