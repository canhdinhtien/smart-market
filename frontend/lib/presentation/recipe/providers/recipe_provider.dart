import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../data/models/recipe_model.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/api_constants.dart';

class RecipeProvider with ChangeNotifier {
  final ApiClient _apiClient;

  List<Recipe> _recipes = <Recipe>[];
  List<Recipe> _recommendations = <Recipe>[];
  bool _isLoading = false;
  bool _isRecommendationsLoading = false;
  String? _error;
  String? _recommendationsError;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalItems = 0;

  RecipeProvider(this._apiClient);

  List<Recipe> get recipes => _recipes;
  List<Recipe> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get isRecommendationsLoading => _isRecommendationsLoading;
  String? get error => _error;
  String? get recommendationsError => _recommendationsError;
  
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  
  void clearState() {
    _recipes = <Recipe>[];
    _recommendations = <Recipe>[];
    _error = null;
    _recommendationsError = null;
    _isLoading = false;
    _isRecommendationsLoading = false;
    notifyListeners();
  }

  Future<void> fetchRecipes({
    String? foodId,
    dynamic groupId,
    String? name,
    int page = 1,
    bool isRefresh = false,
  }) async {
    if (isRefresh) {
      _recipes = <Recipe>[];
      page = 1;
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': 20,
      };

      if (foodId != null) queryParams['foodId'] = foodId;
      if (groupId != null) queryParams['group_id'] = groupId;
      if (name != null) queryParams['name'] = name;

      final response = await _apiClient.dio.get(
        ApiConstants.recipes,
        queryParameters: queryParams,
      );

      final result = response.data;
      final List<dynamic> listData = result['recipes'] ?? [];
      final List<Recipe> newRecipes = listData.map((e) => Recipe.fromJson(e)).toList();

      if (isRefresh || page == 1) {
        _recipes = newRecipes;
      } else {
        _recipes.addAll(newRecipes);
      }

      _currentPage = result['page'] ?? page;
      _totalPages = result['totalPages'] ?? 1;
      _totalItems = result['total'] ?? 0;

    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải danh sách món ăn';
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      print('Fetch Recipes Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<bool> createRecipe(Map<String, dynamic> data, {XFile? image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      dynamic requestData;

      if (image != null) {
        // Create a copy to avoid mutating the original data
        final Map<String, dynamic> uploadData = Map.from(data);
        final ingredients = uploadData.remove('ingredients');
        
        final formData = FormData.fromMap(uploadData);
        if (ingredients != null) {
          formData.fields.add(MapEntry('ingredients', jsonEncode(ingredients)));
        }

        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name.isEmpty ? 'recipe_image.jpg' : image.name,
          ),
        ));
        requestData = formData;
      } else {
        requestData = data;
      }

      final response = await _apiClient.dio.post(
        ApiConstants.recipes,
        data: requestData,
      );
      
      final responseData = response.data['data'] ?? response.data;
      final newRecipe = Recipe.fromJson(responseData);
      _recipes.insert(0, newRecipe);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tạo món ăn';
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateRecipe(dynamic id, Map<String, dynamic> data, {XFile? image}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      dynamic requestData;

      if (image != null) {
        // Create a copy to avoid mutating the original data
        final Map<String, dynamic> uploadData = Map.from(data);
        final ingredients = uploadData.remove('ingredients');
        
        final formData = FormData.fromMap(uploadData);
        if (ingredients != null) {
          formData.fields.add(MapEntry('ingredients', jsonEncode(ingredients)));
        }

        final bytes = await image.readAsBytes();
        formData.files.add(MapEntry(
          'image',
          MultipartFile.fromBytes(
            bytes,
            filename: image.name.isEmpty ? 'recipe_image.jpg' : image.name,
          ),
        ));
        requestData = formData;
      } else {
        requestData = data;
      }

      final response = await _apiClient.dio.put(
        ApiConstants.recipeDetail(id),
        data: requestData,
      );
      
      final responseData = response.data['data'] ?? response.data;
      final updatedRecipe = Recipe.fromJson(responseData);
      
      final index = _recipes.indexWhere((r) => r.id == id);
      if (index != -1) {
        _recipes[index] = updatedRecipe;
      }
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể cập nhật món ăn';
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecipe(dynamic id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiClient.dio.delete(ApiConstants.recipeDetail(id));
      _recipes.removeWhere((r) => r.id == id);
      return true;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể xóa món ăn';
      return false;
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Recipe?> getRecipeDetail(dynamic id, {dynamic groupId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.recipeDetail(id),
        queryParameters: groupId != null ? {'group_id': groupId} : null,
      );
      final data = response.data['data'] ?? response.data;
      return Recipe.fromJson(data);
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải chi tiết món ăn';
      return null;
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRecommendations(dynamic groupId) async {
    if (groupId == null) return;
    
    _isRecommendationsLoading = true;
    _recommendationsError = null;
    _recommendations = []; // Clear old data to prevent stale UI during group switch
    notifyListeners();

    try {
      final response = await _apiClient.dio.get(
        ApiConstants.recipeRecommendations,
        queryParameters: {'group_id': groupId.toString()},
      );

      final result = response.data;
      // Handle different response formats
      final dynamic listData = result is List ? result : (result['data'] ?? result['recommendations'] ?? result['recipes'] ?? []);
      
      if (listData is List) {
        _recommendations = listData.map((e) => Recipe.fromJson(e)).toList();
      }

    } on DioException catch (e) {
      _recommendationsError = e.response?.data['message'] ?? 'Không thể tải gợi ý món ăn';
      print('Fetch Recommendations Error: ${e.response?.data}');
    } catch (e) {
      _recommendationsError = 'Đã xảy ra lỗi khi tải gợi ý';
      print('Fetch Recommendations Error: $e');
    } finally {
      _isRecommendationsLoading = false;
      notifyListeners();
    }
  }
}
