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
        // ケーンや木管楽器をイメージしたナチュラル＆ウォームな配色
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber.shade800,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const CaneStockPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ------------------------------------------------------------
// 以下、先ほどの「舟形ケーンストック管理画面」のコード
// ------------------------------------------------------------

enum InitialForm { tube, gouged }
enum DiameterRange { range9_5_10, range10_10_5, range10_5_plus }

class CaneStock {
  final String id;
  final InitialForm initialForm;
  final String brand;
  final String? purchasePeriod;
  final String? vendor;
  final DiameterRange diameter;
  final String? selectionMemo;
  int remainingCount;

  CaneStock({
    required this.id,
    required this.initialForm,
    required this.brand,
    this.purchasePeriod,
    this.vendor,
    required this.diameter,
    this.selectionMemo,
    required this.remainingCount,
  });

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

class CaneStockPage extends StatefulWidget {
  const CaneStockPage({super.key});

  @override
  State<CaneStockPage> createState() => _CaneStockPageState();
}

class _CaneStockPageState extends State<CaneStockPage> {
  final List<CaneStock> _stocks = [
    CaneStock(
      id: '1',
      initialForm: InitialForm.tube,
      brand: 'Rigotti',
      purchasePeriod: '2025年頃',
      vendor: '〇〇楽器',
      diameter: DiameterRange.range10_10_5,
      selectionMemo: 'L<64, a>7 木目が詰まっていて良さそう',
      remainingCount: 8,
    ),
    CaneStock(
      id: '2',
      initialForm: InitialForm.gouged,
      brand: 'Gonzalez',
      purchasePeriod: '2026年春',
      vendor: '直輸入',
      diameter: DiameterRange.range9_5_10,
      selectionMemo: '硬度やや高め',
      remainingCount: 5,
    ),
  ];

  final List<String> _brandOptions = ['Rigotti', 'Gonzalez', 'Tchankaya', 'Alliaud'];
  final List<String> _vendorOptions = ['〇〇楽器', '直輸入', '海外ショップ'];

  void _showAddStockDialog() {
    InitialForm form = InitialForm.tube;
    String selectedBrand = _brandOptions.first;
    String selectedVendor = _vendorOptions.first;
    DiameterRange selectedDiameter = DiameterRange.range10_10_5;
    
    final periodController = TextEditingController();
    final memoController = TextEditingController();
    final countController = TextEditingController(text: '10');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text('新規舟形ケーンストック登録'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('元の材料形態', style: TextStyle(fontWeight: FontWeight.bold)),
                      SegmentedButton<InitialForm>(
                        segments: const [
                          ButtonSegment(value: InitialForm.tube, label: Text('丸材')),
                          ButtonSegment(value: InitialForm.gouged, label: Text('半カマボコ')),
                        ],
                        selected: {form},
                        onSelectionChanged: (val) {
                          dialogSetState(() => form = val.first);
                        },
                      ),
                      const SizedBox(height: 16),
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
                            tooltip: 'ブランド追加',
                            onPressed: () async {
                              String? newBrand = await _showAddCustomDialog(context, 'ブランド名追加');
                              if (newBrand != null && newBrand.isNotEmpty) {
                                setState(() {
                                  _brandOptions.add(newBrand);
                                  selectedBrand = newBrand;
                                });
                                dialogSetState(() {});
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: periodController,
                        decoration: const InputDecoration(labelText: '購入時期 (例: 2025年頃)'),
                      ),
                      const SizedBox(height: 16),
                      const Text('太さ (直径)', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButtonFormField<DiameterRange>(
                        value: selectedDiameter,
                        items: const [
                          DropdownMenuItem(value: DiameterRange.range9_5_10, child: Text('9.5〜10mm')),
                          DropdownMenuItem(value: DiameterRange.range10_10_5, child: Text('10〜10.5mm')),
                          DropdownMenuItem(value: DiameterRange.range10_5_plus, child: Text('10.5mm〜')),
                        ],
                        onChanged: (val) {
                          if (val != null) dialogSetState(() => selectedDiameter = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: '選別条件メモ (例: L<64 a>7)',
                          helperText: 'ColorMuseの測定値や特徴など',
                        ),
                      ),
                      const SizedBox(height: 16),
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
                        CaneStock(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          initialForm: form,
                          brand: selectedBrand,
                          purchasePeriod: periodController.text,
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
        title: const Text('ReedNote - 舟形ケーンストック管理'),
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
                      Row(
                        children: [
                          Chip(
                            label: Text(stock.initialForm == InitialForm.tube ? '丸材由来' : '半カマボコ由来'),
                            backgroundColor: Colors.amber.shade100,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            stock.brand,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
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
                  if (stock.purchasePeriod != null && stock.purchasePeriod!.isNotEmpty)
                    Text('購入時期: ${stock.purchasePeriod}'),
                  if (stock.selectionMemo != null && stock.selectionMemo!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '選別メモ: ${stock.selectionMemo}',
                        style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.bolt, size: 18),
                      label: const Text('このストックからリードを巻く'),
                      onPressed: stock.remainingCount > 0
                          ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${stock.brand} のストックからリード作成を開始します')),
                              );
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
        label: const Text('新規ストック登録'),
      ),
    );
  }
}