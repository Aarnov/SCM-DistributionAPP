import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditCustomerPage extends StatefulWidget {
  final QueryDocumentSnapshot customer;

  const EditCustomerPage({super.key, required this.customer});

  @override
  _EditCustomerPageState createState() => _EditCustomerPageState();
}

class _EditCustomerPageState extends State<EditCustomerPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _partyNameController;
  late TextEditingController _mobileNoController;
  late TextEditingController _emailController;
  late TextEditingController _billingAddressController;
  late TextEditingController _billingLandmarkController;
  late TextEditingController _billingVillageCityController;
  late TextEditingController _billingDistrictController;
  late TextEditingController _billingStateController;
  late TextEditingController _billingCountryController;
  late TextEditingController _shippingAddressController;
  late TextEditingController _shippingLandmarkController;
  late TextEditingController _shippingVillageCityController;
  late TextEditingController _shippingDistrictController;
  late TextEditingController _shippingStateController;
  late TextEditingController _shippingCountryController;
  late TextEditingController _pancardController;
  late TextEditingController _gstNoController;

  @override
  void initState() {
    super.initState();
    var data = widget.customer.data() as Map<String, dynamic>;

    _partyNameController = TextEditingController(text: data['PartyName']);
    _mobileNoController = TextEditingController(text: data['MobileNo']);
    _emailController = TextEditingController(text: data['Email']);
    _billingAddressController = TextEditingController(text: data['BillingAddress']);
    _billingLandmarkController = TextEditingController(text: data['BillingLandMark']);
    _billingVillageCityController = TextEditingController(text: data['BillingVillageCity']);
    _billingDistrictController = TextEditingController(text: data['BillingDistrict']);
    _billingStateController = TextEditingController(text: data['BillingState']);
    _billingCountryController = TextEditingController(text: data['BillingCountry']);
    _shippingAddressController = TextEditingController(text: data['ShippingAddress']);
    _shippingLandmarkController = TextEditingController(text: data['ShippingLandmark']);
    _shippingVillageCityController = TextEditingController(text: data['ShippingVillageCity']);
    _shippingDistrictController = TextEditingController(text: data['ShippingDistrict']);
    _shippingStateController = TextEditingController(text: data['ShippingState']);
    _shippingCountryController = TextEditingController(text: data['ShippingCountry']);
    _pancardController = TextEditingController(text: data['Pancard']);
    _gstNoController = TextEditingController(text: data['gstNo']);
  }

  void _updateCustomer() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance
          .collection('PartyMaster')
          .doc(widget.customer.id)
          .update({
        'PartyName': _partyNameController.text,
        'MobileNo': _mobileNoController.text,
        'Email': _emailController.text,
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
        'Pancard': _pancardController.text,
        'gstNo': _gstNoController.text,
      });

      Navigator.pop(context); // Close Edit Page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
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
           ElevatedButton(
                  onPressed: _updateCustomer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Update Customer',
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


  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
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
          if (label == 'Email' && !value.contains('@')) return 'Please enter a valid email';
          return null;
        },
      ),
    );
  }
}
