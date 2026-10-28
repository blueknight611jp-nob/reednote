import 'package:flutter/material.dart';
import 'models.dart';

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

  // --- 現在の年月からYYMMを自動生成するヘルパー (例: 2026年10月なら '2610') ---
  static String get _currentYYMM {
    final now = DateTime.now();
    return '${(now.year % 100).toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}';
  }

  // ==========================================
  // 1. 新規登録ダイアログ群（共通サジェスト化）
  // ==========================================

  // 丸材(T) 新規登録
  static void showAddTubeDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required List<String> existingVendors,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(TubeStock) onRegistered,
  }) {
    final brandController = TextEditingController();
    final periodController = TextEditingController(text: _currentYYMM); // 常に本日のYYMMをデフォルトに
    final diameterController = TextEditingController(text: '10-10.5');
    final vendorController = TextEditingController();
    final countController = TextEditingController(text: '10');
    final memoController = TextEditingController();

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentVendors = _getFrequentOptions(existingVendors);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丸材(T) 新規登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド (例: Gonzalez)', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: vendorController, label: '購入先', options: frequentVendors),
              const SizedBox(height: 8),
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

              final id = getNextCode(brand, period, 'T');
              final newStock = TubeStock(
                id: id,
                brand: brand,
                purchasePeriod: period,
                diameter: diameterController.text.trim(),
                vendor: vendorController.text.trim().isEmpty ? null : vendorController.text.trim(),
                remainingCount: int.tryParse(countController.text) ?? 1,
                memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
              );
              onRegistered(newStock);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // 半カマボコ(P) 新規登録（直接購入）
  static void showAddSplitDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(SplitCaneStock) onRegistered,
  }) {
    final brandController = TextEditingController();
    final periodController = TextEditingController(text: _currentYYMM);
    final diameterController = TextEditingController(text: '10-10.5');
    final countController = TextEditingController(text: '10');
    final memoController = TextEditingController();

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('半カマボコ(P) 新規登録（直接購入）'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
              const SizedBox(height: 8),
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
              if (brand.isEmpty) return;

              final id = getNextCode(brand, period, 'P');
              final stock = SplitCaneStock(
                id: id,
                brand: brand,
                purchasePeriod: period,
                diameter: diameterController.text.trim(),
                sourceInfo: '直接購入',
                remainingCount: int.tryParse(countController.text) ?? 1,
                memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
              );
              onRegistered(stock);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // カマボコ(G) 新規登録（直接購入）
  static void showAddGougedDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(GougedCaneStock) onRegistered,
  }) {
    final brandController = TextEditingController();
    final periodController = TextEditingController(text: _currentYYMM);
    final thickController = TextEditingController(text: '0.58');
    final countController = TextEditingController(text: '10');
    final memoController = TextEditingController();

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentThicks = _getFrequentOptions(['0.58', '0.59', '0.60', '0.57']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコ(G) 新規登録（直接購入）'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: thickController, label: '目標厚さ (例: 0.58)', options: frequentThicks),
              const SizedBox(height: 8),
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
              if (brand.isEmpty) return;

              final id = getNextCode(brand, period, 'G');
              final thickness = double.tryParse(thickController.text.trim());

              final stock = GougedCaneStock(
                id: id,
                brand: brand,
                purchasePeriod: period,
                diameter: '-',
                machine: '既製品購入',
                thickness: thickness,
                gougingDate: DateTime.now().toString().split(' ')[0],
                remainingCount: int.tryParse(countController.text) ?? 1,
                memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
              );
              onRegistered(stock);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // 舟形(S) 新規登録（直接購入）
  static void showAddShapedDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(ShapedCaneStock) onRegistered,
  }) {
    final brandController = TextEditingController();
    final periodController = TextEditingController(text: _currentYYMM);
    final shaperController = TextEditingController(text: 'H39');
    final thickController = TextEditingController(text: '0.58');
    final countController = TextEditingController(text: '10');
    final memoController = TextEditingController();

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentShapers = _getFrequentOptions(['H39', 'H69', 'H25', 'Chiarugi 2']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舟形(S) 新規登録（直接購入）'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: shaperController, label: 'シェイパー型番 (例: H39)', options: frequentShapers),
              const SizedBox(height: 8),
              TextField(controller: thickController, decoration: const InputDecoration(labelText: '厚さ (任意)')),
              const SizedBox(height: 8),
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
              if (brand.isEmpty) return;

              final id = getNextCode(brand, period, 'S');
              final thickness = double.tryParse(thickController.text.trim());

              final stock = ShapedCaneStock(
                id: id,
                brand: brand,
                purchasePeriod: period,
                diameter: '-',
                shaper: shaperController.text.trim(),
                thickness: thickness,
                shapingDate: DateTime.now().toString().split(' ')[0],
                remainingCount: int.tryParse(countController.text) ?? 1,
                memo: memoController.text.trim().isEmpty ? null : memoController.text.trim(),
              );
              onRegistered(stock);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // チューブ 新規登録
  static void showAddStapleDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required Function(List<StapleStock>) onRegistered,
  }) {
    final brandController = TextEditingController();
    final modelController = TextEditingController(text: '2 46mm');
    final lengthController = TextEditingController(text: '46');
    final markController = TextEditingController(text: 'a');
    final countController = TextEditingController(text: '10');

    final frequentBrands = _getFrequentOptions(existingBrands);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('チューブ 新規登録'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAutocompleteField(controller: brandController, label: 'ブランド (例: Chiarugi)', options: frequentBrands),
            const SizedBox(height: 8),
            TextField(controller: modelController, decoration: const InputDecoration(labelText: 'モデル (例: 2 46mm)')),
            const SizedBox(height: 8),
            TextField(controller: lengthController, decoration: const InputDecoration(labelText: '長さ')),
            const SizedBox(height: 8),
            TextField(controller: markController, decoration: const InputDecoration(labelText: 'マーク (例: a)')),
            const SizedBox(height: 8),
            TextField(controller: countController, decoration: const InputDecoration(labelText: '数量'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final brand = brandController.text.trim();
              if (brand.isEmpty) return;
              int count = int.tryParse(countController.text) ?? 1;

              List<StapleStock> newStaples = [];
              for (int i = 0; i < count; i++) {
                newStaples.add(StapleStock(
                  id: 'Staple_${DateTime.now().microsecondsSinceEpoch}_$i',
                  brand: brand,
                  model: modelController.text.trim(),
                  length: lengthController.text.trim(),
                  mark: markController.text.trim(),
                  status: StapleStatus.unused,
                ));
              }
              onRegistered(newStaples);
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. 加工プロセスのダイアログ群（IDチェーン結合）
  // ==========================================

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
                  sourceInfo: tube.id,
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

  // ==========================================
  // 3. 各種編集ダイアログ群（サジェスト機能統合）
  // ==========================================

  static void showEditTubeDialog({
    required BuildContext context,
    required TubeStock tube,
    required List<String> existingBrands,
    required VoidCallback onSaved,
  }) {
    final brandController = TextEditingController(text: tube.brand);
    final periodController = TextEditingController(text: tube.purchasePeriod);
    final diameterController = TextEditingController(text: tube.diameter);
    final vendorController = TextEditingController(text: tube.vendor ?? '');
    final countController = TextEditingController(text: tube.remainingCount.toString());
    final memoController = TextEditingController(text: tube.memo ?? '');

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丸材(T) 編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
              const SizedBox(height: 8),
              TextField(controller: vendorController, decoration: const InputDecoration(labelText: '購入先')),
              const SizedBox(height: 8),
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

              tube.brand = brand;
              tube.purchasePeriod = period;
              tube.diameter = diameterController.text.trim();
              tube.vendor = vendorController.text.trim().isEmpty ? null : vendorController.text.trim();
              tube.remainingCount = int.tryParse(countController.text) ?? tube.remainingCount;
              tube.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static void showEditSplitDialog({
    required BuildContext context,
    required SplitCaneStock split,
    required List<String> existingBrands,
    required VoidCallback onSaved,
  }) {
    final brandController = TextEditingController(text: split.brand);
    final periodController = TextEditingController(text: split.purchasePeriod);
    final diameterController = TextEditingController(text: split.diameter);
    final countController = TextEditingController(text: split.remainingCount.toString());
    final memoController = TextEditingController(text: split.memo ?? '');

    final frequentBrands = _getFrequentOptions(existingBrands);
    final frequentDiameters = _getFrequentOptions(['10-10.5', '10.5-11', '9.5-10', '10']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('半カマボコ(P) 編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: brandController, label: 'ブランド', options: frequentBrands),
              const SizedBox(height: 8),
              TextField(controller: periodController, decoration: const InputDecoration(labelText: '購入時期YYMM')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: diameterController, label: '太さ', options: frequentDiameters),
              const SizedBox(height: 8),
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
              split.brand = brandController.text.trim();
              split.purchasePeriod = periodController.text.trim();
              split.diameter = diameterController.text.trim();
              split.remainingCount = int.tryParse(countController.text) ?? split.remainingCount;
              split.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static void showEditGougedDialog({
    required BuildContext context,
    required GougedCaneStock gouged,
    required VoidCallback onSaved,
  }) {
    final machineController = TextEditingController(text: gouged.machine);
    final thickController = TextEditingController(text: gouged.thickness?.toString() ?? '');
    final countController = TextEditingController(text: gouged.remainingCount.toString());
    final memoController = TextEditingController(text: gouged.memo ?? '');

    final frequentThicks = _getFrequentOptions(['0.58', '0.59', '0.60', '0.57']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコ(G) 編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: machineController, decoration: const InputDecoration(labelText: 'ガウジングマシン')),
              const SizedBox(height: 8),
              _buildAutocompleteField(controller: thickController, label: '厚さ', options: frequentThicks),
              const SizedBox(height: 8),
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
              gouged.machine = machineController.text.trim();
              gouged.thickness = double.tryParse(thickController.text.trim());
              gouged.remainingCount = int.tryParse(countController.text) ?? gouged.remainingCount;
              gouged.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  static void showEditShapedDialog({
    required BuildContext context,
    required ShapedCaneStock shaped,
    required VoidCallback onSaved,
  }) {
    final shaperController = TextEditingController(text: shaped.shaper);
    final thickController = TextEditingController(text: shaped.thickness?.toString() ?? '');
    final countController = TextEditingController(text: shaped.remainingCount.toString());
    final memoController = TextEditingController(text: shaped.memo ?? '');

    final frequentShapers = _getFrequentOptions(['H39', 'H69', 'H25', 'Chiarugi 2']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舟形(S) 編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAutocompleteField(controller: shaperController, label: 'シェイパー型番', options: frequentShapers),
              const SizedBox(height: 8),
              TextField(controller: thickController, decoration: const InputDecoration(labelText: '厚さ')),
              const SizedBox(height: 8),
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
              shaped.shaper = shaperController.text.trim();
              shaped.thickness = double.tryParse(thickController.text.trim());
              shaped.remainingCount = int.tryParse(countController.text) ?? shaped.remainingCount;
              shaped.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
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
}