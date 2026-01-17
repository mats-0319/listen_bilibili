import 'package:flutter/material.dart';

import 'package:listen_b/about.dart';
import 'package:listen_b/widgets/transition_builder.dart';

AppBar homepageAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.onSurface,
    leading: SizedBox.shrink(),
    title: Center(
      child: Text("ListenB", style: Theme.of(context).textTheme.titleLarge),
    ),
    actions: [_ToAboutIcon()],
  );
}

AppBar subpageAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.onSurface,
    leading: BackButton(color: Theme.of(context).colorScheme.primary),
    title: Center(
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    ),
    actions: [SizedBox(width: 56)], // default leading width is 56
  );
}

class _ToAboutIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(size: 32),
      child: IconButton(
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const AboutPage(),
            transitionsBuilder: transition,
          ),
        ),
        icon: Icon(Icons.apps),
      ),
    );
  }
}
