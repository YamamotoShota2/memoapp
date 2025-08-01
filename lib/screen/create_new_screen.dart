import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoapp/components/custom_dialog.dart';
import 'package:memoapp/enum.dart';

class CreateNewScreen extends StatefulWidget {
  const CreateNewScreen({super.key});

  @override
  State<CreateNewScreen> createState() => _CreateNewScreen();
}

class _CreateNewScreen extends State<CreateNewScreen> {

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  int? value;

  Future<void> createNew() async{
    try {
      Map<String, String>? select = value != null ? {"name": "${tags[value!].getString()}"} : null;
      final url = 'https://api.notion.com/v1/pages';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 
            'Bearer ${dotenv.env['NOTION_API_KEY']}',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "parent": {"database_id": "${dotenv.env['NOTION_DATABASE_KEY']}"},
          "properties": {
            "タイトル": {
              "title": [
                {
                  "text": {"content": "${_titleController.text}"},
                },
              ],
            },
            "内容": {
              "rich_text": [
                {
                  "text": {"content": "${_contentController.text}"}
                },
              ],
            },
            "タグ": {
              "select": select
            },
          }
        })
      );
      if (response.statusCode == 200) {
        Navigator.pop(context);
      } else {
        throw Exception(response.body);
      }
    } catch (e) {
      _showAlert('error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: createNewAppBar(),
      body: createNewBody(),
    );
  }
 
  PreferredSizeWidget createNewAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.close),
          iconSize: 30,
        ),
      title: Text(
        '新規作成',
      ),
      actions: [
        IconButton(
          onPressed: () {
            createNew();
          },
          icon: Icon(Icons.save),
          iconSize: 30,
        )
      ],
    );
  }

  Widget createNewBody() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
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
      controller: _titleController,
      maxLines: null,
      decoration: InputDecoration(
        hintText: 'Titleを入力'
      ),
    );
  }

  Widget contentField() {
    return TextFormField(
      controller: _contentController,
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

  // ダイアログ表示
  void _showAlert(String alertTitle, String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(title: alertTitle, msg: msg));
  }
} 