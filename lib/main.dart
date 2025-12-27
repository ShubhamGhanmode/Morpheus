import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:morpheus/auth/auth_bloc.dart';
import 'package:morpheus/auth/auth_repository.dart';
import 'package:morpheus/categories/category_cubit.dart';
import 'package:morpheus/categories/category_repository.dart';
import 'package:morpheus/navigation_bar.dart';
import 'package:morpheus/services/auth_service.dart';
import 'package:morpheus/services/encryption_service.dart';
import 'package:morpheus/services/error_reporter.dart';
import 'package:morpheus/services/notification_service.dart';
import 'package:morpheus/splash_page.dart';
import 'package:morpheus/lock/app_lock_gate.dart';
import 'package:morpheus/settings/settings_cubit.dart';
import 'package:morpheus/settings/settings_repository.dart';
import 'package:morpheus/settings/settings_state.dart';
import 'package:morpheus/theme/app_theme.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'firebase_options.dart'; // created by flutterfire configure
import 'signup_page.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();
  await NotificationService.instance.handleRemoteMessage(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  await EncryptionService.initialize();
  await AuthService.initializeGoogle(
    serverClientId:
        "842775331840-gsso7qkcb8mmi0sj97b63upejevbku48.apps.googleusercontent.com",
    clientId:
        (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
            ? "YOUR_IOS_CLIENT_ID.apps.googleusercontent.com"
            : null,
  );

  await NotificationService.instance.initialize();

  final authRepository = AuthRepository();
  final settingsRepository = SettingsRepository();
  final initialSettings = await settingsRepository.load();
  final app = MorpheusApp(
    authRepository: authRepository,
    settingsRepository: settingsRepository,
    initialSettings: initialSettings,
  );

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = sentryDsn;
        options.tracesSampleRate = 0.1;
      },
      appRunner: () async {
        await ErrorReporter.initialize();
        runApp(app);
      },
    );
  } else {
    await ErrorReporter.initialize();
    runApp(app);
  }
}

class MorpheusApp extends StatelessWidget {
  const MorpheusApp({
    super.key,
    required this.authRepository,
    required this.settingsRepository,
    required this.initialSettings,
  });

  final AuthRepository authRepository;
  final SettingsRepository settingsRepository;
  final SettingsState initialSettings;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthBloc(authRepository)..add(const AppStarted())),
          BlocProvider(
            create: (_) => SettingsCubit(
              repository: settingsRepository,
              initialState: initialSettings,
            ),
          ),
        ],
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            return MaterialApp(
              title: 'Morpheus',
              theme: AppTheme.light(
                context,
                contrast: settings.contrast,
              ),
              darkTheme: AppTheme.dark(
                context,
                contrast: settings.contrast,
              ),
              themeMode: settings.themeMode,
              home: AppLockGate(
                enabled: settings.appLockEnabled,
                child: const AuthGate(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Auth error: ${state.message}')),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return SplashPage(
            message: state.message,
            onRetry: () => context.read<AuthBloc>().add(const AppStarted()),
          );
        }

        if (state is AuthAuthenticated) {
          return BlocProvider(
            create: (_) => CategoryCubit(CategoryRepository())..load(),
            child: const AppNavShell(),
          );
        }

        if (state is AuthFailure) {
          return SplashPage(
            message: state.message,
            onRetry: () => context.read<AuthBloc>().add(const AppStarted()),
          );
        }

        return const SignUpPage();
      },
    );
  }
}
