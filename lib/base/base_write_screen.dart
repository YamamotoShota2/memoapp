import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoapp/components/custom_alert_dialog.dart';
import 'package:memoapp/components/custom_dialog.dart';
import 'package:memoapp/enum.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class BaseWriteScreen extends StatefulWidget {
  const BaseWriteScreen({super.key});
}

abstract class BaseWriteScreenState<T extends BaseWriteScreen> extends State<T> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  int? value;
  final formKey = GlobalKey<FormState>();
  abstract final String pageTitle;
  late final AppLifecycleListener listener;

  // API通信
  Future<void> apiConnection() async{
    try {
      Map<String, String>? select = value != null ? {"name": "${tags[value!].getString()}"} : null;
      final url = 'https://api.notion.com/v1/pages';
      final Map<String, String> headers = {
        HttpHeaders.authorizationHeader: 
          'Bearer ${dotenv.env['NOTION_API_KEY']}',
        'Notion-Version': '2022-06-28',
        'Content-Type': 'application/json',
      };
      final Object body = jsonEncode({
        "parent": {"database_id": "${dotenv.env['NOTION_DATABASE_KEY']}"},
        "properties": {
          "タイトル": {
            "title": [
              {
                "text": {"content": "${titleController.text}"},
              },
            ],
          },
          "内容": {
            "rich_text": [
              {
                "text": {"content": "${contentController.text}"}
              },
            ],
          },
          "タグ": {
            "select": select
          },
        }
      });

      final response = await getResponse(url, headers, body);
      if (response.statusCode == 200) {
        hideIndicator(context);
        if (!mounted) return;
        Navigator.pop(context);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      hideIndicator(context);
      _showAlert('error', e.toString());
    }
  }

  dynamic getResponse(url, headers, body);

  setValue() async{
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('title', titleController.text);
    prefs.setString('content', contentController.text);
    if (value != null) {
      prefs.setInt('tag', value!);
    }
    prefs.setString('status', pageTitle);
  }

  @override
  void initState();

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    listener.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: writePageAppBar(),
      body: writePageBody(),
    );
  }

  PreferredSizeWidget writePageAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      leading: IconButton(
        onPressed: () {
          checkDontSave();
        },
        icon: Icon(Icons.close),
        iconSize: 30,
      ),
      title: Text(pageTitle),
      actions: [
        Form(
          child: IconButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                showIndicator(context);
                apiConnection();
              }
            },
            icon: Icon(Icons.save),
            iconSize: 30,
          ),
        )
      ],
    );
  }

  Widget writePageBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              titleField(),
              choseTagButton(),
              contentField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget titleField() {
    return TextFormField(
      controller: titleController,
      maxLines: null,
      decoration: InputDecoration(
        hintText: 'Titleを入力'
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '入力してください';
        }
        return null;
      },
    );
  }

  Widget contentField() {
    return TextFormField(
      controller: contentController,
      maxLines: null,
      decoration: InputDecoration(
        border: InputBorder.none,
      ),
      autofocus: true,
    );
  }

  Widget choseTagButton() {
    return Wrap(
      children: List<Widget>.generate(4, (int index) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(2.0, 8.0, 2.0, 1.0),
          child: ChoiceChip(
            label: Text(tags[index].getString()), 
            selected: value == index,
            selectedColor: tags[index].getColor(),
            onSelected: (bool selected) {
              setState(() {
                value = selected ? index : null;
              });
            },
          ),
        );
      }).toList()
    );
  }

  // タイトル、内容、タグが入力されている場合、注意のアラートを表示
  void checkDontSave() {
    if (titleController.text != "" || contentController.text != "" || value != null) {
      showChecking();
    } else {
      Navigator.pop(context);
    }
  }

  // ダイアログ表示
  void _showAlert(String alertTitle, String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(title: alertTitle, msg: msg));
  }

  // 入力が保存されないことの注意のアラートを表示
  void showChecking() {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomAlertDialog());
  }

  // 通信中のインジケーター表示
  void showIndicator(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );
  }

  // インジケーターを非表示
  void hideIndicator(BuildContext context) {
    if (!mounted) return;
    Navigator.pop(context);
  }
}