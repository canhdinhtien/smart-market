import 'recipe_model.dart';

class MealPlan {
  final int? id;
  final String date;
  final String mealType; // sang, trua, toi
  final int groupId;
  final int? recipeId;
  final int? foodId;
  final bool isDeleted;
  final Recipe? recipe;
  final dynamic food; // Can be a Food model if created later, for now dynamic

  MealPlan({
    this.id,
    required this.date,
    required this.mealType,
    required this.groupId,
    this.recipeId,
    this.foodId,
    this.isDeleted = false,
    this.recipe,
    this.food,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    return MealPlan(
      id: json['id'],
      date: json['date'] ?? '',
      mealType: json['meal_type'] ?? '',
      groupId: json['group_id'] ?? 0,
      recipeId: json['recipe_id'],
      foodId: json['food_id'],
      isDeleted: json['is_deleted'] ?? false,
      recipe: json['Recipe'] != null ? Recipe.fromJson(json['Recipe']) : null,
      food: json['Food'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'meal_type': mealType,
      'group_id': groupId,
      'recipe_id': recipeId,
      'food_id': foodId,
    };
  }
}
