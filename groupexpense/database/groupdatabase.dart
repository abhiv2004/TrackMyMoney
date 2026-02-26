import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class GroupExpenseDB {
  GroupExpenseDB._init();
  static final GroupExpenseDB instance = GroupExpenseDB._init();
  static Database? _db;

  // =========================
  // DATABASE INSTANCE
  // =========================
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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  // =========================
  // CREATE TABLES
  // =========================
  Future _createDB(Database db, int version) async {

    // Groups Table
    await db.execute('''
      CREATE TABLE groups (
        group_id INTEGER PRIMARY KEY AUTOINCREMENT,
        group_name TEXT NOT NULL,
        date TEXT
      )
    ''');

    // Participants Table
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

    // Expenses Table
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

    // Expense Splits Table
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

  // =====================================================
  // 1️⃣ ADD GROUP WITH PARTICIPANTS (Transaction Safe)
  // =====================================================
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

  // =====================================================
  // 2️⃣ GET ALL GROUPS
  // =====================================================
  Future<List<Map<String, dynamic>>> getAllGroups() async {
    final db = await database;
    return await db.query('groups', orderBy: 'group_id DESC');
  }

  // =====================================================
  // 3️⃣ GET GROUP WITH PARTICIPANTS
  // =====================================================
  Future<Map<String, dynamic>> getGroupWithParticipants(int groupId) async {
    final db = await database;

    final group = await db.query(
      'groups',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );

    final participants = await db.query(
      'participants',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );

    return {
      'group': group.first,
      'participants': participants,
    };
  }

  // =====================================================
  // 4️⃣ UPDATE GROUP WITH PARTICIPANTS
  // =====================================================
  Future<void> updateGroupWithParticipants({
    required int groupId,
    required String groupName,
    required List<Map<String, dynamic>> participants,
  }) async {
    final db = await database;

    await db.transaction((txn) async {

      // Update Group Name
      await txn.update(
        'groups',
        {'group_name': groupName},
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      // Get Existing Participants
      final existingParticipants = await txn.query(
        'participants',
        where: 'group_id = ?',
        whereArgs: [groupId],
      );

      List<int> existingIds =
          existingParticipants.map((e) => e['participant_id'] as int).toList();

      List<int> updatedIds = [];

      // Insert or Update
      for (var p in participants) {
        if (p['participant_id'] != null) {
          await txn.update(
            'participants',
            {
              'participant_name': p['name'],
              'image': p['image'],
              'mobile': p['mobile'],
            },
            where: 'participant_id = ?',
            whereArgs: [p['participant_id']],
          );
          updatedIds.add(p['participant_id']);
        } else {
          await txn.insert('participants', {
            'group_id': groupId,
            'participant_name': p['name'],
            'image': p['image'],
            'mobile': p['mobile'],
          });
        }
      }

      // Delete Removed Participants
      for (int id in existingIds) {
        if (!updatedIds.contains(id)) {
          await txn.delete(
            'participants',
            where: 'participant_id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  // =====================================================
  // 5️⃣ DELETE GROUP WITH EVERYTHING (Cascade)
  // =====================================================
  Future<void> deleteGroupWithEverything(int groupId) async {
    final db = await database;

    await db.delete(
      'groups',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  // =====================================================
  // 6️⃣ FETCH EXPENSES BY GROUP ID
  // =====================================================
  Future<List<Map<String, dynamic>>> fetchExpensesByGroupId(int groupId) async {
    final db = await database;

    return await db.query(
      'expenses',
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'expense_date DESC',
    );
  }

  // =====================================================
  // 7️⃣ FETCH PARTICIPANTS BY GROUP ID
  // =====================================================
  Future<List<Map<String, dynamic>>> fetchParticipantsByGroupId(
      int groupId) async {
    final db = await database;

    return await db.query(
      'participants',
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  // =====================================================
  // 8️⃣ FETCH DROPDOWN PARTICIPANTS
  // =====================================================
  Future<List<Map<String, dynamic>>>
      fetchDropdownParticipantsByGroupId(int groupId) async {
    final db = await database;

    return await db.query(
      'participants',
      columns: ['participant_id', 'participant_name'],
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  // =====================================================
  // 9️⃣ FETCH EXPENSE SPLITS BY EXPENSE ID
  // =====================================================
  Future<List<Map<String, dynamic>>>
      fetchExpenseSplitsByExpenseId(int expenseId) async {
    final db = await database;

    return await db.query(
      'expense_splits',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }

  // =====================================================
  // 🔟 INSERT EXPENSE
  // =====================================================
  Future<int> insertExpense({
    required int groupId,
    required String expenseName,
    required double amount,
    required int paidBy,
    required String splitType,
    String? description,
    required String expenseDate,
  }) async {
    final db = await database;

    return await db.insert('expenses', {
      'group_id': groupId,
      'expense_name': expenseName,
      'amount': amount,
      'paid_by': paidBy,
      'split_type': splitType,
      'description': description,
      'expense_date': expenseDate,
    });
  }

  // =====================================================
  // 1️⃣1️⃣ INSERT EXPENSE SPLIT
  // =====================================================
  Future<int> insertExpenseSplit({
    required int expenseId,
    required int participantId,
    required double amount,
    required int groupId,
  }) async {
    final db = await database;

    return await db.insert('expense_splits', {
      'expense_id': expenseId,
      'participant_id': participantId,
      'amount': amount,
      'group_id': groupId,
    });
  }

  // =====================================================
  // 1️⃣2️⃣ UPDATE EXPENSE
  // =====================================================
  Future<int> updateExpense({
    required int expenseId,
    required String expenseName,
    required double amount,
    required int paidBy,
    required String splitType,
    String? description,
    required String expenseDate,
  }) async {
    final db = await database;

    return await db.update(
      'expenses',
      {
        'expense_name': expenseName,
        'amount': amount,
        'paid_by': paidBy,
        'split_type': splitType,
        'description': description,
        'expense_date': expenseDate,
      },
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }

  // =====================================================
  // 1️⃣3️⃣ DELETE EXPENSE (Splits auto delete)
  // =====================================================
  Future<void> deleteExpense(int expenseId) async {
    final db = await database;

    await db.delete(
      'expenses',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
  }

  // =====================================================
  // 1️⃣4️⃣ UPDATE EXPENSE SPLIT
  // =====================================================
  Future<int> updateExpenseSplitByExpenseAndParticipant({
    required int expenseId,
    required int participantId,
    required double amount,
  }) async {
    final db = await database;

    return await db.update(
      'expense_splits',
      {'amount': amount},
      where: 'expense_id = ? AND participant_id = ?',
      whereArgs: [expenseId, participantId],
    );
  }
}