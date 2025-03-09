import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:distribution_management/product/category.dart';
import 'package:distribution_management/product/edit_product.dart';
import 'package:flutter/material.dart';
import 'add_product.dart';
import 'add_subcategory.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 🔍 Search Bar
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by Product Name or Category",
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

            // 🔄 Product List with Flexible to avoid overflow
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  Widget _buildProductList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('ProductMaster').snapshots(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!productSnapshot.hasData || productSnapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found.'));
        }

        var products = productSnapshot.data!.docs;

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            var product = products[index];
            return FutureBuilder<String>(
              future: _fetchCategoryName(product['ProductCategoryId']),
              builder: (context, categorySnapshot) {
                String categoryName = categorySnapshot.data ?? 'Loading...';
                String productName = product['ProductName'].toString().toLowerCase();

                // 🔍 Apply Search Filter
                if (searchQuery.isNotEmpty &&
                    !productName.contains(searchQuery) &&
                    !categoryName.toLowerCase().contains(searchQuery)) {
                  return const SizedBox.shrink(); // Hide item if it doesn't match search
                }

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.shopping_bag, color: Colors.blueAccent),
                    title: Text(product['ProductName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Category: $categoryName\nPrice: ₹${product['SalePriceInclTax']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProductPage(product: product),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String> _fetchCategoryName(String categoryId) async {
    if (categoryId.isEmpty) return 'Unknown Category';

    DocumentSnapshot categoryDoc = await FirebaseFirestore.instance
        .collection('ProductCategoryMaster')
        .doc(categoryId)
        .get();

    if (categoryDoc.exists) {
      return categoryDoc['CategoryDesc'] ?? 'No Name';
    } else {
      return 'Unknown Category';
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.category, color: Colors.blueAccent),
              title: const Text('Add Category'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const CategoryPage());
              },
            ),
            ListTile(
              leading: const Icon(Icons.subdirectory_arrow_right, color: Colors.blueAccent),
              title: const Text('Add Subcategory'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const AddProductSubCategoryPage(categoryId: '',));
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
              title: const Text('Add Product'),
              onTap: () {
                Navigator.pop(context);
                _navigateTo(context, const AddProductPage());
              },
            ),
          ],
        );
      },
    );
  }
}
