import 'package:distribution_management/product/add_product.dart';
import 'package:distribution_management/product/product.dart';
import 'package:distribution_management/sales/proforma_invoice/create_proforma_invoive.dart';
import 'package:distribution_management/sales/proforma_invoice/proforma_list.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Import Firebase options
import 'dashboard_screen.dart';  // Import the dashboard screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Ensure correct Firebase config
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Distribution Management',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => DashboardScreen(),
        '/products': (context) => const ProductPage(),
        '/add_products': (context) => const AddProductPage(),
        '/createProformaInvoice':(context)=>const CreateProformaInvoice(),
        '/proformaList':(context)=> ProformaListPage(),
     
      },
    );
  }
}
