import 'package:flutter_test/flutter_test.dart';
import 'package:reednote/models.dart';

void main() {
  group('素材ストック管理のソート機能テスト', () {
    test('1. 丸材(TubeStock)のソート', () {
      final t1 = TubeStock(id: 'T01-Rig2506', brand: 'Rigotti', purchasePeriod: '2506', diameter: '10-10.5', remainingCount: 15, vendor: 'B店');
      final t2 = TubeStock(id: 'T02-Rig2601', brand: 'Rigotti', purchasePeriod: '2601', diameter: '9.5-10', remainingCount: 5, vendor: 'A店');
      final t3 = TubeStock(id: 'T03-All2501', brand: 'Alliaud', purchasePeriod: '2501', diameter: '10.5-11', remainingCount: 20, vendor: 'C店');

      List<TubeStock> sort(List<TubeStock> list, String order) {
        final res = List<TubeStock>.from(list);
        res.sort((a, b) {
          switch (order) {
            case 'cane_id': return b.code.compareTo(a.code);
            case 'purchase_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'purchase_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'diameter': return a.diameter.compareTo(b.diameter);
            case 'count_desc': return b.remainingCount.compareTo(a.remainingCount);
            case 'count_asc': return a.remainingCount.compareTo(b.remainingCount);
            case 'vendor': return (a.vendor ?? '').compareTo(b.vendor ?? '');
            default: return b.code.compareTo(a.code);
          }
        });
        return res;
      }

      // ケーンID順 (降順: T03, T02, T01)
      expect(sort([t1, t2, t3], 'cane_id').map((e) => e.id).toList(), ['T03-All2501', 'T02-Rig2601', 'T01-Rig2506']);

      // 購入日 (新しい順: 2601, 2506, 2501)
      expect(sort([t1, t2, t3], 'purchase_desc').map((e) => e.id).toList(), ['T02-Rig2601', 'T01-Rig2506', 'T03-All2501']);

      // 在庫数 (多い順: 20, 15, 5)
      expect(sort([t1, t2, t3], 'count_desc').map((e) => e.id).toList(), ['T03-All2501', 'T01-Rig2506', 'T02-Rig2601']);

      // 購入先順 (A店, B店, C店)
      expect(sort([t1, t2, t3], 'vendor').map((e) => e.id).toList(), ['T02-Rig2601', 'T01-Rig2506', 'T03-All2501']);
    });

    test('3. カマボコ(GougedCaneStock)のソート (ガウジング厚さ・加工日)', () {
      final g1 = GougedCaneStock(id: 'G01', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', machine: 'M', thickness: 0.58, gougingDate: '2026-11-01', remainingCount: 3);
      final g2 = GougedCaneStock(id: 'G02', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', machine: 'M', thickness: 0.56, gougingDate: '2026-11-04', remainingCount: 1);
      final g3 = GougedCaneStock(id: 'G03', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', machine: 'M', thickness: 0.60, gougingDate: '2026-10-20', remainingCount: 2);

      List<GougedCaneStock> sort(List<GougedCaneStock> list, String order) {
        final res = List<GougedCaneStock>.from(list);
        res.sort((a, b) {
          switch (order) {
            case 'process_desc': return b.gougingDate.compareTo(a.gougingDate);
            case 'process_asc': return a.gougingDate.compareTo(b.gougingDate);
            case 'thickness_asc': return (a.thickness ?? 999.0).compareTo(b.thickness ?? 999.0);
            case 'thickness_desc': return (b.thickness ?? 0.0).compareTo(a.thickness ?? 0.0);
            default: return b.code.compareTo(a.code);
          }
        });
        return res;
      }

      // 加工日 (新しい順: 11-04, 11-01, 10-20)
      expect(sort([g1, g2, g3], 'process_desc').map((e) => e.id).toList(), ['G02', 'G01', 'G03']);

      // 厚さ (薄い順: 0.56, 0.58, 0.60)
      expect(sort([g1, g2, g3], 'thickness_asc').map((e) => e.id).toList(), ['G02', 'G01', 'G03']);

      // 厚さ (厚い順: 0.60, 0.58, 0.56)
      expect(sort([g1, g2, g3], 'thickness_desc').map((e) => e.id).toList(), ['G03', 'G01', 'G02']);
    });

    test('4. 舟形(ShapedCaneStock)のソート (シェイパーの型)', () {
      final s1 = ShapedCaneStock(id: 'S01', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', shaper: 'H39', shapingDate: '2026-11-01', remainingCount: 2);
      final s2 = ShapedCaneStock(id: 'S02', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', shaper: 'H25', shapingDate: '2026-11-02', remainingCount: 4);
      final s3 = ShapedCaneStock(id: 'S03', brand: 'Rigotti', purchasePeriod: '2506', diameter: '-', shaper: 'H69', shapingDate: '2026-11-03', remainingCount: 1);

      List<ShapedCaneStock> sort(List<ShapedCaneStock> list, String order) {
        final res = List<ShapedCaneStock>.from(list);
        res.sort((a, b) {
          switch (order) {
            case 'shaper': return a.shaper.compareTo(b.shaper);
            case 'process_desc': return b.shapingDate.compareTo(a.shapingDate);
            default: return b.code.compareTo(a.code);
          }
        });
        return res;
      }

      // シェイパー型順: H25, H39, H69
      expect(sort([s1, s2, s3], 'shaper').map((e) => e.id).toList(), ['S02', 'S01', 'S03']);
    });

    test('5. チューブ(StapleStock)のソート (モデル、長さ、使用状況、マーク)', () {
      final st1 = StapleStock(id: '1', model: 'Chiarugi 2', length: '46', mark: 'b', status: StapleStatus.tied);
      final st2 = StapleStock(id: '2', model: 'Rigotti', length: '47', mark: 'a', status: StapleStatus.unused);
      final st3 = StapleStock(id: '3', model: 'Chiarugi 2', length: '46', mark: 'a', status: StapleStatus.unused);

      List<StapleStock> sort(List<StapleStock> list, String order) {
        final res = List<StapleStock>.from(list);
        res.sort((a, b) {
          switch (order) {
            case 'model':
              int c = a.model.compareTo(b.model);
              if (c != 0) return c;
              c = a.length.compareTo(b.length);
              if (c != 0) return c;
              return a.mark.compareTo(b.mark);
            case 'length':
              int c = a.length.compareTo(b.length);
              if (c != 0) return c;
              return a.model.compareTo(b.model);
            case 'status':
              int c = a.status.index.compareTo(b.status.index);
              if (c != 0) return c;
              return a.model.compareTo(b.model);
            case 'mark':
              int c = a.mark.compareTo(b.mark);
              if (c != 0) return c;
              return a.model.compareTo(b.model);
            default:
              return a.model.compareTo(b.model);
          }
        });
        return res;
      }

      // モデル順: Chiarugi 46a (st3), Chiarugi 46b (st1), Rigotti 47a (st2)
      expect(sort([st1, st2, st3], 'model').map((e) => e.id).toList(), ['3', '1', '2']);

      // 使用状況順: unused (st2, st3) が先、tied (st1) が後
      final statusSorted = sort([st1, st2, st3], 'status');
      expect(statusSorted.last.id, '1');

      // マーク順: mark 'a' (st2, st3) が先、'b' (st1) が後
      final markSorted = sort([st1, st2, st3], 'mark');
      expect(markSorted.last.id, '1');
    });

    test('6. 糸巻き(TiedStock)のソート (チューブフル名、ケーンID、糸種類、糸色、糸巻き日)', () {
      final staples = [
        StapleStock(id: 's1', model: 'Rigotti', length: '47', mark: 'a'),
        StapleStock(id: 's2', model: 'Chiarugi 2', length: '46', mark: 'b'),
      ];

      final td1 = TiedStock(id: 't1', stapleId: 's1', shapedCode: 'S02', shapedTitle: 'title', tiedDate: '2026-11-01', totalLength: 73.0, threadColor: '青', threadMaterial: '絹');
      final td2 = TiedStock(id: 't2', stapleId: 's2', shapedCode: 'S01', shapedTitle: 'title', tiedDate: '2026-11-03', totalLength: 73.0, threadColor: '赤', threadMaterial: 'ナイロン');

      List<TiedStock> sort(List<TiedStock> list, String order) {
        final res = List<TiedStock>.from(list);
        res.sort((a, b) {
          switch (order) {
            case 'staple_full':
              final aStaple = staples.firstWhere((s) => s.id == a.stapleId);
              final bStaple = staples.firstWhere((s) => s.id == b.stapleId);
              final aFull = '${aStaple.model} ${aStaple.length} ${aStaple.mark}';
              final bFull = '${bStaple.model} ${bStaple.length} ${bStaple.mark}';
              return aFull.compareTo(bFull);
            case 'cane_id':
              return a.shapedCode.compareTo(b.shapedCode);
            case 'thread_material':
              return (a.threadMaterial ?? '').compareTo(b.threadMaterial ?? '');
            case 'thread_color':
              return (a.threadColor ?? '').compareTo(b.threadColor ?? '');
            case 'date_desc':
              return b.tiedDate.compareTo(a.tiedDate);
            case 'date_asc':
              return a.tiedDate.compareTo(b.tiedDate);
            default:
              return 0;
          }
        });
        return res;
      }

      // チューブ (モデル+長さ+マーク) 順: Chiarugi 2 (t2) が Rigotti (t1) より先
      expect(sort([td1, td2], 'staple_full').map((e) => e.id).toList(), ['t2', 't1']);

      // ケーンID順: S01 (t2), S02 (t1)
      expect(sort([td1, td2], 'cane_id').map((e) => e.id).toList(), ['t2', 't1']);

      // 糸の種類順: ナイロン (t2) が 絹 (t1) より先
      expect(sort([td1, td2], 'thread_material').map((e) => e.id).toList(), ['t2', 't1']);

      // 糸巻き日 (新しい順): 11-03 (t2), 11-01 (t1)
      expect(sort([td1, td2], 'date_desc').map((e) => e.id).toList(), ['t2', 't1']);
    });
  });
}
