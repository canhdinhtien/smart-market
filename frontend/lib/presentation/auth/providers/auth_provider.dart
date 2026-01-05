import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/services/notification_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider with ChangeNotifier {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;
  AuthStatus _status = AuthStatus.unknown;
  String? _token;
  String? _userId;
  bool _isLoading = false;
  String? _errorMessage;
  String? _pendingVerificationEmail;
  String? _verifyToken;
  String? _resetToken;

  AuthProvider(this._apiClient, this._prefs) {
    _checkAuth();

    // Listen for FCM token refreshes
    NotificationService().onTokenRefresh.listen((newToken) {
      if (_status == AuthStatus.authenticated) {
        _syncFcmToken(newToken);
      }
    });

    // Initial sync if already authenticated
    if (_status == AuthStatus.authenticated) {
      _syncFcmToken();
    }
  }

  AuthStatus get status => _status;
  String? get token => _token;
  String? get userId => _userId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isVerificationPending => _pendingVerificationEmail != null;
  String? get pendingEmail => _pendingVerificationEmail;
  VoidCallback? onLogout;

  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  void _checkAuth() {
    _userId = _prefs.getString('user_id');
    final authToken = _prefs.getString('auth_token');
    _isAdmin = _prefs.getBool('is_admin') ?? false;

    if (authToken != null) {
      _token = authToken;
      _status = AuthStatus.authenticated;
    } else {
      _token = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Gọi khi token hết hạn (401) để xóa session cục bộ mà không cần gọi API logout
  void handleUnauthorized() {
    if (_status == AuthStatus.authenticated) {
      _clearLocalSession();
    }
  }

  /// Cập nhật token mới khi refresh thành công
  void updateToken(String newToken) {
    _token = newToken;
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<void> _clearLocalSession() async {
    await _prefs.remove('user_id');
    await _prefs.remove('user_name');
    await _prefs.remove('user_email');
    await _prefs.remove('auth_token');
    await _prefs.remove('refresh_token');
    await _prefs.remove('is_admin');

    _token = null;
    _isAdmin = false;
    _verifyToken = null;
    _pendingVerificationEmail = null;
    _status = AuthStatus.unauthenticated;

    // Trigger external cleanup
    onLogout?.call();
    notifyListeners();
  }

  void updateAdminStatus(bool status) {
    print('updateAdminStatus called: current=$_isAdmin, new=$status');
    if (_isAdmin != status) {
      _isAdmin = status;
      _prefs.setBool('is_admin', _isAdmin);
      print('updateAdminStatus: Changed! Calling notifyListeners()');
      notifyListeners();
    } else {
      print('updateAdminStatus: No change, skipping notifyListeners()');
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {'identifier': email, 'password': password},
      );

      // print("Dữ liệu Server trả về: ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        final userData =
            responseData['curUser'] ??
            responseData['user'] ??
            responseData['data'];
        final accessToken = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];

        // Robust check for admin flag
        dynamic adminValue;
        if (userData != null) {
          adminValue =
              userData['is_admin'] ?? userData['isAdmin'] ?? userData['role'];
        }

        // Fallback to top-level access
        adminValue ??=
            responseData['is_admin'] ??
            responseData['isAdmin'] ??
            responseData['role'] ??
            responseData['admin'];

        print('Login response - userData: $userData');
        print(
          'Login response - adminValue extracted: $adminValue (type: ${adminValue.runtimeType})',
        );

        // CRITICAL: Set ALL data in memory FIRST before any status change
        // This ensures AuthWrapper sees the correct values immediately
        _isAdmin = adminValue is bool
            ? adminValue
            : adminValue is int
            ? (adminValue == 1)
            : adminValue is String
            ? ([
                'true',
                '1',
                'admin',
                'administrator',
              ].contains(adminValue.toLowerCase()))
            : false;

        print('Login: Setting isAdmin = $_isAdmin (from login response)');

        await _prefs.setBool('is_admin', _isAdmin);

        if (accessToken != null) {
          if (userData != null) {
            _userId = userData['id'].toString();
            await _prefs.setString('user_id', _userId!);
            await _prefs.setString('user_name', userData['name'] ?? '');
            await _prefs.setString('user_email', userData['email'] ?? '');
          } else {
            // If userData is null, try to get ID from top level
            _userId =
                responseData['id']?.toString() ??
                responseData['userId']?.toString();
            if (_userId != null) await _prefs.setString('user_id', _userId!);
          }

          await _prefs.setString('auth_token', accessToken);
          if (refreshToken != null) {
            await _prefs.setString('refresh_token', refreshToken);
          }

          _token = accessToken;

          // WORKAROUND: If backend doesn't return is_admin in login response,
          // fetch profile to get the correct value BEFORE setting authenticated status
          if (adminValue == null) {
            print('Backend did not return is_admin, fetching profile...');
            try {
              final profileResponse = await _apiClient.dio.get(
                ApiConstants.getProfile,
              );
              if (profileResponse.statusCode == 200) {
                final profileData =
                    profileResponse.data['user'] ?? profileResponse.data;
                final profileAdmin =
                    profileData['is_admin'] ?? profileData['isAdmin'];
                if (profileAdmin != null) {
                  _isAdmin = profileAdmin is bool
                      ? profileAdmin
                      : (profileAdmin == 1 || profileAdmin == true);
                  await _prefs.setBool('is_admin', _isAdmin);
                  print('Got is_admin from profile: $_isAdmin');
                }
              }
            } catch (e) {
              print('Failed to fetch profile: $e');
            }
          }

          // Set status AFTER we have the correct is_admin value
          _status = AuthStatus.authenticated;

          // Sync FCM token to backend
          _syncFcmToken();

          print('Login: About to notify - isAdmin=$_isAdmin, status=$_status');
          // CRITICAL: Only ONE notifyListeners call with all data ready
          notifyListeners();
        } else {
          _errorMessage = 'Đăng nhập thất bại: Thiếu token từ server';
        }
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        final message = responseData['message'] ?? '';

        if (message.contains('not verified')) {
          _errorMessage = 'Tài khoản chưa được xác thực!';
          _pendingVerificationEmail = email;
          notifyListeners();
          return;
        }

        if (responseData['code'] == '00045') {
          _errorMessage = 'Email hoặc mật khẩu không đúng';
        } else if (responseData['code'] == '00036') {
          _errorMessage = 'Email chưa tồn tại';
        } else {
          _errorMessage = message.isNotEmpty ? message : 'Đăng nhập thất bại';
        }
      } else {
        _errorMessage = 'Lỗi kết nối server';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiClient.dio.post(ApiConstants.logout);
    } catch (e) {
      print("Server Logout error: $e");
    } finally {
      await _clearLocalSession();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String gender,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'gender': gender,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _pendingVerificationEmail = email;
        _verifyToken = response.data['verifyToken'];

        // Lưu ý: Nếu hàm sendVerificationCode cũng trả về token mới, hãy cập nhật nó
        // await sendVerificationCode(email);
        _errorMessage = null;
      }
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        _errorMessage = e.response?.data['message'] ?? 'Đăng ký thất bại';
      } else {
        _errorMessage = 'Lỗi kết nối server (Mã: ${e.response?.statusCode})';
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendVerificationCode(String email) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.sendVerificationCode,
        data: {'email': email},
      );

      // Nếu server trả về verifyToken mới khi resend:
      // Lấy key verificationToken (viết đầy đủ - theo đúng Backend sendVerificationCode)
      if (response.data['verificationToken'] != null) {
        _verifyToken = response.data['verificationToken'];
      }
      // Phòng hờ nếu sau này backend đổi lại, ta dùng toán tử ?? (nếu cái này null thì lấy cái kia)
      else if (response.data['verifyToken'] != null) {
        _verifyToken = response.data['verifyToken'];
      }
    } on DioException catch (e) {
      _errorMessage = 'Không thể gửi mã xác nhận';
      notifyListeners();
    }
  }

  Future<void> verifyEmail(String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.verifyEmail,
        data: {'code': code, 'token': _verifyToken},
      );
      if (response.statusCode == 200) {
        _pendingVerificationEmail = null;
        _verifyToken = null;
        notifyListeners();
      }
    } on DioException catch (e) {
      print("Verify Error: ${e.response?.data}");
      _errorMessage = 'Mã xác nhận không đúng hoặc token hết hạn';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Lưu token để dùng cho bước reset
        _resetToken = response.data['token'] ?? response.data['resetToken'];
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        _errorMessage = e.response?.data['message'] ?? 'Gửi yêu cầu thất bại';
      } else {
        _errorMessage = 'Lỗi kết nối server';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.resetPassword,
        data: {
          'email': email,
          'code': code,
          'token':
              _resetToken, // Gửi kèm token nhận được từ bước forgotPassword
          'newPassword': newPassword, // Backend yêu cầu trường newPassword
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        _resetToken = null; // Xóa token sau khi dùng xong
        return true;
      }
      return false;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        _errorMessage =
            e.response?.data['message'] ?? 'Đặt lại mật khẩu thất bại';
      } else {
        _errorMessage = 'Lỗi kết nối server';
      }
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronize FCM token with backend profile
  Future<void> _syncFcmToken([String? token]) async {
    try {
      final fcmToken = token ?? await NotificationService().getToken();
      if (fcmToken != null) {
        print('Synchronizing FCM Token: $fcmToken');

        String platform = 'web';
        if (!kIsWeb) {
          if (Platform.isAndroid) platform = 'android';
          if (Platform.isIOS) platform = 'ios';
        }

        // Sending to register device endpoint
        await _apiClient.dio.post(
          ApiConstants.registerDevice,
          data: {'fcm_token': fcmToken, 'platform': platform},
        );
      }
    } catch (e) {
      print('FCM Token Sync Error: $e');
    }
  }
}
