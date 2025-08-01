import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({required this.title, required this.msg, super.key});
  final String title;
  final String msg;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(msg),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: Text('OK')
        )
      ],
    );
  }
}