class PlantModel {
  final String id;          // 文档 id
  final String name;        // 比如 "My Plant"
  final int level;          // 等级
  final int water;          // 当前已浇的次数
  final int waterNeeded;    // 升级需要的次数
  final int hpCost;         // 每次浇水要扣多少 HP

  PlantModel({
    required this.id,
    required this.name,
    this.level = 1,
    this.water = 0,
    this.waterNeeded = 5,
    this.hpCost = 10,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map, String docId) {
    return PlantModel(
      id: docId,
      name: map['name'] ?? 'My Plant',
      level: (map['level'] ?? 1) as int,
      water: (map['water'] ?? 0) as int,
      waterNeeded: (map['waterNeeded'] ?? 5) as int,
      hpCost: (map['hpCost'] ?? 10) as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level,
      'water': water,
      'waterNeeded': waterNeeded,
      'hpCost': hpCost,
    };
  }

  PlantModel copyWith({
    String? id,
    String? name,
    int? level,
    int? water,
    int? waterNeeded,
    int? hpCost,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      water: water ?? this.water,
      waterNeeded: waterNeeded ?? this.waterNeeded,
      hpCost: hpCost ?? this.hpCost,
    );
  }
}
