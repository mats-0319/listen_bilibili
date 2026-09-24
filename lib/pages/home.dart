import 'package:flutter/material.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/webview_video.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _videoKey = GlobalKey<VideoState>();

  @override
  Widget build(BuildContext context) {
    var dataState = context.watch<Playlist>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: homepageAppBar(context),
      body: Center(
        child: Column(
          children: [
            Video(key: _videoKey),
            Container(
              margin: EdgeInsets.symmetric(vertical: 30),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "当前播放：${dataState.currentMusic().name} "
                "(${dataState.currentIndex + 1}/${dataState.list.length})",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: dataState.list.length,
                itemBuilder: (context, index) => ListTile(
                  title: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    constraints: BoxConstraints(minHeight: 70),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${index + 1}. ${dataState.list[index].name}",
                            style: theme.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            dataState.play(index); // todo: res check
                            _videoKey.currentState?.play();
                          },
                          child: Text("播放", style: theme.textTheme.labelMedium),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
