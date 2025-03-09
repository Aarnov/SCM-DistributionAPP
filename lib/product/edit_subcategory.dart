import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSubCategoryPage extends StatefulWidget {
  final QueryDocumentSnapshot subCategory;

  const EditSubCategoryPage({super.key, required this.subCategory});

  @override
  _EditSubCategoryPageState createState() => _EditSubCategoryPageState();
}

class _EditSubCategoryPageState extends State<EditSubCategoryPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _subCategoryNameController;

  @override
  void initState() {
    super.initState();
    var data = widget.subCategory.data() as Map<String, dynamic>;
    _subCategoryNameController = TextEditingController(text: data['SubCategoryDesc']);
  }

  void _updateSubCategory() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('ProductSubCategoryMaster')
          .doc(widget.subCategory.id)
          .update({
        'SubCategoryDesc': _subCategoryNameController.text,
      });

      Navigator.pop(context); // Close Edit Page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Subcategory'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader('Subcategory Information'),
              _buildTextField(_subCategoryNameController, 'Subcategory Name', Icons.category),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _updateSubCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Update Subcategory',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          return null;
        },
      ),
    );
  }
}
