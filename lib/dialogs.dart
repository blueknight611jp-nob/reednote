import 'package:flutter/material.dart';
import 'models.dart';

/// 素材の種類を識別するEnum
enum CaneType { tube, split, gouged, shaped }

class StockDialogs {

  // --- 共通ヘルパー: リストから出現頻度が高い順（よく使う順）に抽出する ---
  static List<String> _getFrequentOptions(List<String> rawList) {
    final Map<String, int> frequencyMap = {};
    for (var item in rawList) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty) {
        frequencyMap[trimmed] = (frequencyMap[trimmed] ?? 0) + 1;
      }
    }
    final sortedKeys = frequencyMap.keys.toList()
      ..sort((a, b) => frequencyMap[b]!.compareTo(frequencyMap[a]!));
    return sortedKeys;
  }

  // --- 共通サジェスト付きテキストフィールド（ドロップダウン/ポップアップ表示対応） ---
  static Widget _buildAutocompleteField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return options;
        }
        return options.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        if (fieldController.text != controller.text && controller.text.isNotEmpty) {
          fieldController.text = controller.text;
        }
        fieldController.addListener(() {
          controller.text = fieldController.text;
        });

        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.arrow_drop_down, size: 20),
          ),
        );
      },
    );
  }

  // --- 現在の年月からYYMMを自動生成するヘルパー ---
  static String get _currentYYMM {
    final now = DateTime.now();
    return '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}';
  }

  // ==========================================================
  // 1. ケーン素材 共通新規登録ダイアログ（丸材/半カマボコ/カマボコ/舟形）
  // ==========================================================
  static void showAddCaneDialog({
    required BuildContext context,
    required CaneType caneType,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required List<String> existingVendors,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(dynamic) onRegistered,
  }) {
    final brandController = TextEditingController();
    final periodController = TextEditingController(text: _currentYYMM);
    final diameterController = TextEditingController(text: '10-10.5');
    final vendorController = TextEditingController();
    final countController = TextEditingController(text: '10');
    final memoController = TextEditingController();

    final machineController = TextEditingController(text: caneType == CaneType.gouged ? '既製品購入' : '');
    final shaperController = TextEditingController(text: 'H39');
    final thickController = TextEditingController(text: '0.58');

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentVendors = _getFrequentOptions(existingVendors);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);
    final frequentShapers = _getFrequentOptions(['H39', 'H69', 'H25', 'Chiarugi 2']);
    final frequentThicks = _getFrequentOptions(['0.58', '0.59', '0.60', '0.57']);

    String title;
    String typeLetter;
    switch (caneType) {
      case CaneType.tube:
        title = '丸材(T) 新規登録';
        typeLetter = 'T';
        break;
      case CaneType.split:
        title = '半カマボコ(P) 新規登録（直接購入）';
        typeLetter = 'P';
        break;
      case CaneType.gouged:
        title = 'カマボコ(G) 新規登録（直接購入）';
        typeLetter = 'G';
        break;
      case CaneType.shaped:
        title = '舟形(S) 新規登録（直接購入）';
        typeLetter = 'S';
        break;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: vendorController, label: '購入先 (任意)', options: frequentVendors),
              const SizedBox(height: 8),

              if (caneType == CaneType.tube || caneType == CaneType.split) ...[
                _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
                const SizedBox(height: 8),
              ],

              if (caneType == CaneType.gouged) ...[
                TextField(controller: machineController, decoration: const InputDecoration(labelText: 'ガウジングマシン')),
                const SizedBox(height: 8),
                _buildAutocompleteField(controller: thickController, label: '目標厚さ (例: 0.58)', options: frequentThicks),
                const SizedBox(height: 8),
              ],

              if (caneType == CaneType.shaped) ...[
                _buildAutocompleteField(controller: shaperController, label: 'シェイパー型番', options: frequentShapers),
                const SizedBox(height: 8),
                TextField(controller: thickController, decoration: const InputDecoration(labelText: '厚さ (任意)')),
                const SizedBox(height: 8),
              ],

              TextField(controller: countController, decoration: const InputDecoration(labelText: '数量'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final brand = brandController.text.trim();
              final period = periodController.text.trim();
              if (brand.isEmpty || period.isEmpty) return;

              final id = getNextCode(brand, period, typeLetter);
              final vendor = vendorController.text.trim().isEmpty ? null : vendorController.text.trim();
              final count = int.tryParse(countController.text) ?? 1;
              final memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              dynamic newStock;
              switch (caneType) {
                case CaneType.tube:
                  newStock = TubeStock(
                    id: id,
                    brand: brand,
                    purchasePeriod: period,
                    diameter: diameterController.text.trim(),
                    vendor: vendor,
                    remainingCount: count,
                    memo: memo,
                  );
                  break;
                case CaneType.split:
                  newStock = SplitCaneStock(
                    id: id,
                    brand: brand,
                    purchasePeriod: period,
                    diameter: diameterController.text.trim(),
                    vendor: vendor, // ← sourceInfo から vendor に修正済み
                    remainingCount: count,
                    memo: memo,
                  );
                  break;
                case CaneType.gouged:
                  newStock = GougedCaneStock(
                    id: id,
                    brand: brand,
                    purchasePeriod: period,
                    diameter: '-',
                    machine: machineController.text.trim(),
                    thickness: double.tryParse(thickController.text.trim()),
                    gougingDate: DateTime.now().toString().split(' ')[0],
                    vendor: vendor,
                    remainingCount: count,
                    memo: memo,
                  );
                  break;
                case CaneType.shaped:
                  newStock = ShapedCaneStock(
                    id: id,
                    brand: brand,
                    purchasePeriod: period,
                    diameter: '-',
                    shaper: shaperController.text.trim(),
                    thickness: double.tryParse(thickController.text.trim()),
                    shapingDate: DateTime.now().toString().split(' ')[0],
                    vendor: vendor,
                    remainingCount: count,
                    memo: memo,
                  );
                  break;
              }

              onRegistered(newStock);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 2. ケーン素材 共通編集ダイアログ（丸材/半カマボコ/カマボコ/舟形）
  // ==========================================================
  static void showEditCaneDialog({
    required BuildContext context,
    required dynamic stock,
    required List<String> existingBrands,
    required List<String> existingVendors,
    required VoidCallback onSaved,
  }) {
    final brandController = TextEditingController(text: stock.brand);
    final periodController = TextEditingController(text: stock.purchasePeriod);
    final diameterController = TextEditingController(text: stock.diameter);
    final vendorController = TextEditingController(text: stock.vendor ?? '');
    final countController = TextEditingController(text: stock.remainingCount.toString());
    final memoController = TextEditingController(text: stock.memo ?? '');

    final machineController = TextEditingController(text: (stock is GougedCaneStock) ? stock.machine : '');
    final shaperController = TextEditingController(text: (stock is ShapedCaneStock) ? stock.shaper : '');
    final thickController = TextEditingController(
      text: (stock is GougedCaneStock || stock is ShapedCaneStock) ? (stock.thickness?.toString() ?? '') : '',
    );

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentVendors = _getFrequentOptions(existingVendors);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);
    final frequentShapers = _getFrequentOptions(['H39', 'H69', 'H25', 'Chiarugi 2']);
    final frequentThicks = _getFrequentOptions(['0.58', '0.59', '0.60', '0.57']);

    String title;
    if (stock is TubeStock) title = '丸材(T) 編集';
    else if (stock is SplitCaneStock) title = '半カマボコ(P) 編集';
    else if (stock is GougedCaneStock) title = 'カマボコ(G) 編集';
    else if (stock is ShapedCaneStock) title = '舟形(S) 編集';
    else title = 'ケーン素材 編集';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: vendorController, label: '購入先 (任意)', options: frequentVendors),
              const SizedBox(height: 8),

              if (stock is TubeStock || stock is SplitCaneStock) ...[
                _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
                const SizedBox(height: 8),
              ],

              if (stock is GougedCaneStock) ...[
                TextField(controller: machineController, decoration: const InputDecoration(labelText: 'ガウジングマシン')),
                const SizedBox(height: 8),
                _buildAutocompleteField(controller: thickController, label: '厚さ', options: frequentThicks),
                const SizedBox(height: 8),
              ],

              if (stock is ShapedCaneStock) ...[
                _buildAutocompleteField(controller: shaperController, label: 'シェイパー型番', options: frequentShapers),
                const SizedBox(height: 8),
                TextField(controller: thickController, decoration: const InputDecoration(labelText: '厚さ')),
                const SizedBox(height: 8),
              ],

              TextField(controller: countController, decoration: const InputDecoration(labelText: '数量'), keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final brand = brandController.text.trim();
              final period = periodController.text.trim();
              if (brand.isEmpty || period.isEmpty) return;

              stock.brand = brand;
              stock.purchasePeriod = period;
              stock.diameter = diameterController.text.trim();
              stock.vendor = vendorController.text.trim().isEmpty ? null : vendorController.text.trim();
              stock.remainingCount = int.tryParse(countController.text) ?? stock.remainingCount;
              stock.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              if (stock is GougedCaneStock) {
                stock.machine = machineController.text.trim();
                stock.thickness = double.tryParse(thickController.text.trim());
              } else if (stock is ShapedCaneStock) {
                stock.shaper = shaperController.text.trim();
                stock.thickness = double.tryParse(thickController.text.trim());
              }

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // 3. チューブ (Staple) 専用ダイアログ（新規登録）
  // ==========================================================
  static void showAddStapleDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required Function(List<StapleStock>) onRegistered,
  }) {
    final brandController = TextEditingController();
    final modelController = TextEditingController(text: '2');
    final lengthController = TextEditingController(text: '46mm');
    final markController = TextEditingController(text: 'a');

    final frequentBrands = _getFrequentOptions(existingBrands);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チューブ 新規登録'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAutocompleteField(
              controller: brandController,
              label: 'ブランド (例: Chiarugi)',
              options: frequentBrands,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: modelController,
              decoration: const InputDecoration(labelText: 'モデル (例: 2)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: lengthController,
              decoration: const InputDecoration(labelText: '長さ (例: 46mm)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: markController,
              decoration: const InputDecoration(labelText: 'マーク (例: a)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              final brand = brandController.text.trim();
              if (brand.isEmpty) return;

              // 常に1本だけ生成して呼び出し元へ引き渡す
              final newStaple = StapleStock(
                id: 'Staple_${DateTime.now().microsecondsSinceEpoch}',
                brand: brand,
                model: modelController.text.trim(),
                length: lengthController.text.trim(),
                mark: markController.text.trim(),
                status: StapleStatus.unused,
              );

              onRegistered([newStaple]);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  static void showEditStapleDialog({
    required BuildContext context,
    required StapleStock staple,
    required List<String> existingBrands,
    required VoidCallback onSaved,
  }) {
    final brandController = TextEditingController(text: staple.brand);
    final modelController = TextEditingController(text: staple.model);
    final lengthController = TextEditingController(text: staple.length);
    final markController = TextEditingController(text: staple.mark);
    final memoController = TextEditingController(text: staple.memo ?? '');

    final frequentBrands = _getFrequentOptions(existingBrands);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チューブ 編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: modelController, decoration: const InputDecoration(labelText: 'モデル')),
              const SizedBox(height: 8),
              TextField(controller: lengthController, decoration: const InputDecoration(labelText: '長さ')),
              const SizedBox(height: 8),
              TextField(controller: markController, decoration: const InputDecoration(labelText: 'マーク')),
              const SizedBox(height: 8),
              TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              staple.brand = brandController.text.trim();
              staple.model = modelController.text.trim();
              staple.length = lengthController.text.trim();
              staple.mark = markController.text.trim();
              staple.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // 4. 加工プロセスのダイアログ群（IDチェーン結合）
  // ==========================================================
  static void showProcessTubeToSplitDialog({
    required BuildContext context,
    required TubeStock tube,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(SplitCaneStock) onProcessed,
  }) {
    final countController = TextEditingController(text: '1');
    final memoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('半カマボコ(P)へ加工'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('丸材 [${tube.displayTitle}] から半カマボコを作成します。'),
              const SizedBox(height: 12),
              TextField(
                controller: countController,
                decoration: const InputDecoration(labelText: '加工本数'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: memoController,
                decoration: const InputDecoration(labelText: '加工メモ (任意)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                int count = int.tryParse(countController.text) ?? 1;
                if (count <= 0) count = 1;
                if (count > tube.remainingCount) {
                  count = tube.remainingCount;
                }

                Navigator.pop(context);
                tube.remainingCount -= count;

                String baseSeq = getNextCode(tube.brand, tube.purchasePeriod, 'P').split('-')[0];
                String pId = '$baseSeq-${tube.id}';

                final newSplit = SplitCaneStock(
                  id: pId,
                  brand: tube.brand,
                  purchasePeriod: tube.purchasePeriod,
                  diameter: tube.diameter,
                  vendor: tube.vendor, // 丸材の購入先を引き継ぐ
                  remainingCount: count,
                  memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
                );
                onProcessed(newSplit);
              },
              child: const Text('加工実行'),
            ),
          ],
        );
      },
    );
  }

  static void showProcessSplitToGougedDialog({
    required BuildContext context,
    required SplitCaneStock split,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(GougedCaneStock) onProcessed,
  }) {
    final machineController = TextEditingController(text: 'ミヒャエル');
    final thickController = TextEditingController(text: '0.58');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコ(G)へ加工'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('由来: ${split.id}'),
            TextField(controller: machineController, decoration: const InputDecoration(labelText: 'ガウジングマシン')),
            TextField(controller: thickController, decoration: const InputDecoration(labelText: '目標厚さ (例: 0.58)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              split.remainingCount--;

              String baseSeq = getNextCode(split.brand, split.purchasePeriod, 'G').split('-')[0];
              String gId = '$baseSeq-${split.id}';
              double? thickness = double.tryParse(thickController.text.trim());

              final newGouged = GougedCaneStock(
                id: gId,
                brand: split.brand,
                purchasePeriod: split.purchasePeriod,
                diameter: split.diameter,
                machine: machineController.text.trim(),
                thickness: thickness,
                gougingDate: DateTime.now().toString().split(' ')[0],
                vendor: split.vendor, // 半カマボコの購入先を引き継ぐ
                remainingCount: 1,
              );
              onProcessed(newGouged);
            },
            child: const Text('加工実行'),
          ),
        ],
      ),
    );
  }

  static void showProcessGougedToShapedDialog({
    required BuildContext context,
    required GougedCaneStock gouged,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(ShapedCaneStock) onProcessed,
  }) {
    final shaperController = TextEditingController(text: 'H39');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舟形(S)へ加工'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('由来: ${gouged.id}'),
            TextField(controller: shaperController, decoration: const InputDecoration(labelText: 'シェイパー型番 (例: H39, H25)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              gouged.remainingCount--;

              String baseSeq = getNextCode(gouged.brand, gouged.purchasePeriod, 'S').split('-')[0];
              String sId = '$baseSeq-${gouged.id}';

              final newShaped = ShapedCaneStock(
                id: sId,
                brand: gouged.brand,
                purchasePeriod: gouged.purchasePeriod,
                diameter: gouged.diameter,
                shaper: shaperController.text.trim(),
                thickness: gouged.thickness,
                shapingDate: DateTime.now().toString().split(' ')[0],
                vendor: gouged.vendor, // カマボコの購入先を引き継ぐ
                remainingCount: 1,
              );
              onProcessed(newShaped);
            },
            child: const Text('加工実行'),
          ),
        ],
      ),
    );
  }

  static void showProcessShapedToTiedDialog({
    required BuildContext context,
    required ShapedCaneStock shaped,
    required List<StapleStock> availableStaples,
    required Function(TiedStock, StapleStock) onProcessed,
  }) {
    StapleStock? selectedStaple = availableStaples.isNotEmpty ? availableStaples.first : null;
    final lengthController = TextEditingController(text: '73.0');
    final colorController = TextEditingController(text: '赤');
    final memoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('チューブを選んで糸巻き'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ケーン: ${shaped.displayTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (availableStaples.isEmpty)
                  const Text('利用可能な未使用チューブがありません', style: TextStyle(color: Colors.red))
                else
                  DropdownButton<StapleStock>(
                    isExpanded: true,
                    value: selectedStaple,
                    items: availableStaples.map((st) => DropdownMenuItem(value: st, child: Text('[${st.brand} ${st.model}] ${st.length} (${st.mark})'))).toList(),
                    onChanged: (val) => setState(() => selectedStaple = val),
                  ),
                TextField(controller: lengthController, decoration: const InputDecoration(labelText: '全長 (mm)')),
                TextField(controller: colorController, decoration: const InputDecoration(labelText: '糸の色')),
                TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: selectedStaple == null ? null : () {
                Navigator.pop(context);

                String staplePrefix = '${selectedStaple!.brand}${selectedStaple!.mark}'.replaceAll(' ', '');
                String tiedId = '$staplePrefix-${shaped.id}';

                final tied = TiedStock(
                  id: tiedId,
                  stapleId: selectedStaple!.id,
                  shapedCode: shaped.id,
                  shapedTitle: shaped.displayTitle,
                  tiedDate: DateTime.now().toString().split(' ')[0],
                  totalLength: double.tryParse(lengthController.text) ?? 73.0,
                  threadColor: colorController.text.trim(),
                  vendor: shaped.vendor, // 舟形の購入先を糸巻きストックへ引き継ぐ
                  memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
                );
                onProcessed(tied, selectedStaple!);
              },
              child: const Text('糸巻き完了'),
            ),
          ],
        ),
      ),
    );
  }
}