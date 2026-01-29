class UserData {
  final String name;
  final String age;
  final String gender;
  final String height; // cm
  final String weight; // kg
  final List<String> healthConcerns;

  UserData({
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.healthConcerns,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'healthConcerns': healthConcerns,
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: (json['name'] ?? '').toString(),
      age: (json['age'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      height: (json['height'] ?? '170').toString(), // 기본값 설정
      weight: (json['weight'] ?? '70').toString(),  // 기본값 설정
      healthConcerns: List<String>.from(json['healthConcerns'] ?? []),
    );
  }
}