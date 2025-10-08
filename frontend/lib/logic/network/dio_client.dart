import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  final _storage = FlutterSecureStorage();
  bool _isRefreshing = false;
  final List<Function()> _refreshQueue = [];

  DioClient._internal() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          if (e.response?.statusCode == 401) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken == null) {
              await _clearTokens();
              // TODO: Redirect to login screen
              return handler.reject(e);
            }

            if (_isRefreshing) {
              _refreshQueue.add(() async {
                e.requestOptions.headers['Authorization'] =
                    'Bearer ${await _storage.read(key: 'access_token')}';
                final clonedRequest = await _dio.fetch(e.requestOptions);
                handler.resolve(clonedRequest);
              });
              return;
            }

            _isRefreshing = true;
            try {
              final refreshResponse = await _dio.post(
                'auth/refresh',
                data: {'refresh_token': refreshToken},
              );
              final newAccessToken = refreshResponse.data['access_token'];
              await _storage.write(key: 'access_token', value: newAccessToken);

              for (var callback in _refreshQueue) {
                callback();
              }
              _refreshQueue.clear();

              e.requestOptions.headers['Authorization'] =
                  'Bearer $newAccessToken';
              final clonedRequest = await _dio.fetch(e.requestOptions);
              handler.resolve(clonedRequest);
            } catch (refreshError) {
              await _clearTokens();
              // TODO: Redirect to login screen
              handler.reject(refreshError as DioException);
            } finally {
              _isRefreshing = false;
            }
          } else {
            return handler.next(e);
          }
        },
      ),
    );
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Dio get client => _dio;
}
