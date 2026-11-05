import 'package:flutter/material.dart';
import 'models.dart';
import 'dart:math';

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
    final frequentDiameters = _getFrequentOptions(['10-10.5','9.5-10', '10', '10.5-11']);
    final frequentShapers = _getFrequentOptions(['H39', 'H69', 'H25']);
    final frequentThicks = _getFrequentOptions(['0.58', '0.57', '0.56','0.59']);

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
                    vendor: vendor,
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

  // ==========================================================
  // 3. チューブ (Staple) 専用ダイアログ（新規登録・編集）
  // ==========================================================
  static void showAddStapleDialog({
    required BuildContext context,
    required List<String> existingModels,
    required Function(List<StapleStock>) onRegistered,
  }) {
    final modelController = TextEditingController(text: 'Chiarugi 2');
    final lengthController = TextEditingController(text: '46');
    final markController = TextEditingController(text: 'a'); // 1本登録用
    final startMarkController = TextEditingController(text: 'a'); // 複数登録用（開始）
    final endMarkController = TextEditingController(text: 'h');   // 複数登録用（終了）

    bool isBatchMode = false; // スイッチの状態（デフォルトはfalse: 1本登録）

    final frequentModels = _getFrequentOptions(existingModels);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isBatchMode ? 'チューブ 一括新規登録' : 'チューブ 新規登録'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAutocompleteField(
                  controller: modelController,
                  label: 'モデル (例: Chiarugi 2, Rigotti)',
                  options: frequentModels.isNotEmpty ? frequentModels : ['Chiarugi 2', 'Rigotti', 'Loree', 'Guercio d12'],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: lengthController,
                  decoration: const InputDecoration(labelText: '長さ (例: 46)'),
                ),
                const SizedBox(height: 12),

                // ★ 複数本登録に切り替えるスイッチ
                SwitchListTile(
                  title: const Text('複数本（連続）で登録する', style: TextStyle(fontSize: 14)),
                  value: isBatchMode,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() {
                      isBatchMode = val;
                    });
                  },
                ),
                const SizedBox(height: 8),

                // ★ スイッチの状態に応じて入力欄を切り替え
                if (!isBatchMode) ...[
                  TextField(
                    controller: markController,
                    decoration: const InputDecoration(labelText: 'マーク (例: a)'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startMarkController,
                          decoration: const InputDecoration(labelText: '開始マーク (例: a)'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: endMarkController,
                          decoration: const InputDecoration(labelText: '終了マーク (例: h)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final model = modelController.text.trim();
                if (model.isEmpty) return;

                List<StapleStock> newStaples = [];

                if (!isBatchMode) {
                  // --- 1本登録の場合 ---
                  final mark = markController.text.trim();
                  final uniqueId = 'Staple_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999999)}';
                  
                  newStaples.add(StapleStock(
                    id: uniqueId,
                    model: model,
                    length: lengthController.text.trim(),
                    mark: mark,
                    status: StapleStatus.unused,
                  ));
                } else {
                  // --- 複数本（連続）登録の場合 ---
                  final startChar = startMarkController.text.trim();
                  final endChar = endMarkController.text.trim();

                  if (startChar.length == 1 && endChar.length == 1) {
                    int startCode = startChar.codeUnitAt(0);
                    int endCode = endChar.codeUnitAt(0);

                    if (startCode <= endCode) {
                      for (int code = startCode; code <= endCode; code++) {
                        String markStr = String.fromCharCode(code);
                        final uniqueId = 'Staple_${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(99999999)}_$markStr';
                        
                        newStaples.add(StapleStock(
                          id: uniqueId,
                          model: model,
                          length: lengthController.text.trim(),
                          mark: markStr,
                          status: StapleStatus.unused,
                        ));
                      }
                    }
                  }
                }

                if (newStaples.isNotEmpty) {
                  onRegistered(newStaples);
                  Navigator.pop(context);
                }
              },
              child: Text(isBatchMode ? '一括登録' : '登録'),
            ),
          ],
        ),
      ),
    );
  }

  static void showEditStapleDialog({
    required BuildContext context,
    required StapleStock staple,
    required List<String> existingModels,
    required VoidCallback onSaved,
  }) {
    final modelController = TextEditingController(text: staple.model);
    final lengthController = TextEditingController(text: staple.length);
    final markController = TextEditingController(text: staple.mark);
    final memoController = TextEditingController(text: staple.memo ?? '');
    
    // ★ 選択中の使用状況を保持する変数
    StapleStatus selectedStatus = staple.status;

    final frequentModels = _getFrequentOptions(existingModels);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('チューブ 編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAutocompleteField(controller: modelController, label: 'モデル', options: frequentModels),
                const SizedBox(height: 8),
                TextField(controller: lengthController, decoration: const InputDecoration(labelText: '長さ')),
                const SizedBox(height: 8),
                TextField(controller: markController, decoration: const InputDecoration(labelText: 'マーク')),
                const SizedBox(height: 8),
                
                // ★ 使用状況の切り替え用ドロップダウン
                DropdownButtonFormField<StapleStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: '使用状況'),
                  items: StapleStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status.label), // '未使用' または '糸巻き済み'
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedStatus = val);
                    }
                  },
                ),
                const SizedBox(height: 8),

                TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                staple.model = modelController.text.trim();
                staple.length = lengthController.text.trim();
                staple.mark = markController.text.trim();
                staple.status = selectedStatus; // ★ ステータスを保存
                staple.memo = memoController.text.trim().isEmpty ? null : memoController.text.trim();

                onSaved();
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        ),
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
                  vendor: tube.vendor,
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
                vendor: split.vendor,
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
                vendor: gouged.vendor,
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
    
    final List<String> threadColors = ['黒', '紫', '青', '緑', '黄', '橙', '桃', '赤'];
    String selectedColor = '赤';

    final List<String> threadMaterials = ['ナイロン', 'ポリエステル', '絹'];
    String selectedMaterial = 'ナイロン';
    
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
                    items: availableStaples.map((st) => DropdownMenuItem(value: st, child: Text('[${st.model}] ${st.length} (${st.mark})'))).toList(),
                    onChanged: (val) => setState(() => selectedStaple = val),
                  ),
                const SizedBox(height: 8),
                TextField(controller: lengthController, decoration: const InputDecoration(labelText: '全長 (mm)')),
                const SizedBox(height: 8),
                
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(labelText: '糸の色'),
                  items: threadColors.map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => selectedColor = val);
                    }
                  },
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  value: selectedMaterial,
                  decoration: const InputDecoration(labelText: '糸の種類'),
                  items: threadMaterials.map((mat) => DropdownMenuItem(value: mat, child: Text(mat))).toList(),
                  onChanged: (val) { if (val != null) setState(() => selectedMaterial = val); },
                ),
                
                const SizedBox(height: 8),

                TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: selectedStaple == null ? null : () {
                Navigator.pop(context);

                String staplePrefix = '${selectedStaple!.model}${selectedStaple!.mark}'.replaceAll(' ', '');
                String tiedId = '$staplePrefix-${shaped.id}';

                final tied = TiedStock(
                  id: tiedId,
                  stapleId: selectedStaple!.id,
                  shapedCode: shaped.id,
                  shapedTitle: shaped.displayTitle,
                  tiedDate: DateTime.now().toString().split(' ')[0],
                  totalLength: double.tryParse(lengthController.text) ?? 73.0,
                  threadColor: selectedColor,
                  threadMaterial: selectedMaterial,
                  vendor: shaped.vendor,
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

  /// 糸巻きストック (TiedStock) 編集・複製ダイアログ
  static void showEditTiedDialog({
    required BuildContext context,
    required TiedStock tied,
    required List<StapleStock> allStaples,
    bool isCopy = false,
    required Function(TiedStock, StapleStock, StapleStock?) onSaved,
  }) {
    final availableStaples = allStaples.where((st) => 
      st.status == StapleStatus.unused || st.id == tied.stapleId
    ).toList();

    // モデル ＞ 長さ ＞ マーク順でソート
    availableStaples.sort((a, b) {
      int c = b.model.compareTo(a.model);
      if (c != 0) return c;
      c = b.length.compareTo(a.length);
      if (c != 0) return c;
      return b.mark.compareTo(a.mark);
    });

    StapleStock? selectedStaple = availableStaples.firstWhere(
      (st) => st.id == tied.stapleId,
      orElse: () => availableStaples.isNotEmpty ? availableStaples.first : StapleStock(id: '', model: '不明', length: '', mark: ''),
    );

    final lengthController = TextEditingController(text: tied.totalLength.toString());
    final List<String> threadColors = ['黒', '紫', '青', '緑', '黄', '橙', '桃', '赤'];
    String selectedColor = threadColors.contains(tied.threadColor) ? tied.threadColor! : '赤';

    final List<String> threadMaterials = ['ナイロン', 'ポリエステル', '絹'];
    String selectedMaterial = threadMaterials.contains(tied.threadMaterial) ? tied.threadMaterial! : 'ナイロン';

    final memoController = TextEditingController(text: tied.memo ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isCopy ? '糸巻きストックを複製' : '糸巻きストックを編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ケーン: ${tied.shapedTitle}', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                
                const Text('チューブ選択', style: TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                if (availableStaples.isEmpty)
                  const Text('利用可能なチューブがありません', style: TextStyle(color: Colors.red, fontSize: 13))
                else
                  DropdownButton<StapleStock>(
                    isExpanded: true,
                    value: availableStaples.contains(selectedStaple) ? selectedStaple : availableStaples.first,
                    items: availableStaples.map((st) => DropdownMenuItem(
                      value: st,
                      child: Text('[${st.model}] ${st.length} (${st.mark})', style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStaple = val);
                    },
                  ),
                const SizedBox(height: 12),

                TextField(controller: lengthController, decoration: const InputDecoration(labelText: '全長 (mm)')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedColor,
                  decoration: const InputDecoration(labelText: '糸の色'),
                  items: threadColors.map((color) => DropdownMenuItem(value: color, child: Text(color))).toList(),
                  onChanged: (val) { if (val != null) setState(() => selectedColor = val); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedMaterial,
                  decoration: const InputDecoration(labelText: '糸の種類'),
                  items: threadMaterials.map((mat) => DropdownMenuItem(value: mat, child: Text(mat))).toList(),
                  onChanged: (val) { if (val != null) setState(() => selectedMaterial = val); },
                ),
                const SizedBox(height: 8),
                TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: selectedStaple == null || selectedStaple!.id.isEmpty ? null : () {
                Navigator.pop(context);

                final newLength = double.tryParse(lengthController.text) ?? tied.totalLength;
                final newMemo = memoController.text.trim().isEmpty ? null : memoController.text.trim();
                
                StapleStock? oldStaple = allStaples.firstWhere(
                  (st) => st.id == tied.stapleId,
                  orElse: () => selectedStaple!,
                );

                if (isCopy) {
                  String staplePrefix = '${selectedStaple!.model}${selectedStaple!.mark}'.replaceAll(' ', '');
                  String tiedId = '$staplePrefix-${tied.shapedCode}';
                  if (tiedId == tied.id) {
                    tiedId = '${tiedId}_copy_${DateTime.now().millisecondsSinceEpoch}';
                  }

                  final copiedTied = TiedStock(
                    id: tiedId,
                    stapleId: selectedStaple!.id,
                    shapedCode: tied.shapedCode,
                    shapedTitle: tied.shapedTitle,
                    tiedDate: DateTime.now().toString().split(' ')[0],
                    totalLength: newLength,
                    threadColor: selectedColor,
                    threadMaterial: selectedMaterial,
                    vendor: tied.vendor,
                    memo: newMemo,
                  );
                  onSaved(copiedTied, selectedStaple!, null);
                } else {
                  String staplePrefix = '${selectedStaple!.model}${selectedStaple!.mark}'.replaceAll(' ', '');
                  if (selectedStaple!.id != tied.stapleId) {
                    tied.id = '$staplePrefix-${tied.shapedCode}';
                    tied.stapleId = selectedStaple!.id;
                  }
                  tied.totalLength = newLength;
                  tied.threadColor = selectedColor;
                  tied.threadMaterial = selectedMaterial;
                  tied.memo = newMemo;

                  onSaved(tied, selectedStaple!, oldStaple);
                }
              },
              child: Text(isCopy ? '複製して追加' : '保存'),
            ),
          ],
        ),
      ),
    );
  }
}