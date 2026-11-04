import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:reednote/models.dart';
import 'package:reednote/utils/dismantle_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DismantleHelper Tests', () {
    test('stapleId完全一致でチューブが未使用に戻り、tied_stocksから削除される', () async {
      SharedPreferences.setMockInitialValues({
        'staple_stocks': jsonEncode([
          {
            'id': 'staple_1',
            'model': 'Chiarugi 2',
            'length': '46',
            'mark': 'a',
            'status': 'tied',
          },
          {
            'id': 'staple_2',
            'model': 'Rigotti',
            'length': '47',
            'mark': 'b',
            'status': 'tied',
          },
        ]),
        'tied_stocks': jsonEncode([
          {
            'id': 'tied_1',
            'stapleId': 'staple_1',
            'shapedCode': 'S01-Rig2506',
            'shapedTitle': 'Rig2506S-0.58-H39',
            'tiedDate': '2026-11-01',
            'totalLength': 73.0,
          },
          {
            'id': 'tied_2',
            'stapleId': 'staple_2',
            'shapedCode': 'S02-Rig2506',
            'shapedTitle': 'Rig2506S-0.58-H39',
            'tiedDate': '2026-11-02',
            'totalLength': 73.0,
          },
        ]),
      });

      final prefs = await SharedPreferences.getInstance();

      final reed = WorkReed(
        id: 'tied_1',
        stapleId: 'staple_1',
        shapedCode: 'S01-Rig2506',
        shapedTitle: 'Rig2506S-0.58-H39',
        tiedDate: '2026-11-01',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 1,
        logs: [],
      );

      final result = await DismantleHelper.dismantleReed(reed: reed, prefs: prefs);

      expect(result.stapleUpdated, isTrue);
      expect(result.tiedStockRemoved, isTrue);
      expect(result.stapleInfo, 'Chiarugi 2 46mm (a)');

      // 検証: staple_stocks
      final updatedStaplesJson = prefs.getString('staple_stocks');
      final List updatedStaples = jsonDecode(updatedStaplesJson!);
      expect(updatedStaples[0]['status'], 'unused');
      expect(updatedStaples[1]['status'], 'tied'); // 他のものはtiedのまま

      // 検証: tied_stocks
      final updatedTiedJson = prefs.getString('tied_stocks');
      final List updatedTied = jsonDecode(updatedTiedJson!);
      expect(updatedTied.length, 1);
      expect(updatedTied[0]['id'], 'tied_2');
    });

    test('フォールバック一致: stapleIdが不一致でもtied状態かつモデル名一致のチューブをunusedに戻す', () async {
      SharedPreferences.setMockInitialValues({
        'staple_stocks': jsonEncode([
          {
            'id': 'staple_real_99',
            'model': 'Chiarugi 2',
            'length': '46',
            'mark': 'x',
            'status': 'tied',
          },
        ]),
        'tied_stocks': jsonEncode([]),
      });

      final prefs = await SharedPreferences.getInstance();

      final reed = WorkReed(
        id: 'reed_mismatch',
        stapleId: 'temporary_id_not_found',
        shapedCode: 'S01',
        shapedTitle: 'Chiarugi 2 46mm',
        tiedDate: '2026-11-01',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 2,
        logs: [],
      );

      final result = await DismantleHelper.dismantleReed(reed: reed, prefs: prefs);

      expect(result.stapleUpdated, isTrue);
      expect(result.stapleInfo, 'Chiarugi 2 46mm (x)');

      final updatedStaplesJson = prefs.getString('staple_stocks');
      final List updatedStaples = jsonDecode(updatedStaplesJson!);
      expect(updatedStaples[0]['status'], 'unused');
    });

    test('一致するチューブが見つからない場合は stapleUpdated: false となる', () async {
      SharedPreferences.setMockInitialValues({
        'staple_stocks': jsonEncode([
          {
            'id': 'other_staple',
            'model': 'Loree',
            'length': '47',
            'mark': 'z',
            'status': 'unused', // 既にunusedなのでtiedのフォールバックにも掛からない
          },
        ]),
        'tied_stocks': jsonEncode([]),
      });

      final prefs = await SharedPreferences.getInstance();

      final reed = WorkReed(
        id: 'reed_unknown',
        stapleId: 'non_existent_id',
        shapedCode: 'S01',
        shapedTitle: 'Rigotti 46mm',
        tiedDate: '2026-11-01',
        totalLength: 73.0,
        cuttingLength: '71.0',
        qualityLevel: 1,
        logs: [],
      );

      final result = await DismantleHelper.dismantleReed(reed: reed, prefs: prefs);

      expect(result.stapleUpdated, isFalse);
    });
  });
}
