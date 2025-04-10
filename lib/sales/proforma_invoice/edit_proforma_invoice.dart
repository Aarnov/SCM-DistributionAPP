import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'edit_proforma_functions.dart'; // Import the new functions
import 'create_proforma_functions.dart'; // Import the customer selection dialog

class EditProformaInvoice extends StatefulWidget {
  final Map<String, dynamic> proformaData; // Pass existing data

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
  late List<Map<String, dynamic>> selectedProducts;
  late List<Map<String, dynamic>> selectedCustomers;

  @override
  void initState() {
    super.initState();
    // Initialize fields with existing data
    proformaNo = widget.proformaData['ProformaNo'];
    proformaDate = (widget.proformaData['ProformaDate'] as Timestamp).toDate();
    expiryDate = (widget.proformaData['ExpiryDate'] as Timestamp).toDate();
    selectedProducts = List<Map<String, dynamic>>.from(widget.proformaData['Products'] ?? []);
    selectedCustomers = List<Map<String, dynamic>>.from(widget.proformaData['Customers'] ?? []);

    _paymentDaysController = TextEditingController(text: widget.proformaData['PaymentinDays'].toString());
    _billDescriptionController = TextEditingController(text: widget.proformaData['BillDescription']);
    _notesController = TextEditingController(text: widget.proformaData['Notes']);
    _additionalChargesController = TextEditingController(text: widget.proformaData['AdditionalCharges'].toString());
  }

Future<List<Map<String, dynamic>>> _fetchProducts(String proformaNo) async {
  var snapshot = await FirebaseFirestore.instance
      .collection('ProformaBillItem')
      .where('ProformaNo', isEqualTo: proformaNo)
      .get();

  return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
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
              // Customer Section
              _buildCustomerSection(),

              const SizedBox(height: 16),

              // Invoice Details Section
              _buildInvoiceDetailsSection(),

              const SizedBox(height: 16),

              // Products Section
              _buildProductsSection(),

              const SizedBox(height: 16),

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('ProformaMaster').doc(proformaNo).update({
                    'Products': selectedProducts,
                  });
                  saveEditedProformaInvoice(
                    context: context,
                    proformaNo: proformaNo,
                    proformaDate: proformaDate,
                    expiryDate: expiryDate,
                    billDescription: _billDescriptionController.text,
                    paymentDays: _paymentDaysController.text,
                    additionalCharges: _additionalChargesController.text,
                    notes: _notesController.text,
                    selectedProducts: selectedProducts,
                    selectedCustomers: selectedCustomers,
                  );
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

            selectedCustomers.isEmpty
                ? const Center(
                    child: Text(
                      "No customer selected",
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  )
                : Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text(
                            selectedCustomers[0]['name']![0].toUpperCase(),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          selectedCustomers[0]['name']!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                          onPressed: () => setState(() => selectedCustomers.clear()),
                        ),
                      ),
                    ],
                  ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton.icon(
                onPressed: () {
                  editCustomer(
                    context: context,
                    onCustomerSelected: (customer) {
                      setState(() {
                        selectedCustomers = [customer];
                      });
                    },
                  );
                },
                icon: const Icon(Icons.person_add, color: Colors.black),
                label: const Text("Choose Customer",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
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
                  expiryDate = updateExpiryDate(
                    proformaDate: proformaDate,
                    paymentDays: value,
                  );
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
                  showProductSelectionDialog(
                    context: context,
                    selectedProducts: selectedProducts,
                    onProductSelected: (product) {
                      setState(() {
                        int index = selectedProducts.indexWhere((item) => item['id'] == product['id']);
                        if (index != -1) {
                          // Product already exists, update quantity
                          selectedProducts[index]['quantity'] += product['quantity'];
                        } else {
                          // Add new product
                          selectedProducts.add(product);
                        }
                      });
                    },
                  );
                },
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text("Add Product",
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
          DataColumn(label: Text("GST Amount")),
          DataColumn(label: Text("Selling Price With GST")),
          DataColumn(label: Text("Subtotal")),
          DataColumn(label: Text("Actions")),
        ],
        rows: products.map((product) {
          return DataRow(
            cells: [
              DataCell(Text(product['ProductId'] ?? '')),
              DataCell(Text(product['Quantity'].toString())),
              DataCell(Text("₹${product['PriceWithoutGST']?.toStringAsFixed(2) ?? '0.00'}")),
              DataCell(Text("${product['GSTPercent']}%")),
              DataCell(Text("₹${product['GSTAmount']?.toStringAsFixed(2) ?? '0.00'}")),
              DataCell(Text("₹${product['SellingPriceWithGST']?.toStringAsFixed(2) ?? '0.00'}")),
              DataCell(Text("₹${product['Subtotal']?.toStringAsFixed(2) ?? '0.00'}")),
              DataCell(
                IconButton(
                  icon: const Icon(Icons.visibility, color: Colors.blue),
                  onPressed: () async {
                    String proformaNo = product['ProformaNo'];
                    List<Map<String, dynamic>> products = await fetchProducts(proformaNo);

                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text("Products for Proforma No: $proformaNo"),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: _buildProductTable(products),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Close"),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}