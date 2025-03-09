import 'package:distribution_management/customer/edit_customer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distribution_management/customer/add_customer.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 🔍 Search Field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by Name, Email, or Mobile",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // 🔄 StreamBuilder for Customer List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('PartyMaster')
                  .where('PartyCategoryId', isEqualTo: 'Customer')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data'));
                }

                // 🔍 Filter Customers
                var customers = snapshot.data!.docs.where((customer) {
                  var name = customer['PartyName'].toString().toLowerCase();
                  var email = customer['Email'].toString().toLowerCase();
                  var mobile = customer['MobileNo'].toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      email.contains(searchQuery) ||
                      mobile.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    var customer = customers[index];
                    return CustomerCard(customer: customer);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCustomerPage()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CustomerCard extends StatelessWidget {
  final QueryDocumentSnapshot customer;

  const CustomerCard({required this.customer, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Reduced vertical margin
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.blueAccent, width: 0.5),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), // Reduced padding
        minVerticalPadding: 1, // Remove extra vertical padding
        dense: true, // Make the ListTile denser
        leading: CircleAvatar(
          radius: 18, // Smaller avatar
          backgroundColor: Colors.blueAccent,
          child: Text(
            customer['PartyName'][0], // First letter as avatar
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18, // Smaller font size
            ),
          ),
        ),
        title: Text(
          customer['PartyName'],
          style: const TextStyle(
            fontSize: 16, // Smaller font size
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📧 ${customer['Email'] ?? 'No Email'}',
              style: const TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.grey,
              ),
            ),
            Text(
              '📞 ${customer['MobileNo'] ?? 'No Mobile'}',
              style: const TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(
            Icons.arrow_forward_ios,
            color: Colors.blueAccent,
            size: 16, // Smaller icon size
          ),
          padding: EdgeInsets.zero, // Remove padding around the icon
          constraints: const BoxConstraints(), // Remove constraints
          onPressed: () => _showCustomerDetails(context, customer),
        ),
      ),
    );
  }


void _showCustomerDetails(BuildContext context, QueryDocumentSnapshot customer) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)), // Rounded corners
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
          child: Container(
            width: double.infinity, // Ensure full width inside parent
            constraints: const BoxConstraints(
              maxWidth: 600, // Prevent excessive stretching on large screens
            ),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(color: Colors.grey.shade300, width: 1.5), // Popup border
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Avoid unnecessary stretching
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center( // Centering Party Name
                  child: Text(
                    customer['PartyName'],
                    textAlign: TextAlign.center, // Ensure text stays centered
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('📧 Email', customer['Email'] ?? 'No Email'),
                        _buildDetailRow('📞 Mobile', customer['MobileNo'] ?? 'No Mobile'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📦 Billing Details"),
                        _buildDetailRow('🏠 Address', customer['BillingAddress'] ?? 'No Address'),
                        _buildDetailRow('📍 Landmark', customer['BillingLandMark'] ?? 'No Landmark'),
                        _buildDetailRow('🏙️ City/Village', customer['BillingVillageCity'] ?? 'No City/Village'),
                        _buildDetailRow('🗺️ District', customer['BillingDistrict'] ?? 'No District'),
                        _buildDetailRow('🏳️ State', customer['BillingState'] ?? 'No State'),
                        _buildDetailRow('🌍 Country', customer['BillingCountry'] ?? 'No Country'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📦 Shipping Details"),
                        _buildDetailRow('🏠 Address', customer['ShippingAddress'] ?? 'No Address'),
                        _buildDetailRow('📍 Landmark', customer['ShippingLandmark'] ?? 'No Landmark'),
                        _buildDetailRow('🏙️ City/Village', customer['ShippingVillageCity'] ?? 'No City/Village'),
                        _buildDetailRow('🗺️ District', customer['ShippingDistrict'] ?? 'No District'),
                        _buildDetailRow('🏳️ State', customer['ShippingState'] ?? 'No State'),
                        _buildDetailRow('🌍 Country', customer['ShippingCountry'] ?? 'No Country'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📑 Tax Info"),
                        _buildDetailRow('🆔 Pancard', customer['Pancard'] ?? 'No Pancard'),
                        _buildDetailRow('📝 GST Number', customer['gstNo'] ?? 'No GST'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey, width: 1), // Button border
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close Dialog
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditCustomerPage(customer: customer),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 23, 206, 135),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.grey, width: 1), // Button border
                        ),
                      ),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}