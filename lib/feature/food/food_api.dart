import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'food_api.g.dart';

@RestApi()
abstract class FoodApi {
  factory FoodApi(Dio dio, {required String baseUrl}) = _FoodApi;

  @POST('/food/upload')
  Future<void> uploadFoodData(@Body() Map<String, dynamic> foodData);

  @POST('/food/save')
  Future<void> saveFoodData(@Body() Map<String, dynamic> foodData);
}