import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../dialogs.dart';
import '../utils/helpers.dart';
import '../utils/reed_id_utils.dart';
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

  String? _highlightedId; // 現在ハイライトされているアイテムのID
  Timer? _highlightTimer;   // ハイライトを消すためのタイマー

  List<StapleStock> getSortedStaples() {
    List<StapleStock> list = List.from(stapleStocks);
    list.sort((a, b) {
      int c = b.brand.compareTo(a.brand);
      if (c != 0) return c;
      c = b.model.compareTo(a.model);
      if (c != 0) return c;
      c = b.length.compareTo(a.length);
      if (c != 0) return c;
      return b.mark.compareTo(a.mark);
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
    _highlightTimer?.cancel();
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

  void _jumpAndHighlight(int tabIndex, String targetId) {
    _highlightTimer?.cancel();
    setState(() {
      _highlightedId = targetId;
      _tabController.animateTo(tabIndex);
    });

    _highlightTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _highlightedId = null;
        });
      }
    });
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
        currentTotalLength: tied.totalLength.toString(),
        qualityLevel: 1,
        threadColor: tied.threadColor,
        vendor: tied.vendor,
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
    for (var g in _gougedStocks) { if (g.brand.isNotEmpty) brands.add(g.brand); }
    for (var sh in _shapedStocks) { if (sh.brand.isNotEmpty) brands.add(sh.brand); }
    for (var st in stapleStocks) { if (st.brand.isNotEmpty) brands.add(st.brand); }
    return brands.toList();
  }

  List<String> _getAllExistingVendors() {
    Set<String> vendors = {};
    for (var t in _tubeStocks) { if (t.vendor != null && t.vendor!.isNotEmpty) vendors.add(t.vendor!); }
    for (var s in _splitStocks) { if (s.vendor != null && s.vendor!.isNotEmpty) vendors.add(s.vendor!); }
    for (var g in _gougedStocks) { if (g.vendor != null && g.vendor!.isNotEmpty) vendors.add(g.vendor!); }
    for (var sh in _shapedStocks) { if (sh.vendor != null && sh.vendor!.isNotEmpty) vendors.add(sh.vendor!); }
    for (var td in _tiedStocks) { if (td.vendor != null && td.vendor!.isNotEmpty) vendors.add(td.vendor!); }
    return vendors.toList();
  }

  List<String> _getAllExistingPeriods() {
    Set<String> periods = {'2506', '2601'};
    for (var t in _tubeStocks) { if (t.purchasePeriod.isNotEmpty) periods.add(_formatYYMM(t.purchasePeriod)); }
    for (var s in _splitStocks) { if (s.purchasePeriod.isNotEmpty) periods.add(_formatYYMM(s.purchasePeriod)); }
    return periods.toList();
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
    final existingVendors = _getAllExistingVendors();

    switch (_tabController.index) {
      case 0:
        StockDialogs.showAddCaneDialog(
          context: context,
          caneType: CaneType.tube,
          existingBrands: existingBrands,
          existingPeriods: existingPeriods,
          existingVendors: existingVendors,
          getNextCode: _getNextCode,
          onRegistered: (newStock) { setState(() => _tubeStocks.insert(0, newStock)); _saveData(); },
        );
        break;
      case 1:
        StockDialogs.showAddCaneDialog(
          context: context,
          caneType: CaneType.split,
          existingBrands: existingBrands,
          existingPeriods: existingPeriods,
          existingVendors: existingVendors,
          getNextCode: _getNextCode,
          onRegistered: (newStock) { setState(() => _splitStocks.insert(0, newStock)); _saveData(); },
        );
        break;
      case 2:
        StockDialogs.showAddCaneDialog(
          context: context,
          caneType: CaneType.gouged,
          existingBrands: existingBrands,
          existingPeriods: existingPeriods,
          existingVendors: existingVendors,
          getNextCode: _getNextCode,
          onRegistered: (newStock) { setState(() => _gougedStocks.insert(0, newStock)); _saveData(); },
        );
        break;
      case 3:
        StockDialogs.showAddCaneDialog(
          context: context,
          caneType: CaneType.shaped,
          existingBrands: existingBrands,
          existingPeriods: existingPeriods,
          existingVendors: existingVendors,
          getNextCode: _getNextCode,
          onRegistered: (newStock) { setState(() => _shapedStocks.insert(0, newStock)); _saveData(); },
        );
        break;
      case 4:
        StockDialogs.showAddStapleDialog(
          context: context,
          existingBrands: existingBrands,
          onRegistered: (newStaples) { setState(() => stapleStocks.addAll(newStaples)); _saveData(); },
        );
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
            Tab(icon: Icon(Icons.architecture), text: '5. チューブ(Hülse)'),
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

  Widget _buildStockCard({
    required String displayTitle,
    required String fullId,
    required String subtitle,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    Widget? processButton,
    bool isHighlighted = false,
  }) {
    final bool isInStock = count > 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isHighlighted
          ? Colors.amber.shade100
          : (isInStock ? null : Colors.grey.shade200),
      elevation: isHighlighted ? 6 : 1,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isInStock ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isInStock ? Colors.black54 : Colors.grey.shade600,
                        ),
                      ),
                      ReedIdUtils.buildClickableIdParts(
                        context,
                        fullId,
                        _tabController,
                        onJumpAndHighlight: _jumpAndHighlight,
                      ),
                      Text(
                        ')',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isInStock ? Colors.black54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
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
                ],
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                  tooltip: '編集',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  tooltip: '削除',
                  onPressed: onDelete,
                ),
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
                if (processButton != null && isInStock) processButton else const SizedBox.shrink(),
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

  Widget _buildCaneStockTab<T>({
    required List<T> items,
    required String Function(T) getCode,
    required String Function(T) getDisplayTitle,
    required String Function(T) getId,
    required String Function(T) getSubtitle,
    required int Function(T) getCount,
    required void Function(T, int) setCount,
    required VoidCallback onAddStock,
    required VoidCallback Function(T) onDelete,
    required String processButtonLabel,
    required IconData processButtonIcon,
    required VoidCallback Function(T) onProcess,
    required String emptyMessage,
  }) {
    List<T> filteredItems = _showOnlyInStock 
        ? items.where((e) => getCount(e) > 0).toList() 
        : List.from(items);
    
    filteredItems.sort((a, b) => getCode(b).compareTo(getCode(a)));

    if (filteredItems.isEmpty) return Center(child: Text(emptyMessage));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: filteredItems.length,
      itemBuilder: (context, i) {
        final item = filteredItems[i];
        final count = getCount(item);
        final itemId = getId(item);
        final bool isHighlighted = _highlightedId != null && itemId.contains(_highlightedId!);

        return _buildStockCard(
          displayTitle: getDisplayTitle(item),
          fullId: itemId,
          subtitle: getSubtitle(item),
          count: count,
          isHighlighted: isHighlighted,
          onIncrement: () { setState(() => setCount(item, count + 1)); _saveData(); },
          onDecrement: () { setState(() => setCount(item, count - 1)); _saveData(); },
          onEdit: () => StockDialogs.showEditCaneDialog(
            context: context,
            stock: item,
            existingBrands: _getAllExistingBrands(),
            existingVendors: _getAllExistingVendors(),
            onSaved: () { setState(() {}); _saveData(); },
          ),
          onDelete: onDelete(item),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: Icon(processButtonIcon, size: 16),
            label: Text(processButtonLabel),
            onPressed: onProcess(item),
          ),
        );
      },
    );
  }

  Widget _buildTubeStockTab() {
    return _buildCaneStockTab<TubeStock>(
      items: _tubeStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | 購入先: ${e.vendor ?? "未登録"}\nメモ: ${e.memo ?? "-"}',
      getCount: (e) => e.remainingCount,
      setCount: (e, val) => e.remainingCount = val,
      onAddStock: () {},
      onDelete: (item) => () => _confirmDelete(() { setState(() => _tubeStocks.remove(item)); _saveData(); }),
      processButtonLabel: '半カマボコ(P)へ加工',
      processButtonIcon: Icons.call_split,
      onProcess: (item) => () => StockDialogs.showProcessTubeToSplitDialog(
        context: context,
        tube: item,
        getNextCode: _getNextCode,
        onProcessed: (newSplit) {
          setState(() => _splitStocks.insert(0, newSplit));
          _saveData();
          _tabController.animateTo(1);
        },
      ),
      emptyMessage: '表示する丸材ストックがありません',
    );
  }

  Widget _buildSplitStockTab() {
    return _buildCaneStockTab<SplitCaneStock>(
      items: _splitStocks,
      getCode: (e) => e.id,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | 購入先: ${e.vendor ?? "未登録"}\nメモ: ${e.memo ?? "-"}',
      getCount: (e) => e.remainingCount,
      setCount: (e, val) => e.remainingCount = val,
      onAddStock: () {},
      onDelete: (item) => () => _confirmDelete(() { setState(() => _splitStocks.remove(item)); _saveData(); }),
      processButtonLabel: 'カマボコ(G)へ加工',
      processButtonIcon: Icons.density_medium,
      onProcess: (item) => () => StockDialogs.showProcessSplitToGougedDialog(
        context: context,
        split: item,
        getNextCode: _getNextCode,
        onProcessed: (newGouged) {
          setState(() => _gougedStocks.add(newGouged));
          _saveData();
          _tabController.animateTo(2);
        },
      ),
      emptyMessage: '表示する半カマボコストックがありません',
    );
  }

  Widget _buildGougedStockTab() {
    return _buildCaneStockTab<GougedCaneStock>(
      items: _gougedStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | マシン: ${e.machine} | 厚さ ${e.thickness} | 購入先: ${e.vendor ?? "未登録"}\n日付: ${e.gougingDate} | メモ: ${e.memo ?? "-"}',
      getCount: (e) => e.remainingCount,
      setCount: (e, val) => e.remainingCount = val,
      onAddStock: () {},
      onDelete: (item) => () => _confirmDelete(() { setState(() => _gougedStocks.remove(item)); _saveData(); }),
      processButtonLabel: '舟形(S)へ加工',
      processButtonIcon: Icons.content_cut,
      onProcess: (item) => () => StockDialogs.showProcessGougedToShapedDialog(
        context: context,
        gouged: item,
        getNextCode: _getNextCode,
        onProcessed: (newShaped) {
          setState(() => _shapedStocks.add(newShaped));
          _saveData();
          _tabController.animateTo(3);
        },
      ),
      emptyMessage: '表示するカマボコストックがありません',
    );
  }

  Widget _buildShapedStockTab() {
    return _buildCaneStockTab<ShapedCaneStock>(
      items: _shapedStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | シェーパー: ${e.shaper} | 購入先: ${e.vendor ?? "未登録"}\n日付: ${e.shapingDate} | メモ: ${e.memo ?? "-"}',
      getCount: (e) => e.remainingCount,
      setCount: (e, val) => e.remainingCount = val,
      onAddStock: () {},
      onDelete: (item) => () => _confirmDelete(() { setState(() => _shapedStocks.remove(item)); _saveData(); }),
      processButtonLabel: 'チューブを選んで糸巻き',
      processButtonIcon: Icons.architecture,
      onProcess: (item) => () {
        final availableStaples = getSortedStaples().where((s) => s.status == StapleStatus.unused).toList();
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
            _tabController.animateTo(5);
          },
        );
      },
      emptyMessage: '表示する舟形ストックがありません',
    );
  }

  Widget _buildStapleStockTab() {
    final sortedList = getSortedStaples();
    final items = _showOnlyInStock 
        ? sortedList.where((e) => e.status == StapleStatus.unused).toList() 
        : sortedList;
      
    if (items.isEmpty) {
      return const Center(child: Text('表示するチューブ(Hülse)ストックがありません'));
    }
  
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final bool isUnused = item.status == StapleStatus.unused;
        final bool isHighlighted = _highlightedId != null && item.id.contains(_highlightedId!);
      
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isHighlighted ? Colors.amber.shade100 : null,
          elevation: isHighlighted ? 6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                              children: [
                                TextSpan(
                                  text: '${item.brand} ${item.model} ${item.length} ', 
                                  style: TextStyle(fontSize: 18, color: Colors.grey.shade900),
                                ),
                                TextSpan(
                                  text: item.mark, 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.deepOrange),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '材質: ${item.material}${item.memo != null && item.memo!.isNotEmpty ? " | メモ: ${item.memo}" : ""}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
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
                          tooltip: '編集',
                          onPressed: () => StockDialogs.showEditStapleDialog(
                            context: context,
                            staple: item,
                            existingBrands: _getAllExistingBrands(),
                            onSaved: () {
                              setState(() {});
                              _saveData();
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: '削除',
                          onPressed: () => _confirmDelete(() {
                            setState(() => stapleStocks.remove(item));
                            _saveData();
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTiedStockTab() {
    List<TiedStock> items = List.from(_tiedStocks);
    items.sort((a, b) => b.id.compareTo(a.id));

    if (items.isEmpty) return const Center(child: Text('糸巻き(Tied)されたリードがありません'));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final bool isWorking = _workingReedIds.contains(item.id);
        final bool isHighlighted = _highlightedId != null && item.id.contains(_highlightedId!);

        final staple = stapleStocks.firstWhere(
          (s) => s.id == item.stapleId,
          orElse: () => StapleStock(id: '', brand: '不明', model: '', length: '', mark: ''),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isHighlighted ? Colors.amber.shade100 : null,
          elevation: isHighlighted ? 6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1段目：チューブ情報（ブランド・モデル・長さのみ） ＋ コピー・編集・削除ボタン
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'チューブ: ${staple.brand}${staple.model}${staple.length}${staple.mark}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.deepOrange,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // コピーボタン
                        IconButton(
                          icon: const Icon(Icons.copy_outlined, color: Colors.blueGrey),
                          tooltip: '糸巻きストックを複製',
                          onPressed: () {
                            StockDialogs.showEditTiedDialog(
                              context: context,
                              tied: item,
                              isCopy: true,
                              onSaved: (copiedTied) {
                                setState(() {
                                  _tiedStocks.insert(0, copiedTied);
                                });
                                _saveData();
                              },
                            );
                          },
                        ),
                        // 編集ボタン
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                          tooltip: '糸巻きストックを編集',
                          onPressed: () {
                            StockDialogs.showEditTiedDialog(
                              context: context,
                              tied: item,
                              isCopy: false,
                              onSaved: (_) {
                                setState(() {});
                                _saveData();
                              },
                            );
                          },
                        ),
                        // 削除ボタン
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
                
                // 2段目：ケーン情報
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('ケーン: ${item.shapedTitle}  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('(', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    ReedIdUtils.buildClickableIdParts(
                      context,
                      item.shapedCode,
                      _tabController,
                      onJumpAndHighlight: _jumpAndHighlight,
                    ),
                    const Text(')', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 6),
                
                // 3段目：糸巻き情報（糸巻き日・糸の色・糸の種類・全長を同レベルで表示）
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text('糸巻き日: ${item.tiedDate}'),
                    if (item.threadColor != null && item.threadColor!.isNotEmpty) ...[
                      const Text('| 糸:'),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: getThreadColor(item.threadColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text('${item.threadColor}'),
                    ],
                    Text('| 種類: ${item.threadMaterial ?? "ナイロン"}'),
                    Text('| 全長: ${item.totalLength} mm'),
                    if (item.vendor != null && item.vendor!.isNotEmpty) ...[
                      Text('| 購入先: ${item.vendor}'),
                    ],
                  ],
                ),
                
                // 4段目：メモ
                if (item.memo != null && item.memo!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('メモ: ${item.memo}', style: TextStyle(color: Colors.grey.shade700)),
                ],
                const SizedBox(height: 12),
                
                // 5段目：アクションボタン
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