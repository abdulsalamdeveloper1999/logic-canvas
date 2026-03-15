import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'entitlements_state.dart';

class EntitlementsCubit extends Cubit<EntitlementsState> {
  static const String _boxName = 'entitlements';
  static const String _keyIsPro = 'isPro';

  EntitlementsCubit() : super(EntitlementsState.initial) {
    _load();
  }

  Future<void> _load() async {
    try {
      final box = await Hive.openBox(_boxName);
      final isPro = box.get(_keyIsPro, defaultValue: false) as bool;
      emit(state.copyWith(isPro: isPro));
    } catch (_) {
      // If entitlements fail to load, default to Free.
      emit(state.copyWith(isPro: false));
    }
  }

  Future<void> setPro(bool value) async {
    emit(state.copyWith(isPro: value));
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_keyIsPro, value);
    } catch (_) {
      // Ignore persistence errors; UI state already updated.
    }
  }
}

