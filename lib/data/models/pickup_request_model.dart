enum PickupStatus { pending, accepted, inProgress, completed, cancelled }

enum PickupMaterialType { plastic, metal, glass, paper, cardboard, electronic }

extension PickupStatusJson on PickupStatus {
  String get apiValue {
    switch (this) {
      case PickupStatus.pending:
        return 'PENDING';
      case PickupStatus.accepted:
        return 'ACCEPTED';
      case PickupStatus.inProgress:
        return 'IN_PROGRESS';
      case PickupStatus.completed:
        return 'COMPLETED';
      case PickupStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static PickupStatus fromJson(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PENDING':
        return PickupStatus.pending;
      case 'ACCEPTED':
        return PickupStatus.accepted;
      case 'IN_PROGRESS':
        return PickupStatus.inProgress;
      case 'COMPLETED':
        return PickupStatus.completed;
      case 'CANCELLED':
        return PickupStatus.cancelled;
      default:
        throw FormatException('Unsupported pickup status: $value');
    }
  }
}

extension PickupMaterialTypeJson on PickupMaterialType {
  String get apiValue {
    switch (this) {
      case PickupMaterialType.plastic:
        return 'PLASTIC';
      case PickupMaterialType.metal:
        return 'METAL';
      case PickupMaterialType.glass:
        return 'GLASS';
      case PickupMaterialType.paper:
        return 'PAPER';
      case PickupMaterialType.cardboard:
        return 'CARDBOARD';
      case PickupMaterialType.electronic:
        return 'ELECTRONIC';
    }
  }

  static PickupMaterialType fromJson(String value) {
    switch (value.trim().toUpperCase()) {
      case 'PLASTIC':
        return PickupMaterialType.plastic;
      case 'METAL':
        return PickupMaterialType.metal;
      case 'GLASS':
        return PickupMaterialType.glass;
      case 'PAPER':
        return PickupMaterialType.paper;
      case 'CARDBOARD':
        return PickupMaterialType.cardboard;
      case 'ELECTRONIC':
        return PickupMaterialType.electronic;
      default:
        throw FormatException('Unsupported pickup material type: $value');
    }
  }
}

class PickupRequestModel {
  const PickupRequestModel({
    required this.id,
    required this.citizenId,
    required this.collectorId,
    required this.materialType,
    required this.estimatedWeight,
    required this.imageUrl,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.status,
    required this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String citizenId;
  final String? collectorId;
  final PickupMaterialType? materialType;
  final double? estimatedWeight;
  final String imageUrl;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final PickupStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PickupRequestModel.fromJson(Map<String, dynamic> json) {
    return PickupRequestModel(
      id: json['id']?.toString() ?? '',
      citizenId: json['citizenId']?.toString() ?? '',
      collectorId: json['collectorId']?.toString(),
      materialType: json['materialType'] == null
          ? null
          : PickupMaterialTypeJson.fromJson(json['materialType'].toString()),
      estimatedWeight: _toNullableDouble(json['estimatedWeight']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      pickupLat: _toDouble(json['pickupLat']),
      pickupLng: _toDouble(json['pickupLng']),
      status: PickupStatusJson.fromJson(json['status']?.toString() ?? ''),
      scheduledTime: _toNullableDateTime(json['scheduledTime']),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'citizenId': citizenId,
      'collectorId': collectorId,
      'materialType': materialType?.apiValue,
      'estimatedWeight': estimatedWeight,
      'imageUrl': imageUrl,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'status': status.apiValue,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
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

  static DateTime? _toNullableDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value.toString());
  }
}