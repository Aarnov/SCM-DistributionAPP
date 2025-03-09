import 'package:distribution_management/supplier/add_suplier.dart';
import 'package:distribution_management/supplier/edit_supplier.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupplierPage extends StatefulWidget {
  const SupplierPage({super.key});

  @override
  _SupplierPageState createState() => _SupplierPageState();
}

class _SupplierPageState extends State<SupplierPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
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

          // 🔄 StreamBuilder for Supplier List
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('PartyMaster')
                  .where('PartyCategoryId', isEqualTo: 'Supplier')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(child: Text('Error fetching data'));
                }

                // 🔍 Filter Suppliers
                var suppliers = snapshot.data!.docs.where((supplier) {
                  var name = supplier['PartyName'].toString().toLowerCase();
                  var email = supplier['Email'].toString().toLowerCase();
                  var mobile = supplier['MobileNo'].toString().toLowerCase();
                  return name.contains(searchQuery) ||
                      email.contains(searchQuery) ||
                      mobile.contains(searchQuery);
                }).toList();

                return ListView.builder(
                  itemCount: suppliers.length,
                  itemBuilder: (context, index) {
                    var supplier = suppliers[index];
                    return SupplierCard(Supplier: supplier);
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
            MaterialPageRoute(builder: (context) => AddSupplierPage()),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add),
      ),
    );
  }
}


class SupplierCard extends StatelessWidget {
  final QueryDocumentSnapshot Supplier;

  const SupplierCard({required this.Supplier, super.key});

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
            Supplier['PartyName'][0], // First letter as avatar
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18, // Smaller font size
            ),
          ),
        ),
        title: Text(
          Supplier['PartyName'],
          style: const TextStyle(
            fontSize: 16, // Smaller font size
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📧 ${Supplier['Email'] ?? 'No Email'}',
              style: const TextStyle(
                fontSize: 14, // Smaller font size
                color: Colors.grey,
              ),
            ),
            Text(
              '📞 ${Supplier['MobileNo'] ?? 'No Mobile'}',
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
          onPressed: () => _showSupplierDetails(context, Supplier),
        ),
      ),
    );
  }


void _showSupplierDetails(BuildContext context, QueryDocumentSnapshot Supplier) {
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
                    Supplier['PartyName'],
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
                        _buildDetailRow('📧 Email', Supplier['Email'] ?? 'No Email'),
                        _buildDetailRow('📞 Mobile', Supplier['MobileNo'] ?? 'No Mobile'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📦 Billing Details"),
                        _buildDetailRow('🏠 Address', Supplier['BillingAddress'] ?? 'No Address'),
                        _buildDetailRow('📍 Landmark', Supplier['BillingLandMark'] ?? 'No Landmark'),
                        _buildDetailRow('🏙️ City/Village', Supplier['BillingVillageCity'] ?? 'No City/Village'),
                        _buildDetailRow('🗺️ District', Supplier['BillingDistrict'] ?? 'No District'),
                        _buildDetailRow('🏳️ State', Supplier['BillingState'] ?? 'No State'),
                        _buildDetailRow('🌍 Country', Supplier['BillingCountry'] ?? 'No Country'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📦 Shipping Details"),
                        _buildDetailRow('🏠 Address', Supplier['ShippingAddress'] ?? 'No Address'),
                        _buildDetailRow('📍 Landmark', Supplier['ShippingLandmark'] ?? 'No Landmark'),
                        _buildDetailRow('🏙️ City/Village', Supplier['ShippingVillageCity'] ?? 'No City/Village'),
                        _buildDetailRow('🗺️ District', Supplier['ShippingDistrict'] ?? 'No District'),
                        _buildDetailRow('🏳️ State', Supplier['ShippingState'] ?? 'No State'),
                        _buildDetailRow('🌍 Country', Supplier['ShippingCountry'] ?? 'No Country'),

                        const SizedBox(height: 5),
                        _buildSectionHeader("📑 Tax Info"),
                        _buildDetailRow('🆔 Pancard', Supplier['Pancard'] ?? 'No Pancard'),
                        _buildDetailRow('📝 GST Number', Supplier['gstNo'] ?? 'No GST'),
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
                            builder: (context) => EditSupplierPage(Supplier: Supplier),
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