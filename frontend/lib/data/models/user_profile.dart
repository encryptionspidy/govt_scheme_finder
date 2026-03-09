class UserProfile {
  const UserProfile({
    required this.name,
    required this.age,
    required this.gender,
    required this.occupation,
    required this.income,
    required this.state,
  });

  final String name;
  final int age;
  final String gender;
  final String occupation;
  final int income;
  final String state;

  Map<String, dynamic> toMap() => {
        'name': name,
        'age': age,
        'gender': gender,
        'occupation': occupation,
        'income': income,
        'state': state,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value, [int fallback = 0]) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? fallback;
    }

    return UserProfile(
      name: map['name']?.toString() ?? '',
      age: parseInt(map['age']),
      gender: map['gender']?.toString() ?? 'any',
      occupation: map['occupation']?.toString() ?? '',
      income: parseInt(map['income']),
      state: map['state']?.toString() ?? '',
    );
  }
}
