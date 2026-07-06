class Student {
  final int? id; // null until SQLite assigns it
  final String indexNo;
  final String fullName;
  final String programme;
  final int level;
  final String? email; // added in schema version 2 (migration challenge)

  const Student({
    this.id,
    required this.indexNo,
    required this.fullName,
    required this.programme,
    required this.level,
    this.email,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'indexNo': indexNo,
        'fullName': fullName,
        'programme': programme,
        'level': level,
        'email': email,
      };

  factory Student.fromMap(Map<String, dynamic> m) => Student(
        id: m['id'] as int?,
        indexNo: m['indexNo'] as String,
        fullName: m['fullName'] as String,
        programme: m['programme'] as String,
        level: m['level'] as int,
        email: m['email'] as String?,
      );
}