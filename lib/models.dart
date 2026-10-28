import 'dart:convert';

// 1. 丸材ストックモデル
class TubeStock {
  String id;
  String brand;
  String purchasePeriod;
  String diameter;
  String? vendor;
  int remainingCount;
  String? memo;

  TubeStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    this.vendor,
    required this.remainingCount,
    this.memo,
  });

  String get code => id;
  String get displayTitle => '$brand$purchasePeriod(T)';

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'purchasePeriod': purchasePeriod,
    'diameter': diameter,
    'vendor': vendor,
    'remainingCount': remainingCount,
    'memo': memo,
  };

  factory TubeStock.fromJson(Map<String, dynamic> json) => TubeStock(
    id: json['id'] ?? '',
    brand: json['brand'] ?? '',
    purchasePeriod: json['purchasePeriod'] ?? '',
    diameter: json['diameter'] ?? '',
    vendor: json['vendor'],
    remainingCount: json['remainingCount'] ?? 0,
    memo: json['memo'],
  );
}

// 2. 半カマボコケーンストックモデル
class SplitCaneStock {
  String id;
  String code;
  String brand;
  String purchasePeriod;
  String diameter;
  String sourceInfo;
  int remainingCount;
  String? memo;

  SplitCaneStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    required this.sourceInfo,
    required this.remainingCount,
    this.memo,
  }) : code = id;

  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : 'P';
    return '$brand$purchasePeriod$originTag';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'purchasePeriod': purchasePeriod,
    'diameter': diameter,
    'sourceInfo': sourceInfo,
    'remainingCount': remainingCount,
    'memo': memo,
  };

  factory SplitCaneStock.fromJson(Map<String, dynamic> json) => SplitCaneStock(
    id: json['id'] ?? '',
    brand: json['brand'] ?? '',
    purchasePeriod: json['purchasePeriod'] ?? '',
    diameter: json['diameter'] ?? '',
    sourceInfo: json['sourceInfo'] ?? '',
    remainingCount: json['remainingCount'] ?? 0,
    memo: json['memo'],
  );
}

// 3. カマボコケーンストックモデル
class GougedCaneStock {
  String id;
  String code;
  String brand;
  String purchasePeriod;
  String diameter;
  String machine;
  double? thickness;
  String gougingDate;
  int remainingCount;
  String? memo;
  String sourceTitle;

  GougedCaneStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    required this.machine,
    this.thickness,
    required this.gougingDate,
    required this.remainingCount,
    this.memo,
    this.sourceTitle = '',
  }) : code = id;

  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : (id.contains('-P') ? 'P' : 'G');
    String thickStr = thickness != null ? '-$thickness' : '';
    return '$brand$purchasePeriod$originTag$thickStr';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'purchasePeriod': purchasePeriod,
    'diameter': diameter,
    'machine': machine,
    'thickness': thickness,
    'gougingDate': gougingDate,
    'remainingCount': remainingCount,
    'memo': memo,
    'sourceTitle': sourceTitle,
  };

  factory GougedCaneStock.fromJson(Map<String, dynamic> json) => GougedCaneStock(
    id: json['id'] ?? '',
    brand: json['brand'] ?? '',
    purchasePeriod: json['purchasePeriod'] ?? '',
    diameter: json['diameter'] ?? '',
    machine: json['machine'] ?? '',
    thickness: json['thickness'] != null ? (json['thickness'] as num).toDouble() : null,
    gougingDate: json['gougingDate'] ?? '',
    remainingCount: json['remainingCount'] ?? 0,
    memo: json['memo'],
    sourceTitle: json['sourceTitle'] ?? '',
  );
}

// 4. 舟形ケーンストックモデル
class ShapedCaneStock {
  String id;
  String code;
  String brand;
  String purchasePeriod;
  String diameter;
  String shaper;
  double? thickness;
  String shapingDate;
  int remainingCount;
  String? memo;

  ShapedCaneStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    required this.shaper,
    this.thickness,
    required this.shapingDate,
    required this.remainingCount,
    this.memo,
  }) : code = id;

  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : (id.contains('-P') ? 'P' : (id.contains('-G') ? 'G' : 'S'));
    String thickStr = thickness != null ? '-$thickness' : '';
    String shaperStr = shaper.isNotEmpty ? '-$shaper' : '';
    return '$brand$purchasePeriod$originTag$thickStr$shaperStr';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'purchasePeriod': purchasePeriod,
    'diameter': diameter,
    'shaper': shaper,
    'thickness': thickness,
    'shapingDate': shapingDate,
    'remainingCount': remainingCount,
    'memo': memo,
  };

  factory ShapedCaneStock.fromJson(Map<String, dynamic> json) => ShapedCaneStock(
    id: json['id'] ?? '',
    brand: json['brand'] ?? '',
    purchasePeriod: json['purchasePeriod'] ?? '',
    diameter: json['diameter'] ?? '',
    shaper: json['shaper'] ?? '',
    thickness: json['thickness'] != null ? (json['thickness'] as num).toDouble() : null,
    shapingDate: json['shapingDate'] ?? '',
    remainingCount: json['remainingCount'] ?? 0,
    memo: json['memo'],
  );
}

