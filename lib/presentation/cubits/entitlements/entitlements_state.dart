import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

@immutable
class EntitlementsState {
  final bool isSubscribed;
  final bool isLoading;
  final bool isInitialized;
  final Offerings? offerings;

  const EntitlementsState({
    required this.isSubscribed,
    this.isLoading = false,
    this.isInitialized = false,
    this.offerings,
  });

  EntitlementsState copyWith({
    bool? isSubscribed,
    bool? isLoading,
    bool? isInitialized,
    Offerings? offerings,
  }) {
    return EntitlementsState(
      isSubscribed: isSubscribed ?? this.isSubscribed,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      offerings: offerings ?? this.offerings,
    );
  }

  static const EntitlementsState initial = EntitlementsState(
    isSubscribed: false,
    isLoading: false,
    isInitialized: false,
  );
}
