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
      home: const MainRootPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// 2ページ構成を管理するルート画面 (外部からタブ切り替え可能)
// ==========================================
class MainRootPage extends StatefulWidget {
  const MainRootPage({super.key});

  static void switchPage(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainRootPageState>();
    state?.setPage(index);
  }

  @override
  State<MainRootPage> createState() => _MainRootPageState();
}

class _MainRootPageState extends State<MainRootPage> {
  int _currentIndex = 0; // 0: 削り・調整 (メイン), 1: 素材ストック管理

  void setPage(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdjustmentWorkPage(),
          MainStockNavigationPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note),
            selectedIcon: Icon(Icons.edit_note, color: Colors.amber),
            label: '1. リード管理・調整',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2, color: Colors.amber),
            label: '2. 素材ストック管理',
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 【ページ1】リード管理・調整 メイン作業画面 (レベル別タブ構成)
// ==========================================
class AdjustmentWorkPage extends StatefulWidget {
  const AdjustmentWorkPage({super.key});

  @override
  State<AdjustmentWorkPage> createState() => _AdjustmentWorkPageState();
}

class _AdjustmentWorkPageState extends State<AdjustmentWorkPage>
    with SingleTickerProviderStateMixin {
  List<WorkLead> _workLeads = [];
  late TabController _subTabController;

  // レベル別タブ定義 (Lv.1〜Lv.5)
  final List<int> _levels = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _levels.length, vsync: this);
    _loadWorkLeads();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorkLeads();
  }

  Future<void> _loadWorkLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        _workLeads = decoded.map((e) => WorkLead.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveWorkLeads() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_workLeads.map((e) => e.toJson()).toList());
    await prefs.setString('work_leads_data', jsonString);
  }

  // レベル0（分解）に変更された場合のチューブ返却処理
  Future<void> _handleDismantle(WorkLead lead) async {
    setState(() {
      _workLeads.remove(lead); // ページ1のリストから除外
    });
    await _saveWorkLeads();

    // 該当するチューブ(Staple)を素材ストック側で未使用(unused)に復元
    final prefs = await SharedPreferences.getInstance();
    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) {
      final List decoded = jsonDecode(stapleJson);
      List<StapleStock> staples = decoded.map((e) => StapleStock.fromJson(e)).toList();
      
      bool updated = false;
      for (var st in staples) {
        if (st.stapleId == lead.stapleId) {
          st.status = StapleStatus.unused;
          updated = true;
          break;
        }
      }
      if (updated) {
        await prefs.setString('staple_stocks', jsonEncode(staples.map((e) => e.toJson()).toList()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('リードを分解しました。チューブ[${lead.stapleId}]を未使用ストックへ戻しました。')),
          );
        }
      }
    }
  }

  // 市販・完成品リードの追加ダイアログ
  void _showAddCommercialLeadDialog() {
    final brandController = TextEditingController();
    final stapleController = TextEditingController();
    final lengthController = TextEditingController(text: '71.0');
    final memoController = TextEditingController();
    int selectedLevel = 4; // 初期Lv.4（2軍〜）など

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('市販・購入リードを登録'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: brandController,
                        decoration: const InputDecoration(labelText: 'ブランド・製作者名 (例: Rigotti完成品)'),
                      ),
                      TextField(
                        controller: stapleController,
                        decoration: const InputDecoration(labelText: 'チューブ型番・識別 (例: Chiarugi 2 46)'),
                      ),
                      TextField(
                        controller: lengthController,
                        decoration: const InputDecoration(labelText: '初期全長 (mm)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('初期レベル: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: selectedLevel,
                            items: [3, 4, 5].map((lvl) {
                              return DropdownMenuItem(
                                value: lvl,
                                child: Text('Lv. $lvl ${"★" * lvl} (${lvl == 5 ? "1軍・本番OK" : lvl == 4 ? "2軍・結構いける" : "3軍・練習用"})'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => selectedLevel = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: memoController,
                        decoration: const InputDecoration(
                          labelText: '購入メモ (例: 〇〇楽器で購入)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
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
                    final brand = brandController.text.trim().isEmpty ? '市販リード' : brandController.text.trim();
                    final staple = stapleController.text.trim().isEmpty ? 'Com-${DateTime.now().millisecondsSinceEpoch % 1000}' : stapleController.text.trim();
                    final dateStr = DateTime.now().toString().split(' ')[0];

                    final newLead = WorkLead(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      stapleId: staple,
                      shapedCode: '市販品',
                      shapedTitle: brand,
                      tiedDate: dateStr,
                      currentTotalLength: lengthController.text,
                      qualityLevel: selectedLevel,
                      logs: [
                        if (memoController.text.isNotEmpty)
                          ScrapeLog(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            date: dateStr,
                            totalLength: lengthController.text,
                            memo: '【購入時】 ${memoController.text}',
                          ),
                      ],
                    );

                    setState(() {
                      _workLeads.insert(0, newLead);
                    });
                    _saveWorkLeads();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('[$brand] をLv.$selectedLevelとして登録しました')),
                    );
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

  // ログ追加ダイアログ
  void _showAddLogDialog(WorkLead lead) {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final lengthController = TextEditingController(text: lead.currentTotalLength);
    final resistanceController = TextEditingController();
    final pitchController = TextEditingController();
    final memoController = TextEditingController();
    int currentLevel = lead.qualityLevel;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('[${lead.stapleId}] 削り・試奏ログを追加'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: dateController, decoration: const InputDecoration(labelText: '日付 (YYYY-MM-DD)')),
                      TextField(controller: lengthController, decoration: const InputDecoration(labelText: '現在の全長 (mm)'), keyboardType: TextInputType.number),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('コンディション: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: currentLevel,
                            items: List.generate(6, (i) => i).map((lvl) {
                              String label = '';
                              if (lvl == 0) label = 'Lv.0 (分解・チューブ回収)';
                              if (lvl == 1) label = 'Lv.1 (荒削り)';
                              if (lvl == 2) label = 'Lv.2 (調整中)';
                              if (lvl == 3) label = 'Lv.3 (3軍・練習)';
                              if (lvl == 4) label = 'Lv.4 (2軍)';
                              if (lvl == 5) label = 'Lv.5 (1軍・本番)';
                              return DropdownMenuItem(value: lvl, child: Text(label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => currentLevel = val);
                              }
                            },
                          ),
                        ],
                      ),
                      TextField(controller: resistanceController, decoration: const InputDecoration(labelText: '抵抗感 (例: ちょうど良い)')),
                      TextField(controller: pitchController, decoration: const InputDecoration(labelText: 'ピッチ (例: 442Hz)')),
                      const SizedBox(height: 8),
                      TextField(
                        controller: memoController,
                        decoration: const InputDecoration(labelText: '削り・試奏メモ', border: OutlineInputBorder()),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
                ElevatedButton(
                  onPressed: () {
                    final newLog = ScrapeLog(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: dateController.text,
                      totalLength: lengthController.text,
                      resistanceRating: resistanceController.text,
                      pitchRating: pitchController.text,
                      memo: memoController.text,
                    );

                    setState(() {
                      lead.logs.insert(0, newLog);
                      lead.qualityLevel = currentLevel;
                      if (lengthController.text.isNotEmpty) {
                        lead.currentTotalLength = lengthController.text;
                      }
                    });
                    _saveWorkLeads();
                    Navigator.pop(context);

                    // もしレベル0に設定された場合は即座に分解処理へ
                    if (currentLevel == 0) {
                      _handleDismantle(lead);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ログを追加しました')),
                      );
                    }
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ログ編集ダイアログ
  void _showEditLogDialog(WorkLead lead, ScrapeLog log) {
    final dateController = TextEditingController(text: log.date);
    final lengthController = TextEditingController(text: log.totalLength ?? '');
    final resistanceController = TextEditingController(text: log.resistanceRating ?? '');
    final pitchController = TextEditingController(text: log.pitchRating ?? '');
    final memoController = TextEditingController(text: log.memo ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ログを編集'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: dateController, decoration: const InputDecoration(labelText: '日付')),
                  TextField(controller: lengthController, decoration: const InputDecoration(labelText: '全長 (mm)')),
                  TextField(controller: resistanceController, decoration: const InputDecoration(labelText: '抵抗感')),
                  TextField(controller: pitchController, decoration: const InputDecoration(labelText: 'ピッチ')),
                  const SizedBox(height: 8),
                  TextField(controller: memoController, decoration: const InputDecoration(labelText: 'メモ', border: OutlineInputBorder()), maxLines: 3),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  log.date = dateController.text;
                  log.totalLength = lengthController.text;
                  log.resistanceRating = resistanceController.text;
                  log.pitchRating = pitchController.text;
                  log.memo = memoController.text;
                });
                _saveWorkLeads();
                Navigator.pop(context);
                Navigator.pop(context);
                _showLogHistoryDialog(lead);
              },
              child: const Text('更新'),
            ),
          ],
        );
      },
    );
  }

  // ログ全履歴ポップアップ
  void _showLogHistoryDialog(WorkLead lead) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setHistoryState) {
            return AlertDialog(
              title: Text('[${lead.stapleId}] 調整ログ全履歴 (${lead.logs.length}件)'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: lead.logs.isEmpty
                    ? const Center(child: Text('ログはまだありません'))
                    : ListView.builder(
                        itemCount: lead.logs.length,
                        itemBuilder: (context, index) {
                          final log = lead.logs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('日付: ${log.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Row(
                                        children: [
                                          if (log.totalLength != null && log.totalLength!.isNotEmpty)
                                            Text('全長: ${log.totalLength}mm  ', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                            onPressed: () => _showEditLogDialog(lead, log),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() { lead.logs.remove(log); });
                                              setHistoryState(() {});
                                              _saveWorkLeads();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (log.memo != null && log.memo!.isNotEmpty)
                                    Text('メモ: ${log.memo}', style: const TextStyle(color: Colors.black87)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('閉じる')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リード管理・調整 (レベル別)'),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade100,
              foregroundColor: Colors.amber.shade900,
              elevation: 0,
            ),
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('＋ 市販リードを追加'),
            onPressed: _showAddCommercialLeadDialog,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadWorkLeads,
          ),
        ],
        bottom: TabBar(
          controller: _subTabController,
          isScrollable: true,
          tabs: _levels.map((lvl) {
            String label = '';
            if (lvl == 1) label = 'Lv.1 (荒削り)';
            if (lvl == 2) label = 'Lv.2 (調整中)';
            if (lvl == 3) label = 'Lv.3 (練習用)';
            if (lvl == 4) label = 'Lv.4 (2軍)';
            if (lvl == 5) label = 'Lv.5 (1軍本番)';
            return Tab(text: label);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: _levels.map((lvl) => _buildLeadList(lvl)).toList(),
      ),
    );
  }

  Widget _buildLeadList(int level) {
    // レベルが一致するリードのみ抽出 (Lv.0の分解済は除外される)
    final leads = _workLeads.where((l) => l.qualityLevel == level).toList();

    if (leads.isEmpty) {
      return Center(
        child: Text(
          '「Lv.$level」のリードはありません',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: leads.length,
      itemBuilder: (context, index) {
        final lead = leads[index];
        return Card(
          elevation: 2,
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
                      child: Text(
                        '[${lead.stapleId}] ${lead.shapedTitle}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    // レベル変更用ドロップダウン (カード上でも即座に変更可能)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: lead.qualityLevel,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: List.generate(6, (i) => i).map((lvl) {
                          return DropdownMenuItem(
                            value: lvl,
                            child: Text(
                              lvl == 0 ? 'Lv.0 (分解)' : 'Lv.$lvl ${"★" * lvl}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: lvl == 0 ? Colors.red : Colors.amber.shade900),
                            ),
                          );
                        }).toList(),
                        onChanged: (newLevel) {
                          if (newLevel != null) {
                            if (newLevel == 0) {
                              _handleDismantle(lead);
                            } else {
                              setState(() {
                                lead.qualityLevel = newLevel;
                              });
                              _saveWorkLeads();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('全長: ${lead.currentTotalLength}mm'),
                      backgroundColor: Colors.amber.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('コード: ${lead.shapedCode}  /  登録日: ${lead.tiedDate}'),
                
                const SizedBox(height: 8),

                // 最新ログ表示 ＆ クリックで全履歴ポップアップ
                if (lead.logs.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _showLogHistoryDialog(lead),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        border: Border.all(color: Colors.amber.shade300),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('最新ログ (${lead.logs.first.date})', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900)),
                              Text('全 ${lead.logs.length} 件 ↗', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber.shade900)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (lead.logs.first.memo != null && lead.logs.first.memo!.isNotEmpty)
                            Text(lead.logs.first.memo!, style: const TextStyle(fontSize: 13, color: Colors.black87), maxLines: 2, overflow: TextOverflow.ellipsis)
                          else
                            const Text('メモなし', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                    child: Text('調整ログはまだありません', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  ),
                ],

                const Divider(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddLogDialog(lead),
                    icon: const Icon(Icons.note_add, size: 18),
                    label: const Text('ログ追加'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ==========================================
// 【ページ2】素材ストック管理画面 (従来機能を完全維持)
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
  List<TiedStock> _tiedStocks = [];
  Set<String> _workingLeadIds = {};

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
    _loadWorkingLeadIds();
  }

  Future<void> _loadWorkingLeadIds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        _workingLeadIds = decoded.map((e) => e['id'].toString()).toSet();
      });
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _loadWorkingLeadIds();

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
        return AlertDialog(
          title: const Text('管理・調整部屋へ登録'),
          content: Text('[チューブ: ${tied.stapleId}]\nこのリードを「Lv.1（荒削り）」として登録し、ページ1へ移動しますか？'),
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
    List<WorkLead> currentWorkLeads = [];
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      currentWorkLeads = decoded.map((e) => WorkLead.fromJson(e)).toList();
    }

    final exists = currentWorkLeads.any((w) => w.id == tied.id);
    if (!exists) {
      final newWorkLead = WorkLead(
        id: tied.id,
        stapleId: tied.stapleId,
        shapedCode: tied.shapedCode,
        shapedTitle: tied.shapedTitle,
        tiedDate: tied.tiedDate,
        currentTotalLength: tied.totalLength,
        qualityLevel: 1, // 新規作成時はLv.1（荒削り）スタート
        logs: [],
      );
      currentWorkLeads.add(newWorkLead);
      await prefs.setString('work_leads_data', jsonEncode(currentWorkLeads.map((e) => e.toJson()).toList()));
    }

    await _loadWorkingLeadIds();

    if (mounted) {
      MainRootPage.switchPage(context, 0);
    }
  }

  List<String> _getAllExistingBrands() {
    Set<String> brands = {};
    for (var t in _tubeStocks) { if (t.brand.isNotEmpty) brands.add(t.brand); }
    for (var s in _splitStocks) { if (s.brand.isNotEmpty) brands.add(s.brand); }
    for (var g in _gougedStocks) { brands.add(g.sourceTitle.split(' ')[0]); }
    for (var st in stapleStocks) { if (st.brand.isNotEmpty) brands.add(st.brand); }
    return brands.toList();
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
    RegExp reg = RegExp('^' + typeLetter + r'(\d+)' + RegExp.escape(suffix) + r'$');

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
    html.AnchorElement(href: url)..setAttribute("download", "ReedNote_Backup_${DateTime.now().toString().split(' ')[0]}.json")..click();
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('バックアップファイルをダウンロードしました')));
  }

  void _importDataFromFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        try {
          final data = jsonDecode(reader.result as String) as Map<String, dynamic>;
          setState(() {
            if (data.containsKey('tubes')) _tubeStocks = (data['tubes'] as List).map((e) => TubeStock.fromJson(e)).toList();
            if (data.containsKey('splits')) _splitStocks = (data['splits'] as List).map((e) => SplitCaneStock.fromJson(e)).toList();
            if (data.containsKey('gouged')) _gougedStocks = (data['gouged'] as List).map((e) => GougedCaneStock.fromJson(e)).toList();
            if (data.containsKey('shaped')) _shapedStocks = (data['shaped'] as List).map((e) => ShapedCaneStock.fromJson(e)).toList();
            if (data.containsKey('staples')) stapleStocks = (data['staples'] as List).map((e) => StapleStock.fromJson(e)).toList();
            if (data.containsKey('tied')) _tiedStocks = (data['tied'] as List).map((e) => TiedStock.fromJson(e)).toList();
          });
          _saveData();
          _loadWorkingLeadIds();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('データを正常に読み込みました！')));
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('ファイルの読み込みに失敗しました: $err')));
        }
      });
      reader.readAsText(files[0]);
    });
  }

  void _openAddDialogForCurrentTab() {
    final existingBrands = _getAllExistingBrands();
    final existingVendors = _tubeStocks.map((e) => e.vendor ?? '').where((e) => e.isNotEmpty).toSet().toList();

    switch (_tabController.index) {
      case 0:
        StockDialogs.showAddTubeDialog(context: context, existingBrands: existingBrands, existingVendors: existingVendors, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _tubeStocks.add(newStock)); _saveData(); });
        break;
      case 1:
        StockDialogs.showAddSplitDialog(context: context, existingBrands: existingBrands, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _splitStocks.add(newStock)); _saveData(); });
        break;
      case 2:
        StockDialogs.showAddGougedDialog(context: context, existingBrands: existingBrands, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _gougedStocks.add(newStock)); _saveData(); });
        break;
      case 3:
        StockDialogs.showAddShapedDialog(context: context, existingBrands: existingBrands, getNextCode: _getNextCode, onRegistered: (newStock) { setState(() => _shapedStocks.add(newStock)); _saveData(); });
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
                IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: onEdit),
                if (!isInStock) ...[
                  Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(4)), child: const Text('在庫なし', style: TextStyle(fontSize: 12, color: Colors.white))),
                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
                ],
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
      padding: const EdgeInsets.all(16),
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
            onPressed: () => StockDialogs.showProcessTubeToSplitDialog(context: context, tube: item, getNextCode: _getNextCode, onProcessed: (newSplit) { setState(() => _splitStocks.add(newSplit)); _saveData(); }),
          ),
        );
      },
    );
  }

  Widget _buildSplitStockTab() {
    final items = _showOnlyInStock ? _splitStocks.where((e) => e.remainingCount > 0).toList() : _splitStocks;
    if (items.isEmpty) return const Center(child: Text('表示する半カマボコストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
            onPressed: () => StockDialogs.showProcessSplitToGougedDialog(context: context, split: item, getNextCode: _getNextCode, onProcessed: (newGouged) { setState(() => _gougedStocks.add(newGouged)); _saveData(); }),
          ),
        );
      },
    );
  }

  Widget _buildGougedStockTab() {
    final items = _showOnlyInStock ? _gougedStocks.where((e) => e.remainingCount > 0).toList() : _gougedStocks;
    if (items.isEmpty) return const Center(child: Text('表示するカマボコストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: 'マシン: ${item.machine} | 日付: ${item.gougingDate}\nメモ: ${item.memo ?? "-"}',
          count: item.remainingCount,
          onIncrement: () { setState(() => item.remainingCount++); _saveData(); },
          onDecrement: () { setState(() => item.remainingCount--); _saveData(); },
          onEdit: () => StockDialogs.showEditGougedDialog(context: context, gouged: item, onSaved: () { setState(() {}); _saveData(); }),
          onDelete: () => _confirmDelete(() { setState(() => _gougedStocks.remove(item)); _saveData(); }),
          processButton: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade100, foregroundColor: Colors.amber.shade900, elevation: 0),
            icon: const Icon(Icons.content_cut, size: 16),
            label: const Text('舟形(S)へ加工'),
            onPressed: () => StockDialogs.showProcessGougedToShapedDialog(context: context, gouged: item, getNextCode: _getNextCode, onProcessed: (newShaped) { setState(() => _shapedStocks.add(newShaped)); _saveData(); }),
          ),
        );
      },
    );
  }

  Widget _buildShapedStockTab() {
    final items = _showOnlyInStock ? _shapedStocks.where((e) => e.remainingCount > 0).toList() : _shapedStocks;
    if (items.isEmpty) return const Center(child: Text('表示する舟形ストックがありません'));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        return _buildStockCard(
          title: item.displayTitle,
          subtitle: 'シェーパー: ${item.shaper} | 日付: ${item.shapingDate}\nメモ: ${item.memo ?? "-"}',
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
              StockDialogs.showProcessShapedToTiedDialog(context: context, shaped: item, availableStaples: availableStaples, onProcessed: (newTied, selectedStaple) {
                setState(() { _tiedStocks.add(newTied); item.remainingCount--; selectedStaple.status = StapleStatus.tied; });
                _saveData();
              });
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
      padding: const EdgeInsets.all(16),
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
                        IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey), onPressed: () => StockDialogs.showEditStapleDialog(context: context, staple: item, existingBrands: _getAllExistingBrands(), onSaved: () { setState(() {}); _saveData(); })),
                        IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _confirmDelete(() { setState(() => stapleStocks.remove(item)); _saveData(); })),
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
      padding: const EdgeInsets.all(16),
      itemCount: _tiedStocks.length,
      itemBuilder: (context, i) {
        final item = _tiedStocks[i];
        final bool isWorking = _workingLeadIds.contains(item.id);
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
                    Text('チューブ: ${item.stapleId}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                    Text('全長: ${item.totalLength} mm', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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