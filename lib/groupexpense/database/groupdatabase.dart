import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GroupExpenseDB {
  GroupExpenseDB._init();
  static final GroupExpenseDB instance = GroupExpenseDB._init();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB("group_expense.db");
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // groups table
    await db.execute('''
      CREATE TABLE groups (
        group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_name TEXT NOT NULL,
        date TEXT
      )
    ''');

    // participants table
    await db.execute('''
      CREATE TABLE participants (
        participant_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER,
        participant_name TEXT NOT NULL,
        image TEXT,
        mobile TEXT,
        FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
      )
    ''');

    // expenses table
    await db.execute('''
      CREATE TABLE expenses (
        expense_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_id INTEGER NOT NULL,
        expense_name TEXT NOT NULL,
        amount REAL NOT NULL,
        paid_by INTEGER NOT NULL,
        split_type TEXT NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE,
        FOREIGN KEY (paid_by) REFERENCES participants(participant_id) ON DELETE CASCADE
      )
    ''');

    // expense_splits table
    await db.execute('''
      CREATE TABLE expense_splits (
        split_id INTEGER PRIMARY KEY AUTOINCREMENT,
        expense_id INTEGER NOT NULL,
        participant_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        group_id INTEGER NOT NULL,
        FOREIGN KEY (expense_id) REFERENCES expenses(expense_id) ON DELETE CASCADE,
        FOREIGN KEY (participant_id) REFERENCES participants(participant_id) ON DELETE CASCADE,
        FOREIGN KEY (group_id) REFERENCES groups(group_id) ON DELETE CASCADE
      )
    ''');
  }

  // ----------------------------------------------------------
  // GROUP FUNCTIONS
  // ----------------------------------------------------------
  Future<int> addGroup(String name, String dateIso) async {
    final db = await database;
    return await db.insert('groups', {'group_name': name, 'date': dateIso});
  }

  Future<int> updateGroup(int groupId, String newName) async {
    final db = await database;
    return await db.update(
      'groups',
      {'group_name': newName},
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  Future<int> deleteGroup(int groupId) async {
    final db = await database;
    return await db.delete('groups', where: 'group_id = ?', whereArgs: [groupId]);
  }

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await database;
    return await db.query('groups', orderBy: 'group_id DESC');
  }

  Future<Map<String, dynamic>?> getGroupById(int groupId) async {
    final db = await database;
    final rows = await db.query('groups', where: 'group_id = ?', whereArgs: [groupId]);
    if (rows.isEmpty) return null;
    return rows.first;
  }
  // ----------------------------------------------------------
  // PARTICIPANT FUNCTIONS
  // ----------------------------------------------------------

  Future<int> addParticipant({
    required int groupId,
    required String name,
    String? imagePath,
    String? mobile,
  }) async {
    final db = await database;
    return await db.insert('participants', {
      'group_id': groupId,
      'participant_name': name,
      'image': imagePath,
      'mobile': mobile,
    });
  }

  Future<int> updateParticipant({
    required int participantId,
    required String name,
    String? imagePath,
    required String mobile,
  }) async {
    final db = await database;
    return await db.update(
      'participants',
      {
        'participant_name': name,
        'image': imagePath,
        'mobile': mobile,
      },
      where: 'participant_id = ?',
      whereArgs: [participantId],
    );
  }

  Future<int> deleteParticipant(int participantId) async {
    final db = await database;
    return await db.delete('participants', where: 'participant_id = ?', whereArgs: [participantId]);
  }

  Future<List<Map<String, dynamic>>> getParticipantsByGroup(int groupId) async {
    final db = await database;
    return await db.query('participants', where: 'group_id = ?', whereArgs: [groupId]);
  }
}