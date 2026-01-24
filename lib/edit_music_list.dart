import 'package:flutter/material.dart';
import 'package:listen_b/model/music_list.dart';
import 'package:listen_b/data/theme.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/dialog_operate_music.dart';
import 'package:provider/provider.dart';
import 'model/music.dart';

class EditMusicListPage extends StatefulWidget {
  const EditMusicListPage({super.key});

  @override
  State<EditMusicListPage> createState() => _EditMusicListPageState();
}

class _EditMusicListPageState extends State<EditMusicListPage> {
  @override
  Widget build(BuildContext context) {
    var dataState = context.watch<MusicList>();

    return Scaffold(
      appBar: subpageAppBar(context, "编辑歌单"),
      body: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => showDialog(
                context: context,
                builder: (context) =>
                    OperateMusicDialog(operate: Operate.create),
              ),
              child: Text("新增"),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(children: _displayMusicList(dataState.list)),
            ),
          ],
        ),
      ),
    );
  }
}

List<Widget> _displayMusicList(List<Music> listIns) {
  List<Widget> res = [];

  for (var i = 0; i < listIns.length; i++) {
    res.add(_MusicInstance(index: i, musicIns: listIns[i]));
  }

  return res;
}

class _MusicInstance extends StatefulWidget {
  const _MusicInstance({required this.index, required this.musicIns});

  final int index;
  final Music musicIns;

  @override
  State<_MusicInstance> createState() => _MusicInstanceState();
}

class _MusicInstanceState extends State<_MusicInstance> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadiusGeometry.circular(20),
        color: Theme.of(context).colorScheme.onSurface,
      ),
      child: Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: Row(
          children: [
            _displayMusicInstance(),
            Spacer(),
            Column(
              children: [
                _ModifyButton(musicIns: widget.musicIns),
                _ReOrderButton(
                  musicID: widget.musicIns.id,
                  currentIndex: widget.index,
                ),
                _DeleteButton(id: widget.musicIns.id),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _displayMusicInstance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("> item ${widget.index}:", style: blackText(-2)),
        SizedBox(
          width: 160, // for auto wrap
          child: Text("id: ${widget.musicIns.id}", style: greyText(-3)),
        ),
        SizedBox(
          width: 160, // for auto wrap
          child: Text("name: ${widget.musicIns.name}", style: blackText(-2)),
        ),
        Text("bv: ${widget.musicIns.bv}", style: blackText(-2)),
        Text("page: ${widget.musicIns.page}", style: blackText(-2)),
        Text("volume: ${widget.musicIns.volume}", style: blackText(-2)),
      ],
    );
  }
}

class _ModifyButton extends StatelessWidget {
  const _ModifyButton({required this.musicIns});

  final Music musicIns;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (context) =>
            OperateMusicDialog(operate: Operate.edit, musicIns: musicIns),
      ),
      child: Text("编辑", style: blackText(-2)),
    );
  }
}

class _ReOrderButton extends StatefulWidget {
  const _ReOrderButton({required this.musicID, required this.currentIndex});

  final String musicID;
  final int currentIndex;

  @override
  State<_ReOrderButton> createState() => _ReOrderButtonState();
}

class _ReOrderButtonState extends State<_ReOrderButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: EdgeInsets.only(top: 40, bottom: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _reOrderButton("移动到开头", 0),
                SizedBox(height: 20),
                _reOrderButton("向前移动一个", widget.currentIndex - 1),
                SizedBox(height: 20),
                _reOrderButton("向后移动一个", widget.currentIndex + 2),
                SizedBox(height: 20),
                _reOrderButton("移动到末尾", MusicList().list.length),
              ],
            ),
          ),
        ),
      ),
      child: Text("排序", style: blackText(-2)),
    );
  }

  Widget _reOrderButton(String text, int index) {
    return ElevatedButton(
      onPressed: () {
        MusicList().reOrder(widget.musicID, index);
        Navigator.of(context).pop(); // 因为要在这里用context，所以widget用有状态的
      },
      child: Text(text),
    );
  }
}

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("删除歌曲", style: blackText(1)),
          content: Text(
            "本次删除不可恢复，请确认是否删除id为：\n$id\n的歌曲?",
            style: blackText(-1),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("取消", style: greyText(-1)),
            ),
            TextButton(
              onPressed: () {
                MusicList().delete(id).catchError((err) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(content: Text(err)),
                  );
                });
                Navigator.of(context).pop();
              },
              child: Text("确认", style: blackText(-1)),
            ),
          ],
        ),
      ),
      child: Text("删除", style: blackText(-2)),
    );
  }
}
