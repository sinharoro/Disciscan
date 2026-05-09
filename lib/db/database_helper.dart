import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'models/student.dart';
import 'models/scan_log.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('disciscan.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE students (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        grade TEXT NOT NULL,
        section TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE scan_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id TEXT NOT NULL,
        student_name TEXT,
        grade TEXT,
        scan_time TEXT NOT NULL,
        scan_type TEXT NOT NULL,
        uniform_complete INTEGER NOT NULL,
        id_visible INTEGER NOT NULL,
        status TEXT NOT NULL,
        denied_reason TEXT,
        gate TEXT DEFAULT 'Gate A',
        scanned_by TEXT DEFAULT 'Guard'
      )
    ''');

    await _seedStudents(db);
  }

  Future<void> _seedStudents(Database db) async {
    final now = DateTime.now().toIso8601String();
    final sampleStudents = [
      {'id': '2024-00001', 'name': 'Juan dela Cruz', 'grade': 'Grade 11 - Rizal', 'section': 'A', 'created_at': now},
      {'id': '2024-00002', 'name': 'Maria Santos', 'grade': 'Grade 11 - Rizal', 'section': 'A', 'created_at': now},
      {'id': '2024-00003', 'name': 'Pedro Garcia', 'grade': 'Grade 10 - Bonifacio', 'section': 'B', 'created_at': now},
      {'id': '2024-00004', 'name': 'Ana Reyes', 'grade': 'Grade 9 - Mabini', 'section': 'C', 'created_at': now},
      {'id': '2024-00005', 'name': 'Luis Mejia', 'grade': 'Grade 12 - Jacinto', 'section': 'A', 'created_at': now},
    ];

    for (final student in sampleStudents) {
      await db.insert('students', student);
    }
  }

  Future<Student?> getStudent(String id) async {
    final db = await database;
    final maps = await db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id.trim()],
    );

    if (maps.isNotEmpty) {
      return Student.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Student>> getAllStudents() async {
    final db = await database;
    final result = await db.query('students', orderBy: 'name ASC');
    return result.map((map) => Student.fromMap(map)).toList();
  }

  Future<int> insertStudent(Student student) async {
    final db = await database;
    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> upsertStudent(Student student) async {
    final db = await database;
    return await db.insert(
      'students',
      student.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertScanLog(ScanLog log) async {
    final db = await database;
    return await db.insert('scan_logs', log.toMap());
  }

  Future<List<ScanLog>> getTodayLogs() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final result = await db.query(
      'scan_logs',
      where: 'scan_time >= ? AND scan_time <= ?',
      whereArgs: [startOfDay, endOfDay],
      orderBy: 'scan_time DESC',
    );

    return result.map((map) => ScanLog.fromMap(map)).toList();
  }

  Future<List<ScanLog>> getAllLogs() async {
    final db = await database;
    final result = await db.query('scan_logs', orderBy: 'scan_time DESC');
    return result.map((map) => ScanLog.fromMap(map)).toList();
  }

  Future<List<ScanLog>> getFilteredLogs({
    String? status,
    String? scanType,
    String? searchQuery,
  }) async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    String where = 'scan_time >= ? AND scan_time <= ?';
    List<dynamic> whereArgs = [startOfDay, endOfDay];

    if (status != null && status.isNotEmpty) {
      where += ' AND status = ?';
      whereArgs.add(status);
    }

    if (scanType != null && scanType.isNotEmpty) {
      where += ' AND scan_type = ?';
      whereArgs.add(scanType);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      where += ' AND (student_name LIKE ? OR student_id LIKE ?)';
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    final result = await db.query(
      'scan_logs',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'scan_time DESC',
    );

    return result.map((map) => ScanLog.fromMap(map)).toList();
  }

  Future<int> deleteScanLog(int id) async {
    final db = await database;
    return await db.delete(
      'scan_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearTodayLogs() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    return await db.delete(
      'scan_logs',
      where: 'scan_time >= ? AND scan_time <= ?',
      whereArgs: [startOfDay, endOfDay],
    );
  }

  Future<Map<String, int>> getTodayStats() async {
    final logs = await getTodayLogs();
    final total = logs.length;
    final granted = logs.where((l) => l.status == 'granted').length;
    final denied = logs.where((l) => l.status == 'denied').length;
    final exits = logs.where((l) => l.scanType == 'exit').length;

    return {
      'total': total,
      'granted': granted,
      'denied': denied,
      'exits': exits,
    };
  }

  Future<String> getDbPath() async {
    final dbPath = await getDatabasesPath();
    return p.join(dbPath, 'disciscan.db');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}