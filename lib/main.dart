import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/key_finder_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/history_provider.dart';
import 'providers/search_progress_provider.dart';
import 'providers/performance_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/key_finder_screen.dart';
import 'screens/about_screen.dart';
import 'l10n/app_localizations.dart';
import 'utils/fast_crypto.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar crypto nativo (agora é async)
  await FastCrypto.initialize();

  runApp(const BitFinderApp());
}

class BitFinderApp extends StatelessWidget {
  const BitFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => KeyFinderProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(create: (_) => SearchProgressProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            title: 'Bit Finder',
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.orange,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const InitialScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('first_launch') ?? true;

    if (mounted) {
      if (isFirstLaunch) {
        // Marcar como não sendo mais primeira execução
        await prefs.setBool('first_launch', false);
        if (!mounted) return;

        // Navegar para tela Sobre
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AboutScreenWithContinue(),
          ),
        );
      } else {
        // Navegar para tela principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const KeyFinderScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class AboutScreenWithContinue extends StatelessWidget {
  const AboutScreenWithContinue({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bem-vindo ao Bit Finder'),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            const Expanded(child: AboutScreen(showAppBar: false)),
            Container(
              padding: const EdgeInsets.all(16.0),
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const KeyFinderScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Continuar para o App'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
