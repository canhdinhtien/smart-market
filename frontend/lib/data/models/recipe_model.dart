class Recipe {
  final int? id;
  final String name;
  final String? description;
  final String? instructions;
  final int? groupId;
  final List<RecipeIngredient>? ingredients;
  final double? matchPercentage;
  final int? matchedIngredientsCount;
  final int? missingIngredientsCount;
  final List<MissingIngredient>? missingIngredients;
  final String? imageUrl;

  Recipe({
    this.id,
    required this.name,
    this.description,
    this.instructions,
    this.groupId,
    this.ingredients,
    this.matchPercentage,
    this.matchedIngredientsCount,
    this.missingIngredientsCount,
    this.missingIngredients,
    this.imageUrl,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      instructions: json['instructions'],
      groupId: json['group_id'],
      ingredients: (json['RecipeIngredients'] ?? json['ingredients']) != null
          ? ((json['RecipeIngredients'] ?? json['ingredients']) as List)
              .map((i) => RecipeIngredient.fromJson(i))
              .toList()
          : [],
      matchPercentage: json['matchPercentage'] != null 
          ? (json['matchPercentage'] is int ? (json['matchPercentage'] as int).toDouble() : json['matchPercentage'])
          : null,
      matchedIngredientsCount: json['matchedIngredientsCount'],
      missingIngredientsCount: json['missingIngredientsCount'],
      missingIngredients: json['missingIngredients'] != null
          ? (json['missingIngredients'] as List).map((i) => MissingIngredient.fromJson(i)).toList()
          : null,
      imageUrl: json['image_url'] ?? json['RecipeImage']?['url'] ?? json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'instructions': instructions,
      'group_id': groupId,
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      'image_url': imageUrl,
    };
  }
}

class RecipeIngredient {
  final int? id;
  final int? recipeId;
  final int? foodId;
  final double? quantity;
  final int? unitId;
  final String? foodName;
  final String? unitName;
  final String? foodImage;
  final bool? inFridge;

  RecipeIngredient({
    this.id,
    this.recipeId,
    this.foodId,
    this.quantity,
    this.unitId,
    this.foodName,
    this.unitName,
    this.foodImage,
    this.inFridge,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      id: json['id'],
      recipeId: json['recipe_id'] ?? json['recipeId'] ?? json['RecipeId'],
      foodId: json['food_id'] ?? json['foodId'] ?? json['FoodId'] ?? json['Food']?['id'],
      quantity: json['quantity'] != null 
          ? (json['quantity'] is int ? (json['quantity'] as int).toDouble() : json['quantity']) 
          : null,
      unitId: json['unit_id'] ?? json['unitId'] ?? json['UnitId'] ?? json['Unit']?['id'] ?? json['Food']?['unit_id'] ?? json['Food']?['unitId'],
      foodName: json['Food'] != null ? json['Food']['name'] : (json['food_name'] ?? json['foodName']),
      foodImage: json['Food'] != null ? json['Food']['image_url'] : (json['food_image'] ?? json['foodImage']),
      unitName: json['Unit'] != null ? json['Unit']['name'] : (json['unit_name'] ?? json['unitName']),
      inFridge: json['in_fridge'] ?? json['inFridge'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'foodId': foodId,
      'quantity': quantity,
      'unit_id': unitId,
      'unitId': unitId,
    };
  }
}

class MissingIngredient {
  final int foodId;
  final String name;
  final String? imageUrl;
  final double? quantity;
  final String? unit;

  MissingIngredient({
    required this.foodId,
    required this.name,
    this.imageUrl,
    this.quantity,
    this.unit,
  });

  factory MissingIngredient.fromJson(Map<String, dynamic> json) {
    return MissingIngredient(
      foodId: json['food_id'],
      name: json['name'],
      imageUrl: json['image_url'],
      quantity: json['quantity'] != null 
          ? (json['quantity'] is int ? (json['quantity'] as int).toDouble() : json['quantity']) 
          : null,
      unit: json['unit'],
    );
  }
}
