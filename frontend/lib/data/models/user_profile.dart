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
    return UserProfile(
      name: map['name']?.toString() ?? '',
      age: (map['age'] as num).toInt(),
      gender: map['gender']?.toString() ?? 'any',
      occupation: map['occupation']?.toString() ?? '',
      income: (map['income'] as num?)?.toInt() ?? 0,
      state: map['state']?.toString() ?? '',
    );
  }
}
