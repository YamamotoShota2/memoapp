import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoapp/base/base_screen.dart';

class CreateNewScreen extends StatelessWidget {
  const CreateNewScreen({super.key});

  Future<void> createNew() async{
    try {
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
                  "text": {"content": "タイトル"},
                },
              ],
            },
            "内容": {
              "rich_text": [
                {
                  "text": {"content": "testtest"}
                },
              ],
            },
          }
        })
      );

      print('-------------');
      print(response.body);
    } catch (e) {
      print('===============');
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      customAppBar: CreateNewAppBar(),
      customAppBody: Center(
      )
    );
  }
} 

class CreateNewAppBar extends StatelessWidget 
  implements PreferredSizeWidget {
  const CreateNewAppBar({super.key});

  @override
  Size get preferredSize {
    return Size(double.infinity, 60);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      title: Text(
        '新規作成',
        style: TextStyle(
          color: Colors.white
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => CreateNewScreen().createNew(), 
          icon: Icon(Icons.save),
          color: Colors.white,
        )
      ],
    );
  }
}