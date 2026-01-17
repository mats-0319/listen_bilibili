import 'package:flutter/material.dart';
import 'package:listen_b/edit_music_list.dart';

import 'package:listen_b/theme.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/transition_builder.dart';

import 'model/music_list.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subpageAppBar(context, "关于我们"),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 120),
            _Logo(),
            SizedBox(height: 20),
            _nameInfo(),
            SizedBox(height: 80),
            _buttonsToNewPages(),
            SizedBox(height: 52),
            _copyright(),
          ],
        ),
      ),
    );
  }

  Widget _nameInfo() {
    return Column(
      children: [
        Text("ListenB", style: blackText(1)),
        Text("v1.0.0", style: greyText(-1)),
      ],
    );
  }

  Widget _buttonsToNewPages() {
    return Column(
      children: [_ButtonToNewPage(name: "编辑歌单", page: EditMusicListPage())],
    );
  }

  Widget _copyright() {
    return Column(
      children: [
        Text("开发者：马同帅", style: greyText(-2)),
        Text("代码地址：github.com/mats0319/listen_b", style: greyText(-3)),
        Text("All Rights Reserved", style: greyText(-3)),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Container(
              width: 300,
              constraints: BoxConstraints(maxHeight: 600),
              padding: EdgeInsets.all(40),
              child: ListView(
                shrinkWrap: true,
                children: [Text(MusicList().display(), style: blackText(-2))],
              ),
            ),
          ),
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          image: DecorationImage(
            image: AssetImage("assets/icon_2048.png"),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

class _ButtonToNewPage extends StatelessWidget {
  const _ButtonToNewPage({required this.name, required this.page});

  final String name;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 50,
      child: TextButton(
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder: transition,
          ),
        ),
        style: ButtonStyle(
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          backgroundColor: WidgetStateProperty.all(
            Theme.of(context).colorScheme.onSurface,
          ),
        ),
        child: Text(name, style: blackText(-1)),
      ),
    );
  }
}
