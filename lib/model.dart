// メモのモデルクラス

import 'package:memoapp/enum.dart';

class Memo {
  final String title;
  final String content;
  final DateTime createdTime;
  final DateTime lastEditedTime;
  final Tags tag;
  final bool pin;
  final String pageId;

  const Memo({
    required this.title,
    required this.content,
    required this.createdTime,
    required this.lastEditedTime,
    required this.tag,
    required this.pin,
    required this.pageId
  });

  // 取得したデータからインスタンス化
  factory Memo.fromMap(Map<String, dynamic> map) {
    final properties = map['properties'] as Map<String, dynamic>;
    final createdTimeStr = map['created_time'];
    final lastEditedTimeStr = map['last_edited_time'];
    return Memo(
      title: properties['タイトル']?['title']?[0]?['plain_text'] ?? 'none', 
      content: properties['内容']?['rich_text']?[0]?['plain_text'] ?? 'none', 
      createdTime: DateTime.parse(createdTimeStr), 
      lastEditedTime: DateTime.parse(lastEditedTimeStr), 
      tag: Tags.getEnum(properties['タグ']?['select']?['name']),
      pin: properties['ピン']?['checkbox'],
      pageId: map["id"]
    );
  }
}