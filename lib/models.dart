// ==========================================
// データモデル定義
// ==========================================

class TubeStock {
  final String id;
  String code; // 識別マーク (例: T01-Gon2506)
  String brand;
  String purchasePeriod; // YYYYMM (例: 202506)
  String? vendor;
  String diameter;
  String? memo;
  int remainingCount;

  TubeStock({
    required this.id,
    required this.code,
    required this.brand,
    required this.purchasePeriod,
    this.vendor,
    required this.diameter,
    required this.memo,
    required this.remainingCount,
  });

  String get displayTitle => '[$code] $brand ($purchasePeriod) 丸材';

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'vendor': vendor,
        'diameter': diameter,
        'memo': memo,
        'remainingCount': remainingCount,
      };

  factory TubeStock.fromJson(Map<String, dynamic> json) => TubeStock(
        id: json['id'] ?? DateTime.now().toString(),
        code: json['code'] ?? 'T01-Can2501',
        brand: json['brand'] ?? '',
        purchasePeriod: json['purchasePeriod'] ?? '202506',
        vendor: json['vendor'],
        diameter: json['diameter'] ?? '',
        memo: json['memo'],
        remainingCount: json['remainingCount'] ?? 0,
      );
}

class SplitCaneStock {
  final String id;
  String code; // 識別マーク (例: P01-Gon2506)
  String sourceInfo;
  String brand;
  String purchasePeriod;
  String? vendor;
  String diameter;
  String? memo;
  int remainingCount;

  SplitCaneStock({
    required this.id,
    required this.code,
    required this.sourceInfo,
    required this.brand,
    required this.purchasePeriod,
    this.vendor,
    required this.diameter,
    required this.memo,
    required this.remainingCount,
  });

  String get displayTitle => '[$code] $brand ($purchasePeriod) 半カマボコ';

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'sourceInfo': sourceInfo,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'vendor': vendor,
        'diameter': diameter,
        'memo': memo,
        'remainingCount': remainingCount,
      };

  factory SplitCaneStock.fromJson(Map<String, dynamic> json) => SplitCaneStock(
        id: json['id'] ?? DateTime.now().toString(),
        code: json['code'] ?? 'P01-Can2501',
        sourceInfo: json['sourceInfo'] ?? '手動登録',
        brand: json['brand'] ?? '',
        purchasePeriod: json['purchasePeriod'] ?? '202506',
        vendor: json['vendor'],
        diameter: json['diameter'] ?? '10〜10.5mm',
        memo: json['memo'],
        remainingCount: json['remainingCount'] ?? 0,
      );
}

class GougedCaneStock {
  final String id;
  String code; // 識別マーク (例: G01-Gon2506)
  String sourceTitle;
  String machine;
  String targetThickness;
  String gougingDate;
  String? memo;
  int remainingCount;

  GougedCaneStock({
    required this.id,
    required this.code,
    required this.sourceTitle,
    required this.machine,
    required this.targetThickness,
    required this.gougingDate,
    required this.memo,
    required this.remainingCount,
  });

  String get displayTitle => '[$code] $sourceTitle (G $targetThickness mm)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'sourceTitle': sourceTitle,
        'machine': machine,
        'targetThickness': targetThickness,
        'gougingDate': gougingDate,
        'memo': memo,
        'remainingCount': remainingCount,
      };

  factory GougedCaneStock.fromJson(Map<String, dynamic> json) => GougedCaneStock(
        id: json['id'] ?? DateTime.now().toString(),
        code: json['code'] ?? 'G01-Can2501',
        sourceTitle: json['sourceTitle'] ?? '',
        machine: json['machine'] ?? 'Michel',
        targetThickness: json['targetThickness'] ?? '0.58',
        gougingDate: json['gougingDate'] ?? '',
        memo: json['memo'],
        remainingCount: json['remainingCount'] ?? 0,
      );
}

class ShapedCaneStock {
  final String id;
  String code; // 識別マーク (例: S01-Gon2506)
  String sourceTitle;
  String shaper;
  String shapingDate;
  String? memo;
  int remainingCount;

  ShapedCaneStock({
    required this.id,
    required this.code,
    required this.sourceTitle,
    required this.shaper,
    required this.shapingDate,
    required this.memo,
    required this.remainingCount,
  });

  String get displayTitle => '[$code] $shaper - $sourceTitle (舟形)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'sourceTitle': sourceTitle,
        'shaper': shaper,
        'shapingDate': shapingDate,
        'memo': memo,
        'remainingCount': remainingCount,
      };

  factory ShapedCaneStock.fromJson(Map<String, dynamic> json) => ShapedCaneStock(
        id: json['id'] ?? DateTime.now().toString(),
        code: json['code'] ?? 'S01-Can2501',
        sourceTitle: json['sourceTitle'] ?? '',
        shaper: json['shaper'] ?? 'H39',
        shapingDate: json['shapingDate'] ?? '',
        memo: json['memo'],
        remainingCount: json['remainingCount'] ?? 0,
      );
}

// ==========================================
// チューブ (Staple) 個体管理モデル
// ==========================================

enum StapleStatus {
  unused,    // 未使用
  tied,      // 糸巻き済み
  discarded, // 廃棄・破損
}

extension StapleStatusExtension on StapleStatus {
  String get label {
    switch (this) {
      case StapleStatus.unused:
        return '未使用';
      case StapleStatus.tied:
        return '糸巻き済み';
      case StapleStatus.discarded:
        return '廃棄・破損';
    }
  }

  String toCode() => name;

  static StapleStatus fromCode(String code) {
    return StapleStatus.values.firstWhere(
      (e) => e.name == code,
      orElse: () => StapleStatus.unused,
    );
  }
}

