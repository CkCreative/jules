import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/api_client.dart';
import 'providers/chat_provider.dart';
import 'providers/auth_provider.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/login_screen.dart';

import 'core/local_storage.dart';

import 'core/connectivity_service.dart';

import 'providers/settings_provider.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  final localStorage = LocalStorageService();
  await localStorage.init();

  final settings = SettingsProvider();
  await settings.init();

  final auth = AuthProvider();
  await auth.init();

  final connectivity = ConnectivityService();

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: localStorage),
        Provider.value(value: connectivity),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProxyProvider3<
          AuthProvider,
          LocalStorageService,
          ConnectivityService,
          ChatProvider
        >(
          create: (_) => ChatProvider(),
          update: (_, auth, local, connectivity, chat) {
            if (chat == null) return ChatProvider();
            chat.setDependencies(local, connectivity);
            final accountId = auth.activeAccountId;
            final apiKey = auth.apiKey;
            if (auth.isAuthenticated && accountId != null && apiKey != null) {
              chat.updateClient(ApiClient(apiKey: apiKey), accountId);
            } else {
              chat.clearClient();
            }
            return chat;
          },
        ),
      ],
      child: const JulesApp(),
    ),
  );
}

class JulesApp extends StatelessWidget {
  const JulesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeOption = context.select((SettingsProvider s) => s.themeMode);

    ThemeMode mode;
    switch (themeOption) {
      case ThemeModeOption.light:
        mode = ThemeMode.light;
        break;
      case ThemeModeOption.dark:
        mode = ThemeMode.dark;
        break;
      case ThemeModeOption.system:
        mode = ThemeMode.system;
        break;
    }

    return MaterialApp(
      title: 'Jules AI IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: mode,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
