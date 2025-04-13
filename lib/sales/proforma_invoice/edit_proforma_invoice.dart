import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:distribution_management/sales/proforma_invoice/create_proforma_functions.dart';
import 'package:distribution_management/sales/proforma_invoice/edit_proforma_functions.dart';

class EditProformaInvoice extends StatefulWidget {
  final Map<String, dynamic> proformaData;

  const EditProformaInvoice({super.key, required this.proformaData});

  @override
  State<EditProformaInvoice> createState() => _EditProformaInvoiceState();
}

class _EditProformaInvoiceState extends State<EditProformaInvoice> {
  late TextEditingController _paymentDaysController;
  late TextEditingController _billDescriptionController;
  late TextEditingController _notesController;
  late TextEditingController _additionalChargesController;

  late String proformaNo;
  late DateTime proformaDate;
  late DateTime expiryDate;
  late List<Map<String, dynamic>> selectedProducts = [];

  Map<String, dynamic>? selectedCustomer;
  Map<String, dynamic>? customerDetails;

  @override
  void initState() {
    super.initState();
    proformaNo = widget.proformaData['ProformaNo'];
    proformaDate = (widget.proformaData['ProformaDate'] as Timestamp).toDate();
    expiryDate = (widget.proformaData['ExpiryDate'] as Timestamp).toDate();

    // Fetch products for the given ProformaNo
    _fetchProducts(proformaNo).then((products) {
      setState(() {
        selectedProducts = products;
      });
    });

    // Fetch customer details using PartyId
    if (widget.proformaData['PartyId'] != null) {
      _fetchCustomerDetails(widget.proformaData['PartyId']);
    }

    _paymentDaysController = TextEditingController(text: widget.proformaData['PaymentinDays'].toString());
    _billDescriptionController = TextEditingController(text: widget.proformaData['BillDescription']);
    _notesController = TextEditingController(text: widget.proformaData['Notes']);
    _additionalChargesController = TextEditingController(text: widget.proformaData['AdditionalCharges'].toString());
  }

  Future<List<Map<String, dynamic>>> _fetchProducts(String proformaNo) async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('ProformaBillItem')
          .where('ProformaNo', isEqualTo: proformaNo)
          .get();

      var products = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return {
          'ProductId': data['ProductId'] ?? 'N/A',
          'Quantity': data['Quantity'] ?? 0,
          'PriceWithoutGST': data['PriceWithoutGST'] ?? 0.0,
          'GSTPercent': data['GSTPercent'] ?? 0,
          'Subtotal': data['Subtotal'] ?? 0.0,
        };
      }).toList();

      print("Fetched Products: $products");
      return products;
    } catch (e) {
      print("Error fetching products: $e");
      return [];
    }
  }

  Future<void> _fetchCustomerDetails(String partyId) async {
    try {
      var customerSnapshot = await FirebaseFirestore.instance
          .collection('PartyMaster')
          .doc(partyId)
          .get();

      if (customerSnapshot.exists) {
        setState(() {
          selectedCustomer = {
            'PartyId': partyId,
            'PartyName': customerSnapshot.data()?['PartyName'] ?? 'N/A',
            'MobileNo': customerSnapshot.data()?['MobileNo'] ?? 'N/A',
            'Email': customerSnapshot.data()?['Email'] ?? 'N/A',
            'BillingVillageCity': customerSnapshot.data()?['BillingVillageCity'] ?? 'Unknown',
            'BillingState': customerSnapshot.data()?['BillingState'] ?? 'Unknown',
            'BillingCountry': customerSnapshot.data()?['BillingCountry'] ?? 'Unknown',
          };
          customerDetails = selectedCustomer;
        });
        print("Customer Details: $customerDetails");
      } else {
        print("Customer not found for PartyId: $partyId");
      }
    } catch (e) {
      print("Error fetching customer details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Proforma Invoice"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCustomerSection(),
              const SizedBox(height: 16),
              _buildInvoiceDetailsSection(),
              const SizedBox(height: 16),
              _buildProductsSection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Ensure a customer is selected
                    if (selectedCustomer == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please select a customer before saving!")),
                      );
                      return;
                    }

                    // Save changes to Firestore
                    await FirebaseFirestore.instance.collection('ProformaMaster').doc(proformaNo).update({
                      'ProformaDate': proformaDate,
                      'ExpiryDate': expiryDate,
                      'BillDescription': _billDescriptionController.text.trim(),
                      'PaymentinDays': int.tryParse(_paymentDaysController.text) ?? 0,
                      'AdditionalCharges': double.tryParse(_additionalChargesController.text) ?? 0.0,
                      'Notes': _notesController.text.trim(),
                      'PartyId': selectedCustomer!['PartyId'], // Update PartyId
                    });

                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Proforma Invoice updated successfully!")),
                    );

      
                  } catch (e) {
                    print("Error updating Proforma Invoice: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error updating Proforma Invoice: $e")),
                    );
                  }
                },
                child: const Text("Save Changes"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.group, size: 20),
                SizedBox(width: 8),
                Text("Bill To", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            customerDetails == null
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text(
                            (customerDetails!['PartyName'] ?? 'N/A')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          customerDetails!['PartyName'] ?? 'N/A',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mobile: ${customerDetails!['MobileNo'] ?? 'N/A'}"),
                            Text("Email: ${customerDetails!['Email'] ?? 'N/A'}"),
                            Text("City: ${customerDetails!['BillingVillageCity'] ?? 'Unknown'}"),
                            Text("State: ${customerDetails!['BillingState'] ?? 'Unknown'}"),
                            Text("Country: ${customerDetails!['BillingCountry'] ?? 'Unknown'}"),
                          ],
                        ),
                      ),
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            editCustomer(
                              context: context,
                              proformaNo: proformaNo,
                              onCustomerSelected: (customer) {
                                setState(() {
                                  selectedCustomer = customer;
                                  customerDetails = customer;
                                });
                              },
                            );
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text("Edit Customer"),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Invoice Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _billDescriptionController,
              decoration: const InputDecoration(labelText: "Bill Description"),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _paymentDaysController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Payment Terms (Days)"),
              onChanged: (value) {
                setState(() {
                  expiryDate = proformaDate.add(Duration(days: int.tryParse(value) ?? 0));
                });
              },
            ),
            const SizedBox(height: 8),
            Text("Expiry Date: ${DateFormat('dd MMM yyyy').format(expiryDate)}"),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.inventory, size: 20),
                SizedBox(width: 8),
                Text("Products", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            selectedProducts.isEmpty
                ? const Center(
                    child: Text("No products selected", style: TextStyle(color: Colors.grey)),
                  )
                : _buildProductTable(selectedProducts),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: () {
                  // Add product selection logic here
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  "Add Product",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTable(List<Map<String, dynamic>> products) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        border: TableBorder.all(color: Colors.grey.shade300),
        columns: const [
          DataColumn(label: Text("Product ID")),
          DataColumn(label: Text("Quantity")),
          DataColumn(label: Text("Price Without GST")),
          DataColumn(label: Text("GST %")),
          DataColumn(label: Text("Subtotal")),
        ],
        rows: products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(product['ProductId'] ?? 'N/A')),
              DataCell(Text(product['Quantity']?.toString() ?? '0')),
              DataCell(Text("₹${product['PriceWithoutGST']?.toStringAsFixed(2) ?? '0.00'}")),
              DataCell(Text("${product['GSTPercent']?.toString() ?? '0'}%")),
              DataCell(Text("₹${product['Subtotal']?.toStringAsFixed(2) ?? '0.00'}")),
            ],
          );
        }).toList(),
      ),
    );
  }
}
