import 'package:distribution_management/sales/proforma_invoice/add_product_dialogue.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void showCustomerSelectionDialog({
  required BuildContext context,
  required TextEditingController searchController,
  required Function(String id, String name, String mobile, String email, String billingCity, String billingState, String billingCountry, String shippingCity, String shippingState, String shippingCountry, String pancard, String gstNo) addCustomer,
  required Stream<QuerySnapshot> Function() fetchCustomers,
  required Function(String) updateSearchQuery,
}) {
  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Select Customer"),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: "Search by Name, Email, or Number",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setDialogState(() {
                        updateSearchQuery(value.toLowerCase());
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: StreamBuilder<QuerySnapshot>(
                      stream: fetchCustomers(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        var customers = snapshot.data!.docs.where((doc) {
                          var name = doc['PartyName'].toString().toLowerCase();
                          var email = doc['Email'].toString().toLowerCase();
                          var mobile = doc['MobileNo'].toString().toLowerCase();
                          return name.contains(searchController.text.toLowerCase()) ||
                              email.contains(searchController.text.toLowerCase()) ||
                              mobile.contains(searchController.text.toLowerCase());
                        }).take(5).toList();

                        if (customers.isEmpty) {
                          return const Center(child: Text("No matching customers"));
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            var customer = customers[index];
                            String customerId = customer.id;
                            String customerName = customer['PartyName'];
                            String customerMobile = customer['MobileNo'];
                            String customerEmail = customer['Email'];
                            String billingCity = customer['BillingVillageCity'];
                            String billingState = customer['BillingState'];
                            String billingCountry = customer['BillingCountry'];
                            String shippingCity = customer['ShippingVillageCity'];
                            String shippingState = customer['ShippingState'];
                            String shippingCountry = customer['ShippingCountry'];
                            String pancard = customer['Pancard'];
                            String gstNo = customer['gstNo'];

                            return ListTile(
                              title: Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("📞 $customerMobile", style: const TextStyle(fontSize: 12)),
                                  Text("✉️ $customerEmail", style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              onTap: () {
                                addCustomer(
                                  customerId,
                                  customerName,
                                  customerMobile,
                                  customerEmail,
                                  billingCity,
                                  billingState,
                                  billingCountry,
                                  shippingCity,
                                  shippingState,
                                  shippingCountry,
                                  pancard,
                                  gstNo,
                                );
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
            ),
          );
        },
      );
    },
  );
}


