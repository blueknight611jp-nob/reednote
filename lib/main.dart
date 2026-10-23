import 'package:flutter/material.dart';

void main() {
  runApp(const ReedNoteApp());
}

class ReedNoteApp extends StatelessWidget {
  const ReedNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReedNote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber.shade800,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RawMaterialStockPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// 1. データモデルの定義
// ==========================================
enum MaterialForm { tube, gouged } // 丸材 or 半カマボコ
enum DiameterRange { range9_5_10, range10_10_5, range10_5_plus }

// 原材料ストック（丸材・半カマボコ）
class RawMaterialStock {
  final String id;
  final String brand;
  final String purchasePeriod; // 例: 2026春
  final MaterialForm form;
  final String? vendor;          // 購入先
  final DiameterRange diameter;
  final String? selectionMemo;  // 特徴メモ (L<64, a>7 等)
  int remainingCount;           // 残り本数

  RawMaterialStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.form,
    this.vendor,
    required this.diameter,
    this.selectionMemo,
    required this.remainingCount,
  });

  String get displayTitle {
    final formText = form == MaterialForm.tube ? '丸材' : '半カマボコ';
    return '$brand $purchasePeriod $formText';
  }

  String get diameterLabel {
    switch (diameter) {
      case DiameterRange.range9_5_10:
        return '9.5〜10mm';
      case DiameterRange.range10_10_5:
        return '10〜10.5mm';
      case DiameterRange.range10_5_plus:
        return '10.5mm〜';
    }
  }
}

// ------------------------------------------------------------
// 2. 原材料（丸材・半カマボコ）ストック管理画面
// ------------------------------------------------------------
class RawMaterialStockPage extends StatefulWidget {
  const RawMaterialStockPage({super.key});

  @override
  State<RawMaterialStockPage> createState() => _RawMaterialStockPageState();
}

class _RawMaterialStockPageState extends State<RawMaterialStockPage> {
  final List<RawMaterialStock> _stocks = [
    RawMaterialStock(
      id: '1',
      brand: 'Rigotti',
      purchasePeriod: '2025春',
      form: MaterialForm.tube,
      vendor: '〇〇楽器',
      diameter: DiameterRange.range10_10_5,
      selectionMemo: 'L<64, a>7 木目が詰まっていて良さそう',
      remainingCount: 10,
    ),
    RawMaterialStock(
      id: '2',
      brand: 'Gonzalez',
      purchasePeriod: '2026春',
      form: MaterialForm.tube,
      vendor: '直輸入',
      diameter: DiameterRange.range9_5_10,
      selectionMemo: '硬度やや高め',
      remainingCount: 8,
    ),
  ];

  final List<String> _brandOptions = ['Rigotti', 'Gonzalez', 'Tchankaya', 'Alliaud'];
  final List<String> _vendorOptions = ['〇〇楽器', '日本ダブルリード', '直輸入', '海外ショップ'];

