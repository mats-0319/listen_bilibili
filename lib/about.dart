import 'package:flutter/material.dart';

import 'package:listen_b/data/theme.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/transition_builder.dart';
import 'package:listen_b/edit_music_list.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: subpageAppBar(context, "关于我们"),
      body: Center(
        child: Column(
          children: [_Logo(), _nameInfo(), _buttonsToNewPages(), _copyright()],
        ),
      ),
    );
  }

  Widget _nameInfo() {
    return Column(
      children: [
        SizedBox(height: 20),
        Text("ListenB", style: blackText(1)),
        Text("v0.1.0", style: greyText(-1)),
      ],
    );
  }

  Widget _buttonsToNewPages() {
    return Column(
      children: [
        SizedBox(height: 130),
        _ButtonToNewPage(name: "编辑歌单", page: EditMusicListPage()),
      ],
    );
  }

  Widget _copyright() {
    return Column(
      children: [
        SizedBox(height: 80),
        Text("开发者：马同帅", style: greyText(-2)),
        Text("代码地址：github.com/mats0319/listen_bilibili", style: greyText(-3)),
        Text("All Rights Reserved", style: greyText(-3)),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      margin: EdgeInsets.only(top: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        image: DecorationImage(
          image: AssetImage("assets/icon_2048.png"),
          fit: BoxFit.contain,
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
