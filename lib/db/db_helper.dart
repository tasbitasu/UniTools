import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class HistoryEntry {
  final int? id;
  final String type;       // 'basic', 'scientific', 'bmi', 'land'
  final String expression;
  final String result;
  final DateTime timestamp;

  HistoryEntry({
    this.id,
    required this.type,
    required this.expression,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'expression': expression,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory HistoryEntry.fromMap(Map<String, dynamic> m) => HistoryEntry(
    id: m['id'],
    type: m['type'],
    expression: m['expression'],
    result: m['result'],
    timestamp: DateTime.parse(m['timestamp']),
  );
}

class DBHelper {
  static final DBHelper _inst = DBHelper._();
  factory DBHelper() => _inst;
  DBHelper._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final path = join(await getDatabasesPath(), 'calc_history.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, _) => db.execute('''
        CREATE TABLE history (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          expression TEXT NOT NULL,
          result TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      '''),
    );
  }

  Future<void> insert(HistoryEntry e) async {
    final d = await db;
    await d.insert('history', e.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HistoryEntry>> fetchAll({String? type, int limit = 100}) async {
    final d = await db;
    final rows = await d.query(
      'history',
      where: type != null ? 'type = ?' : null,
      whereArgs: type != null ? [type] : null,
      orderBy: 'id DESC',
      limit: limit,
    );
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<void> deleteAll({String? type}) async {
    final d = await db;
    await d.delete('history',
        where: type != null ? 'type = ?' : null,
        whereArgs: type != null ? [type] : null);
  }

  Future<void> deleteById(int id) async {
    final d = await db;
    await d.delete('history', where: 'id = ?', whereArgs: [id]);
  }
}
