import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class MyPersonalExpenseDB {
  static final MyPersonalExpenseDB instance = MyPersonalExpenseDB._init();
  static Database? _database;

  MyPersonalExpenseDB._init();

  // ---------------- DATABASE INIT ----------------
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB("personal_expense.db");
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1, // no upgrade logic
      onCreate: _createDB,
    );
  }

  // ---------------- CREATE TABLE ----------------
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        amount REAL,
        category TEXT,
        remarks TEXT,
        date TEXT
      )
    ''');
  }

  // ---------------- CREATE ----------------
  Future<int> addExpense(
      String name,
      double amount, {
        required String category,
        String? remarks,
        required String date,
      }) async {
    final db = await instance.database;

    return await db.insert('expenses', {
      'name': name,
      'amount': amount,
      'category': category,
      'remarks': remarks ?? '',
      'date': date,
    });
  }

  // ---------------- READ ALL ----------------
  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      orderBy: 'date DESC',
    );
  }

  // ---------------- READ BY CATEGORY ----------------
  Future<List<Map<String, dynamic>>> getExpensesByCategory(String category) async {
    final db = await instance.database;
    return await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );
  }

  // ---------------- READ BY YEAR ----------------
  Future<List<Map<String, dynamic>>> getExpensesByYear(int year) async {
    final db = await instance.database;

    String startDate = '$year-01-01';
    String endDate = '$year-12-31';

    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );
  }

  // ---------------- CURRENT MONTH ----------------
  Future<List<Map<String, dynamic>>> getExpensesByRunningMonth() async {
    final db = await instance.database;

    DateTime now = DateTime.now();
    String firstDay = DateFormat('yyyy-MM-01').format(now);
    String lastDay = DateFormat('yyyy-MM-dd')
        .format(DateTime(now.year, now.month + 1, 0));

    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [firstDay, lastDay],
      orderBy: 'date DESC',
    );
  }

  // ---------------- YEARLY SUMMARY (MONTH WISE) ----------------
  Future<Map<String, double>> getYearlyExpenses(int year) async {
    final db = await instance.database;

    final result = await db.rawQuery('''
      SELECT strftime('%m', date) AS month, SUM(amount) AS total
      FROM expenses
      WHERE date BETWEEN ? AND ?
      GROUP BY month
      ORDER BY month ASC
    ''', ['$year-01-01', '$year-12-31']);

    Map<String, double> data = {};
    for (var row in result) {
      data[row['month'].toString()] =
          (row['total'] as num).toDouble();
    }

    return data;
  }

  // ---------------- UPDATE ----------------
  Future<int> updateExpense(
      int id,
      String name,
      double amount, {
        required String category,
        String? remarks,
        required String date,
      }) async {
    final db = await instance.database;

    return await db.update(
      'expenses',
      {
        'name': name,
        'amount': amount,
        'category': category,
        'remarks': remarks ?? '',
        'date': date,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---------------- DELETE ----------------
  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
