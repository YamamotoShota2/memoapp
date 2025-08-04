import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:memoapp/components/custom_dialog.dart';
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
  int memoNum = 0;

  Map<String, String> headers = {
    HttpHeaders.authorizationHeader: 
    'Bearer ${dotenv.env['NOTION_API_KEY']}',
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  Future<List<Memo>> getMemos() async {
    try {
      final url = 'https://api.notion.com/v1/databases/${dotenv.env['NOTION_DATABASE_KEY']}/query';
      final response = await http.post(
        Uri.parse(url),
        headers: headers
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
        headers: headers,
        body: jsonEncode({
          "archived": true
        })
      );

      checkStatusCode(response);
    } catch (e) {
      hideIndicator(context);
      _showAlert('エラー', e.toString());
    }
  }

  Future<void> pinMemo(String pageId, bool check) async {
    try {
      final url = 'https://api.notion.com/v1/pages/${pageId}';
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode({
          "properties": {
            "ピン": {"checkbox": check}
          }
        })
      );

      checkStatusCode(response);
    } catch (e) {
      hideIndicator(context);
      _showAlert('エラー', e.toString());
    }
  }

  void checkStatusCode(response) {
    if (response.statusCode == 200) {
        hideIndicator(context);
        setState(() {
          _futureMemos = getMemos();
        });
      } else {
        throw Exception(response.body);
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
          final (memos, pinMemos) = makeMemosList(snapshot.data!);
          memoNum = memos.length + pinMemos.length;
          return SingleChildScrollView(
            child: futureBody(pinMemos, memos),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      }
    );
  }

  Widget futureBody(List pinMemos, List memos) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'ピン留めされたメモ',
            style: TextStyle(
              fontSize: 20
            ),
          ),
        ),
        memosList(pinMemos), 
        Divider(
          height: 50,
        ),  
        memosList(memos),
      ],
    );
  }

  // ピン留めされたメモとそうでないものを分ける
  (List, List) makeMemosList(List data) {
    List memos = [];
    List pinMemos = [];
    for (dynamic memo in data) {
      if (memo.pin == true) {
        pinMemos.add(memo);
      } else {
        memos.add(memo);
      }
    }
    return (memos, pinMemos);
  }

  Widget memosList(List memos) {
    return Column(
      children: [
        for(Memo memo in memos) ...{
          Container(
            margin: EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(
                width: 2.0,
                color: memo.tag.getColor(),
              )
            ),
            child: slidable(memo),
          ),
        }
      ],
    );
  }

  Widget slidable(Memo memo) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          SlidableAction(
            onPressed: (_) {
              showIndicator(context);
              memo.pin ? pinMemo(memo.pageId, false) : pinMemo(memo.pageId, true); 
            },
            backgroundColor: Colors.orangeAccent,
            foregroundColor: Colors.white,
            icon: Icons.push_pin,
          ),
          SlidableAction(
            onPressed: (_) {
              showIndicator(context);
              deleteMemo(memo.pageId);
            },
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8.0),
              bottomRight: Radius.circular(8.0) 
            ),
          )
        ]
      ),
      child: listTile(memo),
    );
  }

  Widget listTile(Memo memo) {
    return ListTile(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return EditScreen(memo: memo);
      })).then((_) {
        setState(() {
          _futureMemos = getMemos();
        });
      }),
      title: showMemoData(memo)
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
          child: Row(
            children: [
              Expanded(child: SizedBox()),
              Center(child: showMemoNum()),
              Expanded(
                child: Align(
                  alignment: Alignment.topRight,
                  child: createNewButton(),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget showMemoNum() {
    return FutureBuilder(
      future: _futureMemos, 
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text('$memoNum件のメモ');
        }
        return SizedBox();
      }
    );
  }

  Widget createNewButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return CreateNewScreen(); 
      })).then((_) {
        setState(() {
          _futureMemos = getMemos();
        });
      }),
      icon: Icon(Icons.edit_square),
      iconSize: 40,
    );
  }

    // ダイアログ表示
  void _showAlert(String alertTitle, String msg) {
    showDialog(
      context: context,
      builder: (BuildContext context) => CustomDialog(title: alertTitle, msg: msg));
  }

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

  void hideIndicator(BuildContext context) {
    Navigator.pop(context);
  }
} 
