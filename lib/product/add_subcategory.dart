import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductSubCategoryPage extends StatefulWidget {
  const AddProductSubCategoryPage({super.key, required String categoryId});

  @override
  _AddProductSubCategoryPageState createState() => _AddProductSubCategoryPageState();
}

class _AddProductSubCategoryPageState extends State<AddProductSubCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subCategoryNameController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  List<DropdownMenuItem<String>> _categoryItems = [];

  void _fetchCategories() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('ProductCategoryMaster').get();

    setState(() {
      _categoryItems = querySnapshot.docs
          .map((doc) => DropdownMenuItem(
                value: doc.id,
                child: Text(doc['CategoryDesc']),
              ))
          .toList();
    });
  }

  void _addSubCategory() async {
    if (_formKey.currentState!.validate() && _selectedCategoryId != null) {
      await FirebaseFirestore.instance.collection('ProductSubCategoryMaster').add({
        'ProductCategoryId': _selectedCategoryId,
        'SubCategoryDesc': _subCategoryNameController.text,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product Subcategory')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                items: _categoryItems,
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                  });
                },
                decoration: InputDecoration(
                   filled: true,
          fillColor: Colors.grey[100],
                  labelText: 'Select Category',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _subCategoryNameController,
                decoration: InputDecoration(
                   filled: true,
          fillColor: Colors.grey[100],
                  labelText: 'Subcategory Name',
                  prefixIcon: const Icon(Icons.subdirectory_arrow_right),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a subcategory name' : null,
              ),
              const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _addSubCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Sub Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
