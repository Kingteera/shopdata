import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'product_form_screen.dart';
import 'product_search_delegate.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

const double kFormFieldFontSize = 18;
const double kAppBarTitleFontSize = 18;

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _products = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  int _currentPage = 0;
  final int _itemsPerPage = 50;

  @override
  void initState() {
    super.initState();
    // _populateSampleProducts();
    _requestPermissions();
    _refreshProductList();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

 Future<void> _refreshProductList() async {
  setState(() {
    _isLoading = true;
  });
  try {
    _currentPage = 0;
    List<Map<String, dynamic>> products = await _dbHelper.queryProductsPaginated(_currentPage, _itemsPerPage);
    setState(() {
      _products = products;
    });
  } catch (e) {
    print('Error refreshing product list: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error refreshing product list')));
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

Future<void> _requestPermissions() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;

    if (!status.isGranted) {
      PermissionStatus newStatus = await Permission.manageExternalStorage.request();
      if (!newStatus.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permission denied. Please grant storage access.')),
        );
      }
    }
  }
  void _addProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProductFormScreen()),
    );
    if (result == true) {
      // _currentPage = 0;
      // _products.clear();
      _refreshProductList();
    }
  }

  void _editProduct(Map<String, dynamic> product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ProductFormScreen(product: product)),
    );
    if (result == true) {
      _currentPage = 0;
      _products.clear();
      _refreshProductList();
    }
  }

  void _viewProductDetail(BuildContext context, int productId) async {
    final DatabaseHelper _dbHelper =
        DatabaseHelper(); // สร้าง DatabaseHelper ภายในฟังก์ชัน
    Map<String, dynamic>? product = await _dbHelper.queryProductById(productId);
    if (product != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductFormScreen(product: product),
        ),
      );
    }
  }


 Future<void> _importDatabase() async {
  if (!await Permission.manageExternalStorage.request().isGranted) {
    await _requestPermissions();
    if (!await Permission.manageExternalStorage.request().isGranted) {
      return; // ออกจากฟังก์ชันถ้าสิทธิ์ยังไม่ได้รับ
    }
  }

  try {
    // เปิด File Picker ให้ผู้ใช้เลือกไฟล์ที่ต้องการนำเข้า
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      // allowedExtensions: ['db'],
    );

    if (result != null) {
      String importPath = result.files.single.path!;

      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, 'products.db');
      
      final dbFile = File(importPath);

      if (await dbFile.exists()) {
        // เปิดฐานข้อมูลที่นำเข้า
        final importedDb = await openDatabase(importPath);

        // ตรวจสอบว่ามีตาราง 'products' อยู่หรือไม่
        final List<Map<String, dynamic>> tables = await importedDb.rawQuery('SELECT name FROM sqlite_master WHERE type="table" AND name="products"');

        if (tables.isEmpty) {
          // ถ้าไม่มีตาราง 'products', ให้สร้างตารางใหม่
          await importedDb.execute('''
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
          await importedDb.execute('''
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
        }

        final List<Map<String, dynamic>> importedProducts = await importedDb.query('products');
        await importedDb.close();

        // เปิดฐานข้อมูลปัจจุบัน
        final db = await openDatabase(dbPath);

        // ตรวจสอบและสร้างตารางถ้ายังไม่มี
        await db.execute('''
          CREATE TABLE IF NOT EXISTS products (
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
          CREATE TABLE IF NOT EXISTS product_history (
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

        final batch = db.batch();

        for (var product in importedProducts) {
          // เพิ่มข้อมูลแต่ละรายการจากฐานข้อมูลที่นำเข้าไปยังฐานข้อมูลปัจจุบัน
          batch.insert(
            'products',
            product,
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        await batch.commit(noResult: true);
        // await db.close();
        await importedDb.close();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Database imported and merged from $importPath to $dbPath')));
        _refreshProductList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No database found at $importPath')));
      }
    }
  } catch (e) {
    print('Error importing database: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error importing database')));
  }
}
  Future<void> _exportDatabase() async {
    if (!await Permission.manageExternalStorage.request().isGranted) {
      await _requestPermissions();
      if (!await Permission.manageExternalStorage.request().isGranted) {
        return; // ออกจากฟังก์ชันถ้าสิทธิ์ยังไม่ได้รับ
      }
    }

    try {
      final databasesPath = await getDatabasesPath();
      final dbPath = path.join(databasesPath, 'products.db');

      String? outputDir = await FilePicker.platform.getDirectoryPath();

      if (outputDir != null) {
        String? fileName = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            String tempFileName = '';
            return AlertDialog(
              title: Text('Enter file name'),
              content: TextField(
                onChanged: (value) {
                  tempFileName = value;
                },
                decoration: InputDecoration(hintText: "File name"),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(tempFileName);
                  },
                ),
              ],
            );
          },
        );

        if (fileName != null && fileName.isNotEmpty) {
          String exportPath = path.join(outputDir, '$fileName.db');
          final dbFile = File(dbPath);

          // ตรวจสอบและสร้างโฟลเดอร์ถ้าไม่มีอยู่
          if (!(await Directory(outputDir).exists())) {
            await Directory(outputDir).create(recursive: true);
          }

          await dbFile.copy(exportPath);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Database exported to $exportPath')));
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('No file name provided')));
        }
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No directory selected')));
      }
    } catch (e) {
      print('Error exporting database: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error exporting database')));
    }
  }


  String formatNumber(dynamic number) {
    if (number is int) {
      return number.toString();
    } else if (number is double) {
      if (number % 1 == 0) {
        return number.toInt().toString();
      } else {
        return number.toStringAsFixed(2);
      }
    } else {
      return '';
    }
  }

  String formatNumberWithComma(dynamic number) {
    final formatter = NumberFormat('#,###.##');

    if (number is int) {
      return formatter.format(number);
    } else if (number is double) {
      return formatter.format(number);
    } else {
      return '';
    }
  }

  // Future<void> _populateSampleProducts() async {
  //   for (int i = 1; i <= 2000; i++) {
  //     final product = {
  //       'name': 'Product $i',
  //       'cost_price': i.toDouble(),
  //       'sale_price': (i + 10).toDouble(),
  //       'contain': 1.0,
  //       'unit_cost': i.toDouble(),
  //       'created_at': DateTime.now().toIso8601String(),
  //       'updated_at': DateTime.now().toIso8601String(),
  //     };
  //     await _dbHelper.insertProduct(product);
  //   }
  //   _refreshProductList();
  // }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500 && !_isLoading) {
      _loadMoreProducts();
    }
  }

  void _loadMoreProducts() async {
  setState(() {
    _isLoading = true;
  });
  try {
    _currentPage++;
    List<Map<String, dynamic>> moreProducts = await _dbHelper.queryProductsPaginated(_currentPage, _itemsPerPage);
    setState(() {
      _products = List.from(_products)..addAll(moreProducts);
    });
  } catch (e) {
    print('Error loading more products: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading more products')));
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product Inventory',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.file_upload),
            onPressed: _exportDatabase,
          ),
          IconButton(
            icon: Icon(Icons.file_download),
            onPressed: _importDatabase,
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              final searchText = await showSearch(
                context: context,
                delegate: ProductSearchDelegate(),
              );
              // if (searchText != null && searchText.isNotEmpty) {
              //   _searchProduct(searchText);
              // }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProductList,
        child: _isLoading && _products.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                controller: _scrollController,
                itemCount: _products.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _products.length) {
                    return Center(child: CircularProgressIndicator());
                  }
                  final product = _products[index];
                  return ListTile(
                    title: Text(product['name'],
                        style: TextStyle(
                            fontSize: kAppBarTitleFontSize,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      'Cost: ${formatNumberWithComma(product['cost_price'])}.-/${formatNumber(product['contain'])} = ${formatNumberWithComma(product['unit_cost'])} | Sale: ${formatNumber(product['sale_price'])}',
                      style: TextStyle(fontSize: kFormFieldFontSize),
                    ),
                    onTap: () {
                      _viewProductDetail(context, product['id']);
                      if (ModalRoute.of(context)!.settings.name == '/search') {
                        Navigator.of(context).pop();
                      }
                    },
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProduct,
        child: Icon(Icons.add),
      ),
    );
  }
}
