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
      version: 1,
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
            time TEXT
          )
        ''');
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
}
