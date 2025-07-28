import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:memoapp/base/base_screen.dart';
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
    } catch (e) {print(e);}
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      customAppBar: createNewAppBar(),
      customAppBody: createNewScreen(),
    );
  }
 
  PreferredSizeWidget createNewAppBar() {
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
          onPressed: () {
            createNew();
            Navigator.pop(context);
          },
          icon: Icon(Icons.save),
          color: Colors.white,
        )
      ],
    );
  }

  Widget createNewScreen() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Form(
        child: Column(
          children: [
            TextFormField(
              controller: _titleController,
            ),
            Wrap(
              children: List<Widget>.generate(4, (int index) {
                return ChoiceChip(
                  label: Text(tags[index].getString()), 
                  selected: value == index,
                  onSelected: (bool selected) {
                    setState(() {
                      value = selected ? index : null;
                    });
                  },
                );
              }).toList()
            ),
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 

// こっちでやるとcontrollerがうまく使えない
// class CreateNewAppBar extends StatelessWidget 
//   implements PreferredSizeWidget {
//   const CreateNewAppBar({super.key});

//   @override
//   Size get preferredSize {
//     return Size(double.infinity, 60);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AppBar(
//       centerTitle: true,
//       backgroundColor: Theme.of(context).colorScheme.primary,
//       title: Text(
//         '新規作成',
//         style: TextStyle(
//           color: Colors.white
//         ),
//       ),
//       actions: [
//         IconButton(
//           onPressed: () => _CreateNewScreen().createNew(), 
//           icon: Icon(Icons.save),
//           color: Colors.white,
//         )
//       ],
//     );
//   }
// }