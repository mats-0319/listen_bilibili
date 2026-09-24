import 'package:flutter/material.dart';
import 'package:listen_b/pages/about.dart';
import 'package:listen_b/widgets/transition.dart';

AppBar homepageAppBar(BuildContext context) {
  final theme = Theme.of(context);

  return AppBar(
    leading: SizedBox.shrink(),
    title: Center(child: Text("ListenB", style: theme.textTheme.titleLarge)),
    actions: [
      IconButton(
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, a, s) => const AboutPage(),
            transitionsBuilder: transition(),
          ),
        ),
        icon: const Icon(Icons.apps),
      ),
    ],
  );
}

AppBar subpageAppBar(BuildContext context, String title) {
  final theme = Theme.of(context);

  return AppBar(
    leading: BackButton(color: theme.colorScheme.primary),
    title: Center(child: Text(title, style: theme.textTheme.titleLarge)),
    actions: [SizedBox(width: 56)], // default leading width is 56
  );
}
