import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'food_balance.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE food_diary (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            calories INTEGER,
            protein INTEGER,
            fat INTEGER,
            carb INTEGER,
            category TEXT,
            time TEXT,
            firebase_id TEXT 
          )
        ''');
      },

      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE food_diary ADD COLUMN firebase_id TEXT',
          );
        }
      },
    );
  }

  // FUNGSI INSERT (Menambah Data)
  Future<int> insertFood(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert('food_diary', row);
  }

  // FUNGSI QUERY (Ambil Semua Data)
  Future<List<Map<String, dynamic>>> queryAllFood() async {
    Database db = await database;
    return await db.query('food_diary', orderBy: 'time DESC');
  }

  // FUNGSI DELETE (Hapus Satu Data berdasarkan ID)
  Future<int> deleteFood(int id) async {
    Database db = await database;
    return await db.delete('food_diary', where: 'id = ?', whereArgs: [id]);
  }

  // FUNGSI RESET DELETE
  Future<int> deleteAllFood() async {
    final db = await database;

    return await db.delete('food_diary');
  }

  // FUNGSI DELETE DATA LAMA
  Future<int> deleteOldData(int days) async {
    if (days <= 0) return 0;

    final db = await database;
    DateTime limitDate = DateTime.now().subtract(Duration(days: days));

    return await db.delete(
      'food_diary',
      where: 'time < ? AND firebase_id IS NOT NULL AND firebase_id != ?',
      whereArgs: [limitDate.toIso8601String(), ''],
    );
  }

  Future<List<Map<String, dynamic>>> getPendingFood() async {
    Database db = await database;

    return await db.query(
      'food_diary',
      where: 'firebase_id IS NULL OR firebase_id = ?',
      whereArgs: [''],
    );
  }

  Future<int> updateFirebaseId(int localId, String firebaseId) async {
    Database db = await database;
    return await db.update(
      'food_diary',
      {'firebase_id': firebaseId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
}
