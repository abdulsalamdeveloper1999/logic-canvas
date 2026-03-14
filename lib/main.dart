import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart';
import 'package:logic_canvas/presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 BUILD_SYNC_TEST_ALPHA: Code is LIVE');
  await Hive.initFlutter();
  await Hive.openBox<bool>('progress');
  configureDependencies();
  runApp(const LogicCanvasApp());
}

class LogicCanvasApp extends StatelessWidget {
  const LogicCanvasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DrawingCubit>()),
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
        BlocProvider(create: (_) => getIt<ProgressCubit>()),
        BlocProvider(create: (_) => getIt<SelectionCubit>()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'LogicCanvas',
            themeMode: state.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blueAccent,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF0F0F0F),
            ),
            home: const SafeArea(child: HomePage()),
          );
        },
      ),
    );
  }
}
