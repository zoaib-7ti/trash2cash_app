class HouseholdSummaryModel {
  const HouseholdSummaryModel({
    required this.id,
    required this.name,
    required this.phone,
    this.profileImage,
  });

  final String id;
  final String name;
  final String phone;
  final String? profileImage;

  factory HouseholdSummaryModel.fromJson(Map<String, dynamic> json) {
    return HouseholdSummaryModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profileImage: json['profileImage']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
    };
  }
}
