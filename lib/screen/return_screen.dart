// 復旧画面

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:memoapp/base/base_write_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnScreen extends BaseWriteScreen {
  const ReturnScreen({
    required this.title, 
    required this.content, 
    required this.value,
    required this.status,
    required this.pageId,
    super.key
  });

  final String? title;
  final String? content;
  final int? value;
  final String? status;
  final String? pageId;

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends BaseWriteScreenState<ReturnScreen> {
  int? status = 0;
  String? pageId = '';

  @override
  String get pageTitle => widget.status!;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.title!;
    contentController.text = widget.content!;
    value = widget.value;
    pageId = widget.pageId;
    listener = AppLifecycleListener(
      onPause: () {
        setValue();
      }
    );
  }

  @override
  getResponse(url, headers, body) {
    if (pageTitle == '新規作成') {
      return post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
    } else {
      url += '/$pageId';
      return patch(
        Uri.parse(url),
        headers: headers,
        body: body,
      );
    }
  }
}
