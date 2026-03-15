import 'package:flutter/foundation.dart';

@immutable
class EntitlementsState {
  final bool isPro;

  const EntitlementsState({required this.isPro});

  EntitlementsState copyWith({bool? isPro}) {
    return EntitlementsState(isPro: isPro ?? this.isPro);
  }

  static const EntitlementsState initial = EntitlementsState(isPro: false);
}

