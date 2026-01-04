import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/network/api_client.dart';
import 'presentation/auth/providers/auth_provider.dart';
import 'presentation/family_group/providers/group_provider.dart';
import 'presentation/fridge/providers/fridge_provider.dart';
import 'presentation/shopping/providers/shopping_provider.dart';
import 'presentation/meal_plan/providers/meal_provider.dart';
import 'presentation/recipe/providers/recipe_provider.dart';
import 'presentation/profile/providers/profile_provider.dart';
import 'presentation/admin/providers/admin_provider.dart';
import 'presentation/food/providers/food_provider.dart';
import 'presentation/consumption/providers/consumption_provider.dart';
import 'presentation/home/providers/notification_provider.dart';
import 'presentation/auth/screens/welcome_screen.dart';
import 'presentation/auth/screens/login_screen.dart';
import 'presentation/auth/screens/register_screen.dart';
import 'presentation/home/screens/home_screen.dart';
import 'presentation/family_group/screens/group_screen.dart';
import 'presentation/fridge/screens/fridge_screen.dart';
import 'presentation/shopping/screens/shopping_list_screen.dart';
import 'presentation/meal_plan/screens/meal_plan_screen.dart';
import 'presentation/recipe/screens/recipe_list_screen.dart';
import 'presentation/consumption/screens/consumption_screen.dart';
import 'presentation/profile/screens/profile_screen.dart';
import 'presentation/admin/screens/admin_screen.dart';
import 'presentation/home/screens/notification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase safely
  try {
    // We use a late initialization or check for options to prevent crash if file is missing
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase Initialized successfully');
  } catch (e) {
    print('Firebase Initialization skipped or failed: $e');
    print('Note: This is expected if firebase_options.dart is missing.');
  }

  // Initialize Notification Service
  final notificationService = NotificationService();
  try {
    await notificationService.initialize();
  } catch (e) {
    print('Notification Init Error: $e');
  }
  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient(prefs);

  final authProvider = AuthProvider(apiClient, prefs);
  apiClient.onUnauthorized = authProvider.handleUnauthorized;
  apiClient.onTokenRefreshed = authProvider.updateToken;

  // Instantiate all providers to enable cross-provider communication for cleanup
  final groupProvider = GroupProvider(apiClient);
  final fridgeProvider = FridgeProvider(apiClient);
  final shoppingProvider = ShoppingProvider(apiClient);
  final mealProvider = MealProvider(apiClient);
  final recipeProvider = RecipeProvider(apiClient);
  final profileProvider = ProfileProvider(apiClient, authProvider: authProvider);
  final adminProvider = AdminProvider(apiClient);
  final foodProvider = FoodProvider(apiClient);
  final consumptionProvider = ConsumptionProvider(apiClient);
  final notificationProvider = NotificationProvider(apiClient);

  // Set up logical cleanup on logout
  authProvider.onLogout = () {
    groupProvider.clearState();
    fridgeProvider.clearState();
    shoppingProvider.clearState();
    mealProvider.clearState();
    recipeProvider.clearState();
    profileProvider.clearState();
    adminProvider.clearState();
    foodProvider.clearState();
    consumptionProvider.clearState();
    notificationProvider.clearState();
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: groupProvider),
        ChangeNotifierProvider.value(value: fridgeProvider),
        ChangeNotifierProvider.value(value: shoppingProvider),
        ChangeNotifierProvider.value(value: mealProvider),
        ChangeNotifierProvider.value(value: recipeProvider),
        ChangeNotifierProvider.value(value: profileProvider),
        ChangeNotifierProvider.value(value: adminProvider),
        ChangeNotifierProvider.value(value: foodProvider),
        ChangeNotifierProvider.value(value: consumptionProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đi Chợ Tiện Lợi',
      theme: AppTheme.theme,
      home: const AuthWrapper(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/group': (context) => const GroupScreen(),
        '/fridge': (context) => const FridgeScreen(),
        '/shopping': (context) => const ShoppingListScreen(),
        '/meal-plan': (context) => const MealPlanScreen(),
        '/recipe': (context) => const RecipeListScreen(),
        '/consumption': (context) => const ConsumptionScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/admin': (context) => const AdminScreen(),
        '/notification': (context) => const NotificationScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Debug: Print current auth state
        print('AuthWrapper rebuild - Status: ${auth.status}, isAdmin: ${auth.isAdmin}, isLoading: ${auth.isLoading}');
        
        // Show loading if auth is loading (e.g., during login)
        if (auth.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        switch (auth.status) {
          case AuthStatus.authenticated:
            final screen = auth.isAdmin ? const AdminScreen() : const HomeScreen();
            print('Navigating to: ${auth.isAdmin ? "AdminScreen" : "HomeScreen"}');
            return screen;
          case AuthStatus.unauthenticated:
            return const WelcomeScreen();
          case AuthStatus.unknown:
          default:
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
      },
    );
  }
}