class StapleStock {
  final String id;
  String brand;         // メーカー (例: Chiarugi, Rigotti, Loree)
  String model;         // モデル (例: 2, 46, D12)
  String length;        // 全長数値 (例: 46, 47)
  String mark;          // 個体マーク (例: a, b, c ... z, ah)
  String material;      // 材質 (デフォルト: Brass)
  StapleStatus status;  // ステータス (未使用 / 糸巻き済み / 廃棄)
  String? memo;         // 備考・メモ

  StapleStock({
    required this.id,
    required this.brand,
    required this.model,
    required this.length,
    required this.mark,
    this.material = 'Brass',
    this.status = StapleStatus.unused,
    this.memo,
  });

  String get stapleId => '$brand$model$length$mark';

  String get displayTitle => '[$stapleId] $brand $model ($length - $mark)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'length': length,
        'mark': mark,
        'material': material,
        'status': status.toCode(),
        'memo': memo,
      };

  factory StapleStock.fromJson(Map<String, dynamic> json) => StapleStock(
        id: json['id'] ?? DateTime.now().toString(),
        brand: json['brand'] ?? 'Chiarugi',
        model: json['model'] ?? '2',
        length: json['length'] ?? '46',
        mark: json['mark'] ?? 'a',
        material: json['material'] ?? 'Brass',
        status: StapleStatusExtension.fromCode(json['status'] ?? 'unused'),
        memo: json['memo'],
      );
}

// ==========================================
// 糸巻き済み (Tied) モデル
// ==========================================
class TiedStock {
  final String id;
  final String stapleId;
  final String shapedCode;
  final String shapedTitle;
  final String tiedDate;
  String totalLength;
  String? threadColor;
  String? memo;

  TiedStock({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.totalLength,
    this.threadColor,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stapleId': stapleId,
        'shapedCode': shapedCode,
        'shapedTitle': shapedTitle,
        'tiedDate': tiedDate,
        'totalLength': totalLength,
        'threadColor': threadColor,
        'memo': memo,
      };

  factory TiedStock.fromJson(Map<String, dynamic> json) => TiedStock(
        id: json['id'] ?? DateTime.now().toString(),
        stapleId: json['stapleId'] ?? '',
        shapedCode: json['shapedCode'] ?? '',
        shapedTitle: json['shapedTitle'] ?? '',
        tiedDate: json['tiedDate'] ?? DateTime.now().toString().split(' ')[0],
        totalLength: json['totalLength'] ?? '73.0',
        threadColor: json['threadColor'],
        memo: json['memo'],
      );
}

// ==========================================
// 日々の削り・試奏ログモデル (dateを編集可能に修正)
// ==========================================
class ScrapeLog {
  final String id;
  String date;                // 記録日 (YYYY-MM-DD)
  int? level;                 // ★追加: その時点のコンディションレベル (1〜5)
  String? totalLength;        // その時点の全長 (例: 71.5mm)
  String? scrapeLength;       // スクレープ長 (例: 10.5mm)
  String? pitchRating;        // ピッチ/音程評価
  String? resistanceRating;   // 抵抗感
  String? memo;               // メモ

  ScrapeLog({
    required this.id,
    required this.date,
    this.level,
    this.totalLength,
    this.scrapeLength,
    this.pitchRating,
    this.resistanceRating,
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'level': level,
        'totalLength': totalLength,
        'scrapeLength': scrapeLength,
        'pitchRating': pitchRating,
        'resistanceRating': resistanceRating,
        'memo': memo,
      };

  factory ScrapeLog.fromJson(Map<String, dynamic> json) => ScrapeLog(
        id: json['id'] ?? DateTime.now().toString(),
        date: json['date'] ?? DateTime.now().toString().split(' ')[0],
        level: json['level'],
        totalLength: json['totalLength'],
        scrapeLength: json['scrapeLength'],
        pitchRating: json['pitchRating'],
        resistanceRating: json['resistanceRating'],
        memo: json['memo'],
      );
}



// ==========================================
// 調整中・完成リードモデル (stageを廃止し、qualityLevel主導に変更)
// ==========================================
class WorkLead {
  final String id;
  final String stapleId;
  final String shapedCode;
  final String shapedTitle;
  final String tiedDate;
  String currentTotalLength; // 現在の全長
  int qualityLevel;          // コンディションレベル (0〜5)
  String? photoBase64;        // ★追加: リードの写真をBase64形式で保持
  List<ScrapeLog> logs;      // 履歴リスト

  WorkLead({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.currentTotalLength,
    this.qualityLevel = 1, // デフォルトLv.1
    this.photoBase64,
    required this.logs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'stapleId': stapleId,
        'shapedCode': shapedCode,
        'shapedTitle': shapedTitle,
        'tiedDate': tiedDate,
        'currentTotalLength': currentTotalLength,
        'qualityLevel': qualityLevel,
        'photoBase64': photoBase64,
        'logs': logs.map((e) => e.toJson()).toList(),
      };

  factory WorkLead.fromJson(Map<String, dynamic> json) => WorkLead(
        id: json['id'] ?? DateTime.now().toString(),
        stapleId: json['stapleId'] ?? '',
        shapedCode: json['shapedCode'] ?? '',
        shapedTitle: json['shapedTitle'] ?? '',
        tiedDate: json['tiedDate'] ?? '',
        currentTotalLength: json['currentTotalLength'] ?? '71.0',
        qualityLevel: json['qualityLevel'] ?? 1,
        logs: (json['logs'] as List? ?? [])
            .map((e) => ScrapeLog.fromJson(e))
            .toList(),
      );
}