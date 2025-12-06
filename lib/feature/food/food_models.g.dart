// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FoodUploadResponse _$FoodUploadResponseFromJson(Map<String, dynamic> json) =>
    FoodUploadResponse(
      message: json['message'] as String,
      data: FoodData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FoodUploadResponseToJson(FoodUploadResponse instance) =>
    <String, dynamic>{
      'message': instance.message,
      'data': instance.data,
    };

FoodData _$FoodDataFromJson(Map<String, dynamic> json) => FoodData(
      foodName: json['foodName'] as String,
      nutritionInfo:
          NutritionInfo.fromJson(json['nutritionInfo'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$FoodDataToJson(FoodData instance) => <String, dynamic>{
      'foodName': instance.foodName,
      'nutritionInfo': instance.nutritionInfo,
    };

NutritionInfo _$NutritionInfoFromJson(Map<String, dynamic> json) =>
    NutritionInfo(
      calories: (json['calories'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      saturatedFat: (json['saturatedFat'] as num).toDouble(),
      cholesterol: (json['cholesterol'] as num).toDouble(),
      sodium: (json['sodium'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      fiber: (json['fiber'] as num).toDouble(),
      sugar: (json['sugar'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
    );

Map<String, dynamic> _$NutritionInfoToJson(NutritionInfo instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'totalFat': instance.totalFat,
      'saturatedFat': instance.saturatedFat,
      'cholesterol': instance.cholesterol,
      'sodium': instance.sodium,
      'totalCarbs': instance.totalCarbs,
      'fiber': instance.fiber,
      'sugar': instance.sugar,
      'protein': instance.protein,
    };
