import 'package:distribution_management/product/edit_subcategory.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_subcategory.dart';

class SubCategoryPage extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const SubCategoryPage({super.key, required this.categoryId, required this.categoryName});

  @override
  _SubCategoryPageState createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  Stream<QuerySnapshot> _fetchSubCategories() {
    return FirebaseFirestore.instance
        .collection('ProductSubCategoryMaster')
        .where('ProductCategoryId', isEqualTo: widget.categoryId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subcategories of ${widget.categoryName}'),
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
                  hintText: "Search Subcategories...",
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

            // 🔄 Subcategory List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _fetchSubCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Subcategories Found.'));
                  }

                  var subCategories = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: subCategories.length,
                    itemBuilder: (context, index) {
                      var subCategory = subCategories[index];
                      String subCategoryName = subCategory['SubCategoryDesc'];

                      // 🔍 Apply Search Filter
                      if (searchQuery.isNotEmpty &&
                          !subCategoryName.toLowerCase().contains(searchQuery)) {
                        return const SizedBox.shrink(); // Hide non-matching items
                      }

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.subdirectory_arrow_right, color: Colors.blueAccent),
                          title: Text(
                            subCategoryName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blueAccent),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditSubCategoryPage(subCategory: subCategory),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddProductSubCategoryPage(categoryId: widget.categoryId),
            ),
          );
        },
        label: const Text('Add Subcategory'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
