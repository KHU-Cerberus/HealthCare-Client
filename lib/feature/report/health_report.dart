import 'dart:ffi';

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'health_report.g.dart';

@RestApi()
abstract class HealthReportApi {
  factory HealthReportApi(Dio dio, {required String baseUrl}) = _HealthReportApi;

  // 날짜별 수면/식사 그래프 조회
  @GET('/report/record/{day}')
  Future<HttpResponse> submitHealthReport(
      @Header('Authorization') String token);

  // 날짜별 건강 보고서 조회
  @GET('/report/health/{day}')
  Future<HttpResponse> getHealthReport(
      @Header('Authorization') String token,
      @Path('id') String id);
  
}