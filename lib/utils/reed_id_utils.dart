import 'package:flutter/material.dart';

class ReedIdUtils {
  /// ID文字列をパーツごとに分解して、クリック可能なリンク風ウィジェットにする
  static Widget buildClickableIdParts(
    BuildContext context,
    String fullId,
    TabController? tabController, {
    Function(int tabIndex, String targetId)? onJumpAndHighlight, // 追加
  }) {
    // カッコや余分な文字を取り除き、ハイフンで分割
    final cleanId = fullId.replaceAll(RegExp(r'[()]'), '');
    final parts = cleanId.split('-');

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: parts.map((part) {
        return InkWell(
          onTap: () => handleIdPartTap(
            context, 
            part, 
            tabController, 
            onJumpAndHighlight: onJumpAndHighlight, // 渡す
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
            child: Text(
              part,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// パーツがタップされたときのタブ切り替え処理
  static void handleIdPartTap(
    BuildContext context,
    String part,
    TabController? tabController, {
    Function(int tabIndex, String targetId)? onJumpAndHighlight, // 追加
  }) {
    int targetIndex = -1;
    String targetTabName = '';

    // プレフィックスの頭文字でジャンプ先を判定
    if (part.startsWith('T')) {
      targetIndex = 0; // 1. 丸材(T)
      targetTabName = '丸材(T)';
    } else if (part.startsWith('P')) {
      targetIndex = 1; // 2. 半カマボコ(P)
      targetTabName = '半カマボコ(P)';
    } else if (part.startsWith('G')) {
      targetIndex = 2; // 3. カマボコ(G)
      targetTabName = 'カマボコ(G)';
    } else if (part.startsWith('S')) {
      targetIndex = 3; // 4. 舟形(S)
      targetTabName = '舟形(S)';
    } else if (part.startsWith('H')) {
      targetIndex = 4; // 5. チューブ(Hülse)
      targetTabName = 'チューブ(Staple)';
    } else if (part.startsWith('W')) {
      targetTabName = 'ワークリード';
    }

    if (targetIndex != -1 && tabController != null) {
      // ハイライト付きジャンプが指定されていればそれを実行、なければ通常のタブ移動
      if (onJumpAndHighlight != null) {
        onJumpAndHighlight(targetIndex, part);
      } else {
        tabController.animateTo(targetIndex);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('「$part」から $targetTabName タブへ移動しました'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('IDパーツ: $part')),
      );
    }
  }
}