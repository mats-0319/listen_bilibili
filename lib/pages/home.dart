import 'package:flutter/material.dart';
import 'package:listen_b/dart/global.dart';
import 'package:listen_b/dart/result.dart';
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
  @override
  Widget build(BuildContext context) {
    var dataState = context.watch<Playlist>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: homepageAppBar(context),
      body: Center(
        child: Column(
          children: [
            Video(music: dataState.currentItem),
            Container(
              margin: EdgeInsets.symmetric(vertical: 30),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "当前播放：${dataState.currentItem?.name} "
                "(${dataState.currentIndex() + 1}/${dataState.list.length})",
                maxLines: 1,
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
                            final res = dataState.play(index);
                            if (res is Failure) {
                              setError(res.err);
                              return;
                            }
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
