import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/reed_id_utils.dart';
import '../main.dart';

class AdjustmentWorkPage extends StatefulWidget {
  const AdjustmentWorkPage({super.key});

  @override
  State<AdjustmentWorkPage> createState() => _AdjustmentWorkPageState();
}

class _AdjustmentWorkPageState extends State<AdjustmentWorkPage>
    with SingleTickerProviderStateMixin {
  List<WorkReed> _workReeds = [];
  List<StapleStock> _stapleStocks = []; // チューブ情報取得用
  late TabController _subTabController;

  final List<int> _levels = [1, 2, 3, 4, 5];

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: _levels.length, vsync: this);
    
    _subTabController.addListener(() {
      if (!_subTabController.indexIsChanging) {
        _loadWorkReeds();
      }
    });

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
    _loadWorkReeds(); // 画面に戻ってきた際やタブ切り替え時に自動リロード
  }

  Future<void> _loadWorkReeds() async {
    final prefs = await SharedPreferences.getInstance();
    
    // リードデータの読み込み
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      _workReeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
    }

    // チューブデータの読み込み（モデル名などの表示に利用）
    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) {
      final List decoded = jsonDecode(stapleJson);
      _stapleStocks = decoded.map((e) => StapleStock.fromJson(e)).toList();
    }

    setState(() {});
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

  Future<void> _registerAndMoveToWork({
    required String id,
    required String stapleId,
    required String shapedCode,
    required String shapedTitle,
    required String tiedDate,
    required double totalLength,
    required String cuttingLength,
    required int qualityLevel,
    required String? threadColor,
    required String? vendor,
    required List<String> photosBase64,
    required String initialMemo,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    List<WorkReed> currentWorkReeds = [];
    if (jsonString != null) {
      final List decoded = jsonDecode(jsonString);
      currentWorkReeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
    }

    final exists = currentWorkReeds.any((w) => w.id == id);
    if (!exists) {
      final dateStr = DateTime.now().toString().split(' ')[0];
      final newWorkReed = WorkReed(
        id: id,
        stapleId: stapleId,
        shapedCode: shapedCode,
        shapedTitle: shapedTitle,
        tiedDate: tiedDate,
        totalLength: totalLength,
        cuttingLength: cuttingLength,
        qualityLevel: qualityLevel,
        threadColor: threadColor,
        vendor: vendor,
        photosBase64: photosBase64,
        logs: [
          ScrapeLog(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            date: dateStr,
            level: qualityLevel,
            cuttingLength: cuttingLength,
            memo: initialMemo,
          ),
        ],
      );
      currentWorkReeds.insert(0, newWorkReed);
      await prefs.setString(
        'work_leads_data',
        jsonEncode(currentWorkReeds.map((e) => e.toJson()).toList()),
      );
    }

    await _loadWorkReeds();

    if (mounted) {
      MainRootPage.switchPage(context, 0);
    }
  }

  void _confirmAndDismantle(WorkReed reed) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リードの分解とチューブ回収'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('[チューブ: '),
                ReedIdUtils.buildClickableIdParts(context, reed.stapleId, null),
                const Text('] '),
                Text(reed.shapedTitle),
              ],
            ),
            const SizedBox(height: 12),
            const Text('このリードを分解しますか？\n※チューブは素材ストックの「未使用」に自動で戻り、このリードは一覧から削除されます。'),
          ],
        ),
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
        content: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Text('['),
            ReedIdUtils.buildClickableIdParts(context, reed.stapleId, null),
            Text('] ${reed.shapedTitle}\n\nこのリードを一覧から完全に削除しますか？'),
          ],
        ),
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
        if (st.id == reed.stapleId) {
          st.status = StapleStatus.unused;
          updated = true;
          break;
        }
      }

      if (!updated) {
        for (var st in staples) {
          if (st.status == StapleStatus.unused &&
              (reed.shapedTitle.contains(st.model) || reed.stapleId.contains(st.model))) {
            st.status = StapleStatus.unused;
            updated = true;
            break;
          }
        }
      }

      if (updated) {
        await prefs.setString('staple_stocks', jsonEncode(staples.map((e) => e.toJson()).toList()));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リードを分解しました。チューブを未使用ストックへ戻しました。')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('リードを分解しました。（対象チューブID: ${reed.stapleId} が見つかりませんでした）')),
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
    final List<String> availableModels = ['Chiarugi 2', 'Chiarugi 2+', 'Rigotti', 'Loree', 'Other'];
    
    String initialModel = 'Chiarugi 2';
    if (existingReed != null) {
      for (var m in availableModels) {
        if (existingReed.shapedTitle.startsWith(m)) {
          initialModel = m;
          break;
        }
      }
    }
    String selectedModel = initialModel;
    
    int qualityLevel = existingReed?.qualityLevel ?? _levels[_subTabController.index];
    String totalLength = existingReed?.cuttingLength ?? '71.0';
    List<String> photos = existingReed != null ? List.from(existingReed.photosBase64) : [];

    final lengthController = TextEditingController(
      text: existingReed != null && existingReed.shapedTitle.contains('mm') 
          ? RegExp(r'(\d+)mm').firstMatch(existingReed.shapedTitle)?.group(1) ?? '46'
          : '46'
    );
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
                        items: availableModels
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
                      Text('マーク表記: $previewId', style: TextStyle(fontSize: 12, color: Colors.amber.shade900, fontWeight: FontWeight.bold)),
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
                  onPressed: () async {
                    final dateStr = DateTime.now().toString().split(' ')[0];
                    final shapedTitleText = '$selectedModel ${lengthController.text}mm';
                    final combinedThreadColor = '$selectedType$selectedColor';

                    if (existingReed == null) {
                      final uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
                      final prefs = await SharedPreferences.getInstance();
                      final stapleJson = prefs.getString('staple_stocks');
                      List<StapleStock> staples = [];
                      if (stapleJson != null) {
                        final List decoded = jsonDecode(stapleJson);
                        staples = decoded.map((e) => StapleStock.fromJson(e)).toList();
                      }
                      
                      staples.add(StapleStock(
                        id: uniqueId,
                        model: selectedModel,
                        length: lengthController.text,
                        mark: markController.text,
                        status: StapleStatus.tied,
                        memo: 'ダイレクト登録から自動作成',
                      ));
                      await prefs.setString('staple_stocks', jsonEncode(staples.map((e) => e.toJson()).toList()));

                      Navigator.pop(context);
                      await _registerAndMoveToWork(
                        id: uniqueId,
                        stapleId: uniqueId,
                        shapedCode: previewId,
                        shapedTitle: shapedTitleText,
                        tiedDate: dateStr,
                        totalLength: 73.0,
                        cuttingLength: totalLengthController.text,
                        qualityLevel: qualityLevel,
                        threadColor: combinedThreadColor,
                        vendor: null,
                        photosBase64: photos,
                        initialMemo: memoController.text.isNotEmpty 
                            ? '【初期登録】 ${memoController.text}' 
                            : 'ダイレクト新規登録',
                      );
                    } else {
                      setState(() {
                        existingReed.shapedTitle = shapedTitleText;
                        existingReed.qualityLevel = qualityLevel;
                        existingReed.cuttingLength = totalLengthController.text;
                        existingReed.threadColor = combinedThreadColor;
                        existingReed.photosBase64 = photos;
                      });
                      _saveWorkReeds();
                      Navigator.pop(context);
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(existingReed == null ? 'リードを登録しました' : 'リード情報を更新しました')),
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

  void _showAddLogDialog(WorkReed reed) {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final lengthController = TextEditingController(text: reed.cuttingLength);
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
              title: const Text('削り・試奏ログを追加'),
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
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      date: dateController.text,
                      level: currentLevel,
                      cuttingLength: lengthController.text,
                      resistanceRating: resistanceController.text,
                      pitchRating: pitchController.text,
                      memo: memoController.text,
                    );

                    setState(() {
                      reed.logs.insert(0, newLog);
                      reed.qualityLevel = currentLevel;
                      if (lengthController.text.isNotEmpty) {
                        reed.cuttingLength = lengthController.text;
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
    final lengthController = TextEditingController(text: log.cuttingLength ?? '');
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
                      log.cuttingLength = lengthController.text;
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
              title: Text('調整ログ全履歴 (${reed.logs.length}件)'),
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

        // 対応するチューブ情報を取得
        final staple = _stapleStocks.firstWhere(
          (s) => s.id == reed.stapleId,
          orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
        );

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ==========================================
                // 1行目：チューブ情報 + ケーンタイトル + IDリンク
                // ==========================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(
                            '${staple.model} ${staple.length}${staple.mark}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                          ),
                          Text(
                            reed.shapedTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (reed.id.isNotEmpty) ...[
                            const Text('(', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                            ReedIdUtils.buildClickableIdParts(context, reed.id, null),
                            const Text(')', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                          ],
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey),
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
                  ],
                ),
                
                const SizedBox(height: 6),

                // ==========================================
                // 2行目：糸の種類、糸の色、ラベルレベル、今の長さ、登録日
                // ==========================================
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    // 糸の種類
                    Text('種類: ${reed.threadMaterial ?? "ナイロン"}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
                    
                    // 糸の色（色ドット ＋ 色名）
                    if (reed.threadColor != null && reed.threadColor!.isNotEmpty) ...[
                      const Text('| 糸:'),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: getThreadColor(reed.threadColor),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(reed.threadColor!, style: const TextStyle(fontSize: 13)),
                    ],

                    // 品質レベル（ドロップダウンでその場で変更可能）
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lvl == 0 ? Colors.red : Colors.amber.shade900),
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

                    // 今の長さ
                    Text('| 長さ: ${reed.cuttingLength}mm', style: const TextStyle(fontSize: 13)),

                    // 登録日
                    Text('| 登録日: ${reed.tiedDate}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
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