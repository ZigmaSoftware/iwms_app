// lib/router/route_observer.dart
import 'package:flutter/material.dart';

/// A global RouteObserver that can be used by the [AppRouter]
/// and any screen that needs to listen to navigation events.
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();