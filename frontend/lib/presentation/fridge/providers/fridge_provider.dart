import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FridgeProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<dynamic> _items = [];
  bool _isLoading = false;
  String? _error;
  
  // Pagination state
  int _totalItems = 0;
  int _currentPage = 1;
  int _totalPages = 1;

  FridgeProvider(this._apiClient);

  List<dynamic> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get totalItems => _totalItems;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  void clearState() {
    _items = [];
    _isLoading = false;
    _error = null;
    _totalItems = 0;
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
      return 'Lỗi Server (${e.response?.statusCode})';
    }
    return e.toString();
  }

  Future<void> fetchItems(dynamic groupId, {int page = 1, String? name}) async {
    if (groupId == null) return;
    _isLoading = true;
    _error = null;
    // Don't clear items on refresh to prevent flickering
    // if (page == 1) _items = []; 
    notifyListeners();

    try {
      String url = '${ApiConstants.fridge}?group_id=$groupId&page=$page';
      if (name != null && name.isNotEmpty) url += '&name=$name';

      final response = await _apiClient.dio.get(url);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) {
          final List<dynamic> fetchedItems = data['items'] ?? [];
          if (page == 1) {
            _items = fetchedItems;
          } else {
            _items.addAll(fetchedItems);
          }
          _totalItems = data['total'] ?? _items.length;
          _currentPage = data['page'] ?? page;
          _totalPages = data['totalPages'] ?? 1;
        } else {
          _items = List<dynamic>.from(data);
          _totalItems = _items.length;
        }
      }
    } catch (e) {
      _error = 'Lỗi tải dữ liệu tủ lạnh: ${_parseError(e)}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem({
    required dynamic foodId,
    required dynamic groupId,
    required double quantity,
    required String useWithin,
    String? note,
  }) async {
    try {
      int useWithinDays = 0;
      try {
        final expiry = DateTime.parse(useWithin);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final target = DateTime(expiry.year, expiry.month, expiry.day);
        useWithinDays = target.difference(today).inDays;
        if (useWithinDays < 0) useWithinDays = 0;
      } catch (_) {}

      await _apiClient.dio.post(ApiConstants.fridge, data: {
        'food_id': foodId,
        'group_id': groupId,
        'quantity': quantity,
        'use_within': useWithin,
        'use_within_days': useWithinDays,
        'note': note,
      });
      
      // Fetch to get full data with relations (Food, Unit, etc)
      await fetchItems(groupId);
    } catch (e) {
      _error = 'Lỗi thêm vào tủ lạnh: ${_parseError(e)}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateItem({
    required dynamic id,
    dynamic foodId,
    dynamic groupId,
    double? quantity,
    String? useWithin,
    String? note,
  }) async {
    try {
      Map<String, dynamic> data = {};
      if (foodId != null) data['food_id'] = foodId;
      if (groupId != null) data['group_id'] = groupId;
      if (quantity != null) data['quantity'] = quantity;
      if (useWithin != null) {
        data['use_within'] = useWithin;
        try {
          final expiry = DateTime.parse(useWithin);
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final target = DateTime(expiry.year, expiry.month, expiry.day);
          int days = target.difference(today).inDays;
          data['use_within_days'] = days < 0 ? 0 : days;
        } catch (_) {}
      }
      if (note != null) data['note'] = note;

      await _apiClient.dio.put(ApiConstants.fridgeDetail(id), data: data);
      
      // Fetch to get full data with relations
      if (groupId != null) {
        await fetchItems(groupId);
      }
    } catch (e) {
      _error = 'Lỗi cập nhật tủ lạnh: ${_parseError(e)}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteItem(dynamic id, dynamic groupId) async {
    try {
      await _apiClient.dio.delete(ApiConstants.fridgeDetail(id));
      
      // Remove item from local state instead of fetching
      _items.removeWhere((item) => item['id'].toString() == id.toString());
      _totalItems--;
      notifyListeners();
    } catch (e) {
      _error = 'Lỗi xóa khỏi tủ lạnh: ${_parseError(e)}';
      notifyListeners();
      rethrow;
    }
  }
}
