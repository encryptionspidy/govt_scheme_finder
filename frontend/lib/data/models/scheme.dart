import 'eligibility.dart';

class Scheme {
  Scheme({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.category,
    required this.state,
    required this.eligibility,
    required this.benefits,
    required this.applicationUrl,
    this.lastDate,
    this.imageUrl,
    this.badge,
    this.agency,
    this.highlight,
  });

  final String id;
  final Map<String, dynamic> title;
  final Map<String, dynamic> shortDescription;
  final String category;
  final String state;
  final Eligibility eligibility;
  final Map<String, dynamic> benefits;
  final String? applicationUrl;
  final DateTime? lastDate;
  final String? imageUrl;
  final String? badge;
  final String? agency;
  final String? highlight;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'shortDescription': shortDescription,
        'category': category,
        'state': state,
        'eligibility': eligibility.toMap(),
        'benefits': benefits,
        'applicationUrl': applicationUrl,
        'lastDate': lastDate?.toIso8601String(),
        'imageUrl': imageUrl,
        'badge': badge,
        'agency': agency,
        'highlight': highlight,
      };

  factory Scheme.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse(value.toString());
    }

    return Scheme(
      id: map['id']?.toString() ?? '',
      title: Map<String, dynamic>.from(map['title'] as Map),
      shortDescription: Map<String, dynamic>.from(map['shortDescription'] as Map),
      category: map['category']?.toString() ?? '',
      state: map['state']?.toString() ?? '',
      eligibility: Eligibility.fromMap(map['eligibility'] as Map<String, dynamic>?),
      benefits: Map<String, dynamic>.from(map['benefits'] as Map),
      applicationUrl: map['applicationUrl']?.toString(),
      lastDate: parseDate(map['lastDate']),
      imageUrl: map['imageUrl']?.toString(),
      badge: map['badge']?.toString(),
      agency: map['agency']?.toString(),
      highlight: map['highlight']?.toString(),
    );
  }

  Scheme copyWith({
    Map<String, dynamic>? title,
    Map<String, dynamic>? shortDescription,
    String? category,
    String? state,
    Eligibility? eligibility,
    Map<String, dynamic>? benefits,
    String? applicationUrl,
    DateTime? lastDate,
    String? imageUrl,
    String? badge,
    String? agency,
    String? highlight,
  }) {
    return Scheme(
      id: id,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      category: category ?? this.category,
      state: state ?? this.state,
      eligibility: eligibility ?? this.eligibility,
      benefits: benefits ?? this.benefits,
      applicationUrl: applicationUrl ?? this.applicationUrl,
      lastDate: lastDate ?? this.lastDate,
      imageUrl: imageUrl ?? this.imageUrl,
      badge: badge ?? this.badge,
      agency: agency ?? this.agency,
      highlight: highlight ?? this.highlight,
    );
  }
}
