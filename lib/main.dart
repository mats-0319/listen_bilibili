import 'package:flutter/material.dart';
import 'package:listen_b/data/playlist.dart';
import 'package:listen_b/home.dart';
import 'package:listen_b/data/theme.dart';
import 'package:provider/provider.dart';

import 'model/music_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MusicList().initialize();
  await _addDemoMusicIns();

  runApp(const App());
}

Future<void> _addDemoMusicIns() async {
  if (MusicList().list.isEmpty) {
    for (var i = 0; i < playlist.length; i++) {
      await MusicList().create(playlist[i], atFirst: false);
    }
  }
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
