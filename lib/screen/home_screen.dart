// ホーム画面、メモの一覧ページ

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
import 'package:memoapp/screen/return_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  late Future<List<Memo>> _futureMemos;
  int memoNum = 0;
  String loadedTitle = '';
  String loadedContent = '';
  int? loadedTag;
  String? loadedStatus = '';

  Map<String, String> headers = {
    HttpHeaders.authorizationHeader: 
    'Bearer ${dotenv.env['NOTION_API_KEY']}',
    'Notion-Version': '2022-06-28',
    'Content-Type': 'application/json',
  };

  // DBからメモを取得
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

  // メモの削除
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

  // メモのピン留め
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

  // PATCH処理の場合のstatusCode確認
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

  // アプリ実行時にメモを取得
  @override
  void initState() {
    super.initState();
    _futureMemos = getMemos();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      getValues().then((_) {
        checkReturn();
      });
    });
  }

  getValues() async {
    final prefs = await SharedPreferences.getInstance();
    loadedTitle = prefs.getString('title') ?? '';
    loadedContent = prefs.getString('content') ?? '';
    loadedTag = prefs.getInt('tag');
    loadedStatus = prefs.getString('status');
  }

  removeValue() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.remove('title');
    await prefs.remove('content');
    await prefs.remove('tag');
    await prefs.remove('status');
    await prefs.remove('pageId');
  }

  void checkReturn() {
    if (loadedTitle != '' || loadedContent != '' || loadedTag != null) {
      _showReturnDialog();
    }
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
              color: Theme.of(context).colorScheme.onInverseSurface,
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

  // リストをスライドした時の処理
  Widget slidable(Memo memo) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.5,
        children: [
          ...memo.pin ? [
            SlidableAction(
              onPressed: (_) {
                showIndicator(context);
                pinMemo(memo.pageId, false); 
              },
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              icon: Icons.push_pin_outlined,
            )
          ] : [
            SlidableAction(
              onPressed: (_) {
                showIndicator(context);
                pinMemo(memo.pageId, true); 
              },
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              icon: Icons.push_pin,
            ),
          ],
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
        removeValue();
      }),
      title: showMemoData(memo)
    );
  }

  // 各メモの表示内容
  Widget showMemoData(dynamic memo) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 3,
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
        Expanded(
          flex: 1,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              DateFormat('yyyy/M/d').format(memo.lastEditedTime),
              maxLines: 1,
            ),
          ),
        ),
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

//  メモの件数表示
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

  // 新規作成ボタン
  Widget createNewButton() {
    return IconButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return CreateNewScreen(); 
      })).then((_) {
        setState(() {
          _futureMemos = getMemos();
        });
        removeValue();
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

  // 通信時のインジケーター表示
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

  Widget returnDialog() {
    return AlertDialog(
      title: Text('中断されたメモがあります'),
      content: Text('再開しますか？'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'Cancel');
            removeValue();
          },
          child: Text('Cancel')
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'OK');
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return ReturnScreen(status: loadedStatus); 
            })).then((_) {
              setState(() {
                _futureMemos = getMemos();
              });
              removeValue();
            });
          },
          child: Text('OK')
        )
      ]
    );
  }

  void _showReturnDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => returnDialog());
  }
} 
