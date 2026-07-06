Answer

Writing to student_records.db only changes the bytes stored on disk. It doesn't change anything Flutter is currently drawing on screen. The widget tree is built from the _students field held in _StudentListPageState, and Flutter only rebuilds a widget when it's told that field's value might be stale.

setState() is that notification. Calling it after the await _dbh.allStudents() call marks the widget dirty and schedules a rebuild, so build() runs again and reads the fresh _students list into the ListView. Skipping setState() would leave the correct data sitting in SQLite while the screen keeps showing whatever list was in memory before the insert/update/delete — the classic "list never updates" bug described in the practical's common-errors section.



