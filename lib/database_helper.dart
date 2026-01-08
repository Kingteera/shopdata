import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'products.db');

    return await openDatabase(
      path,
      version: 3, // Updated version to 3 for new columns
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            cost_price REAL,
            sale_price REAL,
            contain REAL,
            unit_cost REAL,
            created_at TEXT,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE product_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            product_id INTEGER,
            name TEXT,
            cost_price REAL,
            sale_price REAL,
            contain REAL,
            unit_cost REAL,
            modified_at TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE products ADD COLUMN contain REAL');
          await db.execute('ALTER TABLE product_history ADD COLUMN contain REAL');
        }
        if (oldVersion < 3) {
          await db.execute('ALTER TABLE products ADD COLUMN created_at TEXT');
          await db.execute('ALTER TABLE products ADD COLUMN updated_at TEXT');
        }
      },
    );
  }

  Future<int> insertProduct(Map<String, dynamic> product) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    product['created_at'] = now;
    product['updated_at'] = now;
    return await db.insert('products', product);
  }

  Future<int> updateProduct(Map<String, dynamic> product) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    product['updated_at'] = now;

    // Fetch the old product data
    final oldProduct = await db.query('products', where: 'id = ?', whereArgs: [product['id']]);
    if (oldProduct.isNotEmpty) {
      final history = {
        'product_id': product['id'],
        'name': oldProduct[0]['name'],
        'cost_price': oldProduct[0]['cost_price'],
        'contain' : oldProduct[0]['contain'],
        'unit_cost' : oldProduct[0]['unit_cost'],
        'sale_price': oldProduct[0]['sale_price'],
        'modified_at': DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      };
      await db.insert('product_history', history);
    }

    return await db.update('products', product, where: 'id = ?', whereArgs: [product['id']]);
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> queryAllProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<List<Map<String, dynamic>>> searchProducts(String name, int page, int limit) async {
    final db = await database;
    final offset = page * limit;

    if (name.isEmpty) {
      return await db.query(
        'products',
        orderBy: 'updated_at DESC, created_at DESC',
        limit: limit,
        offset: offset,
      );
    }

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT *
      FROM products
      WHERE name LIKE ?
      ORDER BY
        CASE
          WHEN name LIKE ? THEN 0
          ELSE 1
        END, name ASC
      LIMIT ? OFFSET ?
    ''', ['%$name%', '$name%', limit, offset]);

    return result;
  }

  Future<int> insertProductHistory(Map<String, dynamic> productHistory) async {
    final db = await database;
    return await db.insert('product_history', productHistory);
  }

  Future<Map<String, dynamic>?> queryProductById(int productId) async {
    final db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> getProductHistory(int productId) async {
    final db = await database;
    return await db.query(
      'product_history',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'modified_at ASC',
    );
  }

 Future<List<Map<String, dynamic>>> queryProductsPaginated(int page, int limit) async {
    final db = await database;
    final offset = page * limit;
    return await db.query(
      'products',
      orderBy: 'updated_at DESC, created_at DESC',  // เรียงลำดับตาม updated_at และ created_at ล่าสุด
      limit: limit,
      offset: offset,
    );
}

}
