import 'dart:async';
import 'package:flutter/material.dart';

/// A [ChangeNotifier] that listens to a [Stream] and notifies listeners
/// when the stream emits a new value.
/// This is used to bridge a BLoC's state stream to GoRouter's
/// refreshListenable, which requires a Listenable.
class GoRouterRefreshStream extends ChangeNotifier {
  /// Creates a [GoRouterRefreshStream] that listens to the given [stream].
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}