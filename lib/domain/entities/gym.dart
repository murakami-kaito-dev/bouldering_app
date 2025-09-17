class Gym {
  final int id;
  final String name;
  final String hpLink;
  final String prefecture;
  final String city;
  final String addressLine;
  final double latitude;
  final double longitude;
  final String telNo;
  final String fee;
  final int minimumFee;
  final String equipmentRentalFee;
  final int ikitaiCount;
  final int boulCount;
  final bool isBoulderingGym;
  final bool isLeadGym;
  final bool isSpeedGym;
  final GymHours hours;
  final List<String> photoUrls;

  const Gym({
    required this.id,
    required this.name,
    required this.hpLink,
    required this.prefecture,
    required this.city,
    required this.addressLine,
    required this.latitude,
    required this.longitude,
    required this.telNo,
    required this.fee,
    required this.minimumFee,
    required this.equipmentRentalFee,
    required this.ikitaiCount,
    required this.boulCount,
    required this.isBoulderingGym,
    required this.isLeadGym,
    required this.isSpeedGym,
    required this.hours,
    this.photoUrls = const [],
  });

  String get fullAddress => '$prefecture$city$addressLine';
  
  List<String> get climbingTypes {
    final types = <String>[];
    if (isBoulderingGym) types.add('ボルダリング');
    if (isLeadGym) types.add('リード');
    if (isSpeedGym) types.add('スピード');
    return types;
  }

  bool get isCurrentlyOpen {
    // 統一された営業時間判定ロジックを使用
    // Domain層からUtils層への依存を避けるため、ここでは直接実装
    final now = DateTime.now();
    final weekday = now.weekday;
    final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    String? openTime;
    String? closeTime;
    
    switch (weekday) {
      case DateTime.sunday:
        openTime = hours.sunOpen;
        closeTime = hours.sunClose;
        break;
      case DateTime.monday:
        openTime = hours.monOpen;
        closeTime = hours.monClose;
        break;
      case DateTime.tuesday:
        openTime = hours.tueOpen;
        closeTime = hours.tueClose;
        break;
      case DateTime.wednesday:
        openTime = hours.wedOpen;
        closeTime = hours.wedClose;
        break;
      case DateTime.thursday:
        openTime = hours.thuOpen;
        closeTime = hours.thuClose;
        break;
      case DateTime.friday:
        openTime = hours.friOpen;
        closeTime = hours.friClose;
        break;
      case DateTime.saturday:
        openTime = hours.satOpen;
        closeTime = hours.satClose;
        break;
    }

    if (openTime == null || closeTime == null || openTime == '-' || closeTime == '-') {
      return false;
    }

    return time.compareTo(openTime) >= 0 && time.compareTo(closeTime) <= 0;
  }

  double get popularityScore {
    // Simple popularity calculation based on ikitai and post counts
    return (ikitaiCount * 0.7) + (boulCount * 0.3);
  }

  Gym copyWith({
    int? id,
    String? name,
    String? hpLink,
    String? prefecture,
    String? city,
    String? addressLine,
    double? latitude,
    double? longitude,
    String? telNo,
    String? fee,
    int? minimumFee,
    String? equipmentRentalFee,
    int? ikitaiCount,
    int? boulCount,
    bool? isBoulderingGym,
    bool? isLeadGym,
    bool? isSpeedGym,
    GymHours? hours,
    List<String>? photoUrls,
  }) {
    return Gym(
      id: id ?? this.id,
      name: name ?? this.name,
      hpLink: hpLink ?? this.hpLink,
      prefecture: prefecture ?? this.prefecture,
      city: city ?? this.city,
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      telNo: telNo ?? this.telNo,
      fee: fee ?? this.fee,
      minimumFee: minimumFee ?? this.minimumFee,
      equipmentRentalFee: equipmentRentalFee ?? this.equipmentRentalFee,
      ikitaiCount: ikitaiCount ?? this.ikitaiCount,
      boulCount: boulCount ?? this.boulCount,
      isBoulderingGym: isBoulderingGym ?? this.isBoulderingGym,
      isLeadGym: isLeadGym ?? this.isLeadGym,
      isSpeedGym: isSpeedGym ?? this.isSpeedGym,
      hours: hours ?? this.hours,
      photoUrls: photoUrls ?? this.photoUrls,
    );
  }

  /// JSONデータからGymエンティティを生成
  factory Gym.fromJson(Map<String, dynamic> json) {
    return Gym(
      id: json['gym_id'] is int 
          ? json['gym_id'] 
          : int.tryParse(json['gym_id'].toString()) ?? 0,
      name: json['gym_name'] ?? '',
      hpLink: json['hp_link'] ?? '',
      prefecture: json['prefecture'] ?? '',
      city: json['city'] ?? '',
      addressLine: json['address_line'] ?? '',
      latitude: json['latitude'] is double
          ? json['latitude']
          : double.tryParse(json['latitude']?.toString() ?? ''),
      longitude: json['longitude'] is double
          ? json['longitude']
          : double.tryParse(json['longitude']?.toString() ?? ''),
      telNo: json['tel_no'] ?? '',
      fee: json['fee'] ?? '',
      minimumFee: json['minimum_fee'] is int
          ? json['minimum_fee']
          : int.tryParse(json['minimum_fee']?.toString() ?? ''),
      equipmentRentalFee: json['equipment_rental_fee'] ?? '',
      ikitaiCount: json['ikitai_count'] is int
          ? json['ikitai_count']
          : int.tryParse(json['ikitai_count']?.toString() ?? '') ?? 0,
      boulCount: json['boul_count'] is int
          ? json['boul_count']
          : int.tryParse(json['boul_count']?.toString() ?? '') ?? 0,
      isBoulderingGym: json['is_bouldering_gym'] == true ||
          json['is_bouldering_gym'].toString().toLowerCase() == 'true',
      isLeadGym: json['is_lead_gym'] == true ||
          json['is_lead_gym'].toString().toLowerCase() == 'true',
      isSpeedGym: json['is_speed_gym'] == true ||
          json['is_speed_gym'].toString().toLowerCase() == 'true',
      hours: GymHours(
        sunOpen: json['sun_open'],
        sunClose: json['sun_close'],
        monOpen: json['mon_open'],
        monClose: json['mon_close'],
        tueOpen: json['tue_open'],
        tueClose: json['tue_close'],
        wedOpen: json['wed_open'],
        wedClose: json['wed_close'],
        thuOpen: json['thu_open'],
        thuClose: json['thu_close'],
        friOpen: json['fri_open'],
        friClose: json['fri_close'],
        satOpen: json['sat_open'],
        satClose: json['sat_close'],
      ),
      photoUrls: json['photo_urls'] != null 
          ? List<String>.from(json['photo_urls']) 
          : [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Gym &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class GymHours {
  final String? sunOpen;
  final String? sunClose;
  final String? monOpen;
  final String? monClose;
  final String? tueOpen;
  final String? tueClose;
  final String? wedOpen;
  final String? wedClose;
  final String? thuOpen;
  final String? thuClose;
  final String? friOpen;
  final String? friClose;
  final String? satOpen;
  final String? satClose;

  const GymHours({
    this.sunOpen,
    this.sunClose,
    this.monOpen,
    this.monClose,
    this.tueOpen,
    this.tueClose,
    this.wedOpen,
    this.wedClose,
    this.thuOpen,
    this.thuClose,
    this.friOpen,
    this.friClose,
    this.satOpen,
    this.satClose,
  });


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GymHours &&
          runtimeType == other.runtimeType &&
          sunOpen == other.sunOpen &&
          sunClose == other.sunClose &&
          monOpen == other.monOpen &&
          monClose == other.monClose &&
          tueOpen == other.tueOpen &&
          tueClose == other.tueClose &&
          wedOpen == other.wedOpen &&
          wedClose == other.wedClose &&
          thuOpen == other.thuOpen &&
          thuClose == other.thuClose &&
          friOpen == other.friOpen &&
          friClose == other.friClose &&
          satOpen == other.satOpen &&
          satClose == other.satClose;

  @override
  int get hashCode => Object.hash(
        sunOpen,
        sunClose,
        monOpen,
        monClose,
        tueOpen,
        tueClose,
        wedOpen,
        wedClose,
        thuOpen,
        thuClose,
        friOpen,
        friClose,
        satOpen,
        satClose,
      );
}