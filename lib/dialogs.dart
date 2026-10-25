import 'package:flutter/material.dart';
import 'models.dart';

class StockDialogs {
  
  // 共通のブランド入力用 Autocomplete ウィジェット
  static Widget buildBrandAutocomplete({
    required List<String> options,
    required String initialValue,
    required ValueChanged<String> onSelected,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) {
          return options;
        }

        return options.where((option) {
          final fullName = option.toLowerCase();
          final prefix3 = (option.length >= 3 ? option.substring(0, 3) : option).toLowerCase();
          
          return fullName.contains(query) || prefix3.contains(query);
        });
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          onChanged: (text) {
            onSelected(text);
          },
          decoration: const InputDecoration(
            labelText: 'ブランド',
            hintText: 'タップして選択または入力',
          ),
        );
      },
    );
  }

  // 共通の購入時期用 Autocomplete ウィジェット
  static Widget buildPeriodAutocomplete({
    required List<String> options,
    required String initialValue,
    required ValueChanged<String> onSelected,
  }) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initialValue),
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim().toLowerCase();
        if (query.isEmpty) return options;
        return options.where((option) => option.toLowerCase().contains(query));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          onChanged: (text) => onSelected(text),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '購入時期 (例: 202506)',
            hintText: 'タップして選択または入力',
          ),
        );
      },
    );
  }

  // ==========================================
  // 新規登録ダイアログ群
  // ==========================================

  static void showAddTubeDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required List<String> existingVendors,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(TubeStock newStock) onRegistered,
  }) {
    String selectedBrand = '';
    String selectedPeriod = '';
    final periodCtrl = TextEditingController(text: selectedPeriod);
    final codeCtrl = TextEditingController(text: getNextCode('Rigotti', '202506', 'T'));
    String selectedVendor = '直輸入';
    final diameterCtrl = TextEditingController(text: '10〜10.5mm');
    final countCtrl = TextEditingController(text: '10');
    final memoCtrl = TextEditingController();

    void updateCode() {
      final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
      final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
      codeCtrl.text = getNextCode(b, p, 'T');
    }

    periodCtrl.addListener(updateCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丸材ストックの新規登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                  updateCode();
                },
              ),
              buildPeriodAutocomplete(
                options: existingPeriods,
                initialValue: selectedPeriod,
                onSelected: (val) {
                  selectedPeriod = val;
                  periodCtrl.text = val;
                  updateCode();
                },
              ),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return existingVendors;
                  return existingVendors.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                initialValue: TextEditingValue(text: selectedVendor),
                onSelected: (selection) => selectedVendor = selection,
                fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                  return TextField(controller: controller, focusNode: focusNode, onEditingComplete: onEditingComplete, decoration: const InputDecoration(labelText: '購入先'));
                },
              ),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '本数')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '特徴メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク (自動生成例: T01-Gon2506)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              onRegistered(TubeStock(
                id: DateTime.now().toString(),
                code: codeCtrl.text,
                brand: selectedBrand.isEmpty ? 'Rigotti' : selectedBrand,
                purchasePeriod: periodCtrl.text.isEmpty ? '202506' : periodCtrl.text,
                vendor: selectedVendor,
                diameter: diameterCtrl.text,
                memo: memoCtrl.text,
                remainingCount: int.tryParse(countCtrl.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  static void showAddSplitDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(SplitCaneStock newSplit) onRegistered,
  }) {
    String selectedBrand = '';
    String selectedPeriod = '';
    final periodCtrl = TextEditingController(text: selectedPeriod);
    final codeCtrl = TextEditingController(text: getNextCode('Rigotti', '202506', 'P'));
    final diameterCtrl = TextEditingController(text: '10〜10.5mm');
    final sourceCtrl = TextEditingController(text: '手動登録');
    final countCtrl = TextEditingController(text: '10');
    final memoCtrl = TextEditingController();

    void updateCode() {
      final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
      final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
      codeCtrl.text = getNextCode(b, p, 'P');
    }

    periodCtrl.addListener(updateCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('半カマボコストックの新規登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                  updateCode();
                },
              ),
              buildPeriodAutocomplete(
                options: existingPeriods,
                initialValue: selectedPeriod,
                onSelected: (val) {
                  selectedPeriod = val;
                  periodCtrl.text = val;
                  updateCode();
                },
              ),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')),
              TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: '由来メモ')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '枚数')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク (自動生成例: P01-Gon2506)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              onRegistered(SplitCaneStock(
                id: DateTime.now().toString(),
                code: codeCtrl.text,
                sourceInfo: sourceCtrl.text,
                brand: selectedBrand.isEmpty ? 'Rigotti' : selectedBrand,
                purchasePeriod: periodCtrl.text.isEmpty ? '202506' : periodCtrl.text,
                diameter: diameterCtrl.text,
                memo: memoCtrl.text,
                remainingCount: int.tryParse(countCtrl.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  static void showAddGougedDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(GougedCaneStock newStock) onRegistered,
  }) {
    String selectedBrand = '';
    String selectedPeriod = '';
    final periodCtrl = TextEditingController(text: selectedPeriod);
    final codeCtrl = TextEditingController(text: getNextCode('Rigotti', '202506', 'G'));
    final thickCtrl = TextEditingController(text: '0.58');
    final diameterCtrl = TextEditingController(text: '10〜10.5mm'); // ★太さを追加
    final dateCtrl = TextEditingController(text: DateTime.now().toLocal().toString().split(' ')[0]);
    final countCtrl = TextEditingController(text: '5');
    final memoCtrl = TextEditingController();

    void updateCode() {
      final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
      final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
      codeCtrl.text = getNextCode(b, p, 'G');
    }

    periodCtrl.addListener(updateCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコストック(G)の新規登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                  updateCode();
                },
              ),
              buildPeriodAutocomplete(
                options: existingPeriods,
                initialValue: selectedPeriod,
                onSelected: (val) {
                  selectedPeriod = val;
                  periodCtrl.text = val;
                  updateCode();
                },
              ),
              TextField(controller: thickCtrl, decoration: const InputDecoration(labelText: '目標厚さ(mm)')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★太さ入力欄を追加
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'ガウジング日')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '枚数')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク (自動生成例: G01-Gon2506)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
              final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
              onRegistered(GougedCaneStock(
                id: DateTime.now().toString(),
                code: codeCtrl.text,
                sourceTitle: '$b ($p)',
                machine: 'Michel',
                targetThickness: thickCtrl.text,
                diameter: diameterCtrl.text, // ★
                gougingDate: dateCtrl.text,
                memo: memoCtrl.text,
                remainingCount: int.tryParse(countCtrl.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  static void showAddShapedDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required List<String> existingPeriods,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(ShapedCaneStock newStock) onRegistered,
  }) {
    String selectedBrand = '';
    String selectedPeriod = '';
    final periodCtrl = TextEditingController(text: selectedPeriod);
    final codeCtrl = TextEditingController(text: getNextCode('Rigotti', '202506', 'S'));
    final shaperCtrl = TextEditingController(text: 'H39');
    final diameterCtrl = TextEditingController(text: '10〜10.5mm'); // ★太さを追加
    final dateCtrl = TextEditingController(text: DateTime.now().toLocal().toString().split(' ')[0]);
    final countCtrl = TextEditingController(text: '5');
    final memoCtrl = TextEditingController();

    void updateCode() {
      final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
      final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
      codeCtrl.text = getNextCode(b, p, 'S');
    }

    periodCtrl.addListener(updateCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舟形ストック(S)の新規登録'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                  updateCode();
                },
              ),
              buildPeriodAutocomplete(
                options: existingPeriods,
                initialValue: selectedPeriod,
                onSelected: (val) {
                  selectedPeriod = val;
                  periodCtrl.text = val;
                  updateCode();
                },
              ),
              TextField(controller: shaperCtrl, decoration: const InputDecoration(labelText: 'シェーパー型番')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★太さ入力欄を追加
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'シェイピング日')),
              TextField(controller: countCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '枚数')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク (自動生成例: S01-Gon2506)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final b = selectedBrand.isEmpty ? 'Rigotti' : selectedBrand;
              final p = periodCtrl.text.isEmpty ? '202506' : periodCtrl.text;
              onRegistered(ShapedCaneStock(
                id: DateTime.now().toString(),
                code: codeCtrl.text,
                sourceTitle: '$b ($p)',
                shaper: shaperCtrl.text,
                diameter: diameterCtrl.text, // ★
                shapingDate: dateCtrl.text,
                memo: memoCtrl.text,
                remainingCount: int.tryParse(countCtrl.text) ?? 0,
              ));
              Navigator.pop(context);
            },
            child: const Text('登録'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 編集ダイアログ群
  // ==========================================

  static void showEditTubeDialog({
    required BuildContext context,
    required TubeStock tube,
    required List<String> existingBrands,
    required VoidCallback onSaved,
  }) {
    final codeCtrl = TextEditingController(text: tube.code);
    String selectedBrand = tube.brand;
    final periodCtrl = TextEditingController(text: tube.purchasePeriod);
    final vendorCtrl = TextEditingController(text: tube.vendor ?? '');
    final diameterCtrl = TextEditingController(text: tube.diameter);
    final memoCtrl = TextEditingController(text: tube.memo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('丸材ストックの編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                },
              ),
              TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: '購入時期 (YYYYMM)')),
              TextField(controller: vendorCtrl, decoration: const InputDecoration(labelText: '購入先')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '特徴メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              tube.code = codeCtrl.text;
              tube.brand = selectedBrand;
              tube.purchasePeriod = periodCtrl.text;
              tube.vendor = vendorCtrl.text.isEmpty ? null : vendorCtrl.text;
              tube.diameter = diameterCtrl.text;
              tube.memo = memoCtrl.text.isEmpty ? null : memoCtrl.text;
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
    final codeCtrl = TextEditingController(text: split.code);
    String selectedBrand = split.brand;
    final periodCtrl = TextEditingController(text: split.purchasePeriod);
    final diameterCtrl = TextEditingController(text: split.diameter);
    final sourceCtrl = TextEditingController(text: split.sourceInfo);
    final memoCtrl = TextEditingController(text: split.memo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('半カマボコストックの編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              buildBrandAutocomplete(
                options: existingBrands,
                initialValue: selectedBrand,
                onSelected: (val) {
                  selectedBrand = val;
                },
              ),
              TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: '購入時期 (YYYYMM)')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')),
              TextField(controller: sourceCtrl, decoration: const InputDecoration(labelText: '由来メモ')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              split.code = codeCtrl.text;
              split.brand = selectedBrand;
              split.purchasePeriod = periodCtrl.text;
              split.diameter = diameterCtrl.text;
              split.sourceInfo = sourceCtrl.text;
              split.memo = memoCtrl.text.isEmpty ? null : memoCtrl.text;
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
    final codeCtrl = TextEditingController(text: gouged.code);
    final titleCtrl = TextEditingController(text: gouged.sourceTitle);
    final thickCtrl = TextEditingController(text: gouged.targetThickness);
    final diameterCtrl = TextEditingController(text: gouged.diameter); // ★太さを編集
    final dateCtrl = TextEditingController(text: gouged.gougingDate);
    final memoCtrl = TextEditingController(text: gouged.memo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコストックの編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '元素材名')),
              TextField(controller: thickCtrl, decoration: const InputDecoration(labelText: '目標厚さ(mm)')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'ガウジング日')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              gouged.code = codeCtrl.text;
              gouged.sourceTitle = titleCtrl.text;
              gouged.targetThickness = thickCtrl.text;
              gouged.diameter = diameterCtrl.text; // ★
              gouged.gougingDate = dateCtrl.text;
              gouged.memo = memoCtrl.text.isEmpty ? null : memoCtrl.text;
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
    final codeCtrl = TextEditingController(text: shaped.code);
    final titleCtrl = TextEditingController(text: shaped.sourceTitle);
    final shaperCtrl = TextEditingController(text: shaped.shaper);
    final diameterCtrl = TextEditingController(text: shaped.diameter); // ★太さを編集
    final dateCtrl = TextEditingController(text: shaped.shapingDate);
    final memoCtrl = TextEditingController(text: shaped.memo ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('舟形ストックの編集'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: '元素材/情報')),
              TextField(controller: shaperCtrl, decoration: const InputDecoration(labelText: 'シェーパー型番')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★
              TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'シェイピング日')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: '識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              shaped.code = codeCtrl.text;
              shaped.sourceTitle = titleCtrl.text;
              shaped.shaper = shaperCtrl.text;
              shaped.diameter = diameterCtrl.text; // ★
              shaped.shapingDate = dateCtrl.text;
              shaped.memo = memoCtrl.text.isEmpty ? null : memoCtrl.text;
              onSaved();
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 加工移動ダイアログ群 (元の太さを自動引き継ぎ)
  // ==========================================

  static void showProcessTubeToSplitDialog({
    required BuildContext context,
    required TubeStock tube,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(SplitCaneStock newSplit) onProcessed,
  }) {
    final useCountCtrl = TextEditingController(text: '5');
    final yieldCountCtrl = TextEditingController(text: '13');
    final newCodeCtrl = TextEditingController(text: getNextCode(tube.brand, tube.purchasePeriod, 'P'));
    final memoCtrl = TextEditingController(text: '歩留まり良好');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${tube.brand} (${tube.purchasePeriod}) を分割'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('現在の丸材残り: ${tube.remainingCount}本', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(controller: useCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '消費する丸材の本数')),
              TextField(controller: yieldCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '出来上がった枚数')),
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: '加工メモ')),
              const SizedBox(height: 8),
              TextField(controller: newCodeCtrl, decoration: const InputDecoration(labelText: '生成する半カマボコの識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final useCount = int.tryParse(useCountCtrl.text) ?? 0;
              final yieldCount = int.tryParse(yieldCountCtrl.text) ?? 0;

              if (useCount <= 0 || yieldCount <= 0) return;
              if (useCount > tube.remainingCount) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('在庫の丸材本数を超えています')));
                return;
              }

              tube.remainingCount -= useCount;
              onProcessed(SplitCaneStock(
                id: DateTime.now().toString(),
                code: newCodeCtrl.text,
                sourceInfo: '${tube.code} から${useCount}本使用',
                brand: tube.brand,
                purchasePeriod: tube.purchasePeriod,
                vendor: tube.vendor,
                diameter: tube.diameter, // ★ 太さを引き継ぎ
                memo: memoCtrl.text,
                remainingCount: yieldCount,
              ));

              Navigator.pop(context);
            },
            child: const Text('半カマボコへ変換'),
          ),
        ],
      ),
    );
  }

  static void showProcessSplitToGougedDialog({
    required BuildContext context,
    required SplitCaneStock split,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(GougedCaneStock newGouged) onProcessed,
  }) {
    final useCountCtrl = TextEditingController(text: '5');
    final thickCtrl = TextEditingController(text: '0.58');
    final diameterCtrl = TextEditingController(text: split.diameter); // ★半カマボコの太さを引き継ぎ
    final newCodeCtrl = TextEditingController(text: getNextCode(split.brand, split.purchasePeriod, 'G'));
    final memoCtrl = TextEditingController(text: 'Michelマシン');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${split.brand} 半カマボコをガウジング'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: useCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: '加工する枚数')),
              TextField(controller: thickCtrl, decoration: const InputDecoration(labelText: '目標厚さ (mm)')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: newCodeCtrl, decoration: const InputDecoration(labelText: '生成するカマボコの識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final useCount = int.tryParse(useCountCtrl.text) ?? 0;
              if (useCount <= 0 || useCount > split.remainingCount) return;

              split.remainingCount -= useCount;
              onProcessed(GougedCaneStock(
                id: DateTime.now().toString(),
                code: newCodeCtrl.text,
                sourceTitle: '${split.brand} (${split.purchasePeriod})',
                machine: 'Michel',
                targetThickness: thickCtrl.text,
                diameter: diameterCtrl.text, // ★
                gougingDate: DateTime.now().toLocal().toString().split(' ')[0],
                memo: memoCtrl.text,
                remainingCount: useCount,
              ));

              Navigator.pop(context);
            },
            child: const Text('カマボコへ変換'),
          ),
        ],
      ),
    );
  }

  static void showProcessGougedToShapedDialog({
    required BuildContext context,
    required GougedCaneStock gouged,
    required String Function(String brand, String period, String typeLetter) getNextCode,
    required Function(ShapedCaneStock newShaped) onProcessed,
  }) {
    final useCountCtrl = TextEditingController(text: '5');
    final shaperCtrl = TextEditingController(text: 'H39');
    final diameterCtrl = TextEditingController(text: gouged.diameter); // ★カマボコの太さを引き継ぎ
    
    String brand = 'Rigotti';
    String period = '202506';
    if (gouged.code.contains('-')) {
      final parts = gouged.code.split('-');
      if (parts.length > 1) {
        brand = parts[1].replaceAll(RegExp(r'\d'), '');
        period = parts[1].replaceAll(RegExp(r'\D'), '');
      }
    }
    final newCodeCtrl = TextEditingController(text: getNextCode(brand, period, 'S'));
    final memoCtrl = TextEditingController(text: '綺麗にシェイプ完了');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カマボコをシェイピング'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: useCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'シェイプする枚数')),
              TextField(controller: shaperCtrl, decoration: const InputDecoration(labelText: 'シェーパー型番')),
              TextField(controller: diameterCtrl, decoration: const InputDecoration(labelText: '太さ')), // ★
              TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
              const SizedBox(height: 8),
              TextField(controller: newCodeCtrl, decoration: const InputDecoration(labelText: '生成する舟形の識別マーク')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            onPressed: () {
              final useCount = int.tryParse(useCountCtrl.text) ?? 0;
              if (useCount <= 0 || useCount > gouged.remainingCount) return;

              gouged.remainingCount -= useCount;
              onProcessed(ShapedCaneStock(
                id: DateTime.now().toString(),
                code: newCodeCtrl.text,
                sourceTitle: '${gouged.sourceTitle}${gouged.targetThickness}mm',
                shaper: shaperCtrl.text,
                diameter: diameterCtrl.text, // ★
                shapingDate: DateTime.now().toLocal().toString().split(' ')[0],
                memo: memoCtrl.text,
                remainingCount: useCount,
              ));

              Navigator.pop(context);
            },
            child: const Text('舟形へ変換'),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Staple (チューブ) 管理ダイアログ群
  // ==========================================

  static void showAddStapleDialog({
    required BuildContext context,
    required List<String> existingBrands,
    required Function(List<StapleStock> newStaples) onRegistered,
  }) {
    String selectedBrand = '';
    final modelCtrl = TextEditingController(text: '2');
    final lengthCtrl = TextEditingController(text: '46');
    final materialCtrl = TextEditingController(text: 'Brass');
    final startMarkCtrl = TextEditingController(text: 'a');
    final endMarkCtrl = TextEditingController(text: 'z');
    final singleMarkCtrl = TextEditingController(text: 'a');
    final memoCtrl = TextEditingController();
    bool isBatchMode = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final brandForPreview = selectedBrand.isEmpty ? 'Chiarugi' : selectedBrand;
          String previewId = isBatchMode
              ? '$brandForPreview${modelCtrl.text}${lengthCtrl.text}${startMarkCtrl.text}〜'
              : '$brandForPreview${modelCtrl.text}${lengthCtrl.text}${singleMarkCtrl.text}';

          return AlertDialog(
            title: const Text('チューブ (Staple) の新規登録'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildBrandAutocomplete(
                    options: existingBrands.isEmpty ? ['Chiarugi', 'Rigotti', 'Loree', 'Glotin', 'Guercio'] : existingBrands,
                    initialValue: selectedBrand,
                    onSelected: (val) {
                      setState(() => selectedBrand = val);
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: modelCtrl,
                          decoration: const InputDecoration(labelText: 'モデル (例: 2)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lengthCtrl,
                          decoration: const InputDecoration(labelText: '全長数値 (例: 46)'),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: materialCtrl,
                    decoration: const InputDecoration(labelText: '材質'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('マークを連番で一括生成 (a〜z等)'),
                    value: isBatchMode,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => isBatchMode = val),
                  ),
                  if (isBatchMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: startMarkCtrl,
                            decoration: const InputDecoration(labelText: '開始マーク (例: a)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Text('〜'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: endMarkCtrl,
                            decoration: const InputDecoration(labelText: '終了マーク (例: ah)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    TextField(
                      controller: singleMarkCtrl,
                      decoration: const InputDecoration(labelText: '個体マーク (例: ah)'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text('ID生成プレビュー: $previewId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  TextField(
                    controller: memoCtrl,
                    decoration: const InputDecoration(labelText: 'メモ'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
              ElevatedButton(
                onPressed: () {
                  final List<StapleStock> generatedList = [];
                  final now = DateTime.now();
                  final brandToUse = selectedBrand.isEmpty ? 'Chiarugi' : selectedBrand;

                  if (isBatchMode) {
                    final start = startMarkCtrl.text.trim().toLowerCase();
                    final end = endMarkCtrl.text.trim().toLowerCase();
                    final marks = _generateLetterSequence(start, end);

                    for (int i = 0; i < marks.length; i++) {
                      generatedList.add(StapleStock(
                        id: '${now.millisecondsSinceEpoch}_$i',
                        brand: brandToUse,
                        model: modelCtrl.text,
                        length: lengthCtrl.text,
                        mark: marks[i],
                        material: materialCtrl.text,
                        memo: memoCtrl.text.isEmpty ? null : memoCtrl.text,
                      ));
                    }
                  } else {
                    generatedList.add(StapleStock(
                      id: now.toString(),
                      brand: brandToUse,
                      model: modelCtrl.text,
                      length: lengthCtrl.text,
                      mark: singleMarkCtrl.text.trim(),
                      material: materialCtrl.text,
                      memo: memoCtrl.text.isEmpty ? null : memoCtrl.text,
                    ));
                  }

                  onRegistered(generatedList);
                  Navigator.pop(context);
                },
                child: Text(isBatchMode ? '一括登録' : '登録'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showEditStapleDialog({
    required BuildContext context,
    required StapleStock staple,
    required List<String> existingBrands,
    required VoidCallback onSaved,
  }) {
    String selectedBrand = staple.brand;
    final modelCtrl = TextEditingController(text: staple.model);
    final lengthCtrl = TextEditingController(text: staple.length);
    final markCtrl = TextEditingController(text: staple.mark);
    final materialCtrl = TextEditingController(text: staple.material);
    final memoCtrl = TextEditingController(text: staple.memo ?? '');
    StapleStatus selectedStatus = staple.status;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          String currentIdPreview = '$selectedBrand${modelCtrl.text}${lengthCtrl.text}${markCtrl.text}';

          return AlertDialog(
            title: Text('Staple [$currentIdPreview] の編集'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  buildBrandAutocomplete(
                    options: existingBrands,
                    initialValue: selectedBrand,
                    onSelected: (val) => setState(() => selectedBrand = val),
                  ),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: modelCtrl, decoration: const InputDecoration(labelText: 'モデル'), onChanged: (_) => setState(() {}))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: lengthCtrl, decoration: const InputDecoration(labelText: '全長数値'), onChanged: (_) => setState(() {}))),
                    ],
                  ),
                  TextField(controller: markCtrl, decoration: const InputDecoration(labelText: '個体マーク (例: ah)'), onChanged: (_) => setState(() {})),
                  TextField(controller: materialCtrl, decoration: const InputDecoration(labelText: '材質')),
                  DropdownButtonFormField<StapleStatus>(
                    value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'ステータス'),
                    items: StapleStatus.values.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedStatus = val);
                    },
                  ),
                  TextField(controller: memoCtrl, decoration: const InputDecoration(labelText: 'メモ')),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
              ElevatedButton(
                onPressed: () {
                  staple.brand = selectedBrand;
                  staple.model = modelCtrl.text;
                  staple.length = lengthCtrl.text;
                  staple.mark = markCtrl.text.trim();
                  staple.material = materialCtrl.text;
                  staple.status = selectedStatus;
                  staple.memo = memoCtrl.text.isEmpty ? null : memoCtrl.text;
                  onSaved();
                  Navigator.pop(context);
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  static List<String> _generateLetterSequence(String start, String end) {
    List<String> result = [];
    int startVal = _letterToVal(start);
    int endVal = _letterToVal(end);

    if (startVal > endVal) return [start];

    for (int i = startVal; i <= endVal; i++) {
      result.add(_valToLetter(i));
    }
    return result;
  }

  static int _letterToVal(String str) {
    int val = 0;
    for (int i = 0; i < str.length; i++) {
      val = val * 26 + (str.codeUnitAt(i) - 'a'.codeUnitAt(0) + 1);
    }
    return val;
  }

  static String _valToLetter(int val) {
    String res = '';
    while (val > 0) {
      int rem = (val - 1) % 26;
      res = String.fromCharCode('a'.codeUnitAt(0) + rem) + res;
      val = (val - 1) ~/ 26;
    }
    return res;
  }

  static void showProcessShapedToTiedDialog({
    required BuildContext context,
    required ShapedCaneStock shaped,
    required List<StapleStock> availableStaples,
    required Function(TiedStock newTied, StapleStock selectedStaple) onProcessed,
  }) {
    if (availableStaples.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('未使用のチューブがありません'),
          content: const Text('糸巻きに使用できる「未使用(unused)」のチューブ(Staple)がストックにありません。先にチューブを登録してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    StapleStock selectedStaple = availableStaples.first;
    final lengthController = TextEditingController(text: '73.0');
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    
    // ★ 糸の種類と色の選択肢
    final List<String> threadTypes = ['ナイロン', 'ポリエステル', '絹'];
    final List<String> threadColors = ['黒', '紫', '橙', '赤', '桃', '黄', '緑', '青', '白'];
    
    String selectedType = 'ナイロン';
    String selectedColor = '赤';

    final memoController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('糸巻き(Tying)登録 - ${shaped.code}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<StapleStock>(
                      value: selectedStaple,
                      decoration: const InputDecoration(labelText: '使用するチューブ (Staple)'),
                      style: const TextStyle(fontSize: 16, color: Colors.black),
                      items: availableStaples.map((staple) {
                        return DropdownMenuItem<StapleStock>(
                          value: staple,
                          child: Text(
                            '${staple.brand} ${staple.model} (${staple.length}) ${staple.mark}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => selectedStaple = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: lengthController,
                      decoration: const InputDecoration(
                        labelText: '糸巻き全長 (mm)',
                        hintText: '73.0',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateController,
                      decoration: const InputDecoration(labelText: '糸巻き日 (YYYY-MM-DD)'),
                    ),
                    const SizedBox(height: 12),
                    // ★ 糸の種類と色の選択プルダウン
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: '糸の種類'),
                            items: threadTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (val) => setState(() => selectedType = val ?? 'ナイロン'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: selectedColor,
                            decoration: const InputDecoration(labelText: '糸の色'),
                            items: threadColors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => selectedColor = val ?? '赤'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: memoController,
                      decoration: const InputDecoration(labelText: 'メモ'),
                    ),
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
                    // ★ 「ナイロン赤」のように結合して保存
                    final combinedThreadColor = '$selectedType$selectedColor';

                    final newTied = TiedStock(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      stapleId: selectedStaple.stapleId,
                      shapedCode: shaped.code,
                      shapedTitle: shaped.displayTitle,
                      tiedDate: dateController.text,
                      totalLength: lengthController.text.isEmpty ? '73.0' : lengthController.text,
                      threadColor: combinedThreadColor,
                      memo: memoController.text.isEmpty ? null : memoController.text,
                    );

                    onProcessed(newTied, selectedStaple);
                    Navigator.pop(context);
                  },
                  child: const Text('糸巻き完了'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}