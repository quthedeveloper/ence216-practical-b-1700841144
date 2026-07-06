import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'student.dart';

class DatabaseHelper {
  DatabaseHelper._(); // private constructor

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init(); // open only once
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();

    return openDatabase(
      join(dbPath, 'student_records.db'),
      version: 2, // bumped for Challenge 3 (migration)
      onCreate: (db, version) async {
        // Fresh installs go straight to the current schema, email included.
        await db.execute('''
          CREATE TABLE students(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            indexNo TEXT NOT NULL UNIQUE,
            fullName TEXT NOT NULL,
            programme TEXT NOT NULL,
            level INTEGER NOT NULL,
            email TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Existing installs on version 1 gain the email column
        // without losing any of their existing records.
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE students ADD COLUMN email TEXT');
        }
      },
    );
  }

  // CREATE
  Future<int> insertStudent(Student s) async {
    final db = await database;
    return db.insert('students', s.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ (Challenge 1: optional search term filters in SQL, not in Dart)
  Future<List<Student>> allStudents({String? searchTerm}) async {
    final db = await database;
    final rows = (searchTerm == null || searchTerm.trim().isEmpty)
        ? await db.query('students', orderBy: 'fullName ASC')
        : await db.query(
            'students',
            where: 'fullName LIKE ?',
            whereArgs: ['%${searchTerm.trim()}%'],
            orderBy: 'fullName ASC',
          );
    return rows.map(Student.fromMap).toList();
  }

  // UPDATE
  Future<int> updateStudent(Student s) async {
    final db = await database;
    return db.update('students', s.toMap(),
        where: 'id = ?', whereArgs: [s.id]);
  }

  // DELETE
  Future<int> deleteStudent(int id) async {
    final db = await database;
    return db.delete('students', where: 'id = ?', whereArgs: [id]);
  }

  // Challenge 2: level statistics via rawQuery
  Future<List<Map<String, dynamic>>> levelStats() async {
    final db = await database;
    return db.rawQuery(
        'SELECT level, COUNT(*) AS n FROM students GROUP BY level ORDER BY level');
  }
}