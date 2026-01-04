import 'package:flutter/material.dart';
// import 'dart:io'; // Not needed since we use bytes
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileProvider with ChangeNotifier {
  final ApiClient _apiClient;
  final AuthProvider? _authProvider;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  String? _error;

  ProfileProvider(this._apiClient, {AuthProvider? authProvider}) : _authProvider = authProvider;

  Map<String, dynamic>? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearState() {
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Fetch profile data from API
      final response = await _apiClient.dio.get(ApiConstants.getProfile);
      if (response.statusCode == 200) {
        // Handle wrapped response if necessary (checking for 'user' or 'curUser' keys)
        if (response.data is Map && (response.data.containsKey('user') || response.data.containsKey('curUser'))) {
          _user = response.data['user'] ?? response.data['curUser'];
        } else {
          _user = response.data;
        }
        
        if (_user != null && _authProvider != null) {
          dynamic adminValue = _user!['is_admin'] ?? _user!['isAdmin'];
          bool isAdmin = false;
          if (adminValue is bool) {
            isAdmin = adminValue;
          } else if (adminValue is int) {
            isAdmin = adminValue == 1;
          } else if (adminValue is String) {
            isAdmin = adminValue.toLowerCase() == 'true' || adminValue == '1';
          }
          
          _authProvider!.updateAdminStatus(isAdmin);
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        _error = 'Phiên làm việc đã hết hạn. Vui lòng đăng nhập lại.';
      } else {
        _error = 'Không thể tải thông tin cá nhân. Vui lòng thử lại sau.';
      }
    } catch (e) {
      _error = 'Đã có lỗi xảy ra: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put(ApiConstants.updateProfile, data: data);
      await fetchProfile();
    } on DioException catch (e) {
      String message = 'Cập nhật thông tin thất bại';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      throw message;
    } catch (e) {
      throw 'Đã có lỗi xảy ra: $e';
    }
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _apiClient.dio.post(ApiConstants.changePassword, data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      String message = 'Đổi mật khẩu thất bại';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      throw message;
    } catch (e) {
      throw 'Đã có lỗi xảy ra: $e';
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _apiClient.dio.delete(ApiConstants.deleteAccount);
      
      // Trigger logout after successful deletion
      if (_authProvider != null) {
        await _authProvider!.logout();
      }
    } on DioException catch (e) {
      String message = 'Xóa tài khoản thất bại';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      throw message;
    } catch (e) {
      throw 'Đã có lỗi xảy ra: $e';
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String fileName) async {
    _isLoading = true;
    notifyListeners();
    try {
      FormData formData = FormData.fromMap({
        "profile_pic": MultipartFile.fromBytes(bytes, filename: fileName.split('/').last.isEmpty ? 'avatar.jpg' : fileName.split('/').last),
      });

      // Assuming PUT /user/avatar or similar, using generic update path for now or creating a new constant if needed.
      // Based on ApiConstants, use updateProfile or a logical path.
      // Let's assume it's part of update profile, but usually avatar is separate or multipart on update.
      // Detailed API docs are missing, so I will try to use a specific guess or just the update endpoint with multipart.
      // Let's use ApiConstants.updateProfile but with FormData.
      
      final response = await _apiClient.dio.put(
        ApiConstants.updateProfile,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType), // Important for file upload
      );

      if (response.statusCode == 200) {
        await fetchProfile(); 
      }
      
    } on DioException catch (e) {
      String message = 'Tải lên ảnh thất bại';
      if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
      }
      _error = message;
      throw message;
    } catch (e) {
      _error = 'Đã có lỗi xảy ra: $e';
      throw _error!;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
