import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:logic_canvas/data/services/subscription_service.dart';
import 'entitlements_state.dart';

@injectable
class EntitlementsCubit extends Cubit<EntitlementsState> {
  final SubscriptionService _subscriptionService;
  StreamSubscription? _subscription;

  EntitlementsCubit(this._subscriptionService) : super(EntitlementsState.initial) {
    _init();
  }

  Future<void> _init() async {
    // 1. Initialize SDK
    await _subscriptionService.initialize();
    
    // 2. Initial check & Fetch offerings
    emit(state.copyWith(isLoading: true));
    final result = await Future.wait([
      _subscriptionService.isSubscribed(),
      _subscriptionService.getOfferings(),
    ]);

    final isSubscribed = result[0] as bool;
    final offerings = result[1] as Offerings?;

    emit(state.copyWith(
      isSubscribed: isSubscribed,
      offerings: offerings,
      isLoading: false,
      isInitialized: true,
    ));

    // 3. Listen for updates (purchases/restores happening while app is open)
    _subscription = _subscriptionService.subscriptionStatusStream.listen((isSubscribed) {
      emit(state.copyWith(isSubscribed: isSubscribed));
    });
  }

  Future<void> purchasePackage(Package package) async {
    emit(state.copyWith(isLoading: true));
    await _subscriptionService.purchasePackage(package);
    emit(state.copyWith(isLoading: false));
  }

  Future<void> restore() async {
    emit(state.copyWith(isLoading: true));
    await _subscriptionService.restorePurchases();
    emit(state.copyWith(isLoading: false));
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
