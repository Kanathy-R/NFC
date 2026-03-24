import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;

  // 🔹 Get database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  // 🔹 Initialize DB
  static Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'nfc_tags.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tags(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tagId TEXT,
            data TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  // 🔹 Insert tag
  static Future<void> insertTag(String tagId, String data) async {
    final db = await database;

    await db.insert('tags', {
      'tagId': tagId,
      'data': data,
      'createdAt': DateTime.now().toString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // 🔹 Get all tags
  static Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return await db.query('tags', orderBy: 'id DESC');
  }

  // 🔹 Delete tag
  static Future<void> deleteTag(int id) async {
    final db = await database;
    await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }
}
