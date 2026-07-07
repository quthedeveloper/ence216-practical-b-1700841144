class Book {
  final int? id; // null until SQLite assigns it
  final String title;
  final String author;
  final String genre;
  final int year;
  final bool isRead; // added in schema version 2 (migration challenge)

  const Book({
    this.id,
    required this.title,
    required this.author,
    required this.genre,
    required this.year,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'author': author,
        'genre': genre,
        'year': year,
        'isRead': isRead ? 1 : 0, // SQLite has no bool type — stored as 0/1
      };

  factory Book.fromMap(Map<String, dynamic> m) => Book(
        id: m['id'] as int?,
        title: m['title'] as String,
        author: m['author'] as String,
        genre: m['genre'] as String,
        year: m['year'] as int,
        isRead: (m['isRead'] as int) == 1,
      );
}