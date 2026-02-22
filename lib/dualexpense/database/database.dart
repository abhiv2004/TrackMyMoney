import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DualExpenseDB {
  DualExpenseDB._init();
  static final DualExpenseDB instance = DualExpenseDB._init();

  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB("dual_expense.db");
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1, // incremented version for migration
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add mobile column if upgrading from version < 2
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE participants ADD COLUMN mobile TEXT");
      await db.execute("ALTER TABLE transactions ADD COLUMN remarks TEXT DEFAULT ''");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE participants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        mobile TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participantId INTEGER NOT NULL,
        amount REAL NOT NULL,
        type INTEGER NOT NULL, -- 1 = given, -1 = received
        date TEXT NOT NULL, -- ISO8601
        remarks TEXT DEFAULT ''
      )
    ''');
  }

  // ---------------- PARTICIPANTS -----------------

  Future<int> addParticipant(String name, {String? mobile}) async {
    final db = await database;
    return await db.insert("participants", {"name": name, "mobile": mobile});
  }

  Future<List<Map<String, dynamic>>> getParticipants() async {
    final db = await database;
    return await db.query("participants");
  }

  Future<int> updateParticipant(int id, String newName, {String? mobile}) async {
    final db = await database;
    return await db.update(
      "participants",
      {"name": newName, "mobile": mobile},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> deleteParticipant(int id) async {
    final db = await database;
    await db.delete("transactions", where: "participantId = ?", whereArgs: [id]);
    return await db.delete("participants", where: "id = ?", whereArgs: [id]);
  }

  // ---------------- TRANSACTIONS -----------------

  Future<int> addTransaction(int participantId, double amount, int type, {String? remarks}) async {
    final db = await database;
    return await db.insert("transactions", {
      "participantId": participantId,
      "amount": amount,
      "type": type,
      "date": DateTime.now().toIso8601String(),
      "remarks": remarks ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> getUserTransactions(int participantId) async {
    final db = await database;
    return await db.query(
      "transactions",
      where: "participantId = ?",
      whereArgs: [participantId],
      orderBy: "date ASC",
    );
  }

  Future<int> updateTransaction(int id, double amount, int type, {String? remarks}) async {
    final db = await database;
    return await db.update(
      "transactions",
      {
        "amount": amount,
        "type": type,
        "date": DateTime.now().toIso8601String(),
        "remarks": remarks ?? '',
      },
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete("transactions", where: "id = ?", whereArgs: [id]);
  }
}
