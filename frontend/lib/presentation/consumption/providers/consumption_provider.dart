import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ConsumptionProvider with ChangeNotifier {
  final ApiClient _apiClient;
  
  List<Map<String, dynamic>> _myStats = [];
  List<Map<String, dynamic>> _groupStats = [];
  List<Map<String, dynamic>> _allStats = [];
  
  bool _isLoading = false;
  String? _error;

  ConsumptionProvider(this._apiClient);

  List<Map<String, dynamic>> get myStats => _myStats;
  List<Map<String, dynamic>> get groupStats => _groupStats;
  List<Map<String, dynamic>> get allStats => _allStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearState() {
    _myStats = [];
    _groupStats = [];
    _allStats = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchMyStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.myConsumptionStats);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          _myStats = List<Map<String, dynamic>>.from(data);
        } else {
          _myStats = [];
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải thống kê cá nhân';
    } catch (e) {
      _error = 'Đã xảy ra lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchGroupStats(int groupId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.groupConsumptionStats(groupId),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          _groupStats = List<Map<String, dynamic>>.from(data);
        } else {
          _groupStats = [];
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải thống kê nhóm';
    } catch (e) {
      _error = 'Đã xảy ra lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAllStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(ApiConstants.allConsumptionStats);
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          _allStats = List<Map<String, dynamic>>.from(data);
        } else {
          _allStats = [];
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải thống kê toàn hệ thống';
    } catch (e) {
      _error = 'Đã xảy ra lỗi: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
