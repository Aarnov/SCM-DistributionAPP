import 'package:flutter/material.dart'; // For UI components like AlertDialog
import 'package:cloud_firestore/cloud_firestore.dart'; // For Firestore operations
import 'create_proforma_functions.dart'; // For showCustomerSelectionDialog

/// Shows an alert dialog with a message.
void showAlert({
  required BuildContext context,
  required String message,
  bool refresh = false,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close alert
              if (refresh) Navigator.pop(context); // Close edit page
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

/// Updates the expiry date based on the payment days.
DateTime updateExpiryDate({
  required DateTime proformaDate,
  required String paymentDays,
}) {
  int days = int.tryParse(paymentDays) ?? 0;
  return proformaDate.add(Duration(days: days));
}

/// Handles customer selection using the customer selection dialog.
void editCustomer({
  required BuildContext context,
  required Function(Map<String, dynamic>) onCustomerSelected,
}) {
  showCustomerSelectionDialog(
    context: context,
    searchController: TextEditingController(), // Temporary search controller
    addCustomer: (id, name, mobile, email, billingCity, billingState, billingCountry, shippingCity, shippingState, shippingCountry, pancard, gstNo) {
      onCustomerSelected({
        'id': id,
        'name': name,
        'mobile': mobile,
        'email': email,
        'billingCity': billingCity,
        'billingState': billingState,
        'billingCountry': billingCountry,
        'shippingCity': shippingCity,
        'shippingState': shippingState,
        'shippingCountry': shippingCountry,
        'pancard': pancard,
        'gstNo': gstNo,
      });
    },
    fetchCustomers: () {
      return FirebaseFirestore.instance
          .collection('PartyMaster')
          .where('PartyCategoryId', isEqualTo: 'Customer')
          .snapshots();
    },
    updateSearchQuery: (query) {
      // Handle search query updates if needed
    },
  );
}

/// Saves the edited proforma invoice to Firestore.
Future<void> saveEditedProformaInvoice({
  required BuildContext context,
  required String proformaNo,
  required DateTime proformaDate,
  required DateTime expiryDate,
  required String billDescription,
  required String paymentDays,
  required String additionalCharges,
  required String notes,
  required List<Map<String, dynamic>> selectedProducts,
  required List<Map<String, dynamic>> selectedCustomers,
}) async {
  if (selectedCustomers.isEmpty) {
    showAlert(context: context, message: "❌ Please select a customer!");
    return;
  }

  try {
    await FirebaseFirestore.instance.collection('ProformaMaster').doc(proformaNo).update({
      'Customers': selectedCustomers,
      'Products': selectedProducts,
      'BillDescription': billDescription.trim(),
      'ProformaDate': proformaDate,
      'ExpiryDate': expiryDate,
      'PaymentinDays': int.tryParse(paymentDays) ?? 30,
      'AdditionalCharges': double.tryParse(additionalCharges) ?? 0.0,
      'Notes': notes.trim(),
    });

    showAlert(context: context, message: "✅ Proforma Invoice Updated Successfully!", refresh: true);
  } catch (e) {
    print("Error updating Proforma Invoice: $e");
    showAlert(context: context, message: "❌ Error updating Proforma Invoice: $e");
  }
}

void updateProductCalculations({
  required int index,
  required List<Map<String, dynamic>> selectedProducts,
}) {
  var product = selectedProducts[index];

  // Ensure valid values
  double priceWithoutGST = (product['purchasePriceWithoutGST'] ?? 0.0).toDouble();
  int gstPercent = (product['gstPercent'] ?? 0).toInt();
  int quantity = (product['quantity'] ?? 1).toInt();

  // Calculate GST amount
  double gstAmount = (priceWithoutGST * gstPercent) / 100;

  // Calculate subtotal
  double subtotal = (priceWithoutGST + gstAmount) * quantity;

  // Update product details
  product['gstAmount'] = gstAmount;
  product['subtotal'] = subtotal;
}

void showProductSelectionDialog({
  required BuildContext context,
  required List<Map<String, dynamic>> selectedProducts,
  required Function(Map<String, dynamic>) onProductSelected,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          TextEditingController searchController = TextEditingController();
          String searchQuery = "";

          return AlertDialog(
            title: const Text("Select Product"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: "Search by Name or HSN Code",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setDialogState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 300,
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('ProductMaster').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var products = snapshot.data!.docs.where((doc) {
                        var name = doc['name'].toString().toLowerCase();
                        var hsn = doc['hsn'].toString().toLowerCase();
                        return name.contains(searchQuery) || hsn.contains(searchQuery);
                      }).toList();

                      if (products.isEmpty) {
                        return const Center(child: Text("No matching products"));
                      }

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var product = products[index];
                          return ListTile(
                            title: Text(product['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("HSN: ${product['hsn']}"),
                            trailing: const Icon(Icons.add, color: Colors.blue),
                            onTap: () {
                              onProductSelected({
                                'id': product.id,
                                'name': product['name'],
                                'hsn': product['hsn'],
                                'quantity': 1,
                                'purchasePriceWithoutGST': product['purchasePriceWithoutGST'] ?? 0.0,
                                'sellingPriceWithoutGST': product['sellingPriceWithoutGST'] ?? 0.0,
                                'gstPercent': product['gstPercent'] ?? 0,
                                'subtotal': 0.0,
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

