import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/cons.dart';
import 'features/authentication/view/login_page.dart';
import 'features/authentication/view_model/authentication_view_model.dart';
import 'features/health_recs/view/dashboard_screen.dart';
import 'features/health_recs/view/recs_adding_screen.dart';
import 'features/health_recs/view/health_recs_list.dart';
import 'features/health_recs/view_model/health_recs_view_model.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => HealthRecordViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Health App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 1),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontSize: 16),
            titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/records': (context) => const HealthRecordListScreen(),
          '/add-record': (context) => const AddRecordScreen(),
        },
        builder: (context, child) {
          // provide global text scaling limits etc. if desired
          return child!;
        },
      ),
    );
  }
}
