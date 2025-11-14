// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:iwms_citizen_app/core/di.dart';
import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/logic/auth/auth_state.dart';
import 'package:iwms_citizen_app/logic/vehicle_tracking/vehicle_bloc.dart';

// --- Import all your screens ---
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/splashscreen.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_data_screen.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_home_page.dart';
import 'package:iwms_citizen_app/presentation/user_selection/user_selection_screen.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/auth_intro.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/login.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/register.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/chatbot.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/home.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/calender.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/track_waste.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/driver_details.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/map.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/profile.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/personal_map.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/alloted_vehicle_map.dart';
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/grievance_chat.dart';
import 'package:iwms_citizen_app/modules/module3_operator/presentation/screens/operator_login_screen.dart';

// --- Define static route paths ---
class AppRoutePaths {
  static const String splash = '/';
  static const String selectUser = '/select-user';
  static const String citizenAuthIntro = '/citizen/auth';
  static const String citizenLogin = '/citizen/login';
  static const String citizenRegister = '/citizen/register';
  static const String citizenHome = '/citizen/home';
  static const String citizenWelcome = '/citizen/welcome';
  static const String citizenHistory = '/citizen/history';
  static const String citizenTrack = '/citizen/track';
  static const String citizenDriverDetails = '/citizen/driver-details';
  static const String citizenMap = '/citizen/map';
  static const String citizenPersonalMap = '/citizen/personal-map';
  static const String citizenAllotedVehicleMap = '/citizen/alloted-vehicle-map';
  static const String citizenGrievanceChat = '/citizen/grievance-chat';
  static const String citizenProfile = '/citizen/profile';
  static const String citizenChatbot = '/citizen/chatbot';
  static const String operatorLogin = '/operator/login';
}

// --- The App Router ---
class AppRouter {
  final AuthBloc authBloc;
  final RouteObserver<PageRoute> routeObserver;
  late final GoRouter router;
  late final List<RouteBase> _routes;

  AppRouter({
    required this.authBloc,
    required this.routeObserver,
    required Listenable refreshListenable,
  }) {
    _routes = [
      GoRoute(
        path: AppRoutePaths.splash,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.selectUser,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const UserSelectionScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.operatorLogin,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const OperatorLoginScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenAuthIntro,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const CitizenAuthIntroScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenLogin,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const LoginScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenRegister,
        pageBuilder: (context, state) {
          return _buildTransitionPage(
            state,
            const RegisterScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.citizenWelcome,
        pageBuilder: (context, state) {
          final authState = authBloc.state;
          String userName = (authState is AuthStateAuthenticated)
              ? authState.userName ?? "Citizen"
              : "Citizen";
          return _buildTransitionPage(
            state,
            HomeScreen(userName: userName),
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.citizenHome,
        pageBuilder: (context, state) {
          final authState = authBloc.state;
          String userName = (authState is AuthStateAuthenticated)
              ? authState.userName ?? "Citizen"
              : "Citizen";
          return _buildTransitionPage(
            state,
            BlocProvider(
              create: (_) => getIt<VehicleBloc>(),
              child: CitizenDashboard(userName: userName),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.citizenHistory,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const CalendarScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenTrack,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, TrackWasteScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenGrievanceChat,
        pageBuilder: (context, state) =>
            _buildTransitionPage(state, const GrievanceChatScreen()),
      ),
      GoRoute(
        path: AppRoutePaths.citizenDriverDetails,
        pageBuilder: (context, state) {
          return _buildTransitionPage(
            state,
            const DriverDetailsScreen(
              driverName: 'Rajesh Kumar',
              vehicleNumber: 'TN 01 AB 1234',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutePaths.citizenProfile,
        pageBuilder: (context, state) {
          final authState = authBloc.state;
          String userName = (authState is AuthStateAuthenticated)
              ? authState.userName ?? "Citizen"
              : "Citizen";
          return _buildTransitionPage(
            state,
            ProfileScreen(userName: userName),
          );
        },
      ),
      // GoRoute(
      //   path: AppRoutePaths.citizenChatbot,
      //   pageBuilder: (context, state) =>
      //       _buildTransitionPage(state, const ChatBotScreen()),
      // ),
      GoRoute(
        name: 'citizenMap',
        path: AppRoutePaths.citizenMap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _buildTransitionPage(
            state,
            MapScreen(
              driverName: data['driverName'],
              vehicleNumber: data['vehicleNumber'],
            ),
          );
        },
      ),
      GoRoute(
        name: 'citizenAllotedVehicleMap',
        path: AppRoutePaths.citizenAllotedVehicleMap,
        pageBuilder: (context, state) {
          return _buildTransitionPage(
            state,
            const CitizenAllotedVehicleMapScreen(),
          );
        },
      ),
      GoRoute(
        name: 'citizenPersonalMap',
        path: AppRoutePaths.citizenPersonalMap,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _buildTransitionPage(
            state,
            CitizenPersonalMapScreen(
              vehicleId: data['vehicleId'] as String?,
              vehicleNumber: data['vehicleNumber'] as String?,
              siteName: data['siteName'] as String?,
            ),
          );
        },
      ),
          GoRoute(
      path: '/operator-home',
      builder: (context, state) => const OperatorHomePage(),
    ),
    GoRoute(
  path: '/operator-data',
  pageBuilder: (context, state) {
    final data = state.extra as Map<String, dynamic>;
    return CustomTransitionPage(
      key: state.pageKey,
      child: OperatorDataScreen(
        customerId: data['customerId'],
        customerName: data['customerName'],
        contactNo: data['contactNo'],
        latitude: data['latitude'],
        longitude: data['longitude'],
      ),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  },
),

    ];

    router = GoRouter(
      routes: _routes,
      initialLocation: AppRoutePaths.splash,
      debugLogDiagnostics: true,
      redirect: _redirect,
      refreshListenable: refreshListenable,
      observers: [routeObserver],
    );
  }

  // --- Redirect Logic ---
  String? _redirect(BuildContext context, GoRouterState state) {
    final authState = authBloc.state;
    final location = state.matchedLocation;
    final onSplash = location == AppRoutePaths.splash;

    // --- THIS IS THE FIX ---
    // 1. While app is initializing OR a login is in progress, stay put.
    if (authState is AuthStateInitial || authState is AuthStateLoading) {
      return null;
    }
    // --- END FIX ---

    final isLoggingIn = (location == AppRoutePaths.citizenLogin ||
        location == AppRoutePaths.citizenRegister ||
        location == AppRoutePaths.citizenAuthIntro ||
        location == AppRoutePaths.selectUser ||
        location == AppRoutePaths.operatorLogin);

    // 2. If user is authenticated
    if (authState is AuthStateAuthenticated) {
      if (isLoggingIn || onSplash) {
        if (authState.role == UserRole.citizen) {
          return AppRoutePaths.citizenHome;
        }
        // Fallback for any other authenticated role
        return AppRoutePaths.citizenHome;
      }
      return null;
    }

    // 3. If user is UNauthenticated
    if (authState is AuthStateUnauthenticated ||
        authState is AuthStateFailure) {
      if (onSplash) {
        return AppRoutePaths.selectUser;
      }
      if (isLoggingIn) {
        return null;
      }
      return AppRoutePaths.selectUser;
    }

    return null;
  }

  CustomTransitionPage<void> _buildTransitionPage(
      GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      transitionsBuilder:
          (context, animation, secondaryAnimation, transitionChild) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0.9, 0),
          end: Offset.zero,
        ).animate(curvedAnimation);
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: transitionChild,
          ),
        );
      },
    );
  }
}
