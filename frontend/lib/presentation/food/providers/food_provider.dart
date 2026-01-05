import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add XFile support
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FoodProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<dynamic> _foods = [];
  List<dynamic> _categories = [];
  List<dynamic> _units = [];
  dynamic _currentFood;
  bool _isLoading = false;
  String? _error;
  
  // Pagination state
  int _totalFoods = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  FoodProvider(this._apiClient);

  List<dynamic> get foods => _foods;
  List<dynamic> get categories => _categories;
  List<dynamic> get units => _units;
  dynamic get currentFood => _currentFood;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalFoods => _totalFoods;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  void clearState() {
    _foods = [];
    _categories = [];
    _units = [];
    _currentFood = null;
    _isLoading = false;
    _error = null;
    _totalFoods = 0;
    _currentPage = 1;
    _totalPages = 1;
    notifyListeners();
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        return data['message']?.toString() ?? 'Lỗi hệ thống (${e.response?.statusCode})';
      }
      return 'Lỗi Server (${e.response?.statusCode}): ${data?.toString() ?? "Nội dung lỗi không xác định"}';
    }
    return e.toString();
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.categories);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          _categories = data;
        } else if (data is Map) {
          _categories = data['categories'] ?? data['data'] ?? [];
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Lỗi tải danh mục: ${_parseError(e)}';
      _categories = [];
      notifyListeners();
    }
  }

  Future<void> fetchUnits() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.units);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          _units = data;
        } else if (data is Map) {
          _units = data['units'] ?? data['data'] ?? [];
        }
        notifyListeners();
      }
    } catch (e) {
      _error = 'Lỗi Backend: Cột "created_at" không tồn tại trong bảng Units.';
      _units = [];
      notifyListeners();
    }
  }

  Future<void> fetchFoods() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _apiClient.dio.get(ApiConstants.food);
      if (response.statusCode == 200) {
        if (response.data is Map) {
          _foods = List<dynamic>.from(response.data['foods'] ?? []);
          _totalFoods = response.data['total'] ?? _foods.length;
        } else {
          _foods = List<dynamic>.from(response.data);
          _totalFoods = _foods.length;
        }
      }
    } catch (e) {
      _error = 'Lỗi tải danh sách thực phẩm: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFoodsInGroup(dynamic groupId, {int page = 1, String? name, dynamic categoryId}) async {
    if (groupId == null) return;
    _isLoading = true;
    _error = null;
    if (page == 1) _foods = []; // Clear for first page
    notifyListeners();

    try {
      String url = '${ApiConstants.food}?group_id=$groupId&page=$page';
      if (name != null && name.isNotEmpty) url += '&name=$name';
      if (categoryId != null) url += '&category_id=$categoryId';

      final response = await _apiClient.dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final List<dynamic> fetchedFoods = data['foods'] ?? [];
          if (page == 1) {
            _foods = fetchedFoods;
          } else {
            _foods.addAll(fetchedFoods);
          }
          _totalFoods = data['total'] ?? _foods.length;
          _currentPage = data['page'] ?? page;
          _totalPages = data['totalPages'] ?? 1;
        } else {
          _foods = List<dynamic>.from(data);
          _totalFoods = _foods.length;
        }
      }
    } catch (e) {
      _error = 'Lỗi tải thực phẩm nhóm: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchFoodDetail(dynamic id) async {
    if (id == null) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.foodDetail(id));
      if (response.statusCode == 200) {
        _currentFood = response.data;
      }
    } catch (e) {
      _error = 'Lỗi tải chi tiết thực phẩm: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createFood({
    required String name,
    required dynamic groupId,
    dynamic categoryId,
    dynamic unitId,
    double? quantity,
    XFile? image,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> data = {
        'name': name,
        'group_id': groupId,
      };
      if (categoryId != null) data['category_id'] = categoryId;
      if (unitId != null) data['unit_id'] = unitId;
      if (quantity != null) data['quantity'] = quantity;

      FormData formData = FormData.fromMap(data);

      if (image != null) {
        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name.isEmpty ? 'food_image.jpg' : image.name,
          ),
        ));
      }

      final response = await _apiClient.dio.post(ApiConstants.food, data: formData);
      
      // Refresh in background to return quickly
      if (groupId != null) {
        fetchFoodsInGroup(groupId);
      } else {
        fetchFoods();
      }
      return response.data;
    } catch (e) {
      _error = 'Lỗi tạo thực phẩm: ${_parseError(e)}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFood({
    required dynamic id,
    String? name,
    dynamic categoryId,
    dynamic unitId,
    double? quantity,
    XFile? image,
    dynamic groupId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      Map<String, dynamic> data = {};
      if (name != null) data['name'] = name;
      if (categoryId != null) data['category_id'] = categoryId;
      if (unitId != null) data['unit_id'] = unitId;
      if (quantity != null) data['quantity'] = quantity;

      FormData formData = FormData.fromMap(data);

      if (image != null) {
        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name.isEmpty ? 'food_image.jpg' : image.name,
          ),
        ));
      }

      final response = await _apiClient.dio.put(ApiConstants.foodDetail(id), data: formData);
      
      // Refresh in background to return quickly
      if (groupId != null) {
        fetchFoodsInGroup(groupId);
      } else {
        fetchFoods();
      }
      return response.data;
    } catch (e) {
      _error = 'Lỗi cập nhật thực phẩm: ${_parseError(e)}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteFood(dynamic id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.dio.delete(ApiConstants.foodDetail(id));
    } catch (e) {
      _error = 'Lỗi xóa thực phẩm: ${_parseError(e)}';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
