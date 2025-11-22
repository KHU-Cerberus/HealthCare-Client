import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
part 'repository.g.dart';

@RestApi()
abstract class UserRepo {
  factory UserRepo(Dio dio, {required String baseUrl}) = _UserRepo;

  @POST('/login')
  Future<HttpResponse> login(@Body() Map<String, dynamic> body);

  @POST('/register')
  Future<HttpResponse> register(@Body() Map<String, dynamic> body);
  
}