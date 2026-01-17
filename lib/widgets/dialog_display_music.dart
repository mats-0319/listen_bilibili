import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:listen_b/model/music.dart';

import 'package:listen_b/theme.dart';

class DisplayMusicDialog extends StatefulWidget {
  DisplayMusicDialog({super.key, required this.musicIns});

  final Music musicIns;

  @override
  State<DisplayMusicDialog> createState() => _DisplayMusicDialog();
}

class _DisplayMusicDialog extends State<DisplayMusicDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.only(left: 20, right: 20),
      child: Padding(
        padding: EdgeInsets.only(top: 40, bottom: 40, left: 30, right: 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("查看歌曲详情", style: blackText(1)),
            SizedBox(height: 30),
            InputReadonly(text: widget.musicIns.id),
            SizedBox(height: 20),
            InputReadonly(text: widget.musicIns.name),
            SizedBox(height: 20),
            InputReadonly(text: widget.musicIns.bv),
            SizedBox(height: 20),
            InputReadonly(text: widget.musicIns.volume.toString()),
          ],
        ),
      ),
    );
  }
}

class InputReadonly extends StatelessWidget {
  const InputReadonly({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return TextField(
      enabled: false,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 10),
        border: OutlineInputBorder(),
        disabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        hintText: text,
        hintStyle: greyText(-2),
      ),
    );
  }
}
