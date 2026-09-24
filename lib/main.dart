import 'package:flutter/material.dart';
import 'package:listen_b/dart/global.dart';
import 'package:listen_b/dart/result.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/pages/error_page.dart';
import 'package:listen_b/pages/home.dart';
import 'package:listen_b/theme.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final res = await Playlist().initialize();
  if (res is Failure) {
    setInitError(res.err);
  }

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: Playlist(),
    child: MaterialApp(
      navigatorKey: navigatorKey,
      title: "ListenB",
      theme: defaultThemeData(),
      themeMode: ThemeMode.light,
      home: ValueListenableBuilder(
        valueListenable: initError,
        builder: (context, message, _) =>
            message.isNotEmpty ? ErrorPage(message: message) : const HomePage(),
      ),
    ),
  );
}
