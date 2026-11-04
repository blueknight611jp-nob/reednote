import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';

class DismantleResult {
  final bool stapleUpdated;
  final String? stapleInfo;
  final bool tiedStockRemoved;

  DismantleResult({
    required this.stapleUpdated,
    this.stapleInfo,
    required this.tiedStockRemoved,
  });
}

class DismantleHelper {
  /// リードを分解し、チューブステータスを未使用に戻し、糸巻きストックから削除する
  static Future<DismantleResult> dismantleReed({
    required WorkReed reed,
    required SharedPreferences prefs,
  }) async {
    // 1. 糸巻きストック (tied_stocks) から該当するリード/チューブを削除
    bool tiedRemoved = false;
    final tiedJson = prefs.getString('tied_stocks');
    if (tiedJson != null) {
      final List decodedTied = jsonDecode(tiedJson);
      final List<TiedStock> tiedStocks =
          decodedTied.map((e) => TiedStock.fromJson(e)).toList();
      final beforeCount = tiedStocks.length;
      tiedStocks.removeWhere((t) => t.id == reed.id || t.stapleId == reed.stapleId);
      if (tiedStocks.length != beforeCount) {
        await prefs.setString(
          'tied_stocks',
          jsonEncode(tiedStocks.map((e) => e.toJson()).toList()),
        );
        tiedRemoved = true;
      }
    }

    // 2. チューブストック (staple_stocks) のステータスを「未使用(unused)」へ更新
    final stapleJson = prefs.getString('staple_stocks');
    bool stapleUpdated = false;
    String targetStapleInfo = reed.stapleId;

    if (stapleJson != null) {
      final List decoded = jsonDecode(stapleJson);
      final List<StapleStock> staples =
          decoded.map((e) => StapleStock.fromJson(e)).toList();

      // (A) stapleId の完全一致検索
      for (var st in staples) {
        if (st.id == reed.stapleId) {
          st.status = StapleStatus.unused;
          targetStapleInfo = '${st.model} ${st.length}mm (${st.mark})';
          stapleUpdated = true;
          break;
        }
      }

      // (B) ID不一致時のフォールバック:
      //     「糸巻き済み (tied)」状態のチューブの中から、モデル名やマークが合致するものを検索
      if (!stapleUpdated) {
        for (var st in staples) {
          if (st.status == StapleStatus.tied) {
            final matchesModel = st.model.isNotEmpty &&
                (reed.shapedTitle.contains(st.model) ||
                    reed.stapleId.contains(st.model) ||
                    reed.id.contains(st.model));
            final matchesMark = st.mark.isNotEmpty &&
                (reed.stapleId.contains(st.mark) || reed.id.contains(st.mark));

            if (matchesModel || matchesMark) {
              st.status = StapleStatus.unused;
              targetStapleInfo = '${st.model} ${st.length}mm (${st.mark})';
              stapleUpdated = true;
              break;
            }
          }
        }
      }

      if (stapleUpdated) {
        await prefs.setString(
          'staple_stocks',
          jsonEncode(staples.map((e) => e.toJson()).toList()),
        );
      }
    }

    return DismantleResult(
      stapleUpdated: stapleUpdated,
      stapleInfo: targetStapleInfo,
      tiedStockRemoved: tiedRemoved,
    );
  }
}
