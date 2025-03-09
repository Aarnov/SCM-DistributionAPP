import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductPage extends StatefulWidget {
  final QueryDocumentSnapshot product;

  const EditProductPage({super.key, required this.product});

  @override
  _EditProductPageState createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _productDescController;
  late TextEditingController _hsnCodeController;
  late TextEditingController _salePriceController;
  late TextEditingController _taxSaleController;
  late TextEditingController _taxPurchaseController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _measurementUnitController;
  
  String? _selectedCategory;
  String? _selectedSubCategory;

  @override
  void initState() {
    super.initState();
    var data = widget.product.data() as Map<String, dynamic>;
    _productNameController = TextEditingController(text: data['ProductName']);
    _productDescController = TextEditingController(text: data['ProductDesc']);
    _hsnCodeController = TextEditingController(text: data['HSNCode']);
    _salePriceController = TextEditingController(text: data['SalePriceInclTax'].toString());
    _taxSaleController = TextEditingController(text: data['TaxPercemtInSalePrice'].toString());
    _taxPurchaseController = TextEditingController(text: data['TaxPercemtInPurPrice'].toString());
    _purchasePriceController = TextEditingController(text: data['PurPriceInclTax'].toString());
    _measurementUnitController = TextEditingController(text: data['MeasurementUnitId'].toString());
    _selectedCategory = data['ProductCategoryId'];
    _selectedSubCategory = data['ProductSubCatId'];
  }

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('ProductMaster')
          .doc(widget.product.id)
          .update({
        'ProductName': _productNameController.text,
        'ProductDesc': _productDescController.text,
        'ProductCategoryId': _selectedCategory,
        'ProductSubCatId': _selectedSubCategory,
        'MeasurementUnitId': _measurementUnitController.text,
        'HSNCode': _hsnCodeController.text,
        'SalePriceInclTax': double.parse(_salePriceController.text),
        'TaxPercemtInSalePrice': int.parse(_taxSaleController.text),
        'TaxPercemtInPurPrice': int.parse(_taxPurchaseController.text),
        'PurPriceInclTax': double.parse(_purchasePriceController.text),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Product'), backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_productNameController, 'Product Name', Icons.production_quantity_limits),
                _buildTextField(_productDescController, 'Product Description', Icons.description),
                _buildDropdown(
                  'Category', 
                  _selectedCategory, 
                  _fetchCategories, 
                  (value) {
                    setState(() {
                      _selectedCategory = value;
                      _selectedSubCategory = null; // Reset subcategory when category changes
                    });
                  }
                ),
                _buildDropdown(
                  'Subcategory', 
                  _selectedSubCategory, 
                  _fetchSubCategories, 
                  (value) => setState(() => _selectedSubCategory = value),
                  isEnabled: _selectedCategory != null
                ),
                _buildTextField(_measurementUnitController, 'Measurement Unit', Icons.code),
                _buildTextField(_hsnCodeController, 'HSN Code', Icons.code),
                _buildTextField(_salePriceController, 'Sale Price (Incl. Tax)', Icons.attach_money, keyboardType: TextInputType.numberWithOptions(decimal: true)),
                _buildTextField(_taxSaleController, 'Tax % on Sale Price', Icons.percent, keyboardType: TextInputType.number),
                _buildTextField(_taxPurchaseController, 'Tax % on Purchase Price', Icons.percent, keyboardType: TextInputType.number),
                _buildTextField(_purchasePriceController, 'Purchase Price (Incl. Tax)', Icons.attach_money, keyboardType: TextInputType.numberWithOptions(decimal: true)),
                
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Update Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey[100],
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
        ),
        validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String? selectedValue, Future<List<DropdownMenuItem<String>>> Function() fetchItems, Function(String?) onChanged, {bool isEnabled = true}) {
    return FutureBuilder<List<DropdownMenuItem<String>>>(
      future: fetchItems(),
      builder: (context, snapshot) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            items: snapshot.data,
            onChanged: isEnabled ? onChanged : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: isEnabled ? Colors.grey[100] : Colors.grey[300],
              labelText: label,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            ),
            validator: (value) => value == null ? 'Please select $label' : null,
          ),
        );
      },
    );
  }

  Future<List<DropdownMenuItem<String>>> _fetchCategories() async {
    final snapshot = await FirebaseFirestore.instance.collection('ProductCategoryMaster').get();
    return snapshot.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['CategoryDesc']))).toList();
  }

  Future<List<DropdownMenuItem<String>>> _fetchSubCategories() async {
    if (_selectedCategory == null) return []; // Prevents fetching without category
    final snapshot = await FirebaseFirestore.instance.collection('ProductSubCategoryMaster').where('ProductCategoryId', isEqualTo: _selectedCategory).get();
    return snapshot.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['SubCategoryDesc']))).toList();
  }
}