// 5. チューブ (Staple) モデル
enum StapleStatus { unused, tied, used }
extension StapleStatusExt on StapleStatus {
  String get label {
    switch (this) {
      case StapleStatus.unused: return '未使用';
      case StapleStatus.tied: return '糸巻き済';
      case StapleStatus.used: return '使用済み';
    }
  }
}

class StapleStock {
  String id;
  String brand;
  String model;
  String length;
  String mark;
  String material;
  StapleStatus status;
  String? memo;

  StapleStock({
    required this.id,
    required this.brand,
    required this.model,
    required this.length,
    required this.mark,
    this.material = 'ブラス',
    this.status = StapleStatus.unused,
    this.memo,
  });

  String get displayTitle => '$brand $model $length';

  Map<String, dynamic> toJson() => {
    'id': id,
    'brand': brand,
    'model': model,
    'length': length,
    'mark': mark,
    'material': material,
    'status': status.index,
    'memo': memo,
  };

  factory StapleStock.fromJson(Map<String, dynamic> json) => StapleStock(
    id: json['id'] ?? '',
    brand: json['brand'] ?? '',
    model: json['model'] ?? '',
    length: json['length'] ?? '',
    mark: json['mark'] ?? '',
    material: json['material'] ?? 'ブラス',
    status: StapleStatus.values[json['status'] ?? 0],
    memo: json['memo'],
  );
}

// 6. 糸巻き (Tied) モデル
class TiedStock {
  String id;
  String stapleId;
  String shapedCode;
  String shapedTitle;
  String tiedDate;
  double totalLength;
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
    id: json['id'] ?? '',
    stapleId: json['stapleId'] ?? '',
    shapedCode: json['shapedCode'] ?? '',
    shapedTitle: json['shapedTitle'] ?? json['shapedCode'] ?? '',
    tiedDate: json['tiedDate'] ?? '',
    totalLength: (json['totalLength'] as num?)?.toDouble() ?? 73.0,
    threadColor: json['threadColor'],
    memo: json['memo'],
  );
}

// 7. リード調整作業用モデル (ページ1用)
class WorkReed {
  String id;
  String stapleId;
  String shapedCode;
  String shapedTitle;
  String tiedDate;
  String currentTotalLength; // adjustment_work_page.dart に合わせて String に統一
  int qualityLevel;
  String? threadColor;
  List<String> photosBase64;
  List<WorkLog> logs;

  WorkReed({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required dynamic currentTotalLength, // doubleでもStringでも安全に受け取ってStringにする
    required this.qualityLevel,
    this.threadColor,
    List<String>? photosBase64,
    required this.logs,
  }) : this.currentTotalLength = currentTotalLength.toString(),
       this.photosBase64 = photosBase64 ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'stapleId': stapleId,
    'shapedCode': shapedCode,
    'shapedTitle': shapedTitle,
    'tiedDate': tiedDate,
    'currentTotalLength': currentTotalLength,
    'qualityLevel': qualityLevel,
    'threadColor': threadColor,
    'photosBase64': photosBase64,
    'logs': logs.map((e) => e.toJson()).toList(),
  };

  factory WorkReed.fromJson(Map<String, dynamic> json) => WorkReed(
    id: json['id'] ?? '',
    stapleId: json['stapleId'] ?? '',
    shapedCode: json['shapedCode'] ?? '',
    shapedTitle: json['shapedTitle'] ?? json['shapedCode'] ?? '',
    tiedDate: json['tiedDate'] ?? '',
    currentTotalLength: json['currentTotalLength']?.toString() ?? '71.0',
    qualityLevel: json['qualityLevel'] ?? 1,
    threadColor: json['threadColor'],
    photosBase64: (json['photosBase64'] as List?)?.map((e) => e.toString()).toList() ?? [],
    logs: (json['logs'] as List?)?.map((e) => WorkLog.fromJson(e)).toList() ?? [],
  );
}

// 8. 調整ログモデル (ScrapeLog 兼 WorkLog)
typedef ScrapeLog = WorkLog;

class WorkLog {
  String id;
  String date;
  int level;
  String totalLength; // adjustment_work_page.dart に合わせて String に統一
  String? resistanceRating;
  String? pitchRating;
  String memo;

  WorkLog({
    String? id,
    required this.date,
    required this.level,
    dynamic totalLength,
    dynamic length,
    this.resistanceRating,
    this.pitchRating,
    required this.memo,
  }) : this.id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       this.totalLength = (totalLength ?? length ?? '0.0').toString();

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'level': level,
    'totalLength': totalLength,
    'resistanceRating': resistanceRating,
    'pitchRating': pitchRating,
    'memo': memo,
  };

  factory WorkLog.fromJson(Map<String, dynamic> json) => WorkLog(
    id: json['id'],
    date: json['date'] ?? '',
    level: json['level'] ?? 1,
    totalLength: json['totalLength']?.toString() ?? json['length']?.toString() ?? '0.0',
    resistanceRating: json['resistanceRating'],
    pitchRating: json['pitchRating'],
    memo: json['memo'] ?? '',
  );
}