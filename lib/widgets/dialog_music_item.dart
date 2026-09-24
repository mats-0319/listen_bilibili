import 'package:flutter/material.dart';
import 'package:listen_b/dart/result.dart';
import 'package:listen_b/model/music.dart';
import 'package:listen_b/model/playlist.dart';
import 'package:listen_b/widgets/dialog_music_item_components.dart';

enum OperateE {
  create(text: "创建"),
  edit(text: "编辑");

  const OperateE({required this.text});

  final String text;
}

class MusicItemDialog extends StatefulWidget {
  const MusicItemDialog({super.key, required this.operate, required this.m});

  final OperateE operate;
  final Music m;

  @override
  State<MusicItemDialog> createState() => _MusicItemDialogState();
}

class _MusicItemDialogState extends State<MusicItemDialog> {
  late Music mc = Music.deepCopy(widget.m);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${widget.operate.text}音乐实例",
              style: theme.textTheme.titleLarge,
            ),
            SizedBox(height: 30),
            _nameInput(),
            SizedBox(height: 20),
            _bvInput(),
            SizedBox(height: 20),
            _pageInput(),
            SizedBox(height: 20),
            _volumeInput(),
            SizedBox(height: 20),
            ConfirmButton(text: widget.operate.text, func: _operateFunc),
          ],
        ),
      ),
    );
  }

  Widget _nameInput() => Input(
    label: "name",
    defaultValue: mc.name,
    onChanged: (String v) => setState(() => mc.name = v),
  );

  Widget _bvInput() => Input(
    label: "bv",
    defaultValue: mc.bv,
    onChanged: (String v) => setState(() => mc.bv = v),
  );

  Widget _pageInput() => Input(
    label: "page",
    defaultValue: mc.page.toString(),
    onChanged: (String v) => setState(() => mc.page = int.tryParse(v) ?? 1),
  );

  Widget _volumeInput() => Input(
    label: "volume",
    defaultValue: mc.volume.toString(),
    onChanged: (String v) => setState(() => mc.volume = int.tryParse(v) ?? 0),
  );

  Future<Result<void>> _operateFunc() async {
    final Music backup = Music.deepCopy(widget.m);

    copyBack(widget.m, mc);

    Result<void> res = widget.operate == OperateE.create
        ? await Playlist().create(widget.m)
        : await Playlist().update();

    if (res is Failure) {
      copyBack(widget.m, backup);
    }

    return res;
  }
}
