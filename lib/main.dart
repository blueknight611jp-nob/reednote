import 'dart:convert';
import 'dart:html' as html; // Webでのファイル入出力・画像選択用
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'dialogs.dart';

void main() {
  runApp(const ReedNoteApp());
}

// 共通の糸カラー決定ヘルパー
Color getThreadColor(String? threadName) {
  if (threadName == null) return Colors.grey;
  final name = threadName.toLowerCase();
  if (name.contains('赤') || name.contains('桃') || name.contains('red') || name.contains('pink')) {
    return name.contains('桃') ? Colors.pinkAccent : Colors.red;
  }
  if (name.contains('青') || name.contains('blue')) return Colors.blue;
  if (name.contains('黄') || name.contains('yellow')) return Colors.amber;
  if (name.contains('緑') || name.contains('green')) return Colors.green;
  if (name.contains('黒') || name.contains('black')) return Colors.black87;
  if (name.contains('紫') || name.contains('purple')) return Colors.purple;
  if (name.contains('橙') || name.contains('orange')) return Colors.deepOrange;
  if (name.contains('白') || name.contains('white')) return Colors.grey.shade300;
  return Colors.brown;
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
// 2ページ構成を管理するルート画面
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
  List<WorkReed> _workReeds = [];
  late TabController _subTabController;

  final List<int> _levels = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _levels.length, vsync: this);
    _loadWorkReeds();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadWorkReeds();
  }

  Future<void> _loadWorkReeds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      setState(() {
        _workReeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveWorkReeds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(_workReeds.map((e) => e.toJson()).toList());
    await prefs.setString('work_leads_data', jsonString);
  }

  String _generateStapleId(String model, String length, String mark) {
    final cleanModel = model.replaceAll(RegExp(r'\s+'), '');
    final cleanLength = length.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanMark = mark.trim();
    return '$cleanModel$cleanLength$cleanMark';
  }

  void _confirmAndDismantle(WorkReed reed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リードの分解とチューブ回収'),
        content: Text('[チューブ: ${reed.stapleId}] ${reed.shapedTitle}\n\nこのリードを分解しますか？\n※チューブは素材ストックの「未使用」に自動で戻り、このリードは一覧から削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _handleDismantle(reed);
            },
            child: const Text('分解する'),
          ),
        ],
      ),
    );
  }

  void _confirmAndDeleteReed(WorkReed reed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リードの削除'),
        content: Text('[${reed.stapleId}] ${reed.shapedTitle}\n\nこのリードを一覧から完全に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _workReeds.remove(reed);
              });
              _saveWorkReeds();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('リードを削除しました')),
              );
            },
            child: const Text('削除する'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDismantle(WorkReed reed) async {
    setState(() {
      _workReeds.remove(reed);
    });
    await _saveWorkReeds();

    final prefs = await SharedPreferences.getInstance();
    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) {
      final List decoded = jsonDecode(stapleJson);
      List<StapleStock> staples = decoded.map((e) => StapleStock.fromJson(e)).toList();
      
      bool updated = false;
      for (var st in staples) {
        if (st.stapleId == reed.stapleId) {
          st.status = StapleStatus.unused;
          updated = true;
          break;
        }
      }
      if (updated) {
        await prefs.setString('staple_stocks', jsonEncode(staples.map((e) => e.toJson()).toList()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('リードを分解しました。チューブ[${reed.stapleId}]を未使用ストックへ戻しました。')),
          );
        }
      }
    }
  }

  void _pickAndAddPhoto(WorkReed reed) {
    final uploadInput = html.FileUploadInputElement()..accept = 'images/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final base64String = reader.result as String?;
        if (base64String != null) {
          setState(() {
            reed.photosBase64.add(base64String);
          });
          _saveWorkReeds();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('写真を追加しました')),
          );
        }
      });
      reader.readAsDataUrl(files[0]);
    });
  }

  void _showPhotoPreview(String base64Image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.memory(base64Decode(base64Image.split(',').last)),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWorkReedDialog({WorkReed? existingReed}) {
    String selectedModel = existingReed != null 
        ? (existingReed.shapedTitle.contains(' ') ? existingReed.shapedTitle.split(' ').first : 'Chiarugi 2') 
        : 'Chiarugi 2';
    
    int qualityLevel = existingReed?.qualityLevel ?? 1;
    String totalLength = existingReed?.currentTotalLength ?? '71.0';
    List<String> photos = existingReed != null ? List.from(existingReed.photosBase64) : [];

    final lengthController = TextEditingController(text: '46');
    final markController = TextEditingController(text: 'a');
    final totalLengthController = TextEditingController(text: totalLength);
    final memoController = TextEditingController();

    final List<String> threadTypes = ['ナイロン', 'ポリエステル', '絹'];
    final List<String> threadColors = ['黒', '紫', '橙', '赤', '桃', '黄', '緑', '青', '白'];
    String selectedType = 'ナイロン';
    String selectedColor = '赤';

    if (existingReed != null && existingReed.threadColor != null && existingReed.threadColor!.isNotEmpty) {
      final t = existingReed.threadColor!;
      for (var type in threadTypes) {
        if (t.contains(type)) {
          selectedType = type;
          break;
        }
      }
      for (var color in threadColors) {
        if (t.contains(color)) {
          selectedColor = color;
          break;
        }
      }
    }

    if (existingReed != null) {
      if (existingReed.stapleId.contains('46')) {
        lengthController.text = '46';
      } else if (existingReed.stapleId.contains('47')) {
        lengthController.text = '47';
      } else if (existingReed.stapleId.contains('45')) {
        lengthController.text = '45';
      }
      if (existingReed.stapleId.isNotEmpty) {
        markController.text = existingReed.stapleId.substring(existingReed.stapleId.length - 1);
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final previewId = _generateStapleId(selectedModel, lengthController.text, markController.text);

            return AlertDialog(
              title: Text(existingReed == null ? 'リードのダイレクト新規登録' : 'リード情報の編集'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedModel,
                        decoration: const InputDecoration(labelText: 'ステープルモデル'),
                        items: ['Chiarugi 2', 'Chiarugi 2+', 'Rigotti', 'Loree', 'Other']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedModel = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lengthController,
                              decoration: const InputDecoration(labelText: '長さ (mm)'),
                              keyboardType: TextInputType.number,
                              onChanged: (_) => setDialogState(() {}),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('46'),
                            selected: lengthController.text == '46',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => lengthController.text = '46');
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('47'),
                            selected: lengthController.text == '47',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => lengthController.text = '47');
                            },
                          ),
                          const SizedBox(width: 4),
                          ChoiceChip(
                            label: const Text('45'),
                            selected: lengthController.text == '45',
                            onSelected: (selected) {
                              if (selected) setDialogState(() => lengthController.text = '45');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: markController,
                        decoration: const InputDecoration(labelText: '個体マーク (例: a, b)'),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 6),
                      Text('自動IDプレビュー: $previewId', style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: const InputDecoration(labelText: '糸の種類'),
                              items: threadTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                              onChanged: (val) => setDialogState(() => selectedType = val ?? 'ナイロン'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: DropdownButtonFormField<String>(
                              value: selectedColor,
                              decoration: const InputDecoration(labelText: '糸の色'),
                              items: threadColors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                              onChanged: (val) => setDialogState(() => selectedColor = val ?? '赤'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('コンディション: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: qualityLevel,
                            items: [5, 4, 3, 2, 1].map((lvl) {
                              return DropdownMenuItem(
                                value: lvl,
                                child: Text('Lv. $lvl ${"★" * lvl}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => qualityLevel = val);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: totalLengthController,
                        decoration: const InputDecoration(labelText: '現在の全長 (mm)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      const Text('写真管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < photos.length; i++)
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.memory(
                                    base64Decode(photos[i].split(',').last),
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        photos.removeAt(i);
                                      });
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, size: 12, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(50, 50),
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.add_a_photo, size: 16),
                            label: const Text('追加', style: TextStyle(fontSize: 10)),
                            onPressed: () async {
                              final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
                              uploadInput.click();
                              uploadInput.onChange.listen((e) {
                                final files = uploadInput.files;
                                if (files == null || files.isEmpty) return;
                                final reader = html.FileReader();
                                reader.onLoadEnd.listen((e) {
                                  final base64String = reader.result as String?;
                                  if (base64String != null) {
                                    setDialogState(() {
                                      photos.add(base64String);
                                    });
                                  }
                                });
                                reader.readAsDataUrl(files[0]);
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (existingReed == null) ...[
                        TextField(
                          controller: memoController,
                          decoration: const InputDecoration(
                            labelText: '初期メモ・購入理由など',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
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
                    final dateStr = DateTime.now().toString().split(' ')[0];
                    final shapedTitleText = '$selectedModel ${lengthController.text}mm';
                    final combinedThreadColor = '$selectedType$selectedColor';

                    setState(() {
                      if (existingReed == null) {
                        final newReed = WorkReed(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          stapleId: previewId,
                          shapedCode: 'ダイレクト登録',
                          shapedTitle: shapedTitleText,
                          tiedDate: dateStr,
                          currentTotalLength: totalLengthController.text,
                          qualityLevel: qualityLevel,
                          threadColor: combinedThreadColor,
                          photosBase64: photos,
                          logs: [
                            if (memoController.text.isNotEmpty)
                              ScrapeLog(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                date: dateStr,
                                level: qualityLevel,
                                totalLength: totalLengthController.text,
                                memo: '【初期登録】 ${memoController.text}',
                              ),
                          ],
                        );
                        _workReeds.insert(0, newReed);
                      } else {
                        existingReed.stapleId = previewId;
                        existingReed.shapedTitle = shapedTitleText;
                        existingReed.qualityLevel = qualityLevel;
                        existingReed.currentTotalLength = totalLengthController.text;
                        existingReed.threadColor = combinedThreadColor;
                        existingReed.photosBase64 = photos;
                      }
                    });
                    _saveWorkReeds();
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(existingReed == null ? '[$previewId] を登録しました' : 'リード情報を更新しました')),
                    );
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

  void _showAddLogDialog(WorkReed reed) {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final lengthController = TextEditingController(text: reed.currentTotalLength);
    final resistanceController = TextEditingController();
    final pitchController = TextEditingController();
    final memoController = TextEditingController();
    int currentLevel = reed.qualityLevel;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('[${reed.stapleId}] 削り・試奏ログを追加'),
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
                          const Text('この時のレベル: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: currentLevel,
                            items: List.generate(6, (i) => i).reversed.map((lvl) {
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
                      level: currentLevel,
                      totalLength: lengthController.text,
                      resistanceRating: resistanceController.text,
                      pitchRating: pitchController.text,
                      memo: memoController.text,
                    );

                    setState(() {
                      reed.logs.insert(0, newLog);
                      reed.qualityLevel = currentLevel;
                      if (lengthController.text.isNotEmpty) {
                        reed.currentTotalLength = lengthController.text;
                      }
                    });
                    _saveWorkReeds();
                    Navigator.pop(context);

                    if (currentLevel == 0) {
                      _confirmAndDismantle(reed);
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

  void _showEditLogDialog(WorkReed reed, ScrapeLog log) {
    final dateController = TextEditingController(text: log.date);
    final lengthController = TextEditingController(text: log.totalLength ?? '');
    final resistanceController = TextEditingController(text: log.resistanceRating ?? '');
    final pitchController = TextEditingController(text: log.pitchRating ?? '');
    final memoController = TextEditingController(text: log.memo ?? '');
    int editLevel = log.level ?? reed.qualityLevel;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setEditState) {
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('レベル: '),
                          const SizedBox(width: 8),
                          DropdownButton<int>(
                            value: editLevel,
                            items: List.generate(6, (i) => i).reversed.map((lvl) {
                              return DropdownMenuItem(
                                value: lvl,
                                child: Text(lvl == 0 ? 'Lv.0 (分解)' : 'Lv.$lvl ${"★" * lvl}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setEditState(() => editLevel = val);
                              }
                            },
                          ),
                        ],
                      ),
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
                      log.level = editLevel;
                      log.totalLength = lengthController.text;
                      log.resistanceRating = resistanceController.text;
                      log.pitchRating = pitchController.text;
                      log.memo = memoController.text;
                    });
                    _saveWorkReeds();
                    Navigator.pop(context);
                    Navigator.pop(context);
                    _showLogHistoryDialog(reed);
                  },
                  child: const Text('更新'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLogHistoryDialog(WorkReed reed) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setHistoryState) {
            return AlertDialog(
              title: Text('[${reed.stapleId}] 調整ログ全履歴 (${reed.logs.length}件)'),
              content: SizedBox(
                width: 500,
                height: 400,
                child: reed.logs.isEmpty
                    ? const Center(child: Text('ログはまだありません'))
                    : ListView.builder(
                        itemCount: reed.logs.length,
                        itemBuilder: (context, index) {
                          final log = reed.logs[index];
                          final int? logLvl = log.level;
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
                                      Row(
                                        children: [
                                          Text('日付: ${log.date}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          if (logLvl != null) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: Colors.amber.shade400),
                                              ),
                                              child: Text(
                                                'Lv.$logLvl ${"★" * logLvl}',
                                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                            onPressed: () => _showEditLogDialog(reed, log),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() { reed.logs.remove(log); });
                                              setHistoryState(() {});
                                              _saveWorkReeds();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (log.resistanceRating != null && log.resistanceRating!.isNotEmpty)
                                    Text('抵抗感: ${log.resistanceRating}'),
                                  if (log.pitchRating != null && log.pitchRating!.isNotEmpty)
                                    Text('ピッチ: ${log.pitchRating}'),
                                  if (log.memo != null && log.memo!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text('メモ: ${log.memo}', style: const TextStyle(color: Colors.black87)),
                                  ],
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
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: const Text('＋ ダイレクト登録'),
            onPressed: () => _showWorkReedDialog(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadWorkReeds,
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
        children: _levels.map((lvl) => _buildReedList(lvl)).toList(),
      ),
    );
  }

  Widget _buildReedList(int level) {
    final reeds = _workReeds.where((l) => l.qualityLevel == level).toList();

    if (reeds.isEmpty) {
      return Center(
        child: Text(
          '「Lv.$level」のリードはありません',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: reeds.length,
      itemBuilder: (context, index) {
        final reed = reeds[index];
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
                        '[${reed.stapleId}] ${reed.shapedTitle}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                      tooltip: 'リード情報を編集',
                      onPressed: () => _showWorkReedDialog(existingReed: reed),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                      tooltip: 'リードを削除',
                      onPressed: () => _confirmAndDeleteReed(reed),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: reed.qualityLevel,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: List.generate(6, (i) => i).reversed.map((lvl) {
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
                              _confirmAndDismantle(reed);
                            } else {
                              setState(() {
                                reed.qualityLevel = newLevel;
                              });
                              _saveWorkReeds();
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('全長: ${reed.currentTotalLength}mm'),
                      backgroundColor: Colors.amber.shade100,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('コード: ${reed.shapedCode}  /  登録日: ${reed.tiedDate}'),
                    if (reed.threadColor != null && reed.threadColor!.isNotEmpty) ...[
                      const Text('  /  糸: '),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: getThreadColor(reed.threadColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('${reed.threadColor}'),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (int i = 0; i < reed.photosBase64.length; i++)
                            Stack(
                              children: [
                                InkWell(
                                  onTap: () => _showPhotoPreview(reed.photosBase64[i]),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.memory(
                                      base64Decode(reed.photosBase64[i].split(',').last),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        reed.photosBase64.removeAt(i);
                                      });
                                      _saveWorkReeds();
                                    },
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: const Icon(Icons.close, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(60, 60),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            icon: const Icon(Icons.add_a_photo, size: 18),
                            label: const Text('写真追加', style: TextStyle(fontSize: 11)),
                            onPressed: () => _pickAndAddPhoto(reed),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reed.logs.isNotEmpty) ...[
                  InkWell(
                    onTap: () => _showLogHistoryDialog(reed),
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
                              Text(
                                '最新ログ (${reed.logs.first.date})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '全 ${reed.logs.length} 件',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Colors.amber.shade900,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.open_in_full, size: 14, color: Colors.amber),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (reed.logs.first.resistanceRating != null && reed.logs.first.resistanceRating!.isNotEmpty)
                            Text(
                              '抵抗感: ${reed.logs.first.resistanceRating}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          if (reed.logs.first.pitchRating != null && reed.logs.first.pitchRating!.isNotEmpty)
                            Text(
                              'ピッチ: ${reed.logs.first.pitchRating}',
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                          if (reed.logs.first.memo != null && reed.logs.first.memo!.isNotEmpty)
                            Text(
                              reed.logs.first.memo!,
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
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
                    onPressed: () => _showAddLogDialog(reed),
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
// 【ページ2】素材ストック管理画面
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
        const SnackBar(content: Text('すべてのデータ（素材・リード・ログ）を完全バックアップしました')),
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

          if (data.containsKey('tubes')) {
            await prefs.setString('tube_stocks', jsonEncode(data['tubes']));
          }
          if (data.containsKey('splits')) {
            await prefs.setString('split_stocks', jsonEncode(data['splits']));
          }
          if (data.containsKey('gouged')) {
            await prefs.setString('gouged_stocks', jsonEncode(data['gouged']));
          }
          if (data.containsKey('shaped')) {
            await prefs.setString('shaped_stocks', jsonEncode(data['shaped']));
          }
          if (data.containsKey('staples')) {
            await prefs.setString('staple_stocks', jsonEncode(data['staples']));
          }
          if (data.containsKey('tied')) {
            await prefs.setString('tied_stocks', jsonEncode(data['tied']));
          }
          if (data.containsKey('work_leads')) {
            await prefs.setString('work_leads_data', jsonEncode(data['work_leads']));
          }

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
                    Text(item.stapleId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
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