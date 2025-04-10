import 'package:distribution_management/sales/proforma_invoice/add_product_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'create_proforma_functions.dart';

class CreateProformaInvoice extends StatefulWidget {
  const CreateProformaInvoice({super.key});

  @override
  State<CreateProformaInvoice> createState() => _CreateProformaInvoiceState();
}

class _CreateProformaInvoiceState extends State<CreateProformaInvoice> {
  List<Map<String, String>> selectedCustomers = [];
  final TextEditingController _searchCustomerController =
      TextEditingController();
  final TextEditingController _paymentDaysController =
      TextEditingController(text: "30");
  String searchQuery = "";
  String proformaNo = "";
  DateTime proformaDate = DateTime.now();
  DateTime expiryDate = DateTime.now().add(const Duration(days: 30));
  List<Map<String, dynamic>> selectedProducts = [];
  final TextEditingController _billDescriptionController =
      TextEditingController();
  final TextEditingController _notesController = TextEditingController();

// Controller for Additional Charges
  final TextEditingController _additionalChargesController =
      TextEditingController(text: "0");

  @override
  void initState() {
    super.initState();
    _generateProformaNumber();
  }

  void _generateProformaNumber() {
    setState(() {
      proformaNo =
          "PRO-${DateTime.now().millisecondsSinceEpoch % 100000}"; // Example: PRO-54321
    });
  }

