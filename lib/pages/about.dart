import 'package:flutter/material.dart';
import 'package:listen_b/pages/doc.dart';
import 'package:listen_b/pages/playlist_manage.dart';
import 'package:listen_b/widgets/app_bar.dart';
import 'package:listen_b/widgets/transition.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: subpageAppBar(context, "关于我们"),
      body: Center(
        child: Column(
          children: [
            SizedBox(height: 120),
            _logo(),
            SizedBox(height: 40),
            Text("ListenB", style: theme.textTheme.headlineMedium),
            SizedBox(height: 10),
            Text("v1.0.0", style: theme.textTheme.labelLarge),
            SizedBox(height: 70),
            _buttonToDocPage(DocItemE.manual),
            _buttonToDocPage(DocItemE.tech),
            _ButtonToNewPage(
              name: "歌单管理",
              page: (context, a, s) => PlaylistManagePage(),
            ),
            SizedBox(height: 40),
            Text(
              "开发者：马同帅",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "代码地址：github.com/mats0319/listen_bilibili",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              "All Rights Reserved",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _logo() => Container(
    width: 100,
    height: 100,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      image: DecorationImage(
        image: AssetImage("assets/logo_256.png"),
        fit: BoxFit.contain,
      ),
    ),
  );

  Widget _buttonToDocPage(DocItemE doc) => _ButtonToNewPage(
    name: doc.name,
    page: (context, a, s) => DocPage(doc: doc),
  );
}

class _ButtonToNewPage extends StatelessWidget {
  const _ButtonToNewPage({required this.name, required this.page});

  final String name;
  final RoutePageBuilder page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsetsGeometry.only(top: 4, bottom: 4),
      constraints: BoxConstraints(maxWidth: 300, minHeight: 60),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: page,
              transitionsBuilder: transition(),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.surfaceContainerLow,
          ),
          child: Text(name, style: theme.textTheme.labelLarge),
        ),
      ),
    );
  }
}
