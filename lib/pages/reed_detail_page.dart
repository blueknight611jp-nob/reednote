import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models.dart';
import '../utils/helpers.dart';
import '../utils/reed_id_utils.dart';
import '../utils/dismantle_helper.dart';

class ReedDetailPage extends StatefulWidget {
  final WorkReed reed;
  final Function(WorkReed) onUpdated;

  const ReedDetailPage({
    super.key,
    required this.reed,
    required this.onUpdated,
  });

  @override
  State<ReedDetailPage> createState() => _ReedDetailPageState();
}

class _ReedDetailPageState extends State<ReedDetailPage> {
  late WorkReed _reed;
  List<StapleStock> _stapleStocks = [];

  @override
  void initState() {
    super.initState();
    _reed = widget.reed;
    _loadStaples();
  }

  Future<void> _loadStaples() async {
    final prefs = await SharedPreferences.getInstance();
    final stapleJson = prefs.getString('staple_stocks');
    if (stapleJson != null) {
      final List decoded = jsonDecode(stapleJson);
      _stapleStocks = decoded.map((e) => StapleStock.fromJson(e)).toList();
      setState(() {});
    }
  }

  Future<void> _saveWorkReeds() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('work_leads_data');
    if (jsonString != null) {
      List decoded = jsonDecode(jsonString);
      List<WorkReed> reeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
      int index = reeds.indexWhere((r) => r.id == _reed.id);
      if (index != -1) {
        reeds[index] = _reed;
        await prefs.setString(
          'work_leads_data',
          jsonEncode(reeds.map((e) => e.toJson()).toList()),
        );
      }
    }
    widget.onUpdated(_reed);
    setState(() {});
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

  void _pickAndAddPhoto() {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((e) {
        final base64String = reader.result as String?;
        if (base64String != null) {
          setState(() {
            _reed.photosBase64.add(base64String);
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

  void _showAddLogDialog() {
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final lengthController = TextEditingController(text: _reed.cuttingLength);
    final resistanceController = TextEditingController();
    final pitchController = TextEditingController();
    final memoController = TextEditingController();
    int currentLevel = _reed.qualityLevel;

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
                      _reed.logs.insert(0, newLog);
                      _reed.qualityLevel = currentLevel;
                      if (lengthController.text.isNotEmpty) {
                        _reed.cuttingLength = lengthController.text;
                      }
                    });
                    _saveWorkReeds();
                    Navigator.pop(context);

                    if (currentLevel == 0) {
                      _confirmAndDismantle();
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

  void _showEditLogDialog(ScrapeLog log) {
    final dateController = TextEditingController(text: log.date);
    final lengthController = TextEditingController(text: log.cuttingLength ?? '');
    final resistanceController = TextEditingController(text: log.resistanceRating ?? '');
    final pitchController = TextEditingController(text: log.pitchRating ?? '');
    final memoController = TextEditingController(text: log.memo ?? '');
    int editLevel = log.level ?? _reed.qualityLevel;

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

  void _confirmAndDismantle() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('リードの分解とチューブ回収'),
        content: const Text('このリードを分解しますか？\n※チューブは素材ストックの「未使用」に自動で戻り、このリードは一覧から削除されます。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              
              final jsonString = prefs.getString('work_leads_data');
              if (jsonString != null) {
                List decoded = jsonDecode(jsonString);
                List<WorkReed> reeds = decoded.map((e) => WorkReed.fromJson(e)).toList();
                reeds.removeWhere((r) => r.id == _reed.id);
                await prefs.setString('work_leads_data', jsonEncode(reeds.map((e) => e.toJson()).toList()));
              }

              await DismantleHelper.dismantleReed(reed: _reed, prefs: prefs);
              if (mounted) {
                Navigator.pop(context); // 詳細画面を閉じる
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('リードを分解し、チューブを回収しました')),
                );
              }
            },
            child: const Text('分解する'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staple = _stapleStocks.firstWhere(
      (s) => s.id == _reed.stapleId,
      orElse: () => StapleStock(id: '', model: '', length: '', mark: ''),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${staple.model} ${staple.length}${staple.mark} - ${_reed.shapedTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            tooltip: 'リードを分解・削除',
            onPressed: _confirmAndDismantle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 基本情報カード ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${staple.model} ${staple.length}${staple.mark}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange),
                        ),
                        if (_reed.customTag != null && _reed.customTag!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'No. ${_reed.customTag}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('ケーンタイトル: ${_reed.shapedTitle}', style: const TextStyle(fontSize: 15)),
                    if (_reed.id.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('リードID: '),
                          ReedIdUtils.buildClickableIdParts(context, _reed.id, null),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('糸: ${_reed.threadMaterial ?? "ナイロン"} / ${_reed.threadColor ?? "-"}'),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('現在のレベル: '),
                            DropdownButton<int>(
                              value: _reed.qualityLevel,
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
                                    _confirmAndDismantle();
                                  } else {
                                    setState(() {
                                      _reed.qualityLevel = newLevel;
                                    });
                                    _saveWorkReeds();
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        Text('現在の長さ: ${_reed.cuttingLength}mm'),
                        Text('登録日: ${_reed.tiedDate}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- 写真セクション ---
            const Text('写真ギャラリー', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < _reed.photosBase64.length; i++)
                  Stack(
                    children: [
                      InkWell(
                        onTap: () => _showPhotoPreview(_reed.photosBase64[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            base64Decode(_reed.photosBase64[i].split(',').last),
                            width: 80,
                            height: 80,
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
                              _reed.photosBase64.removeAt(i);
                            });
                            _saveWorkReeds();
                          },
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(80, 80),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  icon: const Icon(Icons.add_a_photo, size: 20),
                  label: const Text('追加', style: TextStyle(fontSize: 12)),
                  onPressed: _pickAndAddPhoto,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- ログ一覧セクション ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('調整・試奏ログ (${_reed.logs.length}件)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ElevatedButton.icon(
                  onPressed: _showAddLogDialog,
                  icon: const Icon(Icons.note_add, size: 18),
                  label: const Text('ログ追加'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _reed.logs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('ログはまだありません', style: TextStyle(color: Colors.grey))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reed.logs.length,
                    itemBuilder: (context, index) {
                      final log = _reed.logs[index];
                      final int? logLvl = log.level;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
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
                                      if (log.cuttingLength != null && log.cuttingLength!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text('長さ: ${log.cuttingLength}mm', style: const TextStyle(fontSize: 13, color: Colors.black54)),
                                      ],
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.blueGrey),
                                        tooltip: 'ログを編集',
                                        onPressed: () => _showEditLogDialog(log),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                        tooltip: 'ログを削除',
                                        onPressed: () {
                                          setState(() {
                                            _reed.logs.remove(log);
                                          });
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
          ],
        ),
      ),
    );
  }
}