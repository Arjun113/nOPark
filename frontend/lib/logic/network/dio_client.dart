import 'package:dio/dio.dart';
import 'package:nopark/features/authentications/datasources/local_datastorer.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nopark-api.lachlanmacphee.com/v1',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      validateStatus: (status) => status != null && status < 400,
    ),
  );

  DioClient._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await CredentialStorage.fetchLoginToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            await CredentialStorage.deleteLoginToken();
            // TODO: Redirect to login screen
            return handler.next(e);
          } else {
            return handler.next(e);
          }
        },
      ),
    );
  }

  Dio get client => _dio;
}
