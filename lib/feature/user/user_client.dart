import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'user_client.g.dart';

@RestApi()
abstract class UserRepo {
  factory UserRepo(Dio dio, {required String baseUrl}) = _UserRepo;

  @POST('/auth/login')
  Future<HttpResponse> login(@Body() Map<String, dynamic> body);

  @POST('/auth/register')
  Future<HttpResponse> register(@Body() Map<String, dynamic> body);
  
}