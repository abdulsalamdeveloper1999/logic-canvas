import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logic_canvas/core/injection.dart';
import 'package:logic_canvas/presentation/cubits/drawing/drawing_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_cubit.dart';
import 'package:logic_canvas/presentation/cubits/settings/settings_state.dart';
import 'package:logic_canvas/presentation/cubits/progress/progress_cubit.dart';
import 'package:logic_canvas/presentation/cubits/selection/selection_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_cubit.dart';
import 'package:logic_canvas/presentation/cubits/entitlements/entitlements_state.dart';
import 'package:logic_canvas/presentation/pages/home/home_page.dart';
import 'package:logic_canvas/presentation/pages/subscription/paywall_page.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'presentation/cubits/drawing/drawing_state.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Custom Error Handling for Release Mode diagnosis
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('CRITICAL_FLUTTER_ERROR: ${details.exception}');
  };

  try {
    debugPrint('📦 Hive: Initializing...');
    await Hive.initFlutter();

    debugPrint('📦 Hive: Opening progress box...');
    await Hive.openBox<bool>('progress');

    debugPrint('📦 Hive: Opening settings box...');
    await Hive.openBox('settings');

    debugPrint('📦 Hive: Opening drawing box...');
    await Hive.openBox('drawing');

    debugPrint('📦 Hive: Opening entitlements box...');
    await Hive.openBox('entitlements');

    debugPrint('📦 Hive: Boxes opened successfully');

    debugPrint('💉 DI: Configuring dependencies...');
    configureDependencies();
    debugPrint('💉 DI: Dependencies configured');

    debugPrint('🚀 App: Running LogicCanvasApp...');
    runApp(const LogicCanvasApp());
  } catch (e) {
    debugPrint('❌ CRITICAL_INIT_ERROR: $e');
    runApp(
      MaterialApp(
        home: Scaffold(body: Center(child: Text('Initialization Error: $e'))),
      ),
    );
  }
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
        BlocProvider(create: (_) => getIt<EntitlementsCubit>()),
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
            home: BlocListener<EntitlementsCubit, EntitlementsState>(
              listenWhen: (prev, curr) =>
                  curr.isInitialized && !prev.isInitialized,
              listener: (context, state) {
                // We check if DrawingCubit is also loaded
                if (context.read<DrawingCubit>().state.isLoaded) {
                  FlutterNativeSplash.remove();
                }
              },
              child: BlocListener<DrawingCubit, DrawingState>(
                listenWhen: (prev, curr) => curr.isLoaded && !prev.isLoaded,
                listener: (context, state) {
                  // We check if EntitlementsCubit is also initialized
                  if (context.read<EntitlementsCubit>().state.isInitialized) {
                    FlutterNativeSplash.remove();
                  }
                },
                child: BlocBuilder<EntitlementsCubit, EntitlementsState>(
                  builder: (context, entState) {
                    return BlocBuilder<DrawingCubit, DrawingState>(
                      builder: (context, drawState) {
                        final bool isReady =
                            entState.isInitialized && drawState.isLoaded;

                        if (!isReady) {
                          return const Scaffold(backgroundColor: Colors.black);
                        }

                        if (entState.isSubscribed) {
                          return const SafeArea(child: HomePage());
                        }
                        return const PaywallPage();
                      },
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
