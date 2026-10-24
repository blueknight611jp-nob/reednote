import 'dart:convert';
import 'dart:html' as html; // Webでのファイル入出力用
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'dialogs.dart';

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
      home: const MainStockNavigationPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// メイン画面
// ==========================================
class MainStockNavigationPage extends StatefulWidget {
  const MainStockNavigationPage({super.key});

  @override
  State<MainStockNavigationPage> createState() => _MainStockNavigationPageState();
}

class _MainStockNavigationPageState extends State<MainStockNavigationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showOnlyInStock = true;
  bool _isLoading = true;

  List<TubeStock> _tubeStocks = [];
  List<SplitCaneStock> _splitStocks = [];
  List<GougedCaneStock> _gougedStocks = [];
  List<ShapedCaneStock> _shapedStocks = [];
  List<StapleStock> stapleStocks = [];
  List<TiedStock> _tiedStocks = []; // 第6タブ用

  // ==========================================
  // Staple ソート用ヘルパーメソッド
  // ==========================================
  List<StapleStock> getSortedStaples() {
    List<StapleStock> list = List.from(stapleStocks);
    list.sort((a, b) {
      int brandComp = a.brand.compareTo(b.brand);
      if (brandComp != 0) return brandComp;

      int modelComp = a.model.compareTo(b.model);
      if (modelComp != 0) return modelComp;

      int lengthComp = a.length.compareTo(b.length);
      if (lengthComp != 0) return lengthComp;

      return a.mark.compareTo(b.mark);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // 6タブへ拡張
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final tubeJson = prefs.getString('tube_stocks');
    if (tubeJson != null) {
      final decoded = jsonDecode(tubeJson) as List;
      _tubeStocks = decoded.map((e) => TubeStock.fromJson(e)).toList();
    } else {
      _tubeStocks = [
        TubeStock(id: '1', code: 'T01-Rig2503', brand: 'Rigotti', purchasePeriod: '202503', vendor: '〇〇楽器', diameter: '10〜10.5mm', memo: '木目が詰まっている', remainingCount: 15),
      ];
    }

    final splitJson = prefs.getString('split_stocks');
    if (splitJson != null) {
      final decoded = jsonDecode(splitJson) as List;
      _splitStocks = decoded.map((e) => SplitCaneStock.fromJson(e)).toList();
    } else {
      _splitStocks = [
        SplitCaneStock(id: '1', code: 'P01-Rig2503', sourceInfo: '丸材由来', brand: 'Rigotti', purchasePeriod: '202503', vendor: '〇〇楽器', diameter: '10〜10.5mm', memo: '良質', remainingCount: 12),
      ];
    }

    final gougedJson = prefs.getString('gouged_stocks');
    if (gougedJson != null) {
      final decoded = jsonDecode(gougedJson) as List;
      _gougedStocks = decoded.map((e) => GougedCaneStock.fromJson(e)).toList();
    } else {
      _gougedStocks = [
        GougedCaneStock(id: '1', code: 'G01-Rig2503', sourceTitle: 'Rigotti 202503', machine: 'Michel', targetThickness: '0.58', gougingDate: '2026-10-20', memo: 'センター0.58mm', remainingCount: 6),
      ];
    }

    final shapedJson = prefs.getString('shaped_stocks');
    if (shapedJson != null) {
      final decoded = jsonDecode(shapedJson) as List;
      _shapedStocks = decoded.map((e) => ShapedCaneStock.fromJson(e)).toList();
    } else {
      _shapedStocks = [
        ShapedCaneStock(id: '1', code: 'S01-Rig2503', sourceTitle: 'Rigotti 202503 0.58mm', shaper: 'H39', shapingDate: '2026-10-22', memo: 'エッジ綺麗', remainingCount: 4),
      ];
    }

    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) {
      final decoded = jsonDecode(stapleJson) as List;
      stapleStocks = decoded.map((e) => StapleStock.fromJson(e)).toList();
    } else {
      stapleStocks = [
        StapleStock(id: '1', brand: 'Chiarugi', model: '2', length: '46', mark: 'ah', material: 'Brass', status: StapleStatus.unused, memo: '標準個体'),
      ];
    }

    final tiedJson = prefs.getString('tied_stocks');
    if (tiedJson != null) {
      final decoded = jsonDecode(tiedJson) as List;
      _tiedStocks = decoded.map((e) => TiedStock.fromJson(e)).toList();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tube_stocks', jsonEncode(_tubeStocks.map((e) => e.toJson()).toList()));
    await prefs.setString('split_stocks', jsonEncode(_splitStocks.map((e) => e.toJson()).toList()));
    await prefs.setString('gouged_stocks', jsonEncode(_gougedStocks.map((e) => e.toJson()).toList()));
    await prefs.setString('shaped_stocks', jsonEncode(_shapedStocks.map((e) => e.toJson()).toList()));
    await prefs.setString('staple_stocks', jsonEncode(stapleStocks.map((e) => e.toJson()).toList()));
    await prefs.setString('tied_stocks', jsonEncode(_tiedStocks.map((e) => e.toJson()).toList()));
  }

  List<String> _getAllExistingBrands() {
    Set<String> brands = {};
    for (var t in _tubeStocks) { if (t.brand.isNotEmpty) brands.add(t.brand); }
    for (var s in _splitStocks) { if (s.brand.isNotEmpty) brands.add(s.brand); }
    for (var g in _gougedStocks) {
      brands.add(g.sourceTitle.split(' ')[0]);
    }
    for (var st in stapleStocks) { if (st.brand.isNotEmpty) brands.add(st.brand); }
    return brands.toList();
  }

  String _generatePrefix(String brand) {
    if (brand.isEmpty) return 'Can';
    return brand.length > 3 ? brand.substring(0, 3) : brand;
  }

  String _formatYYMM(String period) {
    String digits = period.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 6) {
      return digits.substring(2, 6);
    } else if (digits.length == 4) {
      return digits;
    }
    return '2501';
  }

  String _getNextCode(String brand, String period, String typeLetter) {
    String prefix = _generatePrefix(brand);
    String yymm = _formatYYMM(period);
    String suffix = '-$prefix$yymm';

    List<String> existingCodes = [];
    for (var t in _tubeStocks) { existingCodes.add(t.code); }
    for (var s in _splitStocks) { existingCodes.add(s.code); }
    for (var g in _gougedStocks) { existingCodes.add(g.code); }
    for (var sh in _shapedStocks) { existingCodes.add(sh.code); }

    int maxNum = 0;
    RegExp reg = RegExp('^' + typeLetter + r'(\d+)' + RegExp.escape(suffix) + r'$');

    for (var code in existingCodes) {
      var match = reg.firstMatch(code);
      if (match != null) {
        int? num = int.tryParse(match.group(1)!);
        if (num != null && num > maxNum) {
          maxNum = num;
        }
      }
    }
    
    String nextNumStr = (maxNum + 1).toString().padLeft(2, '0');
    return '$typeLetter$nextNumStr$suffix';
  }

  // ==========================================
  // ファイル書き出し (ダウンロード)
  // ==========================================
  void _exportDataToFile() {
    final allData = {
      'tubes': _tubeStocks.map((e) => e.toJson()).toList(),
      'splits': _splitStocks.map((e) => e.toJson()).toList(),
      'gouged': _gougedStocks.map((e) => e.toJson()).toList(),
      'shaped': _shapedStocks.map((e) => e.toJson()).toList(),
      'staples': stapleStocks.map((e) => e.toJson()).toList(),
      'tied': _tiedStocks.map((e) => e.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
    final bytes = utf8.encode(jsonString);

    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "ReedNote_Backup_${DateTime.now().toString().split(' ')[0]}.json")
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('バックアップファイルをダウンロードしました')),
    );
  }

  // ==========================================
  // ファイル読み込み (インポート)
  // ==========================================
  void _importDataFromFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) {
        try {
          final content = reader.result as String;
          final data = jsonDecode(content) as Map<String, dynamic>;

          setState(() {
            if (data.containsKey('tubes')) {
              _tubeStocks = (data['tubes'] as List).map((e) => TubeStock.fromJson(e)).toList();
            }
            if (data.containsKey('splits')) {
              _splitStocks = (data['splits'] as List).map((e) => SplitCaneStock.fromJson(e)).toList();
            }
            if (data.containsKey('gouged')) {
              _gougedStocks = (data['gouged'] as List).map((e) => GougedCaneStock.fromJson(e)).toList();
            }
            if (data.containsKey('shaped')) {
              _shapedStocks = (data['shaped'] as List).map((e) => ShapedCaneStock.fromJson(e)).toList();
            }
            if (data.containsKey('staples')) {
              stapleStocks = (data['staples'] as List).map((e) => StapleStock.fromJson(e)).toList();
            }
            if (data.containsKey('tied')) {
              _tiedStocks = (data['tied'] as List).map((e) => TiedStock.fromJson(e)).toList();
            }
          });

          _saveData();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データを正常に読み込みました！')),
          );
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ファイルの読み込みに失敗しました: $err')),
          );
        }
      });

      reader.readAsText(file);
    });
  }

  void _openAddDialogForCurrentTab() {
    final existingBrands = _getAllExistingBrands();
    final existingVendors = _tubeStocks.map((e) => e.vendor ?? '').where((e) => e.isNotEmpty).toSet().toList();

    switch (_tabController.index) {
      case 0:
        StockDialogs.showAddTubeDialog(
          context: context,
          existingBrands: existingBrands,
          existingVendors: existingVendors,
          getNextCode: _getNextCode,
          onRegistered: (newStock) {
            setState(() => _tubeStocks.add(newStock));
            _saveData();
          },
        );
        break;
      case 1:
        StockDialogs.showAddSplitDialog(
          context: context,
          existingBrands: existingBrands,
          getNextCode: _getNextCode,
          onRegistered: (newStock) {
            setState(() => _splitStocks.add(newStock));
            _saveData();
          },
        );
        break;
      case 2:
        StockDialogs.showAddGougedDialog(
          context: context,
          existingBrands: existingBrands,
          getNextCode: _getNextCode,
          onRegistered: (newStock) {
            setState(() => _gougedStocks.add(newStock));
            _saveData();
          },
        );
        break;
      case 3:
        StockDialogs.showAddShapedDialog(
          context: context,
          existingBrands: existingBrands,
          getNextCode: _getNextCode,
          onRegistered: (newStock) {
            setState(() => _shapedStocks.add(newStock));
            _saveData();
          },
        );
        break;
      case 4:
        StockDialogs.showAddStapleDialog(
          context: context,
          existingBrands: existingBrands,
          onRegistered: (newStaples) {
            setState(() => stapleStocks.addAll(newStaples));
            _saveData();
          },
        );
        break;
      case 5:
        // 糸巻き(Tied)直接追加ダイアログがあればここに
        break;
    }
  }

  String get _fabLabel {
    switch (_tabController.index) {
      case 0: return '丸材を新規登録';
      case 1: return '半カマボコを新規登録';
      case 2: return 'カマボコを新規登録';
      case 3: return '舟形を新規登録';
      case 4: return 'チューブを新規登録';
      default: return '新規登録';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReedNote - 素材ストック管理'),
        actions: [
          Tooltip(
            message: 'バックアップファイルを読み込み',
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.brown.shade800),
              icon: const Icon(Icons.folder_open, size: 18),
              label: const Text('Import'),
              onPressed: _importDataFromFile,
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'データをファイルへ保存 (バックアップ)',
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.brown.shade800),
              icon: const Icon(Icons.save_alt, size: 18),
              label: const Text('Export'),
              onPressed: _exportDataToFile,
            ),
          ),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(
              label: Text(_showOnlyInStock ? '在庫ありのみ' : 'すべて表示'),
              selected: !_showOnlyInStock,
              onSelected: (selected) {
                setState(() {
                  _showOnlyInStock = !selected;
                });
              },
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.blur_circular), text: '1. 丸材(T)'),
            Tab(icon: Icon(Icons.call_split), text: '2. 半カマボコ(P)'),
            Tab(icon: Icon(Icons.density_medium), text: '3. カマボコ(G)'),
            Tab(icon: Icon(Icons.content_cut), text: '4. 舟形(S)'),
            Tab(icon: Icon(Icons.architecture), text: '5. チューブ(Staple)'),
            Tab(icon: Icon(Icons.waves), text: '6. 糸巻き(Tied)'),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTubeStockTab(),
          _buildSplitStockTab(),
          _buildGougedStockTab(),
          _buildShapedStockTab(),
          _buildStapleStockTab(),
          _buildTiedStockTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 5
          ? null
          : FloatingActionButton.extended(
              onPressed: _openAddDialogForCurrentTab,
              icon: const Icon(Icons.add),
              label: Text(_fabLabel),
            ),
    );
  }

  Widget _buildStockCard({
    required String title,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    Widget? processButton,
  }) {
    final bool isInStock = count > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isInStock ? null : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isInStock ? Colors.black : Colors.grey.shade600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                  tooltip: '編集する',
                  onPressed: onEdit,
                ),
                if (!isInStock) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('在庫なし', style: TextStyle(fontSize: 12, color: Colors.white)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: '削除する',
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: isInStock ? Colors.black87 : Colors.grey.shade600),
            ),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (processButton != null && isInStock)
                  processButton
                else
                  const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: count > 0 ? onDecrement : null,
                    ),
                    Text(
                      '$count本',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isInStock ? Colors.black : Colors.grey.shade600,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: onIncrement,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTubeStockTab() {
    final items = _showOnlyInStock
        ? _tubeStocks.where((e) => e.remainingCount > 0).toList()
        : _tubeStocks;

    if (items.isEmpty) return const Center(child: Text('表示する丸材ストックがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | 購入先: ${item.vendor ?? "未登録"}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () {
            StockDialogs.showEditTubeDialog(
              context: context,
              tube: item,
              existingBrands: _getAllExistingBrands(),
              onSaved: () { setState(() {}); _saveData(); },
            );
          },
          onDelete: () => _confirmDelete(() {
            setState(() => _tubeStocks.remove(item));
            _saveData();
          }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
            ),
            icon: const Icon(Icons.call_split, size: 16),
            label: const Text('半カマボコ(P)へ加工'),
            onPressed: () {
              StockDialogs.showProcessTubeToSplitDialog(
                context: context,
                tube: item,
                getNextCode: _getNextCode,
                onProcessed: (newSplit) {
                  setState(() => _splitStocks.add(newSplit));
                  _saveData();
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSplitStockTab() {
    final items = _showOnlyInStock
        ? _splitStocks.where((e) => e.remainingCount > 0).toList()
        : _splitStocks;

    if (items.isEmpty) return const Center(child: Text('表示する半カマボコストックがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | 由来: ${item.sourceInfo}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () {
            StockDialogs.showEditSplitDialog(
              context: context,
              split: item,
              existingBrands: _getAllExistingBrands(),
              onSaved: () { setState(() {}); _saveData(); },
            );
          },
          onDelete: () => _confirmDelete(() {
            setState(() => _splitStocks.remove(item));
            _saveData();
          }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
            ),
            icon: const Icon(Icons.density_medium, size: 16),
            label: const Text('カマボコ(G)へ加工'),
            onPressed: () {
              StockDialogs.showProcessSplitToGougedDialog(
                context: context,
                split: item,
                getNextCode: _getNextCode,
                onProcessed: (newGouged) {
                  setState(() => _gougedStocks.add(newGouged));
                  _saveData();
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGougedStockTab() {
    final items = _showOnlyInStock
        ? _gougedStocks.where((e) => e.remainingCount > 0).toList()
        : _gougedStocks;

    if (items.isEmpty) return const Center(child: Text('表示するカマボコストックがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: 'マシン: ${item.machine} | 日付: ${item.gougingDate}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () {
            StockDialogs.showEditGougedDialog(
              context: context,
              gouged: item,
              onSaved: () { setState(() {}); _saveData(); },
            );
          },
          onDelete: () => _confirmDelete(() {
            setState(() => _gougedStocks.remove(item));
            _saveData();
          }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
            ),
            icon: const Icon(Icons.content_cut, size: 16),
            label: const Text('舟形(S)へ加工'),
            onPressed: () {
              StockDialogs.showProcessGougedToShapedDialog(
                context: context,
                gouged: item,
                getNextCode: _getNextCode,
                onProcessed: (newShaped) {
                  setState(() => _shapedStocks.add(newShaped));
                  _saveData();
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildShapedStockTab() {
    final items = _showOnlyInStock
        ? _shapedStocks.where((e) => e.remainingCount > 0).toList()
        : _shapedStocks;

    if (items.isEmpty) return const Center(child: Text('表示する舟形ストックがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: 'シェーパー: ${item.shaper} | 日付: ${item.shapingDate}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () {
            StockDialogs.showEditShapedDialog(
              context: context,
              shaped: item,
              onSaved: () { setState(() {}); _saveData(); },
            );
          },
          onDelete: () => _confirmDelete(() {
            setState(() => _shapedStocks.remove(item));
            _saveData();
          }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
            ),
            icon: const Icon(Icons.architecture, size: 16),
            label: const Text('チューブを選んで糸巻き'),
            onPressed: () {
              // 未使用のチューブのみ抽出
              final availableStaples = stapleStocks.where((s) => s.status == StapleStatus.unused).toList();

              StockDialogs.showProcessShapedToTiedDialog(
                context: context,
                shaped: item,
                availableStaples: availableStaples,
                onProcessed: (newTied, selectedStaple) {
                  setState(() {
                    _tiedStocks.add(newTied); // 糸巻きリストに追加
                    item.remainingCount--; // 舟形ケーン消費
                    selectedStaple.status = StapleStatus.tied; // チューブを糸巻き済みに更新
                  });
                  _saveData();
                },
              );
            },
          ),
        );
      },
    );
  }

  // ==========================================
  // チューブ (Staple) 管理タブ
  // ==========================================
  Widget _buildStapleStockTab() {
    final sortedList = getSortedStaples();
    final items = _showOnlyInStock
        ? sortedList.where((e) => e.status == StapleStatus.unused).toList()
        : sortedList;

    if (items.isEmpty) return const Center(child: Text('表示するチューブ(Staple)ストックがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final bool isUnused = item.status == StapleStatus.unused;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 16),
                          children: [
                            TextSpan(
                              text: '[${item.brand} ${item.model}] ${item.length}  ',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            TextSpan(
                              text: item.mark,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.deepOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isUnused ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.status.label,
                            style: TextStyle(
                              fontSize: 12,
                              color: isUnused ? Colors.green.shade900 : Colors.orange.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          tooltip: '編集する',
                          onPressed: () {
                            StockDialogs.showEditStapleDialog(
                              context: context,
                              staple: item,
                              existingBrands: _getAllExistingBrands(),
                              onSaved: () {
                                setState(() {});
                                _saveData();
                              },
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: '削除する',
                          onPressed: () => _confirmDelete(() {
                            setState(() => stapleStocks.remove(item));
                            _saveData();
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  '材質: ${item.material}${item.memo != null && item.memo!.isNotEmpty ? " | メモ: ${item.memo}" : ""}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // 第6タブ: 糸巻き(Tied) 管理タブ
  // ==========================================
  Widget _buildTiedStockTab() {
    if (_tiedStocks.isEmpty) return const Center(child: Text('糸巻き(Tied)されたリードがありません'));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tiedStocks.length,
      itemBuilder: (context, index) {
        final item = _tiedStocks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'チューブ: ${item.stapleId}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                    ),
                    Text(
                      '全長: ${item.totalLength} mm',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text('ケーン: ${item.shapedTitle} (${item.shapedCode})'),
                const SizedBox(height: 4),
                Text('糸巻き日: ${item.tiedDate}${item.threadColor != null ? " | 糸色: ${item.threadColor}" : ""}'),
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('メモ: ${item.memo}', style: TextStyle(color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(VoidCallback onDeleteConfirmed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ストックの削除'),
        content: const Text('このストック項目を完全に削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              onDeleteConfirmed();
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}