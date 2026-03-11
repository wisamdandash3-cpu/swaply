import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

const String _kRevenueCatApiKey = 'test_LSAhqUsgWoUOnbXdKAkXwYLCQCe';

Future<void> initializeRevenueCat() async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  try {
    await Purchases.configure(PurchasesConfiguration(_kRevenueCatApiKey));
    if (kDebugMode) debugPrint('RevenueCat initialized');
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('RevenueCat init failed: $e');
      debugPrint('$st');
    }
  }
}

Future<void> revenueCatLogIn(String userId) async {
  if (!Platform.isIOS && !Platform.isAndroid) return;
  try {
    await Purchases.logIn(userId);
    if (kDebugMode) debugPrint('RevenueCat logIn: $userId');
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('RevenueCat logIn failed: $e');
      debugPrint('$st');
    }
  }
}
