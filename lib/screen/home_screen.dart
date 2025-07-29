import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:memoapp/base/base_screen.dart';
import 'package:memoapp/screen/create_new_screen.dart';
import 'package:memoapp/model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();

}

class _HomeScreen extends State<HomeScreen> {
  late Future<List<Memo>> _futureMemos;

  Future<List<Memo>> getMemos() async {
    try {
      final url = 'https://api.notion.com/v1/databases/${dotenv.env['NOTION_DATABASE_KEY']}/query';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 
            'Bearer ${dotenv.env['NOTION_API_KEY']}',
          'Notion-Version': '2022-06-28',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['results'] as List).map((e) => Memo.fromMap(e)).toList();
      } else {
        throw Exception(response.body);
      }
    } catch (_) {
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    _futureMemos = getMemos();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      customAppBar: HomeAppBar(),
      customAppBody: homeBody(),
      customBottomNavigationBar: bottomAppBar(),
    );
  }

  Widget homeBody() {
    return Center(
      child: showMemos()
    );
  }

  Widget showMemos() {
    return FutureBuilder<List>(
      future: _futureMemos, 
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final memos = snapshot.data!;
          return Expanded(child: memosList(memos));
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      }
    );
  }

  Widget memosList(List memos) {
    return ListView.builder(
      itemCount: memos.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(3.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              width: 2.0,
              color: memos[index].tag.getColor(),
            )
          ),
          child: ListTile(
            onTap: () => {print('タップ$index')},
            title: showMemoData(memos[index])
          ),
        );
      },
    );
  }

  Widget showMemoData(dynamic memo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                memo.title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                memo.content,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        ),
        Text(DateFormat('yyyy/M/d').format(memo.lastEditedTime)),
      ],
    );
  }

  Widget bottomAppBar() {
    return Builder(
      builder: (context) {
        return BottomAppBar(
          color: Theme.of(context).colorScheme.onInverseSurface,
          child: Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                  return CreateNewScreen(); 
              })).then((value) {
                setState(() {
                  _futureMemos = getMemos();
                });
              }),
              icon: Icon(Icons.note_add_outlined),
              iconSize: 35,
            ),
          ),
        );
      }
    );
  }
} 

class HomeAppBar extends StatelessWidget 
  implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Size get preferredSize {
    return Size(double.infinity, 60);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      title: Text(
        'メモアプリ',
      ),
    );
  }
}