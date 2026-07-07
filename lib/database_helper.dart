import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import './student.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();

    return openDatabase(
      join(dbPath, 'book_library.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE books(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            author TEXT NOT NULL,
            genre TEXT NOT NULL,
            year INTEGER NOT NULL,
            isRead INTEGER NOT NULL DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              'ALTER TABLE books ADD COLUMN isRead INTEGER NOT NULL DEFAULT 0');
        }
      },
    );
  }

  // CREATE
  Future<int> insertBook(Book b) async {
    final db = await database;
    return db.insert('books', b.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ — search by title or author
  Future<List<Book>> allBooks({String? searchTerm}) async {
    final db = await database;
    final rows = (searchTerm == null || searchTerm.trim().isEmpty)
        ? await db.query('books', orderBy: 'title ASC')
        : await db.query(
            'books',
            where: 'title LIKE ? OR author LIKE ?',
            whereArgs: ['%${searchTerm.trim()}%', '%${searchTerm.trim()}%'],
            orderBy: 'title ASC',
          );
    return rows.map(Book.fromMap).toList();
  }

  // UPDATE
  Future<int> updateBook(Book b) async {
    final db = await database;
    return db.update('books', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  // DELETE
  Future<int> deleteBook(int id) async {
    final db = await database;
    return db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  // Stats — books per genre, via rawQuery + GROUP BY
  Future<List<Map<String, dynamic>>> genreStats() async {
    final db = await database;
    return db.rawQuery(
        'SELECT genre, COUNT(*) AS n FROM books GROUP BY genre ORDER BY genre');
  }
}