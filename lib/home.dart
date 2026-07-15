import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:listen_b/model/music_list.dart';
import 'package:listen_b/data/theme.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/dialog_display_music.dart';
import 'package:listen_b/widgets/video.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    var dataState = context.watch<MusicList>();

    return Scaffold(
      appBar: homepageAppBar(context),
      body: Center(
        child: Column(
          children: <Widget>[
            BiliPlayer(musicIns: MusicList().currentMusic()),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface,
                borderRadius: BorderRadiusGeometry.circular(10),
              ),
              height: 100,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "歌曲数量：${dataState.list.length}\n"
                    "当前播放：${MusicList().currentMusic().name} "
                    "(${MusicList().currentIndex + 1})",
                    style: blackText(-1),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dataState.list.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Container(
                      padding: EdgeInsets.only(left: 10, right: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadiusGeometry.circular(10),
                      ),
                      height: 80,
                      child: Row(
                        children: [
                          TextButton(
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => DisplayMusicDialog(
                                musicIns: MusicList().list[index],
                              ),
                            ),
                            child: Text(
                              dataState.list[index].name,
                              style: blackText(-1),
                            ),
                          ),
                          Spacer(),
                          ElevatedButton(
                            onPressed: () => {MusicList().playMusic(index)},
                            child: Text("播放", style: blackText(-1)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
