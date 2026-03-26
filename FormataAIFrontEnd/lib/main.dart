import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/stores/theme_store.dart';
import 'core/stores/auth_store.dart';
import 'core/stores/conversas_store.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeStore = ThemeStore();
  await themeStore.init();
  runApp(FormataAIApp(themeStore: themeStore));
}

class FormataAIApp extends StatefulWidget {
  final ThemeStore themeStore;
  const FormataAIApp({super.key, required this.themeStore});

  @override
  State<FormataAIApp> createState() => _FormataAIAppState();
}

class _FormataAIAppState extends State<FormataAIApp> {
  late final AuthStore _authStore;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authStore = AuthStore();
    _router = criarRouter(_authStore);
    _authStore.tentarRestaurar();
  }

  @override
  void dispose() {
    _router.dispose();
    _authStore.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.themeStore),
        ChangeNotifierProvider.value(value: _authStore),
        ChangeNotifierProvider(create: (_) => ConversasStore()),
      ],
      child: Consumer<ThemeStore>(
        builder: (context, themeStore, _) {
          return MaterialApp.router(
            title: 'FormataAI',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeStore.mode,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
