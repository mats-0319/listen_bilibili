import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:listen_b/model/music.dart';
import 'package:listen_b/model/music_list.dart';
import 'package:listen_b/theme.dart';
import 'package:listen_b/widgets/dialog_display_music.dart';

enum Operate { create, edit }

// include 'create' and 'edit'
class OperateMusicDialog extends StatefulWidget {
  OperateMusicDialog({super.key, required this.operate, Music? musicIns})
    : musicIns = musicIns ?? Music.empty();

  final Operate operate;
  final Music musicIns;

  @override
  State<OperateMusicDialog> createState() => _OperateMusicDialogState();
}

class _OperateMusicDialogState extends State<OperateMusicDialog> {
  void _onNameChanged(String value) {
    setState(() {
      widget.musicIns.name = value;
    });
  }

  void _onBvChanged(String value) {
    setState(() {
      widget.musicIns.bv = value;
    });
  }

  void _onVolumeChanged(String value) {
    setState(() {
      widget.musicIns.volume = int.tryParse(value) ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.only(left: 20, right: 20),
      child: Padding(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _title(),
            SizedBox(height: 30),
            InputReadonly(text: widget.musicIns.id),
            SizedBox(height: 20),
            _Input(
              label: "name",
              initValue: widget.musicIns.name,
              onChanged: _onNameChanged,
            ),
            SizedBox(height: 20),
            _Input(
              label: "bv",
              initValue: widget.musicIns.bv,
              onChanged: _onBvChanged,
            ),
            SizedBox(height: 20),
            _Input(
              label: "volume",
              initValue: widget.musicIns.volume.toString(),
              onChanged: _onVolumeChanged,
            ),
            SizedBox(height: 20),
            _ConfirmButton(
              onlyUpdate: widget.operate == Operate.edit,
              musicIns: widget.musicIns,
            ),
          ],
        ),
      ),
    );
  }

  Widget _title() {
    final title = widget.operate == Operate.create ? "新增歌曲" : "编辑歌曲";
    return Text(title, style: blackText(1));
  }
}

class _Input extends StatefulWidget {
  const _Input({
    required this.label,
    required this.initValue,
    required this.onChanged,
  });

  final String label;
  final String initValue;
  final Function(String) onChanged;

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final _controller = TextEditingController(text: widget.initValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: blackText(-2),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.only(top: 0, bottom: 0, left: 10, right: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelText: widget.label,
      ),
    );
  }
}

class _ConfirmButton extends StatefulWidget {
  _ConfirmButton({required this.onlyUpdate, required this.musicIns});

  final bool onlyUpdate;
  final Music? musicIns;

  @override
  State<_ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<_ConfirmButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    String text = widget.onlyUpdate ? "编辑" : "新增";

    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
              setState(() {
                _isLoading = true;
              });
              MusicList()
                  .create(widget.onlyUpdate ? null : widget.musicIns)
                  .then((_) {
                    Navigator.of(context).pop();
                  })
                  .catchError((err) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(content: Text(err)),
                    );
                  })
                  .whenComplete(() {
                    setState(() {
                      _isLoading = false;
                    });
                  });
            },
      child: _isLoading
          ? CircularProgressIndicator(
              color: Theme.of(context).colorScheme.secondary,
              backgroundColor: Theme.of(context).colorScheme.surface,
            )
          : Text(text, style: blackText(0)),
    );
  }
}
