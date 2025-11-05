// This is a basic Flutter widget test.
import 'package:flutter_test/flutter_test.dart';
import 'package:iwms_citizen_app/core/di.dart';
import 'package:iwms_citizen_app/logic/auth/auth_bloc.dart';
import 'package:iwms_citizen_app/router/app_router.dart';
import 'package:iwms_citizen_app/router/go_router_refresh_stream.dart';
import 'package:iwms_citizen_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iwms_citizen_app/router/route_observer.dart';

// --- FIX: Import the SplashScreen ---
import 'package:iwms_citizen_app/modules/module1_citizen/citizen/splashscreen.dart';
// --- END FIX ---

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 1. Mock SharedPreferences
    SharedPreferences.setMockInitialValues({});

    // 2. Run the real setupDI
    await setupDI();

    // 3. Get the BLoC and create the router, just like in main.dart
    final authBloc = getIt<AuthBloc>();
    final appRouter = AppRouter(
      authBloc: authBloc,
      routeObserver: routeObserver,
      refreshListenable: GoRouterRefreshStream(authBloc.stream),
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(appRouter: appRouter.router, authBloc: authBloc));

    // Verify that the splash screen is shown
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}

