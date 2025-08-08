// 編集作成画面

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:memoapp/base/base_write_screen.dart';
import 'package:memoapp/enum.dart';
import 'package:memoapp/model.dart';

class EditScreen extends BaseWriteScreen {
  const EditScreen({required this.memo, super.key});
  final Memo memo;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends BaseWriteScreenState<EditScreen> {
  late final int? checkValue;

  @override
  String get pageTitle => "編集";

  @override
  void initState() {
    titleController.text = widget.memo.title;
    contentController.text = widget.memo.content;
    value = widget.memo.tag != Tags.none ? tags.indexOf(widget.memo.tag) : null ;
    checkValue = value;
    listener = AppLifecycleListener(
      onPause: () { 
        if (titleController.text == '' || titleController.text.isEmpty) {
          titleController.text = widget.memo.title;
        }
        ifPaused();
      },
    );
    super.initState();
  }

  @override
  getResponse(url, headers, body) {
    url += '/${widget.memo.pageId}';
    return patch(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
  }

  @override
  void checkDontSave() {
    if (titleController.text != widget.memo.title || contentController.text != widget.memo.content || value != checkValue) {
      showChecking();
    } else {
      Navigator.pop(context);
    }
  }
}
