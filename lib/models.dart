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

  /// 検索対象テキスト（カード内に表示される全情報）
  String get searchText => [
        id, brand, purchasePeriod, diameter,
        vendor ?? '', memo ?? '', displayTitle,
      ].join(' ');

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

  /// 検索対象テキスト
  String get searchText => [
        id, brand, purchasePeriod, diameter,
        vendor ?? '', memo ?? '', displayTitle,
      ].join(' ');

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

  /// 検索対象テキスト
  String get searchText => [
        id, brand, purchasePeriod, diameter,
        machine, thickness?.toString() ?? '',
        gougingDate, vendor ?? '', memo ?? '', displayTitle,
      ].join(' ');

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

  /// 検索対象テキスト
  String get searchText => [
        id, brand, purchasePeriod, diameter,
        shaper, thickness?.toString() ?? '',
        shapingDate, vendor ?? '', memo ?? '', displayTitle,
      ].join(' ');

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
  String model;
  String length;
  String mark;
  StapleStatus status;
  String material;
  String? memo;

  StapleStock({
    required this.id,
    required this.model,
    required this.length,
    required this.mark,
    this.status = StapleStatus.unused,
    this.material = '洋白',
    this.memo,
  });

  String get displayTitle => '$model ($length)';

  /// 検索対象テキスト
  String get searchText => [
        id, model, length, mark, material,
        status.label, memo ?? '',
      ].join(' ');

  Map<String, dynamic> toJson() => {
        'id': id,
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
  String? threadMaterial;
  String? vendor;
  String? memo;
  String? customTag;

  TiedStock({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.totalLength,
    this.threadColor,
    this.threadMaterial,
    this.vendor,
    this.memo,
    this.customTag,
  });

  /// 検索対象テキスト
  String get searchText => [
        id, stapleId, shapedCode, shapedTitle, tiedDate,
        threadColor ?? '', threadMaterial ?? '',
        vendor ?? '', memo ?? '', customTag ?? '',
        totalLength.toString(),
      ].join(' ');

  Map<String, dynamic> toJson() => {
        'id': id,
        'stapleId': stapleId,
        'shapedCode': shapedCode,
        'shapedTitle': shapedTitle,
        'tiedDate': tiedDate,
        'totalLength': totalLength,
        'threadColor': threadColor,
        'threadMaterial': threadMaterial,
        'vendor': vendor,
        'memo': memo,
        'customTag': customTag,
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
      threadMaterial: json['threadMaterial'],
      vendor: json['vendor'],
      memo: json['memo'],
      customTag: json['customTag'],
    );
  }
}

// ==========================================
// 7. 調整作業用リード (WorkReed & ログ)
// ==========================================
class WorkReedLog {
  String? id;          
  String date;
  int qualityLevel;
  int? level;
  String? cuttingLength; 
  String? resistanceRating;
  String? pitchRating;
  String comment;
  String? memo;

  WorkReedLog({
    this.id,
    required this.date,
    this.qualityLevel = 1,
    this.level,
    this.cuttingLength,
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
        'cuttingLength': cuttingLength,
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
      cuttingLength: json['cuttingLength']?.toString() ?? json['totalLength']?.toString() ?? json['length']?.toString(),
      resistanceRating: json['resistanceRating'],
      pitchRating: json['pitchRating'],
      comment: json['comment'] ?? '',
      memo: json['memo'],
    );
  }
}

typedef ScrapeLog = WorkReedLog;

class WorkReed {
  String id;
  String stapleId;
  String shapedCode;
  String shapedTitle;
  String tiedDate;
  double totalLength;    
  String cuttingLength;  
  int qualityLevel;
  String? threadColor;
  String? threadMaterial;
  String? vendor;
  String? customTag;
  List<String> photosBase64;
  List<WorkReedLog> logs;

  WorkReed({
    required this.id,
    required this.stapleId,
    required this.shapedCode,
    required this.shapedTitle,
    required this.tiedDate,
    required this.totalLength,
    required this.cuttingLength,
    required this.qualityLevel,
    this.threadColor,
    this.threadMaterial,
    this.vendor,
    this.customTag,
    List<String>? photosBase64,
    required this.logs,
  }) : photosBase64 = photosBase64 ?? [];

  /// 検索対象テキスト（ログ内のメモも含む）
  String get searchText {
    final parts = [
      id, stapleId, shapedCode, shapedTitle, tiedDate,
      cuttingLength, totalLength.toString(),
      threadColor ?? '', threadMaterial ?? '',
      vendor ?? '', customTag ?? '',
      'Lv.$qualityLevel',
    ];
    for (final log in logs) {
      parts.addAll([
        log.comment, log.memo ?? '',
        log.resistanceRating ?? '', log.pitchRating ?? '',
      ]);
    }
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'stapleId': stapleId,
        'shapedCode': shapedCode,
        'shapedTitle': shapedTitle,
        'tiedDate': tiedDate,
        'totalLength': totalLength,
        'cuttingLength': cuttingLength,
        'qualityLevel': qualityLevel,
        'threadColor': threadColor,
        'threadMaterial': threadMaterial,
        'vendor': vendor,
        'customTag': customTag,
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
      totalLength: (json['totalLength'] as num?)?.toDouble() ?? 73.0,
      cuttingLength: json['cuttingLength'] ?? json['currentTotalLength'] ?? '71.0',
      qualityLevel: json['qualityLevel'] ?? 1,
      threadColor: json['threadColor'],
      threadMaterial: json['threadMaterial'],
      vendor: json['vendor'],
      customTag: json['customTag'],
      photosBase64: json['photosBase64'] != null ? List<String>.from(json['photosBase64']) : [],
      logs: (json['logs'] as List?)?.map((e) => WorkReedLog.fromJson(e)).toList() ?? [],
    );
  }
}