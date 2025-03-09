import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



class AddProductDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductSelected;
  final List<Map<String, dynamic>> selectedProducts;

  const AddProductDialog({super.key, required this.onProductSelected, required this.selectedProducts});

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  Stream<QuerySnapshot> _fetchProducts() {
    return FirebaseFirestore.instance.collection('ProductMaster').snapshots();
  }

  void _showQuantityDialog(Map<String, dynamic> product) {
    TextEditingController quantityController = TextEditingController(text: "1");
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Quantity for ${product['ProductName']}"),
          content: TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Enter Quantity",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                int quantity = int.tryParse(quantityController.text) ?? 1;
                setState(() {
                  bool exists = false;
                  for (var item in widget.selectedProducts) {
                    if (item['id'] == product['id']) {
                      item['quantity'] += quantity;
                      item['subtotal'] = item['quantity'] * item['mrp'] * (1 + item['tax'] / 100);
                      exists = true;
                      break;
                    }
                  }
                  if (!exists) {
                    product['quantity'] = quantity;
                    product['subtotal'] = quantity * product['mrp'] * (1 + product['tax'] / 100);
                    widget.onProductSelected(product);
                  }
                });
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text("Select Product"),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _searchController,
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
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchProducts(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var products = snapshot.data!.docs.where((doc) {
                        var name = doc['ProductName'].toString().toLowerCase();
                        var hsn = doc['HSNCode'].toString().toLowerCase();
                        return name.contains(searchQuery) || hsn.contains(searchQuery);
                      }).toList();

                      if (products.isEmpty) {
                        return const Center(child: Text("No matching products"));
                      }

                      return ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          var product = products[index];
                          String productId = product.id;
                          String productName = product['ProductName'];
                          String hsnCode = product['HSNCode'];
                          double mrp = product['SalePriceInclTax'];
                          int taxPercent = product['TaxPercemtInSalePrice'];

                          return ListTile(
                            title: Text(productName),
                            subtitle: Text("HSN: $hsnCode | MRP: ₹$mrp"),
                            onTap: () {
                              _showQuantityDialog({
                                'id': productId,
                                'name': productName,
                                'hsn': hsnCode,
                                'mrp': mrp,
                                'tax': taxPercent,
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
