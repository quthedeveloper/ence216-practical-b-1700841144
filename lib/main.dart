import 'package:flutter/material.dart';
import 'database_helper.dart';
import './student.dart';

void main() => runApp(const LibraryApp());

class LibraryApp extends StatelessWidget {
  const LibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4226), // warm library brown
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My Book Library',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      ),
      home: const BookListPage(),
    );
  }
}

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  State<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  final _dbh = DatabaseHelper.instance;
  List<Book> _books = [];
  bool _loading = true;
  String? _error;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final data = await _dbh.allBooks(searchTerm: _searchTerm);
      if (!mounted) return;
      setState(() {
        _books = data;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _showStats() async {
    final stats = await _dbh.genreStats();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Books per genre'),
        content: stats.isEmpty
            ? const Text('No books yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: stats
                    .map((row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${row['genre']}'),
                              Text('${row['n']} book(s)'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Book Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Stats',
            onPressed: _showStats,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by title or author',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                _searchTerm = value;
                _refresh();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _books.isEmpty
                        ? const Center(child: Text('No books yet — tap +'))
                        : ListView.builder(
                            itemCount: _books.length,
                            itemBuilder: (context, i) {
                              final b = _books[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: b.isRead
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100,
                                    child: Icon(
                                      b.isRead
                                          ? Icons.check
                                          : Icons.menu_book,
                                      color: b.isRead
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  ),
                                  title: Text(b.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle:
                                      Text('${b.author} · ${b.genre} · ${b.year}'),
                                  onTap: () => _openForm(existing: b),
                                  onLongPress: () => _confirmDelete(b),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openForm({Book? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final authorCtrl = TextEditingController(text: existing?.author ?? '');
    final genreCtrl = TextEditingController(text: existing?.genre ?? '');
    final yearCtrl =
        TextEditingController(text: existing?.year.toString() ?? '2024');
    bool isRead = existing?.isRead ?? false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(existing == null ? 'Add Book' : 'Edit Book',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 10),
              TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: 'Author')),
              const SizedBox(height: 10),
              TextField(
                  controller: genreCtrl,
                  decoration: const InputDecoration(labelText: 'Genre')),
              const SizedBox(height: 10),
              TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'Year published')),
              SwitchListTile(
                title: const Text('Already read'),
                value: isRead,
                onChanged: (v) => setModalState(() => isRead = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final book = Book(
                      id: existing?.id,
                      title: titleCtrl.text.trim(),
                      author: authorCtrl.text.trim(),
                      genre: genreCtrl.text.trim(),
                      year: int.tryParse(yearCtrl.text) ?? 2024,
                      isRead: isRead,
                    );
                    if (existing == null) {
                      await _dbh.insertBook(book);
                    } else {
                      await _dbh.updateBook(book);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: Text(existing == null ? 'Save' : 'Update'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _refresh();
  }

  Future<void> _confirmDelete(Book b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${b.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _dbh.deleteBook(b.id!);
      _refresh();
    }
  }
}