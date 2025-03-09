import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductCategoryPage extends StatefulWidget {
  const AddProductCategoryPage({super.key});

  @override
  _AddProductCategoryPageState createState() => _AddProductCategoryPageState();
}

class _AddProductCategoryPageState extends State<AddProductCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryNameController = TextEditingController();

  void _addCategory() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('ProductCategoryMaster').add({
        'CategoryDesc': _categoryNameController.text,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Product Category'),backgroundColor: Colors.blueAccent),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _categoryNameController,
                decoration: InputDecoration(
                    filled: true,
          fillColor: Colors.grey[100],
                  labelText: 'Category Name',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a category name' : null,
              ),
              const SizedBox(height: 16),
               ElevatedButton(
                  onPressed: _addCategory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
      
    );
  }
}
