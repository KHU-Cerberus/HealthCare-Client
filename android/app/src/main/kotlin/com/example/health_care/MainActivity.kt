package com.example.health_care

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.annotation.NonNull
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.SleepSegmentRequest
import com.google.android.gms.location.SleepClassifyEvent
import com.google.android.gms.location.SleepSegmentEvent
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.health_care/tracker"
    private lateinit var methodChannel: MethodChannel

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
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun subscribeSleepUpdates(result: MethodChannel.Result) {
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
            result.success(true)
        }

        task.addOnFailureListener { exception ->
            result.error("SUBSCRIBE_FAILED", exception.message, null)
        }
    }

    private fun unsubscribeSleepUpdates(result: MethodChannel.Result) {
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
            result.success(true)
        }

        task.addOnFailureListener { exception ->
            result.error("UNSUBSCRIBE_FAILED", exception.message, null)
        }
    }

    private fun getSleepData(days: Int, result: MethodChannel.Result) {
        try {
            val prefs = getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
            val sleepDataJson = prefs.getString("segments", "[]")
            
            val gson = Gson()
            val type = object : TypeToken<List<SleepSegmentData>>() {}.type
            val allSegments: List<SleepSegmentData> = gson.fromJson(sleepDataJson, type)
            
            // 최근 N일 데이터만 필터링
            val cutoffTime = System.currentTimeMillis() - TimeUnit.DAYS.toMillis(days.toLong())
            val filteredSegments = allSegments.filter { it.startTime >= cutoffTime }
            
            // Map으로 변환하여 Flutter에 전달
            val segmentMaps = filteredSegments.map { 
                mapOf(
                    "startTime" to it.startTime,
                    "endTime" to it.endTime,
                    "status" to it.status
                )
            }
            
            result.success(segmentMaps)
        } catch (e: Exception) {
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
    override fun onReceive(context: Context, intent: Intent) {
        if (SleepSegmentEvent.hasEvents(intent)) {
            val sleepSegmentEvents = SleepSegmentEvent.extractEvents(intent)
            saveSleepSegments(context, sleepSegmentEvents)
        }

        if (SleepClassifyEvent.hasEvents(intent)) {
            val sleepClassifyEvents = SleepClassifyEvent.extractEvents(intent)
            // 필요시 수면 분류 데이터도 저장 가능
            processSleepClassifications(context, sleepClassifyEvents)
        }
    }

    private fun saveSleepSegments(context: Context, events: List<SleepSegmentEvent>) {
        val prefs = context.getSharedPreferences("sleep_data", Context.MODE_PRIVATE)
        val gson = Gson()
        
        // 기존 데이터 불러오기
        val existingDataJson = prefs.getString("segments", "[]")
        val type = object : TypeToken<MutableList<SleepSegmentData>>() {}.type
        val segments: MutableList<SleepSegmentData> = gson.fromJson(existingDataJson, type)
        
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
        val uniqueSegments = segments.distinctBy { it.startTime }.sortedBy { it.startTime }
        
        // 저장
        val editor = prefs.edit()
        editor.putString("segments", gson.toJson(uniqueSegments))
        editor.apply()
        
        // 디버깅용 로그
        android.util.Log.d("SleepTracker", "Saved ${events.size} new sleep segments")
    }

    private fun processSleepClassifications(context: Context, events: List<SleepClassifyEvent>) {
        // 수면 분류 이벤트 처리
        // confidence, light, motion 등의 정보 활용 가능
        events.forEach { event ->
            android.util.Log.d("SleepTracker", 
                "Sleep classification - Confidence: ${event.confidence}, Light: ${event.light}, Motion: ${event.motion}")
        }
    }
}