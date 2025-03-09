import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSupplierPage extends StatefulWidget {
  const AddSupplierPage({super.key});

  @override
  _AddSupplierPageState createState() => _AddSupplierPageState();
}

class _AddSupplierPageState extends State<AddSupplierPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _partyNameController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _billingLandmarkController = TextEditingController();
  final TextEditingController _billingVillageCityController = TextEditingController();
  final TextEditingController _billingDistrictController = TextEditingController();
  final TextEditingController _billingStateController = TextEditingController();
  final TextEditingController _billingCountryController = TextEditingController();
  final TextEditingController _shippingAddressController = TextEditingController();
  final TextEditingController _shippingLandmarkController = TextEditingController();
  final TextEditingController _shippingVillageCityController = TextEditingController();
  final TextEditingController _shippingDistrictController = TextEditingController();
  final TextEditingController _shippingStateController = TextEditingController();
  final TextEditingController _shippingCountryController = TextEditingController();
  final TextEditingController _mobileNoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _pancardController = TextEditingController();
  final TextEditingController _gstNoController = TextEditingController();

  // PartyCategoryId is set to "Supplier" by default
  final String _partyCategoryId = "Supplier";

  void _addSupplier() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection('PartyMaster').add({
        'PartyName': _partyNameController.text,
        'PartyCategoryId': _partyCategoryId,
        'BillingAddress': _billingAddressController.text,
        'BillingLandMark': _billingLandmarkController.text,
        'BillingVillageCity': _billingVillageCityController.text,
        'BillingDistrict': _billingDistrictController.text,
        'BillingState': _billingStateController.text,
        'BillingCountry': _billingCountryController.text,
        'ShippingAddress': _shippingAddressController.text,
        'ShippingLandmark': _shippingLandmarkController.text,
        'ShippingVillageCity': _shippingVillageCityController.text,
        'ShippingDistrict': _shippingDistrictController.text,
        'ShippingState': _shippingStateController.text,
        'ShippingCountry': _shippingCountryController.text,
        'MobileNo': _mobileNoController.text,
        'Email': _emailController.text,
        'Pancard': _pancardController.text,
        'gstNo': _gstNoController.text,
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Supplier'),
        elevation: 0,
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Party Name
                _buildTextField(_partyNameController, 'Party Name', Icons.person),
            

                     // Contact Information
                _buildSectionHeader('Contact Information'),
                _buildTextField(_mobileNoController, 'Mobile Number', Icons.phone, keyboardType: TextInputType.phone),
                _buildTextField(_emailController, 'Email', Icons.email, keyboardType: TextInputType.emailAddress),

                

                // Billing Address Section
                _buildSectionHeader('Billing Address'),
                _buildTextField(_billingAddressController, 'Address', Icons.location_on),
                _buildTextField(_billingLandmarkController, 'Landmark', Icons.landscape),
                _buildTextField(_billingVillageCityController, 'City/Village', Icons.location_city),
                _buildTextField(_billingDistrictController, 'District', Icons.map),
                _buildTextField(_billingStateController, 'State', Icons.flag),
                _buildTextField(_billingCountryController, 'Country', Icons.public),
         

                // Shipping Address Section
                _buildSectionHeader('Shipping Address'),
                _buildTextField(_shippingAddressController, 'Address', Icons.location_on),
                _buildTextField(_shippingLandmarkController, 'Landmark', Icons.landscape),
                _buildTextField(_shippingVillageCityController, 'City/Village', Icons.location_city),
                _buildTextField(_shippingDistrictController, 'District', Icons.map),
                _buildTextField(_shippingStateController, 'State', Icons.flag),
                _buildTextField(_shippingCountryController, 'Country', Icons.public),
             

           

                // Tax Information
                _buildSectionHeader('Tax Information'),
                _buildTextField(_pancardController, 'Pancard Number', Icons.credit_card),
                _buildTextField(_gstNoController, 'GST Number', Icons.receipt),
                const SizedBox(height: 12),

                // Submit Button
                ElevatedButton(
                  onPressed: _addSupplier,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Supplier',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
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
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blueAccent,
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blueAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16.0,
            horizontal: 20.0,
          ),
        ),
        style: TextStyle(
          color: Colors.grey[900],
          fontSize: 16.0,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          if (label == 'Email' && !value.contains('@')) {
            return 'Please enter a valid email';
          }
          if (label == 'Mobile Number' && value.length != 10) {
            return 'Please enter a valid 10-digit mobile number';
          }
          return null;
        },
      ),
    );
  }
}