import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrintProformaInvoice extends StatefulWidget {
  final String proformaNo;
  
  const PrintProformaInvoice({ required this.proformaNo});

  @override
  _PrintProformaInvoiceState createState() => _PrintProformaInvoiceState();
}

class _PrintProformaInvoiceState extends State<PrintProformaInvoice> {
  Map<String, dynamic>? invoiceData;
  Map<String, dynamic>? customerData;
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchInvoiceDetails();
  }

  Future<void> _fetchInvoiceDetails() async {
    // Fetch invoice details
    var invoiceSnapshot = await FirebaseFirestore.instance
        .collection('ProformaMaster')
        .where('ProformaNo', isEqualTo: widget.proformaNo).limit(1)
        .get();

    if (invoiceSnapshot.docs.isNotEmpty) {
      var invoice = invoiceSnapshot.docs.first;
      setState(() {
        invoiceData = invoice.data();
      });

      // Fetch customer details
      var customerSnapshot = await FirebaseFirestore.instance
          .collection('PartyMaster')
          .doc(invoiceData!['PartyId'])
          .get();

      if (customerSnapshot.exists) {
        setState(() {
          customerData = customerSnapshot.data();
        });
      }

      // Fetch product details
      var productList = invoiceData!['Products'] as List<dynamic>?;
      if (productList != null) {
        for (var product in productList) {
          var productSnapshot = await FirebaseFirestore.instance
              .collection('ProductMaster')
              .doc(product['ProductId'])
              .get();
          if (productSnapshot.exists) {
            setState(() {
              products.add({
                'ProductName': productSnapshot['ProductName'],
                'HSNCode': productSnapshot['HSNCode'],
                'Price': productSnapshot['SalePriceInclTax'],
                'Quantity': product['Quantity'],
                'Total': product['Quantity'] * productSnapshot['SalePriceInclTax'],
              });
            });
          }
        }
      }
    }
  }

  Future<void> _generatePdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Proforma Invoice", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text("Invoice No: ${invoiceData!['ProformaNo']}", style: pw.TextStyle(fontSize: 16)),
              pw.Text("Date: ${_formatDate(invoiceData!['ProformaDate'])}", style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text("Customer: ${customerData!['PartyName']}", style: pw.TextStyle(fontSize: 16)),
              pw.Text("Address: ${customerData!['BillingAddress']['city']}, ${customerData!['BillingAddress']['state']}", style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Product', 'HSN Code', 'Price', 'Qty', 'Total'],
                data: products.map((product) => [
                  product['ProductName'],
                  product['HSNCode'],
                  "₹${product['Price']}",
                  product['Quantity'].toString(),
                  "₹${product['Total']}"
                ]).toList(),
              ),
              pw.SizedBox(height: 20),
              pw.Text("Total Amount: ₹${invoiceData!['BillAmountwithoutGST']}"),
              pw.Text("GST: ₹${invoiceData!['GSTAmount']}"),
              pw.Text("Additional Charges: ₹${invoiceData!['AdditionalCharges']}"),
              pw.Text("Grand Total: ₹${invoiceData!['BillAmountwithoutGST'] + invoiceData!['GSTAmount'] + invoiceData!['AdditionalCharges']}"),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Print Proforma Invoice"),
      ),
      body: invoiceData == null || customerData == null
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Invoice No: ${invoiceData!['ProformaNo']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Date: ${_formatDate(invoiceData!['ProformaDate'])}", style: TextStyle(fontSize: 16)),
                        SizedBox(height: 10),
                        Text("Customer: ${customerData!['PartyName']}", style: TextStyle(fontSize: 16)),
                        Text("Address: ${customerData!['BillingAddress']['city']}, ${customerData!['BillingAddress']['state']}", style: TextStyle(fontSize: 16)),
                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          icon: Icon(Icons.print),
                          label: Text("Print Invoice"),
                          onPressed: _generatePdf,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
