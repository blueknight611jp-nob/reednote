import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../dialogs.dart';
import '../utils/helpers.dart';
import '../main.dart'; // MainRootPage.switchPage 呼び出し用

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
  List<TiedStock> _tiedStocks = [];
  Set<String> _workingReedIds = {};

  List<StapleStock> getSortedStaples() {
    List<StapleStock> list = List.from(stapleStocks);
    list.sort((a, b) {
      int c = a.brand.compareTo(b.brand);
      if (c != 0) return c;
      c = a.model.compareTo(b.model);
      if (c != 0) return c;
      c = a.length.compareTo(b.length);
      if (c != 0) return c;
      return a.mark.compareTo(b.mark);
    });
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorkingReedIds();
  }

  Future<void> _loadWorkingReedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        _workingReedIds = decoded.map((e) => e['id'].toString()).toSet();
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadWorkingReedIds();

    final tubeJson = prefs.getString('tube_stocks');
    if (tubeJson != null) _tubeStocks = (jsonDecode(tubeJson) as List).map((e) => TubeStock.fromJson(e)).toList();
    final splitJson = prefs.getString('split_stocks');
    if (splitJson != null) _splitStocks = (jsonDecode(splitJson) as List).map((e) => SplitCaneStock.fromJson(e)).toList();
    final gougedJson = prefs.getString('gouged_stocks');
    if (gougedJson != null) _gougedStocks = (jsonDecode(gougedJson) as List).map((e) => GougedCaneStock.fromJson(e)).toList();
    final shapedJson = prefs.getString('shaped_stocks');
    if (shapedJson != null) _shapedStocks = (jsonDecode(shapedJson) as List).map((e) => ShapedCaneStock.fromJson(e)).toList();
    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) stapleStocks = (jsonDecode(stapleJson) as List).map((e) => StapleStock.fromJson(e)).toList();
    final tiedJson = prefs.getString('tied_stocks');
    if (tiedJson != null) _tiedStocks = (jsonDecode(tiedJson) as List).map((e) => TiedStock.fromJson(e)).toList();

    setState(() { _isLoading = false; });
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

  void _confirmAndSendToCutAndScrape(TiedStock tied) {
    showDialog(
      context: context,
      builder: (context) {
        final staple = stapleStocks.firstWhere(
          (s) => s.id == tied.stapleId,
          orElse: () => StapleStock(id: '', brand: '不明', model: '', length: '', mark: ''),
        );

        return AlertDialog(
          title: const Text('管理・調整部屋へ登録'),
          content: Text('[チューブ: ${staple.displayTitle}]\nこのリードを「Lv.1（荒削り）」として登録し、ページ1へ移動しますか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
              onPressed: () async {
                Navigator.pop(context);
                await _sendToCutAndScrapeAction(tied);
              },
              child: const Text('登録してページ1へ移動'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendToCutAndScrapeAction(TiedStock tied) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    List<WorkReed> currentWorkReeds = [];
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      currentWorkReeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
    }

    final exists = currentWorkReeds.any((w) => w.id == tied.id);
    if (!exists) {
      final newWorkReed = WorkReed(
        id: tied.id,
        stapleId: tied.stapleId,
        shapedCode: tied.shapedCode,
        shapedTitle: tied.shapedTitle,
        tiedDate: tied.tiedDate,
        currentTotalLength: tied.totalLength,
        qualityLevel: 1,
        threadColor: tied.threadColor,
        logs: [],
      );
      currentWorkReeds.add(newWorkReed);
      await prefs.setString('work_leads_data', jsonEncode(currentWorkReeds.map((e) => e.toJson()).toList()));
    }

    await _loadWorkingReedIds();

    if (mounted) {
      MainRootPage.switchPage(context, 0);
    }
  }

  List<String> _getAllExistingBrands() {
    Set<String> brands = {'Rigotti', 'Tchankaya', 'Alliaud', 'Chiarugi', 'Loree', 'Glotin', 'Guercio'};
    for (var t in _tubeStocks) { if (t.brand.isNotEmpty) brands.add(t.brand); }
    for (var s in _splitStocks) { if (s.brand.isNotEmpty) brands.add(s.brand); }
    for (var g in _gougedStocks) { 
      if (g.sourceTitle.isNotEmpty) brands.add(g.sourceTitle.split(' ')[0]); 
    }
    for (var st in stapleStocks) { if (st.brand.isNotEmpty) brands.add(st.brand); }
    return brands.toList();
  }

  List<String> _getAllExistingPeriods() {
    Set<String> periods = {'202506', '202601'};
    for (var t in _tubeStocks) { if (t.purchasePeriod.isNotEmpty) periods.add(t.purchasePeriod); }
    for (var s in _splitStocks) { if (s.purchasePeriod.isNotEmpty) periods.add(s.purchasePeriod); }
    return periods.toList();
  }

  String _generatePrefix(String brand) {
    if (brand.isEmpty) return 'Can';
    return brand.length > 3 ? brand.substring(0, 3) : brand;
  }

  String _formatYYMM(String period) {
    String digits = period.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 6) return digits.substring(2, 6);
    if (digits.length == 4) return digits;
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
    RegExp reg = RegExp('^' + typeLetter + r'(\d+)');

    for (var code in existingCodes) {
      var match = reg.firstMatch(code);
      if (match != null) {
        int? num = int.tryParse(match.group(1)!);
        if (num != null && num > maxNum) maxNum = num;
      }
    }
    String nextNumStr = (maxNum + 1).toString().padLeft(2, '0');
    return '$typeLetter$nextNumStr$suffix';
  }

  Future<void> _exportDataToFile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final allData = {
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tubes': prefs.getString('tube_stocks') != null ? jsonDecode(prefs.getString('tube_stocks')!) : [],
      'splits': prefs.getString('split_stocks') != null ? jsonDecode(prefs.getString('split_stocks')!) : [],
      'gouged': prefs.getString('gouged_stocks') != null ? jsonDecode(prefs.getString('gouged_stocks')!) : [],
      'shaped': prefs.getString('shaped_stocks') != null ? jsonDecode(prefs.getString('shaped_stocks')!) : [],
      'staples': prefs.getString('staple_stocks') != null ? jsonDecode(prefs.getString('staple_stocks')!) : [],
      'tied': prefs.getString('tied_stocks') != null ? jsonDecode(prefs.getString('tied_stocks')!) : [],
      'work_leads': prefs.getString('work_leads_data') != null ? jsonDecode(prefs.getString('work_leads_data')!) : [],
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(allData);
    final bytes = utf8.encode(jsonString);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    html.AnchorElement(href: url)
      ..setAttribute("download", "ReedNote_Full_Backup_${DateTime.now().toString().split(' ')[0]}.json")
      ..click();
      
    html.Url.revokeObjectUrl(url);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すべてのデータを完全バックアップしました')),
      );
    }
  }

  void _importDataFromFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) async {
        try {
          final data = jsonDecode(reader.result as String) as Map<String, dynamic>;
          final prefs = await SharedPreferences.getInstance();

          if (data.containsKey('tubes')) await prefs.setString('tube_stocks', jsonEncode(data['tubes']));
          if (data.containsKey('splits')) await prefs.setString('split_stocks', jsonEncode(data['splits']));
          if (data.containsKey('gouged')) await prefs.setString('gouged_stocks', jsonEncode(data['gouged']));
          if (data.containsKey('shaped')) await prefs.setString('shaped_stocks', jsonEncode(data['shaped']));
          if (data.containsKey('staples')) await prefs.setString('staple_stocks', jsonEncode(data['staples']));
          if (data.containsKey('tied')) await prefs.setString('tied_stocks', jsonEncode(data['tied']));
          if (data.containsKey('work_leads')) await prefs.setString('work_leads_data', jsonEncode(data['work_leads']));

          await _loadData();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('すべてのデータを完全に復元しました！')),
            );
          }
        } catch (err) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ファイルの読み込みに失敗しました: $err')),
            );
          }
        }
      });
      reader.readAsText(files[0]);
    });
  }

  void _openAddDialogForCurrentTab() {
    final existingBrands = _getAllExistingBrands();
    final existingPeriods = _getAllExistingPeriods();
    final existingVendors = _tubeStocks.map((e) => e.vendor ?? '').where((e) => e.isNotEmpty).toSet().toList();

    switch (_tabController.index) {
      case 0:
        StockDialogs.showAddTubeDialog(context: context, existingBrands: existingBrands, existingPeriods: existingPeriods, existingVendors: existingVendors, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _tubeStocks.add(newStock)); _saveData(); });
        break;
      case 1:
        StockDialogs.showAddSplitDialog(context: context, existingBrands: existingBrands, existingPeriods: existingPeriods, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _splitStocks.add(newStock)); _saveData(); });
        break;
      case 2:
        StockDialogs.showAddGougedDialog(context: context, existingBrands: existingBrands, existingPeriods: existingPeriods, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _gougedStocks.add(newStock)); _saveData(); });
        break;
      case 3:
        StockDialogs.showAddShapedDialog(context: context, existingBrands: existingBrands, existingPeriods: existingPeriods, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _shapedStocks.add(newStock)); _saveData(); });
        break;
      case 4:
        StockDialogs.showAddStapleDialog(context: context, existingBrands: existingBrands, onRegistered: (newStaples) { setState(() => stapleStocks.addAll(newStaples)); _saveData(); });
        break;
      case 5:
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
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('ReedNote - 素材ストック管理'),
        actions: [
          Tooltip(message: 'インポート', child: TextButton.icon(style: TextButton.styleFrom(foregroundColor: Colors.brown.shade800), icon: const Icon(Icons.folder_open, size: 18), label: const Text('Import'), onPressed: _importDataFromFile)),
          const SizedBox(width: 8),
          Tooltip(message: 'エクスポート', child: TextButton.icon(style: TextButton.styleFrom(foregroundColor: Colors.brown.shade800), icon: const Icon(Icons.save_alt, size: 18), label: const Text('Export'), onPressed: _exportDataToFile)),
          const SizedBox(width: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: ChoiceChip(label: Text(_showOnlyInStock ? '在庫ありのみ' : 'すべて表示'), selected: !_showOnlyInStock, onSelected: (s) => setState(() => _showOnlyInStock = !s)),
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
      floatingActionButton: _tabController.index == 5 ? null : FloatingActionButton.extended(onPressed: _openAddDialogForCurrentTab, icon: const Icon(Icons.add), label: Text(_fabLabel)),
    );
  }

  Widget _buildStockCard({required String title, required String subtitle, required int count, required VoidCallback onIncrement, required VoidCallback onDecrement, required VoidCallback onEdit, required VoidCallback onDelete, Widget? processButton}) {
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
                Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isInStock ? Colors.black : Colors.grey.shade600))),
                if (!isInStock) ...[
                  Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)), child: const Text('在庫なし', style: TextStyle(fontSize: 12, color: Colors.white))),
                ],
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), tooltip: '編集', onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: '削除', onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: isInStock ? Colors.black87 : Colors.grey.shade600)),
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (processButton != null && isInStock) processButton else const SizedBox.shrink(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: count > 0 ? onDecrement : null),
                    Text('$count本', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isInStock ? Colors.black : Colors.grey.shade600)),
                    IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: onIncrement),
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
    final items = _showOnlyInStock ? _tubeStocks.where((e) => e.remainingCount > 0).toList() : _tubeStocks;
    if (items.isEmpty) return const Center(child: Text('表示する丸材ストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | 購入先: ${item.vendor ?? "未登録"}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () => StockDialogs.showEditTubeDialog(context: context, tube: item, existingBrands: _getAllExistingBrands(), onSaved: () { setState(() {}); _saveData(); }),
          onDelete: () => _confirmDelete(() { setState(() => _tubeStocks.remove(item)); _saveData(); }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: const Icon(Icons.call_split, size: 16),
            label: const Text('半カマボコ(P)へ加工'),
            onPressed: () => StockDialogs.showProcessTubeToSplitDialog(
              context: context,
              tube: item,
              getNextCode: _getNextCode,
              onProcessed: (newSplit) {
                setState(() => _splitStocks.add(newSplit));
                _saveData();
                _tabController.animateTo(1); // 半カマボコタブへ自動移動
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSplitStockTab() {
    final items = _showOnlyInStock ? _splitStocks.where((e) => e.remainingCount > 0).toList() : _splitStocks;
    if (items.isEmpty) return const Center(child: Text('表示する半カマボコストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | 由来: ${item.sourceInfo}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () => StockDialogs.showEditSplitDialog(context: context, split: item, existingBrands: _getAllExistingBrands(), onSaved: () { setState(() {}); _saveData(); }),
          onDelete: () => _confirmDelete(() { setState(() => _splitStocks.remove(item)); _saveData(); }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: const Icon(Icons.density_medium, size: 16),
            label: const Text('カマボコ(G)へ加工'),
            onPressed: () => StockDialogs.showProcessSplitToGougedDialog(
              context: context,
              split: item,
              getNextCode: _getNextCode,
              onProcessed: (newGouged) {
                setState(() => _gougedStocks.add(newGouged));
                _saveData();
                _tabController.animateTo(2); // カマボコタブへ自動移動
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildGougedStockTab() {
    final items = _showOnlyInStock ? _gougedStocks.where((e) => e.remainingCount > 0).toList() : _gougedStocks;
    if (items.isEmpty) return const Center(child: Text('表示するカマボコストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | マシン: ${item.machine} | 日付: ${item.gougingDate}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () => StockDialogs.showEditGougedDialog(context: context, gouged: item, onSaved: () { setState(() {}); _saveData(); }),
          onDelete: () => _confirmDelete(() { setState(() => _gougedStocks.remove(item)); _saveData(); }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: const Icon(Icons.content_cut, size: 16),
            label: const Text('舟形(S)へ加工'),
            onPressed: () => StockDialogs.showProcessGougedToShapedDialog(
              context: context,
              gouged: item,
              getNextCode: _getNextCode,
              onProcessed: (newShaped) {
                setState(() => _shapedStocks.add(newShaped));
                _saveData();
                _tabController.animateTo(3); // 舟形タブへ自動移動
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildShapedStockTab() {
    final items = _showOnlyInStock ? _shapedStocks.where((e) => e.remainingCount > 0).toList() : _shapedStocks;
    if (items.isEmpty) return const Center(child: Text('表示する舟形ストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: '太さ: ${item.diameter} | シェーパー: ${item.shaper} | 日付: ${item.shapingDate}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () => StockDialogs.showEditShapedDialog(context: context, shaped: item, onSaved: () { setState(() {}); _saveData(); }),
          onDelete: () => _confirmDelete(() { setState(() => _shapedStocks.remove(item)); _saveData(); }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: const Icon(Icons.architecture, size: 16),
            label: const Text('チューブを選んで糸巻き'),
            onPressed: () {
              final availableStaples = stapleStocks.where((s) => s.status == StapleStatus.unused).toList();
              StockDialogs.showProcessShapedToTiedDialog(
                context: context,
                shaped: item,
                availableStaples: availableStaples,
                onProcessed: (newTied, selectedStaple) {
                  setState(() {
                    _tiedStocks.add(newTied);
                    item.remainingCount--;
                    selectedStaple.status = StapleStatus.tied;
                  });
                  _saveData();
                  _tabController.animateTo(5); // 糸巻きタブへ自動移動
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStapleStockTab() {
    final sortedList = getSortedStaples();
    final items = _showOnlyInStock ? sortedList.where((e) => e.status == StapleStatus.unused).toList() : sortedList;
    if (items.isEmpty) return const Center(child: Text('表示するチューブ(Staple)ストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
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
                    Expanded(child: RichText(text: TextSpan(style: const TextStyle(color: Colors.black, fontSize: 16), children: [TextSpan(text: '[${item.brand} ${item.model}] ${item.length}  ', style: TextStyle(color: Colors.grey.shade700)), TextSpan(text: item.mark, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrange))]))),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: isUnused ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(4)), child: Text(item.status.label, style: TextStyle(fontSize: 12, color: isUnused ? Colors.green.shade900 : Colors.orange.shade900, fontWeight: FontWeight.bold))),
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), tooltip: '編集', onPressed: () => StockDialogs.showEditStapleDialog(context: context, staple: item, existingBrands: _getAllExistingBrands(), onSaved: () { setState(() {}); _saveData(); })),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), tooltip: '削除', onPressed: () => _confirmDelete(() { setState(() => stapleStocks.remove(item)); _saveData(); })),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text('材質: ${item.material}${item.memo != null && item.memo!.isNotEmpty ? " | メモ: ${item.memo}" : ""}', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTiedStockTab() {
    if (_tiedStocks.isEmpty) return const Center(child: Text('糸巻き(Tied)されたリードがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _tiedStocks.length,
      itemBuilder: (context, i) {
        final item = _tiedStocks[i];
        final bool isWorking = _workingReedIds.contains(item.id);

        final staple = stapleStocks.firstWhere(
          (s) => s.id == item.stapleId,
          orElse: () => StapleStock(id: '', brand: '不明', model: '', length: '', mark: ''),
        );

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
                    Text('[${staple.displayTitle}]', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('全長: ${item.totalLength} mm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: '糸巻きストックを削除',
                          onPressed: () => _confirmDelete(() {
                            setState(() => _tiedStocks.remove(item));
                            _saveData();
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),
                Text('ケーン: ${item.shapedTitle} (${item.shapedCode})'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('糸巻き日: ${item.tiedDate}'),
                    if (item.threadColor != null && item.threadColor!.isNotEmpty) ...[
                      const Text(' | 糸: '),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getThreadColor(item.threadColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${item.threadColor}'),
                    ],
                  ],
                ),
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('メモ: ${item.memo}', style: TextStyle(color: Colors.grey.shade700)),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: isWorking
                      ? ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.grey.shade700),
                          icon: const Icon(Icons.check_circle, size: 18),
                          label: const Text('作業中 (ページ1へ登録済み)'),
                          onPressed: null,
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800, foregroundColor: Colors.white),
                          icon: const Icon(Icons.content_cut, size: 18),
                          label: const Text('管理・調整部屋へ登録'),
                          onPressed: () => _confirmAndSendToCutAndScrape(item),
                        ),
                ),
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
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () { onDeleteConfirmed(); Navigator.pop(context); }, child: const Text('削除')),
        ],
      ),
    );
  }
}