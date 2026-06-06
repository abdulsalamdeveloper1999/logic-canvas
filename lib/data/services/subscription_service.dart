import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:injectable/injectable.dart';

import 'package:logic_canvas/core/env.dart';

abstract class SubscriptionService {
  Future<void> initialize();
  Future<bool> isSubscribed();
  Future<Offerings?> getOfferings();
  Future<CustomerInfo?> purchasePackage(Package package);
  Future<CustomerInfo?> restorePurchases();
  Stream<bool> get subscriptionStatusStream;
}

@LazySingleton(as: SubscriptionService)
class RevenueCatSubscriptionService implements SubscriptionService {
  static final _apiKey = Env.revenueCatApiKey;
  static const _entitlementId = 'pro';

  @override
  Future<void> initialize() async {
    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    late PurchasesConfiguration configuration;
    if (Platform.isAndroid || Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKey);
    } else {
      // Handle other platforms if necessary
      return;
    }

    // RevenueCat automatically handles anonymous app user IDs.
    // This is perfect for apps without their own authentication system.
    await Purchases.configure(configuration);
  }

  @override
  Future<bool> isSubscribed() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return _checkEntitlement(customerInfo);
    } catch (e) {
      debugPrint('Error checking subscription: $e');
      return false;
    }
  }

  @override
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (kDebugMode) {
        debugPrint('DEBUG: Fetching offerings...');
        if (offerings.current == null) {
          debugPrint('DEBUG: Current offering is NULL! Check RC Dashboard.');
        } else {
          debugPrint(
            'DEBUG: Current offering: ${offerings.current?.identifier}',
          );
          debugPrint(
            'DEBUG: Available packages count: ${offerings.current?.availablePackages.length}',
          );
          for (var p in offerings.current?.availablePackages ?? []) {
            debugPrint(
              'DEBUG:   - Package: ${p.identifier} (Product: ${p.storeProduct.identifier})',
            );
          }
        }
      }
      return offerings;
    } catch (e) {
      debugPrint('Error fetching offerings: $e');
      return null;
    }
  }

  @override
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo;
    } catch (e) {
      debugPrint('Error making purchase: $e');
      return null;
    }
  }

  @override
  Future<CustomerInfo?> restorePurchases() async {
    try {
      return await Purchases.restorePurchases();
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return null;
    }
  }

  @override
  Stream<bool> get subscriptionStatusStream {
    // In newer versions, we use Purchases.addCustomerInfoUpdateListener
    // It returns a stream or we use the listener approach.
    // Actually, addCustomerInfoUpdateListener is the correct name but check type.
    final controller = StreamController<bool>();
    Purchases.addCustomerInfoUpdateListener((info) {
      controller.add(_checkEntitlement(info));
    });
    return controller.stream;
  }

  bool _checkEntitlement(CustomerInfo customerInfo) {
    // Check if the specific entitlement is active
    return customerInfo.entitlements.active.containsKey(_entitlementId);
  }
}
