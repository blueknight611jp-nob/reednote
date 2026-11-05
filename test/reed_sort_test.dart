import 'package:flutter_test/flutter_test.dart';
import 'package:reednote/models.dart';

void main() {
  group('リード管理・調整のソート機能テスト', () {
    late WorkReed reed1;
    late WorkReed reed2;
    late WorkReed reed3;
    late List<StapleStock> staples;

    setUp(() {
      staples = [
        StapleStock(id: 's1', model: 'Chiarugi 2', length: '46', mark: 'a'),
        StapleStock(id: 's2', model: 'Rigotti', length: '47', mark: 'b'),
        StapleStock(id: 's3', model: 'Loree', length: '46', mark: 'c'),
      ];

      // reed1: Chiarugi 2, ケーン S02, 糸: 赤, 登録日: 2026-11-01, ログ: 2026-11-04
      reed1 = WorkReed(
        id: 'r1',
        stapleId: 's1',
        shapedCode: 'S02-Can2501',
        shapedTitle: 'Chiarugi 2 46mm',
        tiedDate: '2026-11-01',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 1,
        threadColor: '赤',
        logs: [
          WorkReedLog(date: '2026-11-04', level: 1),
          WorkReedLog(date: '2026-11-02', level: 1),
        ],
      );

      // reed2: Rigotti, ケーン S01, 糸: 青, 登録日: 2026-11-03, ログ: 2026-11-05
      reed2 = WorkReed(
        id: 'r2',
        stapleId: 's2',
        shapedCode: 'S01-Can2501',
        shapedTitle: 'Rigotti 47mm',
        tiedDate: '2026-11-03',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 1,
        threadColor: '青',
        logs: [
          WorkReedLog(date: '2026-11-05', level: 1),
        ],
      );

      // reed3: Loree, ケーン S03, 糸: 黄, 登録日: 2026-11-02, ログなし
      reed3 = WorkReed(
        id: 'r3',
        stapleId: 's3',
        shapedCode: 'S03-Can2501',
        shapedTitle: 'Loree 46mm',
        tiedDate: '2026-11-02',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 1,
        threadColor: '黄',
        logs: [],
      );
    });

    String getStapleModel(WorkReed reed) {
      final staple = staples.firstWhere(
        (s) => s.id == reed.stapleId,
        orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
      );
      if (staple.model.isNotEmpty) {
        return '${staple.model} ${staple.length}${staple.mark}';
      }
      return reed.shapedTitle;
    }

    List<WorkReed> sortReeds(List<WorkReed> list, String sortOrder) {
      final reeds = List<WorkReed>.from(list);
      reeds.sort((a, b) {
        switch (sortOrder) {
          case 'log_date_desc':
            final aDate = a.logs.isNotEmpty ? a.logs.first.date : '';
            final bDate = b.logs.isNotEmpty ? b.logs.first.date : '';
            if (aDate.isEmpty && bDate.isNotEmpty) return 1;
            if (aDate.isNotEmpty && bDate.isEmpty) return -1;
            int cmp = bDate.compareTo(aDate);
            if (cmp != 0) return cmp;
            return b.tiedDate.compareTo(a.tiedDate);

          case 'log_date_asc':
            final aDate = a.logs.isNotEmpty ? a.logs.first.date : '';
            final bDate = b.logs.isNotEmpty ? b.logs.first.date : '';
            if (aDate.isEmpty && bDate.isNotEmpty) return 1;
            if (aDate.isNotEmpty && bDate.isEmpty) return -1;
            int cmp = aDate.compareTo(bDate);
            if (cmp != 0) return cmp;
            return a.tiedDate.compareTo(b.tiedDate);

          case 'model':
            final aModel = getStapleModel(a);
            final bModel = getStapleModel(b);
            int cmp = aModel.compareTo(bModel);
            if (cmp != 0) return cmp;
            return b.tiedDate.compareTo(a.tiedDate);

          case 'cane_id':
            final aCode = a.shapedCode.isNotEmpty ? a.shapedCode : a.id;
            final bCode = b.shapedCode.isNotEmpty ? b.shapedCode : b.id;
            int cmp = aCode.compareTo(bCode);
            if (cmp != 0) return cmp;
            return b.tiedDate.compareTo(a.tiedDate);

          case 'thread_color':
            final aColor = a.threadColor ?? '';
            final bColor = b.threadColor ?? '';
            int cmp = aColor.compareTo(bColor);
            if (cmp != 0) return cmp;
            return b.tiedDate.compareTo(a.tiedDate);

          case 'tied_date_desc':
            int cmp = b.tiedDate.compareTo(a.tiedDate);
            if (cmp != 0) return cmp;
            return b.id.compareTo(a.id);

          case 'tied_date_asc':
            int cmp = a.tiedDate.compareTo(b.tiedDate);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);

          default:
            return 0;
        }
      });
      return reeds;
    }

    test('ログの日時 (新しい順): 最新ログの日時が新しい順に並び、ログなしは末尾になる', () {
      final sorted = sortReeds([reed1, reed3, reed2], 'log_date_desc');
      // reed2 (11-05), reed1 (11-04), reed3 (ログなし)
      expect(sorted.map((r) => r.id).toList(), ['r2', 'r1', 'r3']);
    });

    test('ログの日時 (古い順): ログの日時が古い順に並び、ログなしは末尾になる', () {
      final sorted = sortReeds([reed2, reed1, reed3], 'log_date_asc');
      // reed1 (11-04), reed2 (11-05), reed3 (ログなし)
      expect(sorted.map((r) => r.id).toList(), ['r1', 'r2', 'r3']);
    });

    test('モデル名順: チューブのモデル名順に並ぶ', () {
      final sorted = sortReeds([reed2, reed1, reed3], 'model');
      // Chiarugi 2 (r1), Loree (r3), Rigotti (r2)
      expect(sorted.map((r) => r.id).toList(), ['r1', 'r3', 'r2']);
    });

    test('ケーンのID順: shapedCode順に並ぶ', () {
      final sorted = sortReeds([reed3, reed1, reed2], 'cane_id');
      // S01 (r2), S02 (r1), S03 (r3)
      expect(sorted.map((r) => r.id).toList(), ['r2', 'r1', 'r3']);
    });

    test('糸の色順: 糸の色文字列で昇順ソートされる', () {
      final sorted = sortReeds([reed1, reed2, reed3], 'thread_color');
      // '赤', '青', '黄' (Unicode / 辞書順)
      // '赤'.compareTo('青') < 0 (赤: \u8d64, 青: \u9752, 黄: \u9ec4)
      expect(sorted.map((r) => r.id).toList(), ['r1', 'r2', 'r3']);
    });

    test('登録日 (新しい順): tiedDateが新しい順に並ぶ', () {
      final sorted = sortReeds([reed1, reed3, reed2], 'tied_date_desc');
      // reed2 (11-03), reed3 (11-02), reed1 (11-01)
      expect(sorted.map((r) => r.id).toList(), ['r2', 'r3', 'r1']);
    });

    test('登録日 (古い順): tiedDateが古い順に並ぶ', () {
      final sorted = sortReeds([reed2, reed1, reed3], 'tied_date_asc');
      // reed1 (11-01), reed3 (11-02), reed2 (11-03)
      expect(sorted.map((r) => r.id).toList(), ['r1', 'r3', 'r2']);
    });
  });
}
