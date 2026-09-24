import 'package:flutter/material.dart';
import 'package:listen_b/pages/error_page.dart';
import 'package:listen_b/widgets/transition.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final ValueNotifier<String> globalError = ValueNotifier<String>("");

final ValueNotifier<String> initError = ValueNotifier<String>("");

bool _isWorking = false;

void setError(String message) {
  if (globalError.value == message && _isWorking) return;

  globalError.value = message;
  _isWorking = true;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _isWorking = false;
    final nav = navigatorKey.currentState;
    if (nav == null || nav.canPop()) return;

    nav.push(
      PageRouteBuilder(
        pageBuilder: (context, a, s) => ErrorPage(message: globalError.value),
        transitionsBuilder: transition(),
      ),
    );
  });
}

void setInitError(String message) => initError.value = message;
