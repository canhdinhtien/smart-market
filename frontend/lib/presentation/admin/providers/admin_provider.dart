import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class AdminProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<dynamic> _categories = [];
  List<dynamic> _units = [];
  List<dynamic> _users = [];
  int _totalUsers = 0; 
  int _absoluteTotalUsers = 0; 
  int _totalUnits = 0;
  List<dynamic> _logs = [];
  int _totalLogs = 0;
  bool _isLoading = false;
  String? _error;

  AdminProvider(this._apiClient) {
    _categories = [];
    _units = [];
    _users = [];
    _logs = [];
  }

  List<dynamic> get categories => _categories;
  List<dynamic> get units => _units;
  List<dynamic> get users => _users;
  List<dynamic> get logs => _logs;
  Map<String, int> get logStats {
    final stats = <String, int>{'create': 0, 'update': 0, 'delete': 0, 'other': 0};
    for (var log in _logs) {
      final action = (log['action']?.toString() ?? '').toLowerCase();
      if (action.contains('create') || action.contains('add')) {
        stats['create'] = (stats['create'] ?? 0) + 1;
      } else if (action.contains('update') || action.contains('edit')) {
        stats['update'] = (stats['update'] ?? 0) + 1;
      } else if (action.contains('delete') || action.contains('remove')) {
        stats['delete'] = (stats['delete'] ?? 0) + 1;
      } else {
        stats['other'] = (stats['other'] ?? 0) + 1;
      }
    }
    return stats;
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  int get categoriesCount {
    try { return _categories.length; } catch (_) { return 0; }
  }
  int get unitsCount {
    if (_totalUnits > 0) return _totalUnits;
    try { return _units.length; } catch (_) { return 0; }
  }
  int get usersCount {
    if (_absoluteTotalUsers > 0) return _absoluteTotalUsers;
    if (_totalUsers > 0) return _totalUsers;
    try { return _users.length; } catch (_) { return 0; }
  }
  int get logsCount {
    if (_totalLogs > 0) return _totalLogs;
    try { return _logs.length; } catch (_) { return 0; }
  }

  void clearState() {
    _categories = [];
    _units = [];
    _users = [];
    _totalUsers = 0;
    _absoluteTotalUsers = 0;
    _totalUnits = 0;
    _logs = [];
    _totalLogs = 0;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchLogs({int page = 1, int limit = 20}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get(ApiConstants.adminLogs, queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('logs')) {
           final List<dynamic> newLogs = (data['logs'] as List<dynamic>?) ?? [];
           if (page == 1) {
             _logs = List.from(newLogs);
           } else {
             _logs.addAll(newLogs);
           }
           _totalLogs = int.tryParse(data['total']?.toString() ?? '') ?? (_logs?.length ?? 0);
        } else if (data is List) {
          if (page == 1) {
            _logs = List.from(data);
          } else {
            _logs.addAll(data);
          }
          _totalLogs = _logs?.length ?? 0;
        }
      }
    } catch (e) {
      _error = 'Không thể tải lịch sử hoạt động: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        return 'Kết nối máy chủ bị quá hạn. Vui lòng thử lại sau.';
      }
      if (e.type == DioExceptionType.connectionError) {
        return 'Không thể kết nối với máy chủ. Vui lòng kiểm tra internet.';
      }
      
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      
      if (statusCode == 409) {
        return 'Dữ liệu đã tồn tại trong hệ thống (Tên bị trùng).';
      }
      
      if (statusCode == 403) {
        return 'Bạn không có quyền thực hiện hành động này (Chỉ Admin).';
      }

      if (data is Map) {
        return data['message']?.toString() ?? 'Lỗi hệ thống (Mã: $statusCode)';
      }
      return 'Lỗi hệ thống ($statusCode)';
    }
    return e.toString();
  }

  Future<void> initializeDashboard() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await Future.wait([
        fetchCategories(),
        fetchUnits(),
        fetchUsers(),
        fetchLogs(),
      ]);
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Categories
  Future<void> fetchCategories({String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParameters = name != null && name.isNotEmpty ? {'name': name} : null;
      final response = await _apiClient.dio.get(ApiConstants.categories, queryParameters: queryParameters);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('categories')) {
          _categories = data['categories'] as List<dynamic>;
        } else if (data is List) {
          _categories = data;
        } else {
          _categories = [];
        }
      }
    } catch (e) {
      _error = 'Không thể tải danh dạng danh mục: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String name) async {
    _error = null;
    try {
      await _apiClient.dio.post(ApiConstants.categories, data: {'name': name});
      await fetchCategories();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  Future<void> updateCategory(String oldName, String newName) async {
    _error = null;
    try {
      await _apiClient.dio.put(ApiConstants.categories, data: {
        'oldName': oldName,
        'newName': newName,
      });
      await fetchCategories();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  Future<void> deleteCategoryByName(String name) async {
    _error = null;
    try {
      await _apiClient.dio.delete(ApiConstants.categories, data: {'name': name});
      await fetchCategories();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  // Units
  Future<void> fetchUnits({String? name}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final queryParameters = name != null && name.isNotEmpty ? {'name': name} : null;
      
      final response = await _apiClient.dio.get(ApiConstants.units, queryParameters: queryParameters);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && (data.containsKey('units') || data.containsKey('data'))) {
          _units = (data['units'] ?? data['data']) as List<dynamic>;
          _totalUnits = int.tryParse(data['total']?.toString() ?? '') ?? (_units?.length ?? 0);
        } else if (data is List) {
          _units = data;
          _totalUnits = _units?.length ?? 0;
        }
      }
    } catch (e) {
      _error = 'Lỗi Backend: Cột "created_at" không tồn tại trong bảng Units. Hãy cập nhật DB hoặc Model Unit.';
      _units = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addUnit(String name) async {
    _error = null;
    try {
      await _apiClient.dio.post(ApiConstants.units, data: {'unitName': name});
      await fetchUnits();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  Future<void> updateUnitByName(String oldName, String newName) async {
    _error = null;
    try {
      await _apiClient.dio.put(ApiConstants.units, data: {
        'oldName': oldName,
        'newName': newName,
      });
      await fetchUnits();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  Future<void> deleteUnitByName(String name) async {
    _error = null;
    try {
      await _apiClient.dio.delete(ApiConstants.units, data: {'unitName': name});
      await fetchUnits();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  // Users Management
  Future<void> fetchUsers({String query = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final url = '${ApiConstants.searchUsers(query)}&limit=100';
      final response = await _apiClient.dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('users')) {
          _users = data['users'] as List<dynamic>;
          _totalUsers = int.tryParse(data['total']?.toString() ?? '') ?? (_users?.length ?? 0);
          if (query.isEmpty) {
            _absoluteTotalUsers = _totalUsers;
          }
        } else if (data is List) {
          _users = data;
          _totalUsers = _users?.length ?? 0;
          if (query.isEmpty) {
            _absoluteTotalUsers = _totalUsers;
          }
        } else {
          _users = [];
          _totalUsers = 0;
        }
      }
    } catch (e) {
      _error = 'Không thể tải danh sách người dùng: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUserDetails(dynamic userId, Map<String, dynamic> userData) async {
    // Disabled due to backend limitations
  }

  Future<void> updateUserRole(dynamic userId, bool isAdmin) async {
    try {
      await _apiClient.dio.put(ApiConstants.userRole(userId), data: {'is_admin': isAdmin});
      await fetchUsers();
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }

  Future<void> deleteUser(dynamic userId) async {
    _error = null;
    try {
      await _apiClient.dio.delete(ApiConstants.userDetail(userId));
      // Try to refresh user list, but don't fail if refresh fails
      try {
        await fetchUsers();
      } catch (refreshError) {
        // Log refresh error but don't rethrow - deletion was successful
        print('Warning: Failed to refresh user list after deletion: $refreshError');
      }
    } catch (e) {
      _error = _parseError(e);
      throw _error!;
    }
  }
}
