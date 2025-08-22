// 復旧画面

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:memoapp/base/base_write_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReturnScreen extends BaseWriteScreen {
  const ReturnScreen({required this.status, super.key});
  final String? status;

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
    getValues();
    listener = AppLifecycleListener(
      onPause: () {
        setValue();
      }
    );
  }

  setValue() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('title', titleController.text);
    prefs.setString('content', contentController.text);
    if (value != null) {
      prefs.setInt('tag', value!);
    }
    prefs.setString('status', pageTitle);
  }

  getValues() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      titleController.text = prefs.getString('title') ?? '';
      contentController.text = prefs.getString('content') ?? '';
      value = prefs.getInt('tag');
    });
    pageId = prefs.getString('pageId');
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
