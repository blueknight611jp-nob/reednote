import 'package:flutter/material.dart';

// 共通の糸カラー決定ヘルパー
Color getThreadColor(String? threadName) {
  if (threadName == null) return Colors.grey;
  final name = threadName.toLowerCase();
  if (name.contains('赤') || name.contains('桃') || name.contains('red') || name.contains('pink')) {
    return name.contains('桃') ? Colors.pinkAccent : Colors.red;
  }
  if (name.contains('青') || name.contains('blue')) return Colors.blue;
  if (name.contains('黄') || name.contains('yellow')) return Colors.amber;
  if (name.contains('緑') || name.contains('green')) return Colors.green;
  if (name.contains('黒') || name.contains('black')) return Colors.black87;
  if (name.contains('紫') || name.contains('purple')) return Colors.purple;
  if (name.contains('橙') || name.contains('orange')) return Colors.deepOrange;
  if (name.contains('白') || name.contains('white')) return Colors.grey.shade300;
  return Colors.brown;
}