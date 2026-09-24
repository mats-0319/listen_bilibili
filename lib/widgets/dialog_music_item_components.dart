import 'package:flutter/material.dart';
import 'package:listen_b/dart/result.dart';

class Input extends StatefulWidget {
  const Input({
    super.key,
    required this.label,
    required this.defaultValue,
    required this.onChanged,
  });

  final String label;
  final String defaultValue;
  final ValueChanged<String> onChanged;

  @override
  State<Input> createState() => _InputState();
}

class _InputState extends State<Input> {
  late final _controller = TextEditingController(text: widget.defaultValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      style: theme.textTheme.labelLarge,
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        labelText: widget.label,
        labelStyle: theme.textTheme.labelLarge,
      ),
    );
  }
}

class ConfirmButton extends StatefulWidget {
  const ConfirmButton({super.key, required this.text, required this.func});

  final String text;
  final Future<Result<void>> Function() func;

  @override
  State<ConfirmButton> createState() => _ConfirmButtonState();
}

class _ConfirmButtonState extends State<ConfirmButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: () async {
        if (_isLoading) {
          return;
        }

        setState(() => _isLoading = true);

        try {
          var res = await widget.func();
          if (!context.mounted) {
            return;
          }

          switch (res) {
            case Success():
              Navigator.of(context).pop();
            case Failure():
              throw res.err;
          }
        } catch (e) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(content: Text(e.toString())),
          );
          setState(() => _isLoading = false);
        }
      },
      child: _isLoading
          ? CircularProgressIndicator(
              color: theme.colorScheme.onSurfaceVariant,
              backgroundColor: theme.colorScheme.surface,
            )
          : Text(widget.text),
    );
  }
}
