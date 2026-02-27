import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GroupExpenseDB {
  GroupExpenseDB._init();
  static final GroupExpenseDB instance = GroupExpenseDB._init();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB("group_expense_lib2.db");
    return _db!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE groups (
        group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_name TEXT NOT NULL,
        date TEXT
      )
    ''');

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

  // Group Methods
  Future<int> addGroupWithParticipants({
    required String groupName,
    required String dateIso,
    required List<Map<String, dynamic>> participants,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      int groupId = await txn.insert('groups', {
        'group_name': groupName,
        'date': dateIso,
      });

      for (var p in participants) {
        await txn.insert('participants', {
          'group_id': groupId,
          'participant_name': p['name'],
          'image': p['image'],
          'mobile': p['mobile'],
        });
      }
      return groupId;
    });
  }

  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await database;
    return await db.query('groups', orderBy: 'group_id DESC');
  }

  Future<Map<String, dynamic>> getGroupWithParticipants(int groupId) async {
    final db = await database;
    final group = await db.query('groups', where: 'group_id = ?', whereArgs: [groupId]);
    final participants = await db.query('participants', where: 'group_id = ?', whereArgs: [groupId]);
    return {
      'group': group.first,
      'participants': participants,
    };
  }

  Future<void> updateGroupWithParticipants({
    required int groupId,
    required String groupName,
    required List<Map<String, dynamic>> participants,
  }) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update('groups', {'group_name': groupName}, where: 'group_id = ?', whereArgs: [groupId]);

      final existingParticipants = await txn.query('participants', where: 'group_id = ?', whereArgs: [groupId]);
      List<int> existingIds = existingParticipants.map((e) => e['participant_id'] as int).toList();
      List<int> keptIds = [];

      for (var p in participants) {
        if (p['participant_id'] != null) {
          await txn.update('participants', {
            'participant_name': p['name'],
            'image': p['image'],
            'mobile': p['mobile'],
          }, where: 'participant_id = ?', whereArgs: [p['participant_id']]);
          keptIds.add(p['participant_id']);
        } else {
          await txn.insert('participants', {
            'group_id': groupId,
            'participant_name': p['name'],
            'image': p['image'],
            'mobile': p['mobile'],
          });
        }
      }

      for (int id in existingIds) {
        if (!keptIds.contains(id)) {
          await txn.delete('participants', where: 'participant_id = ?', whereArgs: [id]);
        }
      }
    });
  }

  Future<void> deleteGroup(int groupId) async {
    final db = await database;
    await db.delete('groups', where: 'group_id = ?', whereArgs: [groupId]);
  }

  // Expense Methods
  Future<List<Map<String, dynamic>>> getExpensesByGroupId(int groupId) async {
    final db = await database;
    return await db.query('expenses', where: 'group_id = ?', whereArgs: [groupId], orderBy: 'expense_date DESC');
  }

  Future<List<Map<String, dynamic>>> getParticipantsByGroupId(int groupId) async {
    final db = await database;
    return await db.query('participants', where: 'group_id = ?', whereArgs: [groupId]);
  }

  Future<int> insertExpenseWithSplits({
    required Map<String, dynamic> expense,
    required List<Map<String, dynamic>> splits,
  }) async {
    final db = await database;
    return await db.transaction((txn) async {
      int expenseId = await txn.insert('expenses', expense);
      for (var split in splits) {
        split['expense_id'] = expenseId;
        await txn.insert('expense_splits', split);
      }
      return expenseId;
    });
  }

  Future<void> deleteExpense(int expenseId) async {
    final db = await database;
    await db.delete('expenses', where: 'expense_id = ?', whereArgs: [expenseId]);
  }

  Future<List<Map<String, dynamic>>> getSplitsByExpenseId(int expenseId) async {
    final db = await database;
    return await db.query('expense_splits', where: 'expense_id = ?', whereArgs: [expenseId]);
  }

  Future<List<Map<String, dynamic>>> getAllSplitsForGroup(int groupId) async {
    final db = await database;
    return await db.query('expense_splits', where: 'group_id = ?', whereArgs: [groupId]);
  }
}
