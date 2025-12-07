// food_api.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'food_models.dart';

class FoodApi {
  final Dio _dio;

  FoodApi(this._dio);

  // 1. 음식 이미지 업로드 및 분석
  Future<FoodUploadResponse> uploadFoodData(File file) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/food/upload',
        data: formData,
      );

      return FoodUploadResponse.fromJson(response.data);
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  // 2. 음식 데이터 저장
  Future<void> saveFoodData({
    required File file,
    required String foodName,
    required double calories,
    required double totalFat,
    required double saturatedFat,
    required double cholesterol,
    required double sodium,
    required double totalCarbs,
    required double fiber,
    required double sugar,
    required double protein,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'foodName': foodName,
        'calories': calories,
        'totalFat': totalFat,
        'saturatedFat': saturatedFat,
        'cholesterol': cholesterol,
        'sodium': sodium,
        'totalCarbs': totalCarbs,
        'fiber': fiber,
        'sugar': sugar,
        'protein': protein,
      });

      await _dio.post(
        '/food/save',
        data: formData,
      );
    } catch (e) {
      print('Save error: $e');
      rethrow;
    }
  }
}