  void _showAddStockDialog() {
    MaterialForm form = MaterialForm.tube;
    String selectedBrand = _brandOptions.first;
    String selectedVendor = _vendorOptions.first;
    DiameterRange selectedDiameter = DiameterRange.range10_10_5;
    
    final periodController = TextEditingController(text: '2026秋');
    final memoController = TextEditingController();
    final countController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('新規素材ストック登録'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedBrand,
                              decoration: const InputDecoration(labelText: 'ブランド'),
                              items: _brandOptions
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) dialogSetState(() => selectedBrand = val);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              String? newBrand = await _showAddCustomDialog(context, 'ブランド追加');
                              if (newBrand != null && newBrand.isNotEmpty) {
                                setState(() => _brandOptions.add(newBrand));
                                dialogSetState(() => selectedBrand = newBrand);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: periodController,
                        decoration: const InputDecoration(labelText: '購入時期 (例: 2026春)'),
                      ),
                      const SizedBox(height: 12),
                      const Text('材料形態', style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<MaterialForm>(
                        segments: const [
                          ButtonSegment(value: MaterialForm.tube, label: Text('丸材')),
                          ButtonSegment(value: MaterialForm.gouged, label: Text('半カマボコ')),
                        ],
                        selected: {form},
                        onSelectionChanged: (val) {
                          dialogSetState(() => form = val.first);
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedVendor,
                              decoration: const InputDecoration(labelText: '購入先'),
                              items: _vendorOptions
                                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) dialogSetState(() => selectedVendor = val);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () async {
                              String? newVendor = await _showAddCustomDialog(context, '購入先追加');
                              if (newVendor != null && newVendor.isNotEmpty) {
                                setState(() => _vendorOptions.add(newVendor));
                                dialogSetState(() => selectedVendor = newVendor);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<DiameterRange>(
                        value: selectedDiameter,
                        decoration: const InputDecoration(labelText: '太さ (直径)'),
                        items: const [
                          DropdownMenuItem(value: DiameterRange.range9_5_10, child: Text('9.5〜10mm')),
                          DropdownMenuItem(value: DiameterRange.range10_10_5, child: Text('10〜10.5mm')),
                          DropdownMenuItem(value: DiameterRange.range10_5_plus, child: Text('10.5mm〜')),
                        ],
                        onChanged: (val) {
                          if (val != null) dialogSetState(() => selectedDiameter = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: '特徴メモ (例: L<64, a>7)',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: countController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '本数'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _stocks.add(
                        RawMaterialStock(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          brand: selectedBrand,
                          purchasePeriod: periodController.text,
                          form: form,
                          vendor: selectedVendor,
                          diameter: selectedDiameter,
                          selectionMemo: memoController.text,
                          remainingCount: int.tryParse(countController.text) ?? 10,
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('登録'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<String?> _showAddCustomDialog(BuildContext context, String title) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('追加')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ReedNote - 素材ストック管理'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stocks.length,
        itemBuilder: (context, index) {
          final stock = _stocks[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        stock.displayTitle,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: stock.remainingCount > 0
                                ? () => setState(() => stock.remainingCount--)
                                : null,
                          ),
                          Text(
                            '${stock.remainingCount}本',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => stock.remainingCount++),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),
                  Text('太さ: ${stock.diameterLabel}'),
                  if (stock.vendor != null && stock.vendor!.isNotEmpty)
                    Text('購入先: ${stock.vendor}'),
                  if (stock.selectionMemo != null && stock.selectionMemo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '特徴メモ: ${stock.selectionMemo}',
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.settings_suggest, size: 18),
                      label: const Text('このストックをガウジングする'),
                      onPressed: stock.remainingCount > 0
                          ? () async {
                              // ガウジング作業ページへ遷移
                              final int? processedCount = await Navigator.push<int>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GougingPage(materialStock: stock),
                                ),
                              );
                              if (processedCount != null && processedCount > 0) {
                                setState(() {
                                  stock.remainingCount -= processedCount;
                                });
                              }
                            }
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStockDialog,
        icon: const Icon(Icons.add),
        label: const Text('新規素材登録'),
      ),
    );
  }
}

// ==========================================
// 3. ガウジング作業ページ (Michel マシン)
// ==========================================
class GougingPage extends StatefulWidget {
  final RawMaterialStock materialStock;

  const GougingPage({super.key, required this.materialStock});

  @override
  State<GougingPage> createState() => _GougingPageState();
}

class _GougingPageState extends State<GougingPage> {
  final _countController = TextEditingController(text: '5');
  final _targetThicknessController = TextEditingController(text: '0.58');
  final _dateController = TextEditingController(
    text: DateTime.now().toLocal().toString().split(' ')[0], // 本日の日付
  );
  final _memoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ガウジング作業 (Michel)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('使用する素材', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      widget.materialStock.displayTitle,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('残り在庫: ${widget.materialStock.remainingCount}本'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ガウジング日
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: 'ガウジング実施日',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            // 使用マシン表示（固定）
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'ガウジングマシン',
                border: OutlineInputBorder(),
                hintText: 'Michel ガウジングマシン',
              ),
              controller: TextEditingController(text: 'Michel ガウジングマシン'),
            ),
            const SizedBox(height: 16),

            // 目標厚さ
            TextField(
              controller: _targetThicknessController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '目標厚さ (mm) [例: 0.58]',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 加工本数
            TextField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '今回ガウジングする本数',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ガウジングメモ
            TextField(
              controller: _memoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ガウジングメモ (刃の状態や削り心地など)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // 次のステップ（シェイピングへ進む）ボタン
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                label: const Text('次へ：シェイピング工程に進む', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  final count = int.tryParse(_countController.text) ?? 0;
                  if (count <= 0) return;
                  if (count > widget.materialStock.remainingCount) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('素材の在庫本数を超えています')),
                    );
                    return;
                  }

                  // シェイピング作業ページへ進む（ガウジング情報を引き渡す）
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShapingPage(
                        materialStock: widget.materialStock,
                        gougingDate: _dateController.text,
                        targetThickness: _targetThicknessController.text,
                        gougingCount: count,
                        gougingMemo: _memoController.text,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. シェイピング作業ページ (H39等)
// ==========================================
class ShapingPage extends StatefulWidget {
  final RawMaterialStock materialStock;
  final String gougingDate;
  final String targetThickness;
  final int gougingCount;
  final String gougingMemo;

  const ShapingPage({
    super.key,
    required this.materialStock,
    required this.gougingDate,
    required this.targetThickness,
    required this.gougingCount,
    required this.gougingMemo,
  });

  @override
  State<ShapingPage> createState() => _ShapingPageState();
}

class _ShapingPageState extends State<ShapingPage> {
  final List<String> _shaperOptions = ['H39', 'H25', 'H69', 'H21', 'その他'];
  late String _selectedShaper;
  final _shapingDateController = TextEditingController(
    text: DateTime.now().toLocal().toString().split(' ')[0],
  );
  final _shapingMemoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedShaper = _shaperOptions.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('シェイピング作業'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Card(
              color: Colors.amber.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('加工元＆ガウジング情報', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      widget.materialStock.displayTitle,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('ガウジング日: ${widget.gougingDate} (目標厚さ: ${widget.targetThickness}mm)'),
                    Text('対象本数: ${widget.gougingCount}本'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // シェイピング日
            TextField(
              controller: _shapingDateController,
              decoration: const InputDecoration(
                labelText: 'シェイピング実施日',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 16),

            // シェーパー選択
            DropdownButtonFormField<String>(
              value: _selectedShaper,
              decoration: const InputDecoration(
                labelText: '使用シェーパー (Shaper)',
                border: OutlineInputBorder(),
              ),
              items: _shaperOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedShaper = val);
              },
            ),
            const SizedBox(height: 16),

            // シェイピングメモ
            TextField(
              controller: _shapingMemoController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'シェイピングメモ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // 完了ボタン（素材の在庫を減らして舟形ケーンストックへ完了）
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle),
                label: const Text('舟形ケーンストックとして登録を完了する', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  // 素材ストック画面まで戻りつつ、ガウジングした本数を削る
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${widget.materialStock.displayTitle} から ${widget.gougingCount}本を加工し、$_selectedShaper の舟形ケーンとして登録しました！',
                      ),
                    ),
                  );

                  // Navigatorを素材ストック画面まで一気に戻し、消費本数を返す
                  Navigator.popUntil(context, (route) => route.isFirst);
                  // ※本来はここで素材のストック数を減らすコールバック等を渡します
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}