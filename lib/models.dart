import 'package:flutter/material.dart';

// ==========================================
// 1. 丸材ストック (TubeStock)
// ==========================================
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

  String get shortBrand => brand.length > 3 ? brand.substring(0, 3) : brand;
  String get code => id;
  String get displayTitle => '$shortBrand$purchasePeriod(T)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'diameter': diameter,
        'vendor': vendor,
        'remainingCount': remainingCount,
        'memo': memo,
      };

  factory TubeStock.fromJson(Map<String, dynamic> json) {
    return TubeStock(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      purchasePeriod: json['purchasePeriod'] ?? '',
      diameter: json['diameter'] ?? '',
      vendor: json['vendor'],
      remainingCount: json['remainingCount'] ?? 0,
      memo: json['memo'],
    );
  }
}

// ==========================================
// 2. 半カマボコケーンストック (SplitCaneStock)
// ==========================================
class SplitCaneStock {
  String id;
  String brand;
  String purchasePeriod;
  String diameter;
  String? vendor;
  int remainingCount;
  String? memo;

  SplitCaneStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    this.vendor,
    required this.remainingCount,
    this.memo,
  });

  String get shortBrand => brand.length > 3 ? brand.substring(0, 3) : brand;
  String get code => id;
  
  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : 'P';
    return '$shortBrand$purchasePeriod$originTag';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'diameter': diameter,
        'vendor': vendor,
        'remainingCount': remainingCount,
        'memo': memo,
      };

  factory SplitCaneStock.fromJson(Map<String, dynamic> json) {
    return SplitCaneStock(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      purchasePeriod: json['purchasePeriod'] ?? '',
      diameter: json['diameter'] ?? '',
      vendor: json['vendor'],
      remainingCount: json['remainingCount'] ?? 0,
      memo: json['memo'],
    );
  }
}

// ==========================================
// 3. カマボコケーンストック (GougedCaneStock)
// ==========================================
class GougedCaneStock {
  String id;
  String brand;
  String purchasePeriod;
  String diameter;
  String machine;
  double? thickness;
  String gougingDate;
  String? vendor;
  int remainingCount;
  String? memo;

  GougedCaneStock({
    required this.id,
    required this.brand,
    required this.purchasePeriod,
    required this.diameter,
    required this.machine,
    this.thickness,
    required this.gougingDate,
    this.vendor,
    required this.remainingCount,
    this.memo,
  });

  String get shortBrand => brand.length > 3 ? brand.substring(0, 3) : brand;
  String get code => id;

  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : (id.contains('-P') ? 'P' : 'G');
    String thickStr = thickness != null ? '-$thickness' : '';
    return '$shortBrand$purchasePeriod$originTag$thickStr';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'diameter': diameter,
        'machine': machine,
        'thickness': thickness,
        'gougingDate': gougingDate,
        'vendor': vendor,
        'remainingCount': remainingCount,
        'memo': memo,
      };

  factory GougedCaneStock.fromJson(Map<String, dynamic> json) {
    return GougedCaneStock(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      purchasePeriod: json['purchasePeriod'] ?? '',
      diameter: json['diameter'] ?? '-',
      machine: json['machine'] ?? '',
      thickness: json['thickness'] != null ? (json['thickness'] as num).toDouble() : null,
      gougingDate: json['gougingDate'] ?? '',
      vendor: json['vendor'],
      remainingCount: json['remainingCount'] ?? 0,
      memo: json['memo'],
    );
  }
}

// ==========================================
// 4. 舟形ケーンストック (ShapedCaneStock)
// ==========================================
class ShapedCaneStock {
  String id;
  String brand;
  String purchasePeriod;
  String diameter;
  String shaper;
  double? thickness;
  String shapingDate;
  String? vendor;
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
    this.vendor,
    required this.remainingCount,
    this.memo,
  });

  String get shortBrand => brand.length > 3 ? brand.substring(0, 3) : brand;
  String get code => id;

  String get displayTitle {
    String originTag = id.contains('-T') ? 'T' : (id.contains('-P') ? 'P' : (id.contains('-G') ? 'G' : 'S'));
    String thickStr = thickness != null ? '-$thickness' : '';
    String shaperStr = shaper.isNotEmpty ? '-$shaper' : '';
    return '$shortBrand$purchasePeriod$originTag$thickStr$shaperStr';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'purchasePeriod': purchasePeriod,
        'diameter': diameter,
        'shaper': shaper,
        'thickness': thickness,
        'shapingDate': shapingDate,
        'vendor': vendor,
        'remainingCount': remainingCount,
        'memo': memo,
      };

  factory ShapedCaneStock.fromJson(Map<String, dynamic> json) {
    return ShapedCaneStock(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      purchasePeriod: json['purchasePeriod'] ?? '',
      diameter: json['diameter'] ?? '-',
      shaper: json['shaper'] ?? '',
      thickness: json['thickness'] != null ? (json['thickness'] as num).toDouble() : null,
      shapingDate: json['shapingDate'] ?? '',
      vendor: json['vendor'],
      remainingCount: json['remainingCount'] ?? 0,
      memo: json['memo'],
    );
  }
}

// ==========================================
// 5. チューブ (StapleStock)
// ==========================================
enum StapleStatus {
  unused('未使用'),
  tied('糸巻き済み');

