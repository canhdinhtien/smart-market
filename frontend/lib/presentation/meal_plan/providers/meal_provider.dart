import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../data/models/meal_plan_model.dart';
import '../../../data/models/recipe_model.dart';

class MealProvider with ChangeNotifier {
  final ApiClient _apiClient;
  List<MealPlan> _plans = [];
  bool _isLoading = false;
  String? _error;
  String? _createError; // Separate error for create operation

  MealProvider(this._apiClient);

  List<MealPlan> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get createError => _createError;

  void clearState() {
    _plans = [];
    _isLoading = false;
    _error = null;
    _createError = null;
    notifyListeners();
  }

  Future<void> fetchMealPlan({
    required int groupId,
    String? startDate,
    String? endDate,
    int page = 1,
    int limit = 50,
  }) async {
    _isLoading = true;
    _error = null;
    _plans = []; // Clear old data to prevent stale UI during group switch
    notifyListeners();

    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;

      final response = await _apiClient.dio.get(
        ApiConstants.mealsByGroup(groupId),
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> list = data['plans'] ?? [];
        
        // Debug: Print first item to see structure
        if (list.isNotEmpty) {
          print('🔍 DEBUG Meal Plan Data (first item): ${list.first}');
          print('📊 Total items from API: ${list.length}');
        }
        
        // Filter out deleted items and parse
        _plans = list
            .where((e) => 
              e['deleted_at'] == null && 
              e['is_deleted'] != true &&
              // Also check if Recipe or Food is deleted
              (e['Recipe'] == null || (e['Recipe']['deleted_at'] == null && e['Recipe']['is_deleted'] != true)) &&
              (e['Food'] == null || (e['Food']['deleted_at'] == null && e['Food']['is_deleted'] != true))
            )
            .map((e) => MealPlan.fromJson(e))
            .toList();
            
        print('✅ Items after filtering: ${_plans.length}');
        
        // Fetch missing recipe/food details for images
        await _enrichMealPlansWithImages();
        
        if (_plans.isNotEmpty) {
          final firstPlan = _plans.first;
          print('📝 First filtered plan - Recipe: ${firstPlan.recipe?.name}, Food: ${firstPlan.food?['name']}');
          print('🖼️ First plan image - Recipe: ${firstPlan.recipe?.imageUrl}, Food: ${firstPlan.food?['image_url']}');
        }
      }
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể tải kế hoạch ăn uống';
    } catch (e) {
      _error = 'Đã xảy ra lỗi không xác định';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMealPlan(Map<String, dynamic> data) async {
    _isLoading = true;
    _createError = null; // Clear create error, not fetch error
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiConstants.meals,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Refresh or add to list
        return true;
      }
      return false;
    } on DioException catch (e) {
      _createError = e.response?.data['message'] ?? 'Không thể tạo kế hoạch';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMealPlan(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.put(
        ApiConstants.mealDetail(id),
        data: data,
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể cập nhật kế hoạch';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMealPlan(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.delete(ApiConstants.mealDetail(id));
      if (response.statusCode == 200) {
        _plans.removeWhere((p) => p.id == id);
        notifyListeners();
        return true;
      }
      return false;
    } on DioException catch (e) {
      _error = e.response?.data['message'] ?? 'Không thể xóa kế hoạch';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch recipe/food details for meal plans that are missing images
  Future<void> _enrichMealPlansWithImages() async {
    try {
      for (int i = 0; i < _plans.length; i++) {
        final plan = _plans[i];
        
        // Check if recipe exists but missing image
        if (plan.recipeId != null && (plan.recipe?.imageUrl == null || plan.recipe?.imageUrl?.isEmpty == true)) {
          try {
            // Try to get recipe from list endpoint with filter
            final response = await _apiClient.dio.get('${ApiConstants.recipes}?id=${plan.recipeId}');
            if (response.statusCode == 200) {
              final data = response.data;
              // Handle different response structures
              dynamic recipeData;
              if (data is Map && data['recipes'] != null && data['recipes'] is List && (data['recipes'] as List).isNotEmpty) {
                recipeData = (data['recipes'] as List).first;
              } else if (data is Map && data['recipe'] != null) {
                recipeData = data['recipe'];
              } else if (data is List && data.isNotEmpty) {
                recipeData = data.first;
              } else {
                recipeData = data;
              }
              
              if (recipeData != null) {
                // Update the plan with full recipe data
                _plans[i] = MealPlan(
                  id: plan.id,
                  date: plan.date,
                  mealType: plan.mealType,
                  groupId: plan.groupId,
                  recipeId: plan.recipeId,
                  foodId: plan.foodId,
                  isDeleted: plan.isDeleted,
                  recipe: Recipe.fromJson(recipeData),
                  food: plan.food,
                );
                print('🖼️ Enriched recipe ${plan.recipeId} with image: ${recipeData['image_url']}');
              }
            }
          } on DioException catch (e) {
            if (e.response?.statusCode == 404) {
              print('⚠️ Recipe ${plan.recipeId} not found (404) - may have been deleted');
            } else {
              print('⚠️ Failed to fetch recipe ${plan.recipeId}: ${e.message}');
            }
          } catch (e) {
            print('⚠️ Failed to fetch recipe ${plan.recipeId}: $e');
          }
        }
        
        // Check if food exists but missing image
        if (plan.foodId != null && (plan.food?['image_url'] == null || plan.food?['image_url']?.isEmpty == true)) {
          try {
            final response = await _apiClient.dio.get(ApiConstants.foodDetail(plan.foodId!));
            if (response.statusCode == 200) {
              final foodData = response.data['food'] ?? response.data;
              // Update the plan with full food data
              _plans[i] = MealPlan(
                id: plan.id,
                date: plan.date,
                mealType: plan.mealType,
                groupId: plan.groupId,
                recipeId: plan.recipeId,
                foodId: plan.foodId,
                isDeleted: plan.isDeleted,
                recipe: plan.recipe,
                food: foodData,
              );
              print('🖼️ Enriched food ${plan.foodId} with image: ${foodData['image_url']}');
            }
          } catch (e) {
            print('⚠️ Failed to fetch food ${plan.foodId}: $e');
          }
        }
      }
    } catch (e) {
      print('⚠️ Error enriching meal plans: $e');
    }
  }
}
