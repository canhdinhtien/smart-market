class ApiConstants {
  static const String baseUrl = "https://smart-market-ykj4.onrender.com";

  // Auth
  static const String register = "/api/users";
  static const String getProfile = '/api/users';
  static const String deleteAccount = '/api/users';
  static const String updateProfile = '/api/users';
  static const String login = "/api/users/login";
  static const String logout = '/api/users/logout';
  static const String sendVerificationCode =
      '/api/users/send-verification-code';
  static const String verifyEmail = '/api/users/verify-email';
  static const String changePassword = '/api/users/change-password';
  static const String forgotPassword = '/api/users/forgot-password';
  static const String resetPassword = '/api/users/reset-password';
  static const String refreshToken = '/api/users/refresh-token';
  static const String allUsers = '/api/users/all';
  static String userRole(dynamic id) => '/api/users/$id/role';
  static String userDetail(dynamic id) => '/api/users/$id';

  // Group
  static const String groups = '/api/groups';
  static const String group = '/api/groups';
  static String groupMembers(dynamic id) => '/api/groups/$id/members';
  static String groupMember(dynamic groupId, dynamic userId) =>
      '/api/groups/$groupId/members/$userId';
  static String searchUsers(String query) => '/api/users/search?q=$query';

  // Notifications
  static const String registerDevice = '/api/notifications/register-fcm';

  // Fridge
  static const String fridge = '/api/fridge';
  static String fridgeDetail(dynamic id) => '/api/fridge/$id';

  // Shopping
  static const String shopping = '/api/shopping';
  static String shoppingDetail(dynamic id) => '/api/shopping/$id';
  static String shoppingTasks(dynamic id) => '/api/shopping/$id/tasks';
  static String shoppingTaskDetail(dynamic taskId) =>
      '/api/shopping/tasks/$taskId';

  // Meal
  static const String meals = '/api/meals';
  static String mealsByGroup(dynamic groupId) => '/api/meals/$groupId';
  static String mealDetail(dynamic id) => '/api/meals/$id';

  // Recipe
  static const String recipes = '/api/recipes';
  static String recipeDetail(dynamic id) => '/api/recipes/$id';
  static const String recipeRecommendations = '/api/recipes/recommendations';

  // Admin
  static const String adminCategory = '/api/admin/category';
  static const String adminUnit = '/api/admin/unit';
  static const String food = '/api/food';
  static String foodsInGroup(dynamic groupId) => '/api/food?group_id=$groupId';
  static String foodDetail(dynamic id) => '/api/food/$id';
  static const String foodCategories = '/api/food/categories';
  static const String foodUnits = '/api/food/units';
  static const String categories = '/api/categories';
  static const String units = '/api/units';

  // Consumption
  static const String myConsumptionStats = '/api/consumptions/my-stats';
  static String groupConsumptionStats(dynamic groupId) =>
      '/api/consumptions/group/$groupId/stats';
  static const String allConsumptionStats = '/api/consumptions/stats';

  static const String adminLogs = '/api/logs';
}
