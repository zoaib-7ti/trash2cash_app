class CollectorSummaryModel {
  const CollectorSummaryModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
    this.vehicleType,
  });

  final String id;
  final String name;
  final String phone;
  final String? profileImage;
  final String? vehicleType;

  factory CollectorSummaryModel.fromJson(Map<String, dynamic> json) {
    return CollectorSummaryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
      vehicleType: json['vehicleType']?.toString(),
    );
  }
}