  final String label;
  const StapleStatus(this.label);
}

class StapleStock {
  String id;
  String brand;
  String model;
  String length;
  String mark;
  StapleStatus status;
  String material;
  String? memo;

  StapleStock({
    required this.id,
    required this.brand,
    required this.model,
    required this.length,
    required this.mark,
    this.status = StapleStatus.unused,
    this.material = '洋白',
    this.memo,
  });

  String get shortBrand => brand.length > 3 ? brand.substring(0, 3) : brand;
  String get displayTitle => '$brand $model ($length)';

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'length': length,
        'mark': mark,
        'status': status.name,
        'material': material,
        'memo': memo,
      };

  factory StapleStock.fromJson(Map<String, dynamic> json) {
    return StapleStock(
      id: json['id'] ?? '',
      brand: json['brand'] ?? '',
      model: json['model'] ?? '',
      length: json['length'] ?? '',
      mark: json['mark'] ?? '',
      status: StapleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => StapleStatus.unused,
      ),
      material: json['material'] ?? '洋白',
      memo: json['memo'],
    );
  }
}

// ==========================================
// 6. 糸巻き済みストック (TiedStock)
// ==========================================
class TiedStock {
  String id;
  String stapleId;
  String shapedCode;
  String shapedTitle;
  String tiedDate;
  double totalLength;
  String? threadColor;
  String? vendor;
  String? memo;

  TiedStock({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.totalLength,
    this.threadColor,
    this.vendor,
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
        'vendor': vendor,
        'memo': memo,
      };

  factory TiedStock.fromJson(Map<String, dynamic> json) {
    return TiedStock(
      id: json['id'] ?? '',
      stapleId: json['stapleId'] ?? '',
      shapedCode: json['shapedCode'] ?? '',
      shapedTitle: json['shapedTitle'] ?? '',
      tiedDate: json['tiedDate'] ?? '',
      totalLength: (json['totalLength'] as num?)?.toDouble() ?? 73.0,
      threadColor: json['threadColor'],
      vendor: json['vendor'],
      memo: json['memo'],
    );
  }
}

// ==========================================
// 7. 調整作業用リード (WorkReed & ログ)
// ==========================================
class WorkReedLog {
  String? id;          // 追加：ログの個別ID
  String date;
  int qualityLevel;
  int? level;
  double length;
  String? totalLength; // 追加：ログごとの全長（テキスト入力対応用）
  String? resistanceRating;
  String? pitchRating;
  String comment;
  String? memo;

  WorkReedLog({
    this.id,
    required this.date,
    this.qualityLevel = 1,
    this.level,
    this.length = 0.0,
    this.totalLength,
    this.resistanceRating,
    this.pitchRating,
    this.comment = '',
    this.memo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date,
        'qualityLevel': qualityLevel,
        'level': level,
        'length': length,
        'totalLength': totalLength,
        'resistanceRating': resistanceRating,
        'pitchRating': pitchRating,
        'comment': comment,
        'memo': memo,
      };

  factory WorkReedLog.fromJson(Map<String, dynamic> json) {
    return WorkReedLog(
      id: json['id'],
      date: json['date'] ?? '',
      qualityLevel: json['qualityLevel'] ?? 1,
      level: json['level'],
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      totalLength: json['totalLength'] ?? (json['length']?.toString()),
      resistanceRating: json['resistanceRating'],
      pitchRating: json['pitchRating'],
      comment: json['comment'] ?? '',
      memo: json['memo'],
    );
  }
}

// 互換性のためのエイリアス
typedef ScrapeLog = WorkReedLog;

class WorkReed {
  String id;
  String stapleId;
  String shapedCode;
  String shapedTitle;
  String tiedDate;
  String currentTotalLength;
  int qualityLevel;
  String? threadColor;
  String? vendor;
  List<String> photosBase64;
  List<WorkReedLog> logs;

  WorkReed({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.currentTotalLength,
    required this.qualityLevel,
    this.threadColor,
    this.vendor,
    List<String>? photosBase64,
    required this.logs,
  }) : photosBase64 = photosBase64 ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'stapleId': stapleId,
        'shapedCode': shapedCode,
        'shapedTitle': shapedTitle,
        'tiedDate': tiedDate,
        'currentTotalLength': currentTotalLength,
        'qualityLevel': qualityLevel,
        'threadColor': threadColor,
        'vendor': vendor,
        'photosBase64': photosBase64,
        'logs': logs.map((e) => e.toJson()).toList(),
      };

  factory WorkReed.fromJson(Map<String, dynamic> json) {
    return WorkReed(
      id: json['id'] ?? '',
      stapleId: json['stapleId'] ?? '',
      shapedCode: json['shapedCode'] ?? '',
      shapedTitle: json['shapedTitle'] ?? '',
      tiedDate: json['tiedDate'] ?? '',
      currentTotalLength: json['currentTotalLength'] ?? '73.0',
      qualityLevel: json['qualityLevel'] ?? 1,
      threadColor: json['threadColor'],
      vendor: json['vendor'],
      photosBase64: json['photosBase64'] != null ? List<String>.from(json['photosBase64']) : [],
      logs: (json['logs'] as List?)?.map((e) => WorkReedLog.fromJson(e)).toList() ?? [],
    );
  }
}