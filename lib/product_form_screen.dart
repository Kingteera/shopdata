import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'product_history_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Map<String, dynamic>? product;

  ProductFormScreen({Key? key, this.product}) : super(key: key);

  @override
  _ProductFormScreenState createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  late TextEditingController _nameController;
  late TextEditingController _costPriceController;
  late TextEditingController _salePriceController;
  late TextEditingController _containController;
  late TextEditingController _unitCostController;

  late FocusNode _nameFocusNode;
  late FocusNode _costPriceFocusNode;
  late FocusNode _salePriceFocusNode;
  late FocusNode _containFocusNode;

  double _fontSize = 18.0;
  double _buttonSize = 18.0;

  bool _isEditing = false;

String _calculateUnitCost() {
    double cost = double.tryParse(_costPriceController.text) ?? 0;
    double contain = double.tryParse(_containController.text) ?? 1;
    return (cost / contain).toStringAsFixed(2);
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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?['name'] ?? '');
    _costPriceController = TextEditingController(text: formatNumber(widget.product?['cost_price']));
    _salePriceController = TextEditingController(text: formatNumber(widget.product?['sale_price']));
    _containController = TextEditingController(text: formatNumber(widget.product?['contain']));
    _unitCostController = TextEditingController(text: _calculateUnitCost());
        _nameFocusNode = FocusNode();
    _costPriceFocusNode = FocusNode();
    _salePriceFocusNode = FocusNode();
    _containFocusNode = FocusNode();
    _costPriceController.addListener(_updateUnitCost);
    _containController.addListener(_updateUnitCost);


  }
void _updateUnitCost() {
    setState(() {
      _unitCostController.text = _calculateUnitCost();
    });
  }


  @override
  void dispose() {
    _nameController.dispose();
    _costPriceController.dispose();
    _salePriceController.dispose();
    _containController.dispose();
    _unitCostController.dispose();
    _nameFocusNode.dispose();
    _costPriceFocusNode.dispose();
    _salePriceFocusNode.dispose();
    _containFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = {
        'id': widget.product?['id'],
        'name': _nameController.text,
        'cost_price': double.parse(_costPriceController.text),
        'sale_price': double.parse(_salePriceController.text),
        'contain': double.parse(_containController.text),
        'unit_cost': double.parse(_unitCostController.text),
      };

      if (widget.product == null) {
        await _databaseHelper.insertProduct(product);
      } else {
        await _databaseHelper.updateProduct(product);
      }

      Navigator.pop(context, true);
    }
  }

  Future<void> _deleteProduct() async {
    if (widget.product != null) {
      await _databaseHelper.deleteProduct(widget.product!['id']);
      Navigator.pop(context, true);
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteProduct();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(fontSize: _fontSize,color: Colors.black);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Product Details',style: TextStyle(fontWeight: FontWeight.bold)),
        actions: widget.product != null
            ? [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: _toggleEditMode,
                ),
                IconButton(
                  icon: Icon(Icons.history),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductHistoryScreen(productId: widget.product!['id']),
                      ),
                    );
                  },
                ),
              ]
            : [],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                focusNode: _nameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  labelStyle: labelStyle,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
                style: TextStyle(fontSize: _fontSize,color: Colors.black),
                enabled: _isEditing || widget.product == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_costPriceFocusNode);
                },
              ),
              TextFormField(
                controller: _costPriceController,
                focusNode: _costPriceFocusNode,
                decoration: InputDecoration(
                  labelText: 'Cost Price',
                  labelStyle: labelStyle,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a cost price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                style: TextStyle(fontSize: _fontSize,color: Colors.black),
                enabled: _isEditing || widget.product == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_containFocusNode);
                },
                
              ),
              TextFormField(
                controller: _containController,
                focusNode: _containFocusNode,
                decoration: InputDecoration(
                  labelText: 'Contain',
                  labelStyle: labelStyle,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
                style: TextStyle(fontSize: _fontSize,color: Colors.black),
                enabled: _isEditing || widget.product == null,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) {
                  FocusScope.of(context).requestFocus(_salePriceFocusNode);
                },
                
              ),
              TextFormField(
                controller: _unitCostController,
                decoration: InputDecoration(
                  labelText: 'Unit Cost',
                  labelStyle: labelStyle,
                ),
                
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
                style: TextStyle(fontSize: _fontSize,color: Colors.black),
                enabled: false ,
              ),
              TextFormField(
                controller: _salePriceController,
                focusNode: _salePriceFocusNode,
                decoration: InputDecoration(
                  labelText: 'Sale Price',
                  labelStyle: labelStyle,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a sale price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
                style: TextStyle(fontSize: _fontSize,color: Colors.black),
                enabled: _isEditing || widget.product == null,
                
              ),
              
              
              SizedBox(height: 20),
              if (_isEditing || widget.product == null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    
                    if (widget.product != null)
                      ElevatedButton(
                        onPressed: _showDeleteConfirmationDialog,
                        style: ElevatedButton.styleFrom(primary: Colors.red),
                        child: Text('Delete', style: TextStyle(fontSize: _buttonSize)),
                      ),
                      ElevatedButton(
                      onPressed: _saveProduct,
                      child: Text('Save', style: TextStyle(fontSize: _buttonSize)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
