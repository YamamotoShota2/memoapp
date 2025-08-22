// 新規作成画面

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:memoapp/base/base_write_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateNewScreen extends BaseWriteScreen {
  const CreateNewScreen({super.key});

  @override
  State<CreateNewScreen> createState() => _CreateNewScreenState();
}

class _CreateNewScreenState extends BaseWriteScreenState<CreateNewScreen> {

  @override
  String get pageTitle => "新規作成";

  @override
  void initState() {
    super.initState();
    listener = AppLifecycleListener(
      onPause: () {
        if (titleController.text.isNotEmpty || contentController.text.isNotEmpty || value != null) {
          setValue();
        }
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
    prefs.setString('status', '新規作成');
  }


  @override
  getResponse(url, headers, body) {
    return post(
      Uri.parse(url),
      headers: headers,
      body: body,
    );
  }
}
