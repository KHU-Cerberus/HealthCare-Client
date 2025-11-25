import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

/*
@RestApi()
abstract class SleepApi {
  factory SleepApi(Dio dio, {required String baseUrl}) = _SleepApi;

  @POST('/sleep/pattern')
  Future<HttpResponse> setSleepingPattern(@Header('Authorization') String token);

  @PATCH('/sleep/pattern')
  Future<HttpResponse> updateSleepingPattern(
      @Header('Authorization') String token,
      @Body() Map<String, dynamic> body);

  @GET('/sleep/pattern')
  Future<HttpResponse> getSleepingPattern(
    @Header('Authorization') String token);
    
}
*/