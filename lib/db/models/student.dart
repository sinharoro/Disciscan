class Student {
  final String id;
  final String name;
  final String grade;
  final String? section;
  final String createdAt;

  Student({
    required this.id,
    required this.name,
    required this.grade,
    this.section,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'section': section,
      'created_at': createdAt,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as String,
      name: map['name'] as String,
      grade: map['grade'] as String,
      section: map['section'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  String get initials {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Student copyWith({
    String? id,
    String? name,
    String? grade,
    String? section,
    String? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}