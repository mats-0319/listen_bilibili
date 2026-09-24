import 'package:flutter/material.dart';
import 'package:listen_b/widgets/app_bar.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: subpageAppBar(context, "错误信息"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SelectableText(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
