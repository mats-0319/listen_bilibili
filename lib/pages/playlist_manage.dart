import 'package:flutter/material.dart';
import 'package:listen_b/model/music.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/dialog_music_item.dart';
import 'package:provider/provider.dart';

class PlaylistManagePage extends StatefulWidget {
  const PlaylistManagePage({super.key});

  @override
  State<PlaylistManagePage> createState() => _PlaylistManagePageState();
}

class _PlaylistManagePageState extends State<PlaylistManagePage> {
  @override
  Widget build(BuildContext context) {
    var dataState = context.watch<Playlist>();

    return Scaffold(
      appBar: subpageAppBar(context, "歌单管理"),
      body: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _functionBar(context),
            Expanded(
              child: ReorderableListView(
                onReorderItem: (oldIndex, newIndex) =>
                    dataState.reorder(oldIndex, newIndex), // todo: check res
                children: _displayMusicList(context, dataState.list),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _functionBar(BuildContext context) {
  final theme = Theme.of(context);

  return Container(
    margin: EdgeInsets.only(bottom: 20),
    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        ElevatedButton(
          onPressed: () => showDialog(
            context: context,
            builder: (context) =>
                MusicItemDialog(operate: OperateE.create, m: Music.empty()),
          ),
          child: Text(OperateE.create.text, style: theme.textTheme.labelMedium),
        ),
        Spacer(),
      ],
    ),
  );
}

List<Widget> _displayMusicList(BuildContext context, List<Music> list) {
  final theme = Theme.of(context);

  return list.indexed.map((record) {
    final (index, item) = record;

    return Container(
      key: ValueKey(item.id),
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadiusGeometry.circular(20),
        color: theme.colorScheme.surfaceContainerLow,
      ),
      child: Row(
        children: [_details(context, index, item), _operates(context, item)],
      ),
    );
  }).toList();
}

Widget _details(BuildContext context, int index, Music m) {
  final theme = Theme.of(context);

  return Expanded(
    child: Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("> item ${index + 1}:", style: theme.textTheme.labelMedium),
        Text(
          "name: ${m.name}",
          style: theme.textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "bv: ${m.bv}",
          style: theme.textTheme.labelMedium,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          "page:${m.page}, volume:${m.volume}",
          style: theme.textTheme.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget _operates(BuildContext context, Music m) {
  final theme = Theme.of(context);

  return Column(
    children: [
      ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => MusicItemDialog(operate: OperateE.edit, m: m),
        ),
        child: Text(OperateE.edit.text, style: theme.textTheme.labelMedium),
      ),
      ElevatedButton(
        onPressed: () => showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("删除音乐实例", style: theme.textTheme.labelLarge),
            content: Text(
              "本次删除不可恢复，请确认是否删除以下实例：\n"
              "- name: ${m.name}\n"
              "- bv: ${m.bv}\n"
              "- page: ${m.page}",
              style: theme.textTheme.labelLarge,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  "取消",
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Playlist().deleteHard(m); // todo: res check
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text("确认", style: theme.textTheme.labelLarge),
              ),
            ],
          ),
        ),
        child: Text("删除", style: theme.textTheme.labelMedium),
      ),
    ],
  );
}
