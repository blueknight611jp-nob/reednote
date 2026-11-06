import 'dart:convert';
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../dialogs.dart';
import '../utils/helpers.dart';
import '../utils/reed_id_utils.dart';
import '../utils/search_query_parser.dart';
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

  // 検索
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _tubeSortOrder = 'cane_id';
  String _splitSortOrder = 'cane_id';
  String _gougedSortOrder = 'cane_id';
  String _shapedSortOrder = 'cane_id';
  String _stapleSortOrder = 'model';
  String _tiedSortOrder = 'staple_full';

  void _changeSortOrder(String prefKey, String newSort, void Function() apply) {
    setState(() {
      apply();
    });
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(prefKey, newSort);
    });
  }

  List<StapleStock> getSortedStaples() {
    List<StapleStock> list = List.from(stapleStocks);
    list.sort((a, b) {
      int c = b.model.compareTo(a.model);
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
    _searchController.dispose();
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
      try {
        dynamic decoded = jsonDecode(jsonString);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          setState(() {
            _workingReedIds = Set<String>.from(decoded.map((e) => e['id'].toString()));
          });
        }
      } catch (e) {
        debugPrint('Error loading working reed ids: $e');
      }
    }
  }

  /// 二重エンコード対策を含んだ安全なリストデコードヘルパー
  List<T> _safeDecodeList<T>(SharedPreferences prefs, String key, T Function(Map<String, dynamic>) fromJson) {
    final rawJson = prefs.getString(key);
    if (rawJson == null || rawJson.isEmpty) return [];
    try {
      dynamic decoded = jsonDecode(rawJson);
      // 二重シリアライズ（文字列の中にJSON文字列が入っている状態）を安全に解除
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      if (decoded is List) {
        return decoded.map((e) => fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    } catch (e) {
      debugPrint('Error decoding $key: $e');
    }
    return [];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadWorkingReedIds();

    _tubeStocks = _safeDecodeList(prefs, 'tube_stocks', (json) => TubeStock.fromJson(json));
    _splitStocks = _safeDecodeList(prefs, 'split_stocks', (json) => SplitCaneStock.fromJson(json));
    _gougedStocks = _safeDecodeList(prefs, 'gouged_stocks', (json) => GougedCaneStock.fromJson(json));
    _shapedStocks = _safeDecodeList(prefs, 'shaped_stocks', (json) => ShapedCaneStock.fromJson(json));
    stapleStocks = _safeDecodeList(prefs, 'staple_stocks', (json) => StapleStock.fromJson(json));
    _tiedStocks = _safeDecodeList(prefs, 'tied_stocks', (json) => TiedStock.fromJson(json));

    final tubeSort = prefs.getString('stock_sort_tube');
    if (tubeSort != null) _tubeSortOrder = tubeSort;
    final splitSort = prefs.getString('stock_sort_split');
    if (splitSort != null) _splitSortOrder = splitSort;
    final gougedSort = prefs.getString('stock_sort_gouged');
    if (gougedSort != null) _gougedSortOrder = gougedSort;
    final shapedSort = prefs.getString('stock_sort_shaped');
    if (shapedSort != null) _shapedSortOrder = shapedSort;
    final stapleSort = prefs.getString('stock_sort_staple');
    if (stapleSort != null) _stapleSortOrder = stapleSort;
    final tiedSort = prefs.getString('stock_sort_tied');
    if (tiedSort != null) _tiedSortOrder = tiedSort;

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
    final cuttingLengthController = TextEditingController(text: '71.0');

    showDialog(
      context: context,
      builder: (context) {
        final staple = stapleStocks.firstWhere(
          (s) => s.id == tied.stapleId,
          orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
        );

        return AlertDialog(
          title: const Text('管理・調整部屋へ登録'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('[チューブ: ${staple.model} ${staple.length}mm (${staple.mark})]\nケーン: ${tied.shapedTitle}'),
              const SizedBox(height: 8),
              Text('糸巻き時全長: ${tied.totalLength} mm', style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 16),
              TextField(
                controller: cuttingLengthController,
                decoration: const InputDecoration(
                  labelText: '先端カット後の長さ (mm)',
                  border: OutlineInputBorder(),
                  helperText: '※初期カット後の使用長を入力してください',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              const Text('このリードを「Lv.1（荒削り）」として登録し、ページ1へ移動しますか？'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final cutLen = cuttingLengthController.text.trim().isEmpty 
                    ? '71.0' 
                    : cuttingLengthController.text.trim();
                Navigator.pop(context);
                await _sendToCutAndScrapeAction(tied, cutLen);
              },
              child: const Text('登録してページ1へ移動'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendToCutAndScrapeAction(TiedStock tied, String cuttingLength) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    List<WorkReed> currentWorkReeds = [];
    if (jsonString != null) {
      try {
        dynamic decoded = jsonDecode(jsonString);
        if (decoded is String) decoded = jsonDecode(decoded);
        if (decoded is List) {
          currentWorkReeds = decoded.map((e) => WorkReed.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        }
      } catch (e) {
        debugPrint('Error loading work_leads_data: $e');
      }
    }

    final exists = currentWorkReeds.any((w) => w.id == tied.id);
    if (!exists) {
      final newWorkReed = WorkReed(
        id: tied.id,
        stapleId: tied.stapleId,
        shapedCode: tied.shapedCode,
        shapedTitle: tied.shapedTitle,
        tiedDate: tied.tiedDate,
        totalLength: tied.totalLength,
        cuttingLength: cuttingLength,
        qualityLevel: 1, // 確実に Lv.1
        threadColor: tied.threadColor,
        threadMaterial: tied.threadMaterial,
        vendor: tied.vendor,
        logs: [
          ScrapeLog(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: DateTime.now().toString().split(' ')[0],
            level: 1,
            cuttingLength: cuttingLength,
            memo: '素材ストックから登録 (カット長: ${cuttingLength}mm)',
          ),
        ],
      );
      currentWorkReeds.add(newWorkReed);
      await prefs.setString('work_leads_data', jsonEncode(currentWorkReeds.map((e) => e.toJson()).toList()));
    }

    await _loadWorkingReedIds();

    await prefs.setInt('initial_work_tab_index', 0);

    if (mounted) {
      try {
        MainRootPage.switchPage(context, 0);
      } catch (e) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  List<String> _getAllExistingBrands() {
    Set<String> brands = {'Rigotti', 'Tchankaya', 'Alliaud', 'Chiarugi', 'Loree', 'Glotin', 'Guercio'};
    for (var t in _tubeStocks) { if (t.brand.isNotEmpty) brands.add(t.brand); }
    for (var s in _splitStocks) { if (s.brand.isNotEmpty) brands.add(s.brand); }
    for (var g in _gougedStocks) { if (g.brand.isNotEmpty) brands.add(g.brand); }
    for (var sh in _shapedStocks) { if (sh.brand.isNotEmpty) brands.add(sh.brand); }
    return brands.toList();
  }

  List<String> _getAllExistingModels() {
    Set<String> models = {'Chiarugi 2', 'Chiarugi 2+', 'Rigotti', 'Loree'};
    for (var st in stapleStocks) { if (st.model.isNotEmpty) models.add(st.model); }
    return models.toList();
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
    
    dynamic safeParseRaw(String key) {
      final str = prefs.getString(key);
      if (str == null) return [];
      try {
        dynamic dec = jsonDecode(str);
        if (dec is String) dec = jsonDecode(dec);
        return dec;
      } catch (_) {
        return [];
      }
    }

    final allData = {
      'version': '2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'tubes': safeParseRaw('tube_stocks'),
      'splits': safeParseRaw('split_stocks'),
      'gouged': safeParseRaw('gouged_stocks'),
      'shaped': safeParseRaw('shaped_stocks'),
      'staples': safeParseRaw('staple_stocks'),
      'tied': safeParseRaw('tied_stocks'),
      'work_leads': safeParseRaw('work_leads_data'),
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
    final existingModels = _getAllExistingModels();
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
          existingModels: existingModels,
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              // 検索バー
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '検索 (AND / OR / NOT 使用可。例: Rigotti AND 2506)',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            tooltip: '検索をクリア',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : Tooltip(
                            message: SearchQueryParser.helpText,
                            child: const Icon(Icons.help_outline, size: 18, color: Colors.black38),
                          ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              // タブバー
              TabBar(
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
            ],
          ),
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
    required String Function(T) getSearchText,
    required int Function(T) getCount,
    required void Function(T, int) setCount,
    required VoidCallback onAddStock,
    required VoidCallback Function(T) onDelete,
    required String processButtonLabel,
    required IconData processButtonIcon,
    required VoidCallback Function(T) onProcess,
    required String emptyMessage,
    required String sortOrder,
    required List<DropdownMenuItem<String>> sortOptions,
    required ValueChanged<String> onSortChanged,
    required void Function(List<T> list, String sortOrder) sortFunction,
  }) {
    List<T> filteredItems = _showOnlyInStock 
        ? items.where((e) => getCount(e) > 0).toList() 
        : List.from(items);
    
    // 検索フィルタ
    if (_searchQuery.trim().isNotEmpty) {
      final matcher = SearchQueryParser.compile(_searchQuery);
      filteredItems = filteredItems.where((e) => matcher(getSearchText(e))).toList();
    }

    sortFunction(filteredItems, sortOrder);

    return Column(
      children: [
        if (_searchQuery.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '絞り込み中: ${filteredItems.length}件',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('ソート: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: sortOrder,
                items: sortOptions,
                onChanged: (val) {
                  if (val != null) onSortChanged(val);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredItems.isEmpty
              ? Center(child: Text(
                  _searchQuery.trim().isNotEmpty ? '「$_searchQuery」に一致するアイテムはありません' : emptyMessage,
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
                ),
        ),
      ],
    );
  }

  Widget _buildTubeStockTab() {
    return _buildCaneStockTab<TubeStock>(
      items: _tubeStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | 購入先: ${e.vendor ?? "未登録"}\nメモ: ${e.memo ?? "-"}',
      getSearchText: (e) => e.searchText,
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
      sortOrder: _tubeSortOrder,
      sortOptions: const [
        DropdownMenuItem(value: 'cane_id', child: Text('ケーンID順')),
        DropdownMenuItem(value: 'purchase_desc', child: Text('購入日 (新しい順)')),
        DropdownMenuItem(value: 'purchase_asc', child: Text('購入日 (古い順)')),
        DropdownMenuItem(value: 'process_desc', child: Text('加工日 (新しい順)')),
        DropdownMenuItem(value: 'process_asc', child: Text('加工日 (古い順)')),
        DropdownMenuItem(value: 'diameter', child: Text('太さ順')),
        DropdownMenuItem(value: 'count_desc', child: Text('在庫数 (多い順)')),
        DropdownMenuItem(value: 'count_asc', child: Text('在庫数 (少ない順)')),
        DropdownMenuItem(value: 'vendor', child: Text('購入先順')),
      ],
      onSortChanged: (newSort) => _changeSortOrder('stock_sort_tube', newSort, () => _tubeSortOrder = newSort),
      sortFunction: (list, order) {
        list.sort((a, b) {
          switch (order) {
            case 'cane_id': return b.code.compareTo(a.code);
            case 'purchase_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'purchase_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'process_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'process_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'diameter': return a.diameter.compareTo(b.diameter);
            case 'count_desc': return b.remainingCount.compareTo(a.remainingCount);
            case 'count_asc': return a.remainingCount.compareTo(b.remainingCount);
            case 'vendor': return (a.vendor ?? '').compareTo(b.vendor ?? '');
            default: return b.code.compareTo(a.code);
          }
        });
      },
    );
  }

  Widget _buildSplitStockTab() {
    return _buildCaneStockTab<SplitCaneStock>(
      items: _splitStocks,
      getCode: (e) => e.id,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | 購入先: ${e.vendor ?? "未登録"}\nメモ: ${e.memo ?? "-"}',
      getSearchText: (e) => e.searchText,
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
      sortOrder: _splitSortOrder,
      sortOptions: const [
        DropdownMenuItem(value: 'cane_id', child: Text('ケーンID順')),
        DropdownMenuItem(value: 'purchase_desc', child: Text('購入日 (新しい順)')),
        DropdownMenuItem(value: 'purchase_asc', child: Text('購入日 (古い順)')),
        DropdownMenuItem(value: 'process_desc', child: Text('加工日 (新しい順)')),
        DropdownMenuItem(value: 'process_asc', child: Text('加工日 (古い順)')),
        DropdownMenuItem(value: 'diameter', child: Text('太さ順')),
        DropdownMenuItem(value: 'count_desc', child: Text('在庫数 (多い順)')),
        DropdownMenuItem(value: 'count_asc', child: Text('在庫数 (少ない順)')),
      ],
      onSortChanged: (newSort) => _changeSortOrder('stock_sort_split', newSort, () => _splitSortOrder = newSort),
      sortFunction: (list, order) {
        list.sort((a, b) {
          switch (order) {
            case 'cane_id': return b.code.compareTo(a.code);
            case 'purchase_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'purchase_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'process_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'process_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'diameter': return a.diameter.compareTo(b.diameter);
            case 'count_desc': return b.remainingCount.compareTo(a.remainingCount);
            case 'count_asc': return a.remainingCount.compareTo(b.remainingCount);
            default: return b.code.compareTo(a.code);
          }
        });
      },
    );
  }

  Widget _buildGougedStockTab() {
    return _buildCaneStockTab<GougedCaneStock>(
      items: _gougedStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | マシン: ${e.machine} | 厚さ ${e.thickness} | 購入先: ${e.vendor ?? "未登録"}\n日付: ${e.gougingDate} | メモ: ${e.memo ?? "-"}',
      getSearchText: (e) => e.searchText,
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
      sortOrder: _gougedSortOrder,
      sortOptions: const [
        DropdownMenuItem(value: 'cane_id', child: Text('ケーンID順')),
        DropdownMenuItem(value: 'purchase_desc', child: Text('購入日 (新しい順)')),
        DropdownMenuItem(value: 'purchase_asc', child: Text('購入日 (古い順)')),
        DropdownMenuItem(value: 'process_desc', child: Text('加工日 (新しい順)')),
        DropdownMenuItem(value: 'process_asc', child: Text('加工日 (古い順)')),
        DropdownMenuItem(value: 'diameter', child: Text('太さ順')),
        DropdownMenuItem(value: 'count_desc', child: Text('在庫数 (多い順)')),
        DropdownMenuItem(value: 'count_asc', child: Text('在庫数 (少ない順)')),
        DropdownMenuItem(value: 'thickness_asc', child: Text('ガウジング厚さ (薄い順)')),
        DropdownMenuItem(value: 'thickness_desc', child: Text('ガウジング厚さ (厚い順)')),
      ],
      onSortChanged: (newSort) => _changeSortOrder('stock_sort_gouged', newSort, () => _gougedSortOrder = newSort),
      sortFunction: (list, order) {
        list.sort((a, b) {
          switch (order) {
            case 'cane_id': return b.code.compareTo(a.code);
            case 'purchase_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'purchase_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'process_desc': return b.gougingDate.compareTo(a.gougingDate);
            case 'process_asc': return a.gougingDate.compareTo(b.gougingDate);
            case 'diameter': return a.diameter.compareTo(b.diameter);
            case 'count_desc': return b.remainingCount.compareTo(a.remainingCount);
            case 'count_asc': return a.remainingCount.compareTo(b.remainingCount);
            case 'thickness_asc': return (a.thickness ?? 999.0).compareTo(b.thickness ?? 999.0);
            case 'thickness_desc': return (b.thickness ?? 0.0).compareTo(a.thickness ?? 0.0);
            default: return b.code.compareTo(a.code);
          }
        });
      },
    );
  }

  Widget _buildShapedStockTab() {
    return _buildCaneStockTab<ShapedCaneStock>(
      items: _shapedStocks,
      getCode: (e) => e.code,
      getDisplayTitle: (e) => e.displayTitle,
      getId: (e) => e.id,
      getSubtitle: (e) => '太さ: ${e.diameter} | シェーパー: ${e.shaper} | 購入先: ${e.vendor ?? "未登録"}\n日付: ${e.shapingDate} | メモ: ${e.memo ?? "-"}',
      getSearchText: (e) => e.searchText,
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
          onProcessed: (newTied, selectedStaple) async {
            setState(() {
              _tiedStocks.insert(0, newTied); // 新しいものを先頭に追加
              item.remainingCount--;
              selectedStaple.status = StapleStatus.tied;
            });
            await _saveData();
            await _loadData();
            _tabController.animateTo(5);
          },
        );
      },
      emptyMessage: '表示する舟形ストックがありません',
      sortOrder: _shapedSortOrder,
      sortOptions: const [
        DropdownMenuItem(value: 'cane_id', child: Text('ケーンID順')),
        DropdownMenuItem(value: 'purchase_desc', child: Text('購入日 (新しい順)')),
        DropdownMenuItem(value: 'purchase_asc', child: Text('購入日 (古い順)')),
        DropdownMenuItem(value: 'process_desc', child: Text('加工日 (新しい順)')),
        DropdownMenuItem(value: 'process_asc', child: Text('加工日 (古い順)')),
        DropdownMenuItem(value: 'diameter', child: Text('太さ順')),
        DropdownMenuItem(value: 'count_desc', child: Text('在庫数 (多い順)')),
        DropdownMenuItem(value: 'count_asc', child: Text('在庫数 (少ない順)')),
        DropdownMenuItem(value: 'shaper', child: Text('シェイパーの型順')),
      ],
      onSortChanged: (newSort) => _changeSortOrder('stock_sort_shaped', newSort, () => _shapedSortOrder = newSort),
      sortFunction: (list, order) {
        list.sort((a, b) {
          switch (order) {
            case 'cane_id': return b.code.compareTo(a.code);
            case 'purchase_desc': return b.purchasePeriod.compareTo(a.purchasePeriod);
            case 'purchase_asc': return a.purchasePeriod.compareTo(b.purchasePeriod);
            case 'process_desc': return b.shapingDate.compareTo(a.shapingDate);
            case 'process_asc': return a.shapingDate.compareTo(b.shapingDate);
            case 'diameter': return a.diameter.compareTo(b.diameter);
            case 'count_desc': return b.remainingCount.compareTo(a.remainingCount);
            case 'count_asc': return a.remainingCount.compareTo(b.remainingCount);
            case 'shaper': return a.shaper.compareTo(b.shaper);
            default: return b.code.compareTo(a.code);
          }
        });
      },
    );
  }

  Widget _buildStapleStockTab() {
    List<StapleStock> items = List.from(stapleStocks);
    if (_showOnlyInStock) {
      items = items.where((e) => e.status == StapleStatus.unused).toList();
    }

    // 検索フィルタ
    if (_searchQuery.trim().isNotEmpty) {
      final matcher = SearchQueryParser.compile(_searchQuery);
      items = items.where((e) => matcher(e.searchText)).toList();
    }

    items.sort((a, b) {
      switch (_stapleSortOrder) {
        case 'model':
          int c = a.model.compareTo(b.model);
          if (c != 0) return c;
          c = a.length.compareTo(b.length);
          if (c != 0) return c;
          return a.mark.compareTo(b.mark);
        case 'length':
          int c = a.length.compareTo(b.length);
          if (c != 0) return c;
          c = a.model.compareTo(b.model);
          if (c != 0) return c;
          return a.mark.compareTo(b.mark);
        case 'status':
          int c = a.status.index.compareTo(b.status.index);
          if (c != 0) return c;
          c = a.model.compareTo(b.model);
          if (c != 0) return c;
          return a.length.compareTo(b.length);
        case 'mark':
          int c = a.mark.compareTo(b.mark);
          if (c != 0) return c;
          c = a.model.compareTo(b.model);
          if (c != 0) return c;
          return a.length.compareTo(b.length);
        default:
          int c = a.model.compareTo(b.model);
          if (c != 0) return c;
          return a.length.compareTo(b.length);
      }
    });

    return Column(
      children: [
        if (_searchQuery.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '絞り込み中: ${items.length}件',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('ソート: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _stapleSortOrder,
                items: const [
                  DropdownMenuItem(value: 'model', child: Text('モデル順')),
                  DropdownMenuItem(value: 'length', child: Text('長さ順')),
                  DropdownMenuItem(value: 'status', child: Text('使用状況順 (未使用優先)')),
                  DropdownMenuItem(value: 'mark', child: Text('マーク順')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _changeSortOrder('stock_sort_staple', val, () => _stapleSortOrder = val);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('表示するチューブ(Hülse)ストックがありません'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
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
                                              text: '${item.model} ${item.length}mm ', 
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
                                        existingModels: _getAllExistingModels(),
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
                ),
        ),
      ],
    );
  }

  Widget _buildTiedStockTab() {
    List<TiedStock> sortedItems = List.from(_tiedStocks);

    // 検索フィルタ（チューブ情報も含む）
    if (_searchQuery.trim().isNotEmpty) {
      final matcher = SearchQueryParser.compile(_searchQuery);
      sortedItems = sortedItems.where((item) {
        final staple = stapleStocks.firstWhere(
          (s) => s.id == item.stapleId,
          orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
        );
        return matcher('${item.searchText} ${staple.searchText}');
      }).toList();
    }

    sortedItems.sort((a, b) {
      switch (_tiedSortOrder) {
        case 'staple_full':
          final aStaple = stapleStocks.firstWhere(
            (s) => s.id == a.stapleId,
            orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
          );
          final bStaple = stapleStocks.firstWhere(
            (s) => s.id == b.stapleId,
            orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
          );
          final aFull = '${aStaple.model} ${aStaple.length} ${aStaple.mark}';
          final bFull = '${bStaple.model} ${bStaple.length} ${bStaple.mark}';
          int c = aFull.compareTo(bFull);
          if (c != 0) return c;
          return b.tiedDate.compareTo(a.tiedDate);

        case 'cane_id':
          int c = a.shapedCode.compareTo(b.shapedCode);
          if (c != 0) return c;
          return b.tiedDate.compareTo(a.tiedDate);

        case 'thread_material':
          int c = (a.threadMaterial ?? '').compareTo(b.threadMaterial ?? '');
          if (c != 0) return c;
          return b.tiedDate.compareTo(a.tiedDate);

        case 'thread_color':
          int c = (a.threadColor ?? '').compareTo(b.threadColor ?? '');
          if (c != 0) return c;
          return b.tiedDate.compareTo(a.tiedDate);

        case 'date_desc':
          int c = b.tiedDate.compareTo(a.tiedDate);
          if (c != 0) return c;
          return b.id.compareTo(a.id);

        case 'date_asc':
          int c = a.tiedDate.compareTo(b.tiedDate);
          if (c != 0) return c;
          return a.id.compareTo(b.id);

        default:
          return 0;
      }
    });

    return Column(
      children: [
        if (_searchQuery.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
            child: Row(
              children: [
                Icon(Icons.filter_list, size: 14, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  '絞り込み中: ${sortedItems.length}件',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade800, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text('ソート: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _tiedSortOrder,
                items: const [
                  DropdownMenuItem(value: 'staple_full', child: Text('チューブ (モデル+長さ+マーク) 順')),
                  DropdownMenuItem(value: 'cane_id', child: Text('ケーンID順')),
                  DropdownMenuItem(value: 'thread_material', child: Text('糸の種類順')),
                  DropdownMenuItem(value: 'thread_color', child: Text('糸の色順')),
                  DropdownMenuItem(value: 'date_desc', child: Text('糸巻き日 (新しい順)')),
                  DropdownMenuItem(value: 'date_asc', child: Text('糸巻き日 (古い順)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _changeSortOrder('stock_sort_tied', val, () => _tiedSortOrder = val);
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: sortedItems.isEmpty 
              ? Center(child: Text(
                  _searchQuery.trim().isNotEmpty ? '「$_searchQuery」に一致するアイテムはありません' : '糸巻き(Tied)されたリードがありません',
                ))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: sortedItems.length,
                  itemBuilder: (context, i) {
                    final item = sortedItems[i];
                    final bool isWorking = _workingReedIds.contains(item.id);
                    final bool isHighlighted = _highlightedId != null && item.id.contains(_highlightedId!);

                    final staple = stapleStocks.firstWhere(
                      (s) => s.id == item.stapleId,
                      orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'チューブ: ${staple.model} ${staple.length}mm (${staple.mark})',
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
                                    IconButton(
                                      icon: const Icon(Icons.copy_outlined, color: Colors.blueGrey),
                                      tooltip: '糸巻きストックを複製',
                                      onPressed: () {
                                        StockDialogs.showEditTiedDialog(
                                          context: context,
                                          tied: item,
                                          allStaples: stapleStocks,
                                          isCopy: true,
                                          onSaved: (copiedTied, selectedStaple, oldStaple) {
                                            setState(() {
                                              _tiedStocks.insert(0, copiedTied);
                                              selectedStaple.status = StapleStatus.tied;
                                            });
                                            _saveData();
                                          },
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                                      tooltip: '糸巻きストックを編集',
                                      onPressed: () {
                                        StockDialogs.showEditTiedDialog(
                                          context: context,
                                          tied: item,
                                          allStaples: stapleStocks,
                                          isCopy: false,
                                          onSaved: (updatedTied, selectedStaple, oldStaple) {
                                            setState(() {
                                              selectedStaple.status = StapleStatus.tied;
                                              if (oldStaple != null && oldStaple.id != selectedStaple.id) {
                                                oldStaple.status = StapleStatus.unused;
                                              }
                                            });
                                            _saveData();
                                          },
                                        );
                                      },
                                    ),
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
                ),
        ),
      ],
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