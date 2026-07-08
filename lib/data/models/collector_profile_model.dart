enum AvailabilityStatus { online, offline, busy }

extension AvailabilityStatusJson on AvailabilityStatus {
  String get apiValue {
    switch (this) {
      case AvailabilityStatus.online:
        return 'ONLINE';
      case AvailabilityStatus.offline:
        return 'OFFLINE';
      case AvailabilityStatus.busy:
        return 'BUSY';
    }
  }

  static AvailabilityStatus fromJson(String value) {
    switch (value.trim().toUpperCase()) {
      case 'ONLINE':
        return AvailabilityStatus.online;
      case 'OFFLINE':
        return AvailabilityStatus.offline;
      case 'BUSY':
        return AvailabilityStatus.busy;
      default:
        throw FormatException('Unsupported availability status: $value');
    }
  }
}

class CollectorProfileModel {
  const CollectorProfileModel({
    required this.id,
    required this.userId,
    required this.cnicNumber,
    required this.vehicleType,
    required this.currentLat,
    required this.currentLng,
    required this.availabilityStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String cnicNumber;
  final String? vehicleType;
  final double? currentLat;
  final double? currentLng;
  final AvailabilityStatus availabilityStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CollectorProfileModel.fromJson(Map<String, dynamic> json) {
    return CollectorProfileModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      cnicNumber: json['cnicNumber']?.toString() ?? '',
      vehicleType: json['vehicleType']?.toString(),
      currentLat: _toNullableDouble(json['currentLat']),
      currentLng: _toNullableDouble(json['currentLng']),
      availabilityStatus:
          AvailabilityStatusJson.fromJson(json['availabilityStatus']?.toString() ?? ''),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'cnicNumber': cnicNumber,
      'vehicleType': vehicleType,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'availabilityStatus': availabilityStatus.apiValue,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }
}