  Stream<QuerySnapshot> _fetchCustomers() {
    return FirebaseFirestore.instance
        .collection('PartyMaster')
        .where('PartyCategoryId', isEqualTo: 'Customer')
        .snapshots();
  }

// Usage
  void _showCustomerSelectionDialog() {
    showCustomerSelectionDialog(
      context: context,
      searchController: _searchCustomerController,
      addCustomer: _addCustomer,
      fetchCustomers: _fetchCustomers,
      updateSearchQuery: (query) {
        setState(() {
          searchQuery = query;
        });
      },
    );
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AddProductDialog(
          selectedProducts: selectedProducts,
          onProductSelected: (product) {
            setState(() {
              int index = selectedProducts
                  .indexWhere((item) => item['id'] == product['id']);

              if (index != -1) {
                // Product already exists, update quantity
                selectedProducts[index] = {
                  ...selectedProducts[index],
                  'quantity':
                      selectedProducts[index]['quantity'] + product['quantity'],
                };
              } else {
                // Add new product
                selectedProducts.add(product);
                index = selectedProducts.length - 1;
              }

              // ✅ Immediately update calculations after adding product
              _updateProductCalculations(index);
            });
          },
        );
      },
    ).then((_) {
      setState(() {}); // Ensure UI updates after dialog closes
    });
  }

  double _calculateTotal() {
    double additionalCharges =
        double.tryParse(_additionalChargesController.text) ?? 0.0;
    double productTotal = selectedProducts.fold<double>(
        0, (sum, item) => sum + ((item['subtotal'] ?? 0).toDouble()));
    return productTotal + additionalCharges;
  }

  void _showAlert(String message, {bool refresh = false}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close alert
                if (refresh) {
                  setState(() {
                    selectedCustomers.clear();
                    selectedProducts.clear();
                    _paymentDaysController.text = "30";
                    _additionalChargesController.text = "0";
                    proformaNo =
                        "PRO-${DateTime.now().millisecondsSinceEpoch % 100000}";
                  });
                }
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _addCustomer(
      String id,
      String name,
      String mobile,
      String email,
      String billingCity,
      String billingState,
      String billingCountry,
      String shippingCity,
      String shippingState,
      String shippingCountry,
      String pancard,
      String gstNo) {
    setState(() {
      selectedCustomers = [
        {
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
        }
      ]; // Ensures only one customer is selected at a time
    });
  }

  void _removeCustomer() {
    setState(() {
      selectedCustomers.clear();
    });
  }

  void _updateExpiryDate() {
    int days = int.tryParse(_paymentDaysController.text) ?? 0;
    setState(() {
      expiryDate = proformaDate.add(Duration(days: days));
    });
  }

// Header Row Styling (Light Gray)
  Widget _buildHeader(String text) {
    return Container(
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

// Editable Fields (Regular Text)
  Widget _buildEditableField(
      int index, String key, String value, TextInputType inputType) {
    return SizedBox(
      width: 80,
      child: TextFormField(
        controller: TextEditingController(text: value),
        keyboardType: inputType,
        textAlign: TextAlign.center,
        onChanged: (newValue) {
          setState(() {
            selectedProducts[index][key] = inputType == TextInputType.number
                ? double.tryParse(newValue) ?? 0.0
                : newValue;
            _updateProductCalculations(index);
          });
        },
      ),
    );
  }

// Derived (Read-Only) Fields (Light Blue)
  Widget _buildDerivedValue(String value) {
    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

// Discount Dropdown
  Widget _buildDropdown(int index, String key, String currentValue) {
    return DropdownButton<String>(
      value: currentValue,
      onChanged: (value) {
        setState(() {
          selectedProducts[index][key] = value!;
          _updateProductCalculations(index);
        });
      },
      items: ["%", "₹"].map((unit) {
        return DropdownMenuItem(value: unit, child: Text(unit));
      }).toList(),
    );
  }

  void _updateProductCalculations(int index) {
    var product = selectedProducts[index];

    // Ensure valid values
    double purchasePriceWithoutGST =
        (product['purchasePriceWithoutGST'] ?? 0.0).toDouble();
    double sellingPriceWithoutGST =
        (product['sellingPriceWithoutGST'] ?? 0.0).toDouble(); // User input
    int gstPercent = (product['gstPercent'] ?? 0).toInt();
    double saleDiscount = (product['saleDiscount'] ?? 0.0).toDouble();
    String saleDiscountUnit = product['saleDiscountUnit'] ?? "%";
    int quantity = (product['quantity'] ?? 1).toInt();

    // ✅ Step 1: Calculate Purchase Price With GST
    double purchasePriceWithGST =
        purchasePriceWithoutGST * (1 + gstPercent / 100);
    product['purchasePriceWithGST'] = purchasePriceWithGST;

    // ✅ Step 2: Calculate Discount Amount Per Unit
    double discountAmountPerUnit = (saleDiscountUnit == "%")
        ? (sellingPriceWithoutGST * saleDiscount / 100) // % discount
        : saleDiscount; // ₹ discount
    product['discountAmount'] = discountAmountPerUnit;

    // ✅ Step 3: Calculate Selling Price After Discount (Before GST)
    double sellingPriceAfterDiscount =
        sellingPriceWithoutGST - discountAmountPerUnit;

    // ✅ Step 4: Calculate GST Amount for Each Item
    double gstAmountPerUnit = (sellingPriceAfterDiscount * gstPercent) / 100;
    double totalGSTAmount = gstAmountPerUnit * quantity;
    product['gstAmount'] = totalGSTAmount; // Store total GST amount

    // ✅ Step 5: Calculate Selling Price With GST
    double sellingPriceWithGST = sellingPriceAfterDiscount + gstAmountPerUnit;
    product['sellingPriceWithGST'] = sellingPriceWithGST;

    // ✅ Step 6: Calculate Subtotal (Total Amount for Selected Quantity)
    double subtotal = sellingPriceWithGST * quantity;
    product['subtotal'] = subtotal;

    // ✅ Refresh UI
    setState(() {});
  }

  Future<void> _saveProformaInvoice(String billStatus) async {
    if (selectedCustomers.isEmpty) {
      _showAlert("❌ Please select a customer!");
      return;
    }

    String partyId = selectedCustomers[0]['id']!;
    double billAmountWithoutGST = selectedProducts.fold<double>(
        0, (sum, item) => sum + ((item['subtotal'] ?? 0).toDouble()));
    double gstAmount = selectedProducts.fold<double>(
        0, (sum, item) => sum + ((item['gstAmount'] ?? 0).toDouble()));
    double additionalCharges =
        double.tryParse(_additionalChargesController.text) ?? 0.0;

    String billDescription = _billDescriptionController.text.trim();
    String notes = _notesController.text.trim();

    try {
      // ✅ Save ProformaMaster
      await FirebaseFirestore.instance
          .collection('ProformaMaster')
          .doc(proformaNo)
          .set({
        'ProformaNo': proformaNo,
        'BillDescription': billDescription,
        'ProformaDate': proformaDate,
        'PartyId': partyId,
        'BillAmountwithoutGST': billAmountWithoutGST,
        'GSTAmount': gstAmount,
        'AdditionalCharges': additionalCharges,
        'PaymentinDays': int.tryParse(_paymentDaysController.text) ?? 30,
        'ExpiryDate': expiryDate,
        'Notes': notes,
        'BillStatus': billStatus, // "Final" or "Draft"
      });

      // ✅ Save ProformaBillItem for each product
      for (var product in selectedProducts) {
        await FirebaseFirestore.instance.collection('ProformaBillItem').add({
          'ProformaNo': proformaNo,
          'ItemNo': product['id'], // ✅ Use Product ID as ItemNo
          'ProductId': product['id'],
          'Quantity': product['quantity'],
          'PriceWithoutGST': product['purchasePriceWithoutGST'],
          'GSTPercent': product['gstPercent'],
          'GSTAmount': product['gstAmount'], // ✅ Store calculated GST Amount
          'SaleDiscount': product['saleDiscount'],
          'SaleDiscountUnit': product['saleDiscountUnit'],
          'DistMargin': 0.0, // If applicable
          'DistMarginUnit': '%',
          'SellingPriceWithGST': product['sellingPriceWithGST'],
          'MRPWithGST': product['mrpWithGST'],
        });
      }

      // ✅ Show success alert and reload the page
      _showSuccessAndReload("✅ Proforma Invoice Saved Successfully!");
    } catch (e) {
      _showAlert("❌ Error saving Proforma Invoice: $e");
    }
  }

  void _showSuccessAndReload(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close alert

                // ✅ Reload the page by replacing the current route
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CreateProformaInvoice()),
                );
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Proforma Invoice"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap both cards inside IntrinsicHeight to match their height
                  Expanded(
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title
                                    const Row(
                                      children: [
                                        Icon(Icons.group, size: 20),
                                        SizedBox(width: 8),
                                        Text("Bill To",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Customer Details or No Selection Message

                                    Expanded(
                                      child: selectedCustomers.isEmpty
                                          ? const Center(
                                              child: Text(
                                                "No customer selected",
                                                style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            )
                                          : Column(
                                              children: [
                                                ListTile(
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 12,
                                                          vertical: 8),
                                                  leading: CircleAvatar(
                                                    radius: 24,
                                                    backgroundColor: Colors
                                                        .blueAccent
                                                        .withOpacity(0.2),
                                                    child: Text(
                                                      selectedCustomers[0]
                                                              ['name']![0]
                                                          .toUpperCase(),
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  title: Text(
                                                    selectedCustomers[0]
                                                        ['name']!,
                                                    style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                  trailing: IconButton(
                                                    icon: const Icon(
                                                        Icons.close,
                                                        size: 18,
                                                        color:
                                                            Colors.redAccent),
                                                    onPressed: _removeCustomer,
                                                  ),
                                                ),

                                                // Divider for Separation
                                                const Divider(),

                                                // Customer Info Section
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 12,
                                                      vertical: 4),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Mobile
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.phone,
                                                              size: 16,
                                                              color:
                                                                  Colors.blue),
                                                          const SizedBox(
                                                              width: 6),
                                                          Text(
                                                            selectedCustomers[0]
                                                                ['mobile']!,
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        14),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),

                                                      // Email
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.email,
                                                              size: 16,
                                                              color:
                                                                  Colors.green),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              selectedCustomers[
                                                                  0]['email']!,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // PAN Card
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons.credit_card,
                                                              size: 16,
                                                              color: Colors
                                                                  .purple),
                                                          const SizedBox(
                                                              width: 6),
                                                          const Text("PAN: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Expanded(
                                                            child: Text(
                                                              selectedCustomers[
                                                                      0]
                                                                  ['pancard']!,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // GST Number
                                                      Row(
                                                        children: [
                                                          const Icon(
                                                              Icons
                                                                  .receipt_long,
                                                              size: 16,
                                                              color: Colors
                                                                  .orange),
                                                          const SizedBox(
                                                              width: 6),
                                                          const Text("GST No: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          Expanded(
                                                            child: Text(
                                                              selectedCustomers[
                                                                  0]['gstNo']!,
                                                              style:
                                                                  const TextStyle(
                                                                      fontSize:
                                                                          14),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // Billing Location
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              "Billing Location: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              "${selectedCustomers[0]['billingCity']}, "
                                                              "${selectedCustomers[0]['billingState']}, "
                                                              "${selectedCustomers[0]['billingCountry']}",
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade700),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),

                                                      // Shipping Location
                                                      Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          const Text(
                                                              "Shipping Location: ",
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                          const SizedBox(
                                                              width: 6),
                                                          Expanded(
                                                            child: Text(
                                                              "${selectedCustomers[0]['shippingCity']}, "
                                                              "${selectedCustomers[0]['shippingState']}, "
                                                              "${selectedCustomers[0]['shippingCountry']}",
                                                              style: TextStyle(
                                                                  fontSize: 14,
                                                                  color: Colors
                                                                      .grey
                                                                      .shade700),
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Choose Customer Button
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.black,
                                            style: BorderStyle.solid),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: TextButton.icon(
                                        onPressed: _showCustomerSelectionDialog,
                                        icon: const Icon(Icons.person_add,
                                            color: Colors.black),
                                        label: const Text("Choose Customer",
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Invoice Details Section
                          Expanded(
                            flex: 1,
                            child: Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.receipt, size: 20),
                                        SizedBox(width: 8),
                                        Text("Invoice Details",
                                            style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    _buildDetailRow("Proforma No:", proformaNo),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                        "Date:",
                                        DateFormat('dd MMM yyyy')
                                            .format(proformaDate)),
                                    const SizedBox(height: 16),

                                    // Bill Description Field
                                    TextField(
                                      controller:
                                          _billDescriptionController, // ✅ Attach controller
                                      decoration: const InputDecoration(
                                        labelText: "Bill Description",
                                        border: OutlineInputBorder(),
                                      ),
                                      maxLines: 2,
                                    ),

                                    const SizedBox(height: 16),

                                    // Payment Terms Field
                                    TextField(
                                      controller: _paymentDaysController,
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        labelText: "Payment Terms (Days)",
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_month),
                                      ),
                                      onChanged: (value) => _updateExpiryDate(),
                                    ),
                                    const SizedBox(height: 16),

                                    _buildDetailRow(
                                        "Expiry Date:",
                                        DateFormat('dd MMM yyyy')
                                            .format(expiryDate)),
                                    const SizedBox(height: 16),
                                    const Spacer(),

                                    // Save Buttons
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.black),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _saveProformaInvoice("Final"),
                                              icon: const Icon(Icons.save,
                                                  color: Colors.black),
                                              label: const Text("Save Proforma",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.blueAccent),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: TextButton.icon(
                                              onPressed: () =>
                                                  _saveProformaInvoice("Draft"),
                                              icon: const Icon(Icons.edit,
                                                  color: Colors.black),
                                              label: const Text("Save Draft",
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Products Section
              // Products Section
              Card(
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
                          Text("Products",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      selectedProducts.isEmpty
                          ? const Center(
                              child: Text("No products selected",
                                  style: TextStyle(color: Colors.grey)),
                            )
                          : SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                border: TableBorder.all(
                                    color: Colors.grey.shade300),
                                columns: [
                                  DataColumn(label: _buildHeader("ProductID")),
                                  DataColumn(label: _buildHeader("Name")),
                                  DataColumn(label: _buildHeader("HSN Code")),
                                  DataColumn(label: _buildHeader("Quantity")),
                                  DataColumn(
                                      label: _buildHeader(
                                          "Purchase Price Without GST")),
                                  DataColumn(
                                      label: _buildHeader(
                                          "Selling Price Without GST")),
                                  DataColumn(
                                      label: _buildHeader("MRP with Gst")),
                                  DataColumn(label: _buildHeader("GST %")),
                                  DataColumn(
                                      label: _buildHeader("Sale Discount")),
                                  DataColumn(
                                      label: _buildHeader("Discount Unit")),
                                  DataColumn(
                                      label: _buildHeader(
                                          "Purchase Price With GST")),
                                  DataColumn(
                                      label: _buildHeader(
                                          "Selling Price With GST")),
                                  DataColumn(label: _buildHeader("Subtotal")),
                                  DataColumn(label: _buildHeader("Actions")),
                                ],
                                rows: selectedProducts
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  int index = entry.key;
                                  var product = entry.value;

                                  return DataRow(
                                    color: MaterialStateProperty.resolveWith<
                                        Color?>(
                                      (Set<MaterialState> states) {
                                        return index.isEven
                                            ? Colors.grey.shade100
                                            : null; // Alternate row colors
                                      },
                                    ),
                                    cells: [
                                      DataCell(Text(product['id'] ?? '')),
                                      DataCell(Text(product['name'] ?? '')),
                                      DataCell(Text(product['hsn'] ?? '')),

                                      // Editable Quantity
                                      DataCell(_buildEditableField(
                                          index,
                                          "quantity",
                                          "${product['quantity'] ?? 1}",
                                          TextInputType.number)),

                                      // Editable Purchase Price Without GST
                                      DataCell(_buildEditableField(
                                          index,
                                          "purchasePriceWithoutGST",
                                          (product['purchasePriceWithoutGST'] ??
                                                  0.0)
                                              .toStringAsFixed(2),
                                          TextInputType.number)),

                                      // Editable Selling Price Without GST
                                      DataCell(_buildEditableField(
                                          index,
                                          "sellingPriceWithoutGST",
                                          (product['sellingPriceWithoutGST'] ??
                                                  0.0)
                                              .toStringAsFixed(2),
                                          TextInputType.number)),

                                      // Editable MRP With GST
                                      DataCell(_buildEditableField(
                                          index,
                                          "mrpWithGST",
                                          (product['mrpWithGST'] ?? 0.0)
                                              .toStringAsFixed(2),
                                          TextInputType.number)),

                                      // Editable GST Percent
                                      DataCell(_buildEditableField(
                                          index,
                                          "gstPercent",
                                          (product['gstPercent'] ?? 0)
                                              .toString(),
                                          TextInputType.number)),

                                      // Editable Sale Discount
                                      DataCell(_buildEditableField(
                                          index,
                                          "saleDiscount",
                                          (product['saleDiscount'] ?? 0.0)
                                              .toStringAsFixed(2),
                                          TextInputType.number)),

                                      // Editable Discount Unit Dropdown
                                      DataCell(_buildDropdown(
                                          index,
                                          "saleDiscountUnit",
                                          product['saleDiscountUnit'] ?? "%")),

                                      // Derived Purchase Price With GST
                                      DataCell(_buildDerivedValue(
                                          "₹${(product['purchasePriceWithGST'] ?? 0.0).toStringAsFixed(2)}")),

                                      // Derived Selling Price With GST
                                      DataCell(_buildDerivedValue(
                                          "₹${(product['sellingPriceWithGST'] ?? 0.0).toStringAsFixed(2)}")),

                                      // Subtotal
                                      DataCell(_buildDerivedValue(
                                          "₹${(product['subtotal'] ?? 0.0).toStringAsFixed(2)}")),

                                      // Delete Product Button
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              selectedProducts.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "Total: ₹${_calculateTotal().toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: Colors.black, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton.icon(
                          onPressed: _showProductSelectionDialog,
                          icon: const Icon(Icons.add, color: Colors.black),
                          label: const Text("Add Product",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const SizedBox(height: 16),

// Notes & Additional Charges (Row Layout)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Add Notes Field (Expandable)
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _notesController, // ✅ Attach controller
                      minLines: 1,
                      maxLines: null, // Expands dynamically
                      decoration: InputDecoration(
                        labelText: "Add Notes",
                        border: OutlineInputBorder(),
                        hintText: "Enter any additional details...",
                      ),
                    ),
                  ),

                  const SizedBox(width: 16), // Space between fields

// Additional Charges Field (Numeric Input)
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _additionalChargesController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Additional Charges",
                        border: OutlineInputBorder(),
                        prefixText: "₹ ",
                      ),
                      onChanged: (value) =>
                          setState(() {}), // Ensures total updates dynamically
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}

Widget _buildTextInputField(
    String label, TextEditingController controller, Function() onChanged) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) => onChanged(),
    ),
  );
}
