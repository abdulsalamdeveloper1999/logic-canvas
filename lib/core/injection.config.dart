// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:logic_canvas/data/repositories/progress_repository_impl.dart'
    as _i447;
import 'package:logic_canvas/data/services/handwriting_service.dart' as _i818;
import 'package:logic_canvas/data/services/ml_shape_service.dart' as _i134;
import 'package:logic_canvas/domain/repositories/i_progress_repository.dart'
    as _i790;
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart'
    as _i697;
import 'package:logic_canvas/presentation/cubits/progress/progress_cubit.dart'
    as _i123;
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart'
    as _i202;
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart'
    as _i655;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.factory<_i202.SelectionCubit>(() => _i202.SelectionCubit());
    gh.lazySingleton<_i134.MLShapeService>(() => _i134.MLShapeService());
    gh.lazySingleton<_i818.HandwritingRecognitionService>(
      () => _i818.HandwritingRecognitionService(),
    );
    gh.factory<_i697.DrawingCubit>(
      () => _i697.DrawingCubit(
        gh<_i818.HandwritingRecognitionService>(),
        gh<_i134.MLShapeService>(),
      ),
    );
    gh.lazySingleton<_i790.IProgressRepository>(
      () => _i447.ProgressRepositoryImpl(),
    );
    gh.factory<_i655.SettingsCubit>(
      () => _i655.SettingsCubit(
        gh<_i818.HandwritingRecognitionService>(),
        gh<_i134.MLShapeService>(),
      ),
    );
    gh.factory<_i123.ProgressCubit>(
      () => _i123.ProgressCubit(gh<_i790.IProgressRepository>()),
    );
    return this;
  }
}
