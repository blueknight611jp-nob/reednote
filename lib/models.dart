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