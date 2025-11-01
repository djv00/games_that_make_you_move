import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'di/injection_container.dart';

// UI
import 'features/bottom_navbar/presentation/pages/bottom_navbar.dart';
import 'features/intro/presentation/pages/intro_page.dart';

// cubits
import 'features/intro/presentation/manager/auth_status/auth_status_cubit.dart';
import 'features/intro/presentation/manager/auth_status/auth_status_state.dart';
import 'package:flutter_steps_tracker/utilities/locale/cubit/utility_cubit.dart';

// intl
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_steps_tracker/generated/l10n.dart';

// 开发期的种子
import 'package:flutter_steps_tracker/seed/seed_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) 只初始化 Firebase，一次就好
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) 初始化 DI
  await configure();

  // 3) 开发调试时要的种子，真机可以注释
   //await SeedData.runAll();

  runApp(const StepsApp());
}

class StepsApp extends StatelessWidget {
  const StepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // 语言/主题之类你原来就有的
        BlocProvider<UtilityCubit>(
          create: (_) => getIt<UtilityCubit>(),
        ),

        // 🔑 核心：启动先问我有没有账号
        BlocProvider<AuthStatusCubit>(
          create: (_) => getIt<AuthStatusCubit>()..checkAuthStatus(),
        ),
      ],
      child: MaterialApp(
        title: 'Steps Tracker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF5B7BFF),
          ),
          useMaterial3: true,
        ),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        // 👇 根据登录状态切页面
        home: BlocBuilder<AuthStatusCubit, AuthStatusState>(
          builder: (context, state) {
            return state.maybeWhen(
              authenticated: () => const BottomNavbar(),
              unAuthenticated: () => const IntroPage(),
              // 刚启动还没查到就先给个空白
              orElse: () => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          },
        ),
      ),
    );
  }
}
