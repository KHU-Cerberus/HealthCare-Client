import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'sleep_api.g.dart';

@RestApi()
abstract class SleepApi {
  factory SleepApi(Dio dio, {required String baseUrl}) = _SleepApi;

  // 수면 패턴 설정
  @POST('/user/sleep-pattern')
  Future<HttpResponse> setSleepingPattern(
    @Header('Authorization') String token,
    @Body() Map<String, dynamic> body);

  // 수면 기록 추가
  @POST('/sleep/record')
  Future<HttpResponse> updateSleepingPattern(
      @Header('Authorization') String token,
      @Body() Map<String, dynamic> body);

  // 수면기록 조회
  @GET('/sleep/record')
  Future<HttpResponse> getSleepingPattern(@Header('Authorization') String token);
  
  // 수면기록 삭제
  @DELETE('/sleep/record/{id}')
  Future<HttpResponse> deleteSleepingPattern(
      @Header('Authorization') String token,
      @Path('id') String id);

}
