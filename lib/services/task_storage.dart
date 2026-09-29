import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/task.dart';

class TaskStorage {
  TaskStorage._();

  static final TaskStorage instance = TaskStorage._();

  static const String _databaseName = 'todo.db';
  static const int _databaseVersion = 4;
  static const String _tableName = 'tasks';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(
      databasePath,
      _databaseName,
    );

    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            is_completed INTEGER NOT NULL,
            priority INTEGER NOT NULL DEFAULT 1,
            due_date INTEGER,
            reminder_at INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE $_tableName
            ADD COLUMN priority INTEGER NOT NULL DEFAULT 1
          ''');
        }

        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE $_tableName
            ADD COLUMN due_date INTEGER
          ''');
        }

        if (oldVersion < 4) {
          await db.execute('''
            ALTER TABLE $_tableName
            ADD COLUMN reminder_at INTEGER
          ''');
        }
      },
    );
  }

  Future<List<Task>> getTasks() async {
    final db = await database;

    final maps = await db.query(
      _tableName,
      orderBy: 'rowid ASC',
    );

    return maps
        .map(
          (map) => Task.fromMap(map),
        )
        .toList();
  }

  Future<void> insertTask(Task task) async {
    final db = await database;

    await db.insert(
      _tableName,
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTask(Task task) async {
    final db = await database;

    await db.update(
      _tableName,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<void> deleteTask(String taskId) async {
    final db = await database;

    await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }
}