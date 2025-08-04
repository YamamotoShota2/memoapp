// 入力内容が保存されないことの注意のアラート

import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  const CustomAlertDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text('保存せずに戻りますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: Text('Cancel')
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'OK');
            Navigator.pop(context);
          },
          child: Text('OK')
        )
      ],
    );
  }
}