import 'collector_profile_model.dart';

enum UserRole { citizen, collector, admin, vendor }

extension UserRoleJson on UserRole {
  String get apiValue {
    switch (this) {
      case UserRole.citizen:
        return 'CITIZEN';
      case UserRole.collector:
        return 'COLLECTOR';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.vendor:
        return 'VENDOR';
    }
  }

  static UserRole fromJson(String value) {
    switch (value.trim().toUpperCase()) {
      case 'CITIZEN':
        return UserRole.citizen;
      case 'COLLECTOR':
        return UserRole.collector;
      case 'ADMIN':
        return UserRole.admin;
      case 'VENDOR':
        return UserRole.vendor;
      default:
        throw FormatException('Unsupported user role: $value');
    }
  }
}

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.profileImage,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    required this.collectorProfile,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;
  final String? profileImage;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CollectorProfileModel? collectorProfile;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: UserRoleJson.fromJson(json['role']?.toString() ?? ''),
      profileImage: json['profileImage']?.toString(),
      isVerified: json['isVerified'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.parse(json['updatedAt']?.toString() ?? ''),
      collectorProfile: json['collectorProfile'] is Map<String, dynamic>
          ? CollectorProfileModel.fromJson(json['collectorProfile'] as Map<String, dynamic>)
          : json['collectorProfile'] is Map
              ? CollectorProfileModel.fromJson(
                  (json['collectorProfile'] as Map).map(
                    (key, value) => MapEntry(key.toString(), value),
                  ),
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.apiValue,
      'profileImage': profileImage,
      'isVerified': isVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'collectorProfile': collectorProfile?.toJson(),
    };
  }
}