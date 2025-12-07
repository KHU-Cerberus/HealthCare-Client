import 'package:json_annotation/json_annotation.dart';

part 'food_models.g.dart';

@JsonSerializable()
class FoodUploadResponse {
  final String message;
  final FoodData data;

  FoodUploadResponse({
    required this.message,
    required this.data,
  });

  factory FoodUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$FoodUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FoodUploadResponseToJson(this);
}

@JsonSerializable()
class FoodData {
  final String foodName;
  final NutritionInfo nutritionInfo;

  FoodData({
    required this.foodName,
    required this.nutritionInfo,
  });

  factory FoodData.fromJson(Map<String, dynamic> json) =>
      _$FoodDataFromJson(json);

  Map<String, dynamic> toJson() => _$FoodDataToJson(this);
}

@JsonSerializable()
class NutritionInfo {
  final double calories;
  final double totalFat;
  final double saturatedFat;
  final double cholesterol;
  final double sodium;
  final double totalCarbs;
  final double fiber;
  final double sugar;
  final double protein;

  NutritionInfo({
    required this.calories,
    required this.totalFat,
    required this.saturatedFat,
    required this.cholesterol,
    required this.sodium,
    required this.totalCarbs,
    required this.fiber,
    required this.sugar,
    required this.protein,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionInfoFromJson(json);

  Map<String, dynamic> toJson() => _$NutritionInfoToJson(this);
}