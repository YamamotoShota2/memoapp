import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:memoapp/screen/create_new_screen.dart';
import 'package:memoapp/model.dart';
import 'package:memoapp/screen/edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  late Future<List<Memo>> _futureMemos;
  final memos = [];
  final pinMemos = [];

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
        return (data['results'] as List).map((e) => Memo.fromMap(e)).toList()
          ..sort((a, b) => b.lastEditedTime.compareTo(a.lastEditedTime));
      } else {
        throw Exception(response.body);
      }
    } catch (_) {
      rethrow;
    }
  }

  Future<void> deleteMemo(String pageId) async {
    try {
      final url = 'https://api.notion.com/v1/pages/${pageId}';
      final response = await http.patch(
        Uri.parse(url),
        headers: {
          HttpHeaders.authorizationHeader: 
            'Bearer ${dotenv.env['NOTION_API_KEY']}',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "archived": true
        })
      );
      
      if (response.statusCode == 200) {
        setState(() {
          _futureMemos = getMemos();
        });
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
    return Scaffold(
      appBar: homeAppBar(),
      body: homeBody(),
      bottomNavigationBar: bottomAppBar(),
    );
  }

  PreferredSizeWidget homeAppBar() {
    return AppBar(
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
      title: Text(
        'メモアプリ',
      ),
    );
  }

  Widget homeBody() {
    return Center(child: showMemos());
  }

  Widget showMemos() {
    return FutureBuilder<List>(
      future: _futureMemos, 
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final memos = snapshot.data!;
          // makeMemosList(snapshot.data!);
          return memosList(memos);
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      }
    );
  }

  // // ピン留めされたメモとそうでないものを分ける
  // void makeMemosList(List data) {
  //   for (dynamic memo in data) {
  //     if (memo.pin == true) {
  //       memos.add(memo);
  //     } else {
  //       pinMemos.add(memo);
  //     }
  //   }
  // }

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
          child: Slidable(
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.5,
              children: [
                SlidableAction(
                  onPressed: (_) {
                    deleteMemo(memos[index].pageId);
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0) 
                  ),
                )
              ]
            ),
            child: ListTile(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                return EditScreen(memo: memos[index]);
              })).then((_) {
                setState(() {
                  _futureMemos = getMemos();
                });
              }),
              title: showMemoData(memos[index])
            ),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                memo.content,
                maxLines: 1,
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
              })).then((_) {
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
