import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class ShoppingProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<dynamic> _shoppingLists = [];
  List<dynamic> _tasks = [];
  bool _isLoading = false;
  String? _error;

  ShoppingProvider(this._apiClient);

  List<dynamic> get shoppingLists => _shoppingLists;
  List<dynamic> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void clearState() {
    _shoppingLists = [];
    _tasks = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> fetchShoppingLists({dynamic groupId}) async {
    _isLoading = true;
    _error = null;
    _shoppingLists = []; // Clear old data to prevent stale UI during group switch
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {};
      if (groupId != null) {
        // Force to string as per documentation "group_id (string, required)"
        queryParams['group_id'] = groupId.toString();
      }

      final response = await _apiClient.dio.get(
        ApiConstants.shopping,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic>? fetchedLists;
        
        if (data is List) {
          fetchedLists = data;
        } else if (data is Map) {
          fetchedLists = data['lists'] ?? data['data'] ?? data['results'] ?? data['shoppingLists'];
          
          // Double check if it's nested in data['data']
          if (fetchedLists == null && data['data'] is Map) {
            final innerData = data['data'] as Map;
            fetchedLists = innerData['lists'] ?? innerData['shoppingLists'] ?? innerData['data'];
          }
          
          // If still null, check if any value is a list (fallback)
          if (fetchedLists == null) {
            for (var value in data.values) {
              if (value is List) {
                fetchedLists = value;
                break;
              }
            }
          }
        }
        
        // Filter out soft-deleted items (check both deleted_at and is_deleted flag)
        _shoppingLists = (fetchedLists ?? []).where((list) => 
          list['deleted_at'] == null && list['is_deleted'] != true
        ).toList();
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải danh sách đi chợ';
      _shoppingLists = []; 
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      _shoppingLists = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createShoppingList({
    required String name,
    required dynamic groupId,
    String? note,
    String? date,
  }) async {
    try {
      final gId = int.tryParse(groupId.toString()) ?? groupId;
      await _apiClient.dio.post(ApiConstants.shopping, data: {
        'name': name,
        'group_id': gId,
        'note': note,
        'nite': note, // Support the potential 'nite' column
        'date': date,
      });
      await fetchShoppingLists(groupId: groupId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addTask(dynamic listId, Map<String, dynamic> taskData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.shoppingTasks(listId.toString()), 
        data: taskData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final newTask = response.data;
        
        // Update current tasks list if it belongs to this list
        _tasks.add(newTask);
        
        // Update shopping list progress
        final listIndex = _shoppingLists.indexWhere((l) => l['id'].toString() == listId.toString());
        if (listIndex != -1) {
          final list = Map<String, dynamic>.from(_shoppingLists[listIndex]);
          final tasks = List<dynamic>.from(list['shopping_list_tasks'] ?? []);
          tasks.add(newTask);
          list['shopping_list_tasks'] = tasks;
          _shoppingLists[listIndex] = list;
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTask(dynamic taskId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.put(ApiConstants.shoppingTaskDetail(taskId.toString()), data: data);
      
      if (response.statusCode == 200) {
        final updatedData = response.data;
        
        // Update current tasks list
        final taskIndex = _tasks.indexWhere((t) => t['id'].toString() == taskId.toString());
        if (taskIndex != -1) {
          _tasks[taskIndex] = <String, dynamic>{
            ...Map<String, dynamic>.from(_tasks[taskIndex]),
            ...Map<String, dynamic>.from(updatedData),
          };
        }
        
        // Update shopping list progress
        for (int i = 0; i < _shoppingLists.length; i++) {
          final list = Map<String, dynamic>.from(_shoppingLists[i]);
          final listTasks = List<dynamic>.from(list['shopping_list_tasks'] ?? []);
          final idx = listTasks.indexWhere((t) => t['id'].toString() == taskId.toString());
          if (idx != -1) {
            listTasks[idx] = <String, dynamic>{
              ...Map<String, dynamic>.from(listTasks[idx]),
              ...Map<String, dynamic>.from(updatedData),
            };
            list['shopping_list_tasks'] = listTasks;
            _shoppingLists[i] = list;
            break;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(dynamic taskId) async {
    try {
      await _apiClient.dio.delete(ApiConstants.shoppingTaskDetail(taskId.toString()));
      
      // Update current tasks list
      _tasks.removeWhere((t) => t['id'].toString() == taskId.toString());
      
      // Update shopping list progress
      for (int i = 0; i < _shoppingLists.length; i++) {
        final list = Map<String, dynamic>.from(_shoppingLists[i]);
        final listTasks = List<dynamic>.from(list['shopping_list_tasks'] ?? []);
        final idx = listTasks.indexWhere((t) => t['id'].toString() == taskId.toString());
        if (idx != -1) {
          listTasks.removeAt(idx);
          list['shopping_list_tasks'] = listTasks;
          _shoppingLists[i] = list;
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateShoppingList(dynamic id, Map<String, dynamic> data) async {
    try {
      await _apiClient.dio.put(ApiConstants.shoppingDetail(id.toString()), data: data);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteShoppingList(dynamic id) async {
    try {
      await _apiClient.dio.delete(ApiConstants.shoppingDetail(id.toString()));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchTasks(dynamic listId) async {
    _isLoading = true;
    _error = null;
    _tasks = []; // Clear current tasks to avoid stale UI while loading
    notifyListeners();
    
    try {
      final response = await _apiClient.dio.get(ApiConstants.shoppingDetail(listId.toString()));
      final responseData = response.data;
      
      // Handle both wrapped { data: { ... } } and unwrapped responses
      final data = (responseData is Map && responseData['data'] != null) 
          ? responseData['data'] 
          : responseData;

      if (data != null && data is Map) {
        // Search for task lists in common keys
        final rawTasks = data['shopping_list_tasks'] ?? 
                         data['tasks'] ?? 
                         data['ShoppingListTasks'] ?? 
                         data['items'] ?? 
                         [];
        
        if (rawTasks is List) {
          _tasks = rawTasks.where((t) => 
            t['deleted_at'] == null && t['is_deleted'] != true
          ).toList();
        }
      } else if (data is List) {
        // Case where the endpoint returns a list of tasks directly
        _tasks = data.where((t) => 
          t['deleted_at'] == null && t['is_deleted'] != true
        ).toList();
      }
    } catch (e) {
      _error = 'Lỗi tải danh mục: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getShoppingListDetail(dynamic id) async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.shoppingDetail(id.toString()));
      final responseData = response.data;
      
      // Determine the actual content map
      final Map<String, dynamic> dataMap = (responseData is Map && responseData['data'] != null)
          ? Map<String, dynamic>.from(responseData['data'])
          : (responseData is Map ? Map<String, dynamic>.from(responseData) : {});

      // Centralized filtering of soft-deleted tasks within common keys
      for (var key in ['shopping_list_tasks', 'ShoppingListTasks', 'tasks', 'items']) {
        if (dataMap[key] != null && dataMap[key] is List) {
          dataMap[key] = (dataMap[key] as List).where((t) => 
            t['deleted_at'] == null && t['is_deleted'] != true
          ).toList();
        }
      }
      
      return {'data': dataMap}; // Maintain legacy wrapper expectations if any
    } catch (e) {
      rethrow;
    }
  }
}
