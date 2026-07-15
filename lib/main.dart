import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:listen_b/data/playlist.dart';
import 'package:listen_b/data/theme.dart';
import 'package:listen_b/model/music_list.dart';
import 'package:listen_b/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MusicList().initialize();
  await _initializeMusicListDemo();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MusicList(),
      child: MaterialApp(
        title: "ListenB",
        theme: defaultThemeData(),
        home: const HomePage(),
      ),
    );
  }
}

Future<void> _initializeMusicListDemo() async {
  if (MusicList().list.isEmpty) {
    for (var i = playlist.length - 1; i >= 0; i--) {
      await MusicList().create(playlist[i]);
    }
  }
}
