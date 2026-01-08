import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'product_form_screen.dart';
import 'package:intl/intl.dart';

const double kFormFieldFontSize = 18;
const double kAppBarTitleFontSize = 18;

class ProductSearchDelegate extends SearchDelegate {
  final DatabaseHelper _databaseHelper = DatabaseHelper();
  List<Map<String, dynamic>> _products = [];
  int _currentPage = 0;
  final int _itemsPerPage = 50;
  bool _isLoadingMore = false;
  ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _loadingNotifier = ValueNotifier(false);

  ProductSearchDelegate() {
    _scrollController.addListener(_onScroll);
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          _resetPagination();
          showSuggestions(context); // Refresh suggestions when clearing the search
        },
      ),
    ];
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

  void _viewProductDetail(BuildContext context, int productId) async {
    final DatabaseHelper _dbHelper = DatabaseHelper(); // สร้าง DatabaseHelper ภายในฟังก์ชัน
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

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _resetAndSearchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _products.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No products found.'));
        }

        _products = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          itemCount: _products.length + (snapshot.connectionState == ConnectionState.waiting ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return Center(child: CircularProgressIndicator());
            }
            final product = _products[index];
            return ListTile(
              title: Text(product['name'], style: TextStyle(fontSize: kFormFieldFontSize,fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Cost: ${formatNumberWithComma(product['cost_price'])}.-/${formatNumber(product['contain'])} = ${formatNumberWithComma(product['unit_cost'])} | Sale: ${formatNumber(product['sale_price'])}',
                style: TextStyle(fontSize: kFormFieldFontSize),
              ),
              onTap: () {
                close(context, product);
                _viewProductDetail(context, product['id']);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _resetAndSearchProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _products.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('An error occurred: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('No products found.'));
        }

        _products = snapshot.data!;
        return ListView.builder(
          controller: _scrollController,
          itemCount: _products.length + (snapshot.connectionState == ConnectionState.waiting ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _products.length) {
              return Center(child: CircularProgressIndicator());
            }
            final product = _products[index];
            return ListTile(
              title: Text(product['name'], style: TextStyle(fontSize: kFormFieldFontSize,fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Cost: ${formatNumberWithComma(product['cost_price'])}.-/${formatNumber(product['contain'])} = ${formatNumberWithComma(product['unit_cost'])} | Sale: ${formatNumber(product['sale_price'])}',
                style: TextStyle(fontSize: kFormFieldFontSize),
              ),
              onTap: () {
                close(context, product);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductFormScreen(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _resetAndSearchProducts() async {
    _resetPagination();
    return await _searchProducts();
  }

  Future<List<Map<String, dynamic>>> _searchProducts() async {
    if (_isLoadingMore) return _products;
    if (_products.isEmpty) _currentPage = 0;

    _loadingNotifier.value = true;
    _isLoadingMore = true;

    List<Map<String, dynamic>> newProducts = await _databaseHelper.searchProducts(query, _currentPage, _itemsPerPage);

    if (_currentPage == 0) {
      _products = List<Map<String, dynamic>>.from(newProducts);
    } else {
      _products.addAll(newProducts);
    }

    _loadingNotifier.value = false;
    _isLoadingMore = false;

    return _products;
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 500 && !_isLoadingMore) {
      _currentPage++;
      _searchProducts();
    }
  }

  void _resetPagination() {
    _products = [];
    _currentPage = 0;
    _isLoadingMore = false;
  }
}
