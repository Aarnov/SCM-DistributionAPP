import 'package:distribution_management/product/add_category.dart';
import 'package:distribution_management/product/edit_category.dart';
import 'package:distribution_management/product/subcategory.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  Stream<QuerySnapshot> _fetchCategories() {
    return FirebaseFirestore.instance.collection('ProductCategoryMaster').snapshots();
  }

  Future<int> _fetchCategoryItemCount(String categoryId) async {
    QuerySnapshot subCategorySnapshot = await FirebaseFirestore.instance
        .collection('ProductSubCategoryMaster')
        .where('ProductCategoryId', isEqualTo: categoryId)
        .get();
    return subCategorySnapshot.docs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
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
                  hintText: "Search Categories...",
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

            // 🔄 Category List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _fetchCategories(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('No Categories Found.'));
                  }

                  var categories = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      var category = categories[index];
                      String categoryName = category['CategoryDesc'];
                      String categoryId = category.id;

                      // 🔍 Apply Search Filter
                      if (searchQuery.isNotEmpty &&
                          !categoryName.toLowerCase().contains(searchQuery)) {
                        return const SizedBox.shrink(); // Hide non-matching items
                      }

                      return FutureBuilder<int>(
                        future: _fetchCategoryItemCount(categoryId),
                        builder: (context, countSnapshot) {
                          int itemCount = countSnapshot.data ?? 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const Icon(Icons.category, color: Colors.blueAccent),
                              title: Text(
                                categoryName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text("Subcategories: $itemCount"),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blueAccent),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditCategoryPage(category: category),
                                    ),
                                  );
                                },
                              ),
                              onTap: () {
                                // Navigate to SubCategoryPage with selected Category ID & Name
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubCategoryPage(
                                      categoryId: categoryId,
                                      categoryName: categoryName,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductCategoryPage()),
          );
        },
        label: const Text('Add Category'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}
