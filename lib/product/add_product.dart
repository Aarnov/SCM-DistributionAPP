import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  _AddProductPageState createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _productDescController = TextEditingController();
  final TextEditingController _hsnCodeController = TextEditingController();
  final TextEditingController _salePriceController = TextEditingController();
  final TextEditingController _taxSaleController = TextEditingController();
  final TextEditingController _taxPurchaseController = TextEditingController();
  final TextEditingController _purchasePriceController = TextEditingController();
  final TextEditingController _measurementUnitController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubCategory;


  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('ProductMaster').add({
        'ProductName': _productNameController.text,
        'ProductDesc': _productDescController.text,
        'ProductCategoryId': _selectedCategory,
        'ProductSubCatId': _selectedSubCategory,
        'MeasurementUnitId':_measurementUnitController.text,
        
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
      appBar: AppBar(title: const Text('Add Product'), backgroundColor: Colors.blueAccent),
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
                _buildDropdown('Category', _selectedCategory, _fetchCategories, (value) => setState(() => _selectedCategory = value)),
                _buildDropdown('Subcategory', _selectedSubCategory, _fetchSubCategories, (value) => setState(() => _selectedSubCategory = value)),
                 _buildTextField(_measurementUnitController, 'Measurement Unit', Icons.code),
                _buildTextField(_hsnCodeController, 'HSN Code', Icons.code),
         _buildTextField(_salePriceController, 'Sale Price (Incl. Tax)', Icons.attach_money, keyboardType: TextInputType.numberWithOptions(decimal: true)),
_buildTextField(_taxSaleController, 'Tax % on Sale Price', Icons.percent, keyboardType: TextInputType.number),
_buildTextField(_taxPurchaseController, 'Tax % on Purchase Price', Icons.percent, keyboardType: TextInputType.number),
_buildTextField(_purchasePriceController, 'Purchase Price (Incl. Tax)', Icons.attach_money, keyboardType: TextInputType.numberWithOptions(decimal: true)),

                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _addProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Product', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildTextField(
    TextEditingController controller, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text}) {
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


  Widget _buildDropdown(String label, String? selectedValue, Future<List<DropdownMenuItem<String>>> Function() fetchItems, Function(String?) onChanged) {
    return FutureBuilder<List<DropdownMenuItem<String>>>(
      future: fetchItems(),
      builder: (context, snapshot) {
    
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: DropdownButtonFormField<String>(
            value: selectedValue,
            items: snapshot.data,
            onChanged: onChanged,
            decoration: InputDecoration(
                filled: true,
          fillColor: Colors.grey[100],
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
    if (_selectedCategory == null) return [];
    final snapshot = await FirebaseFirestore.instance.collection('ProductSubCategoryMaster').where('ProductCategoryId', isEqualTo: _selectedCategory).get();
    return snapshot.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc['SubCategoryDesc']))).toList();
  }
}
