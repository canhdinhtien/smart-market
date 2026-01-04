import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  late Dio _dio;
  final SharedPreferences _prefs;

  Function()? onUnauthorized;
  Function(String token)? onTokenRefreshed;

  ApiClient(this._prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
            final refreshToken = _prefs.getString('refresh_token');
            if (refreshToken != null) {
              try {
                // Attempt to refresh token using a separate Dio instance to avoid interceptor loops
                final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
                final response = await refreshDio.post(
                  ApiConstants.refreshToken,
                  data: {'refreshToken': refreshToken},
                );

                if (response.statusCode == 200 || response.statusCode == 201) {
                  final newToken = response.data['accessToken'];
                  final newRefreshToken = response.data['refreshToken'];

                  if (newToken != null) {
                    await _prefs.setString('auth_token', newToken);
                    if (newRefreshToken != null) {
                      await _prefs.setString('refresh_token', newRefreshToken);
                    }
                    
                    // Notify AuthProvider or others
                    onTokenRefreshed?.call(newToken);

                    // Retry the original request with new token
                    final options = e.requestOptions;
                    options.headers['Authorization'] = 'Bearer $newToken';
                    
                    final retryResponse = await _dio.fetch(options);
                    return handler.resolve(retryResponse);
                  }
                }
              } catch (refreshError) {
                // If refresh fails (e.g. refresh token expired), continue to unauthorized handling
              }
            }
            onUnauthorized?.call();
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // Future<Response> post(String path, {dynamic data}) async {
  //   try {
  //     return await _dio.post(path, data: data);
  //   } on DioException {
  //     rethrow; // Để AuthProvider xử lý lỗi cụ thể
  //   }
  // }
}
