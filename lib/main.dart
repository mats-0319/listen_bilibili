import 'package:flutter/material.dart';
import 'package:listen_b/home.dart';
import 'package:listen_b/theme.dart';
import 'package:provider/provider.dart';

import 'model/music.dart';
import 'model/music_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MusicList().initialize();
  await _addDemoMusicIns();

  runApp(const App());
}

Future<void> _addDemoMusicIns() async {
  if (MusicList().list.isEmpty) {
    await MusicList().create(
      Music("故风吟游之地", "BV1Fer3YyE3n", 0),
      atFirst: false,
    );
    await MusicList().create(
      Music("当飞鸟划过天空", "BV1sRj1zcEhV", -10),
      atFirst: false,
    );
    await MusicList().create(
      Music("Unwritten in the stars", "BV1JtrKBXE9Y", -5),
      atFirst: false,
    );
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
