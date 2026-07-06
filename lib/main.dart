import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'student.dart';

void main() => runApp(const RecordsApp());

class RecordsApp extends StatelessWidget {
  const RecordsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3A5FCD), 
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Attendance Records',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
        appBarTheme: AppBarTheme(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.secondary,
          foregroundColor: Colors.white,
          elevation: 3,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        listTileTheme: ListTileThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          tileColor: Colors.white,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: const StudentListPage(),
    );
  }
}

class StudentListPage extends StatefulWidget {
  const StudentListPage({super.key});

  @override
  State<StudentListPage> createState() => _StudentListPageState();
}

class _StudentListPageState extends State<StudentListPage> {
  final _dbh = DatabaseHelper.instance;
  List<Student> _students = [];
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
      final data = await _dbh.allStudents(searchTerm: _searchTerm);
      if (!mounted) return;
      setState(() {
        _students = data;
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

  // Challenge 2: statistics dialog fed by a rawQuery GROUP BY
  Future<void> _showStats() async {
    final stats = await _dbh.levelStats();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Students per level'),
        content: stats.isEmpty
            ? const Text('No records yet.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: stats
                    .map((row) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Level ${row['level']}'),
                              Text('${row['n']} student(s)'),
                            ],
                          ),
                        ))
                    .toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
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
                labelText: 'Search by name',
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
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, size: 40),
                              const SizedBox(height: 8),
                              Text(
                                'Could not open the database:\n$_error\n\n'
                                'If you are running on desktop or web, add '
                                'sqflite_common_ffi (or sqflite_common_ffi_web) '
                                'and initialize databaseFactory before runApp(). '
                                'Otherwise, run on an Android emulator or device.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: _refresh,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _students.isEmpty
                        ? const Center(child: Text('No students yet — tap +'))
                        : ListView.builder(
                            itemCount: _students.length,
                            itemBuilder: (context, i) {
                              final s = _students[i];
                              final scheme = Theme.of(context).colorScheme;
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: scheme.primaryContainer,
                                    foregroundColor: scheme.onPrimaryContainer,
                                    child: Text(
                                      '${s.level ~/ 100}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  title: Text(
                                    s.fullName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text('${s.indexNo} · ${s.programme}'
                                      '${s.email != null && s.email!.isNotEmpty ? " · ${s.email}" : ""}'),
                                  onTap: () => _openForm(existing: s),
                                  onLongPress: () => _confirmDelete(s),
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

  Future<void> _openForm({Student? existing}) async {
    final indexCtrl = TextEditingController(text: existing?.indexNo ?? '');
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final progCtrl = TextEditingController(text: existing?.programme ?? '');
    final levelCtrl =
        TextEditingController(text: existing?.level.toString() ?? '100');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(existing == null ? 'Add Student' : 'Edit Student',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
                controller: indexCtrl,
                decoration: const InputDecoration(labelText: 'Index number')),
            const SizedBox(height: 10),
            TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name')),
            const SizedBox(height: 10),
            TextField(
                controller: progCtrl,
                decoration: const InputDecoration(labelText: 'Programme')),
            const SizedBox(height: 10),
            TextField(
                controller: levelCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Level (100–400)')),
            const SizedBox(height: 10),
            TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration:
                    const InputDecoration(labelText: 'Email (optional)')),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final student = Student(
                    id: existing?.id,
                    indexNo: indexCtrl.text.trim(),
                    fullName: nameCtrl.text.trim(),
                    programme: progCtrl.text.trim(),
                    level: int.tryParse(levelCtrl.text) ?? 100,
                    email: emailCtrl.text.trim().isEmpty
                        ? null
                        : emailCtrl.text.trim(),
                  );
                  if (existing == null) {
                    await _dbh.insertStudent(student);
                  } else {
                    await _dbh.updateStudent(student);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: Text(existing == null ? 'Save' : 'Update'),
              ),
            ),
          ],
        ),
      ),
    );
    _refresh(); 
  }

  Future<void> _confirmDelete(Student s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${s.fullName}?'),
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
      await _dbh.deleteStudent(s.id!);
      _refresh();
    }
  }
}