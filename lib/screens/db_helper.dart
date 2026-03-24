import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> getDB() async {
    if (_db != null) return _db!;

    _db = await openDatabase(
      join(await getDatabasesPath(), 'nfc_data.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE nfc_tags(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            tagId TEXT,
            payload TEXT
          )
        ''');
      },
      version: 1,
    );

    return _db!;
  }

  // INSERT
  static Future<void> insertTag(String tagId, String payload) async {
    final db = await getDB();

    await db.insert('nfc_tags', {
      'tagId': tagId,
      'payload': payload,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // READ ALL
  static Future<List<Map<String, dynamic>>> getTags() async {
    final db = await getDB();
    return db.query('nfc_tags');
  }
}
