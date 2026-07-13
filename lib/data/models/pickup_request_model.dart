import 'package:flutter/material.dart';
import 'collector_summary_model.dart';
import 'household_summary_model.dart';

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

extension PickupMaterialTypeUi on PickupMaterialType {
  String get label {
    switch (this) {
      case PickupMaterialType.plastic:
        return 'Plastic';
      case PickupMaterialType.metal:
        return 'Metal';
      case PickupMaterialType.glass:
        return 'Glass';
      case PickupMaterialType.paper:
        return 'Paper';
      case PickupMaterialType.cardboard:
        return 'Cardboard';
      case PickupMaterialType.electronic:
        return 'Electronic';
    }
  }

  IconData get icon {
    switch (this) {
      case PickupMaterialType.plastic:
        return Icons.local_drink_outlined;
      case PickupMaterialType.metal:
        return Icons.build_outlined;
      case PickupMaterialType.glass:
        return Icons.wine_bar_outlined;
      case PickupMaterialType.paper:
        return Icons.description_outlined;
      case PickupMaterialType.cardboard:
        return Icons.inventory_2_outlined;
      case PickupMaterialType.electronic:
        return Icons.devices_outlined;
    }
  }
}

class PickupRequestModel {
  const PickupRequestModel({
    required this.id,
    required this.citizenId,
    required this.collectorId,
    required this.materialTypes,
    required this.estimatedWeight,
    required this.imageUrl,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.status,
    required this.scheduledTime,
    required this.createdAt,
    required this.updatedAt,
    this.collector,
    this.citizen,
  });

  final String id;
  final String citizenId;
  final String? collectorId;
  final List<PickupMaterialType> materialTypes;
  final double? estimatedWeight;
  final String imageUrl;
  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;
  final PickupStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CollectorSummaryModel? collector;
  final HouseholdSummaryModel? citizen;

  factory PickupRequestModel.fromJson(Map<String, dynamic> json) {
    final collectorJson = json['collector'];
    CollectorSummaryModel? collector;
    if (collectorJson is Map<String, dynamic>) {
      try {
        collector = CollectorSummaryModel.fromJson(collectorJson);
      } catch (_) {
        collector = null;
      }
    } else if (collectorJson is Map) {
      try {
        collector = CollectorSummaryModel.fromJson(
          Map<String, dynamic>.from(collectorJson),
        );
      } catch (_) {
        collector = null;
      }
    } else {
      collector = null;
    }

    final citizenJson = json['citizen'];
    HouseholdSummaryModel? citizen;
    if (citizenJson is Map<String, dynamic>) {
      try {
        citizen = HouseholdSummaryModel.fromJson(citizenJson);
      } catch (_) {
        citizen = null;
      }
    } else if (citizenJson is Map) {
      try {
        citizen = HouseholdSummaryModel.fromJson(
          Map<String, dynamic>.from(citizenJson),
        );
      } catch (_) {
        citizen = null;
      }
    } else {
      citizen = null;
    }
    // Check both materialTypes (new field) and materialType (legacy field for backward compatibility)
    List<PickupMaterialType> materialTypes =
        (json['materialTypes'] as List<dynamic>? ?? [])
            .map((v) => v?.toString())
            .whereType<String>()
            .map((v) {
              try {
                return PickupMaterialTypeJson.fromJson(v);
              } catch (_) {
                return null;
              }
            })
            .whereType<PickupMaterialType>()
            .toList();
    // If no materialTypes, try to parse legacy materialType
    if (materialTypes.isEmpty && json['materialType'] != null) {
      try {
        final legacyType = PickupMaterialTypeJson.fromJson(
          json['materialType'].toString(),
        );
        materialTypes = [legacyType];
      } catch (_) {
        // ignore
      }
    }
    return PickupRequestModel(
      id: json['id']?.toString() ?? '',
      citizenId: json['citizenId']?.toString() ?? '',
      collectorId: json['collectorId']?.toString(),
      materialTypes: materialTypes,
      estimatedWeight: _toNullableDouble(json['estimatedWeight']),
      imageUrl: json['imageUrl']?.toString() ?? '',
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      pickupLat: _toDouble(json['pickupLat']),
      pickupLng: _toDouble(json['pickupLng']),
      status: PickupStatusJson.fromJson(json['status']?.toString() ?? ''),
      scheduledTime: _toNullableDateTime(json['scheduledTime']),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? ''),
      collector: collector,
      citizen: citizen,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'citizenId': citizenId,
      'collectorId': collectorId,
      'materialTypes': materialTypes.map((m) => m.apiValue).toList(),
      'estimatedWeight': estimatedWeight,
      'imageUrl': imageUrl,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'status': status.apiValue,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'citizen': citizen?.toJson(),
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
