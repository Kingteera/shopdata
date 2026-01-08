import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProductHistoryScreen extends StatelessWidget {
  final int productId;

  ProductHistoryScreen({required this.productId});

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Product History',style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _databaseHelper.getProductHistory(productId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No history found.'));
          }

          final history = snapshot.data!;
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return ListTile(
                title: Text(item['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Cost Price: ${item['cost_price']}'),
                    Text('Contain: ${item['contain']}'),
                    Text('Unit Cost: ${item['unit_cost']}'),
                    Text('Sale Price: ${item['sale_price']}'),
                    Text('Modified At: ${item['modified_at']}'),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
