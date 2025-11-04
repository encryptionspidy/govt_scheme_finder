class Eligibility {
  const Eligibility({
    this.ageRange,
    this.gender,
    this.incomeMax,
    this.occupations = const [],
    this.states = const [],
  });

  final List<int?>? ageRange;
  final String? gender;
  final int? incomeMax;
  final List<String> occupations;
  final List<String> states;

  Map<String, dynamic> toMap() => {
        'ageRange': ageRange,
        'gender': gender,
        'incomeMax': incomeMax,
        'occupations': occupations,
        'states': states,
      };

  factory Eligibility.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      return const Eligibility();
    }

    List<int?>? parseAgeRange(dynamic value) {
      if (value is List) {
        return value.map((dynamic v) {
          if (v == null) return null;
          if (v is num) return v.toInt();
          final int? parsed = int.tryParse(v.toString());
          return parsed;
        }).toList();
      }
      return null;
    }

    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((dynamic v) => v.toString()).toList();
      }
      if (value is String) {
        return value.split(',').map((v) => v.trim()).toList();
      }
      return [];
    }

    int? parseIncome(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return Eligibility(
      ageRange: parseAgeRange(map['ageRange']),
      gender: map['gender']?.toString(),
      incomeMax: parseIncome(map['incomeMax']),
      occupations: parseStringList(map['occupations']),
      states: parseStringList(map['states']),
    );
  }
}
