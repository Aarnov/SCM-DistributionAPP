import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle;

class PrintProformaInvoice extends StatefulWidget {
  final String proformaNo;

  const PrintProformaInvoice({required this.proformaNo, Key? key})
      : super(key: key);

  @override
  State<PrintProformaInvoice> createState() => _PrintProformaInvoiceState();
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
    final invoiceSnapshot = await FirebaseFirestore.instance
        .collection('ProformaMaster')
        .where('ProformaNo', isEqualTo: widget.proformaNo)
        .limit(1)
        .get();

    if (invoiceSnapshot.docs.isNotEmpty) {
      final invoice = invoiceSnapshot.docs.first.data();
      setState(() {
        invoiceData = invoice;
      });

      final customerSnapshot = await FirebaseFirestore.instance
          .collection('PartyMaster')
          .doc(invoice['PartyId'])
          .get();

      if (customerSnapshot.exists) {
        setState(() {
          customerData = customerSnapshot.data();
        });
      }

      final productSnapshot = await FirebaseFirestore.instance
          .collection('ProformaBillItem')
          .where('ProformaNo', isEqualTo: widget.proformaNo)
          .get();

      List<Map<String, dynamic>> productList = [];

      for (var doc in productSnapshot.docs) {
        final item = doc.data();
        final productId = item['ProductId'];

        final productDetail = await FirebaseFirestore.instance
            .collection('ProductMaster')
            .doc(productId)
            .get();

        final productData = productDetail.data() ?? {};

        productList.add({
          'ProductName': productData['ProductName'] ?? '',
          'HSNCode': productData['HSNCode'] ?? '',
          'MRPWithGST': productData['SalePriceInclTax'] ?? 0,
          'PriceWithoutGST':
              item['PriceWithoutGST'] ?? productData['PurPriceInclTax'] ?? 0,
          'Quantity': item['Quantity'] ?? 0,
          'SaleDiscount': item['SaleDiscount'] ?? 0,
          'SaleDiscountUnit': item['SaleDiscountUnit'] ?? '%',
          'GSTPercent':
              item['GSTPercent'] ?? productData['TaxPercemtInSalePrice'] ?? 0,
        });
      }

      setState(() {
        products = productList;
      });
    }
  }

  Future<void> _printPdf() async {
    if (invoiceData == null || customerData == null || products.isEmpty) return;

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async {
        final pdf = await generateInvoicePdf();
        return pdf;
      },
    );
  }

  Future<Uint8List> generateInvoicePdf() async {
    final pdf = pw.Document();
    final ttf =
        pw.Font.ttf(await rootBundle.load('lib/assets/NotoSans-Regular.ttf'));

    double subtotal = 0;
    double gstTotal = 0;
    double additionalCharges =
        invoiceData!['AdditionalCharges']?.toDouble() ?? 0;

    final rows = products.map((p) {
      final qty = p['Quantity'] ?? 0;
      final price = p['PriceWithoutGST']?.toDouble() ?? 0;
      final discount = p['SaleDiscount']?.toDouble() ?? 0;
      final gst = p['GSTPercent']?.toDouble() ?? 0;
      final discountUnit = p['SaleDiscountUnit'] ?? '%';

      double effectivePrice = price;
      if (discountUnit == '%') {
        effectivePrice -= (price * discount / 100);
      } else {
        effectivePrice -= discount;
      }

      final gstAmount = effectivePrice * gst / 100;
      final lineTotal = (effectivePrice + gstAmount) * qty;

      subtotal += effectivePrice * qty;
      gstTotal += gstAmount * qty;

      return [
        p['ProductName'],
        p['HSNCode'],
        '₹${p['MRPWithGST']}',
        '$qty',
        '₹$price',
        '$discount$discountUnit',
        '$gst%',
        '₹${effectivePrice.toStringAsFixed(2)}',
        '₹${lineTotal.toStringAsFixed(2)}'
      ];
    }).toList();

    final grandTotal = subtotal + gstTotal + additionalCharges;

    pdf.addPage(
      pw.MultiPage(
        margin: pw.EdgeInsets.all(30),
        build: (context) => [
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blueGrey900),
              color: PdfColors.blueGrey50,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('PROFORMA INVOICE',
                      style: pw.TextStyle(
                          font: ttf,
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey900)),
                ),
                pw.SizedBox(height: 12),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Proforma No: ${invoiceData!['ProformaNo']}',
                            style: pw.TextStyle(font: ttf)),
                        pw.Text(
                            'Date: ${_formatDate(invoiceData!['ProformaDate'])}',
                            style: pw.TextStyle(font: ttf)),
                        pw.Text(
                            'Expiry: ${_formatDate(invoiceData!['ExpiryDate'])}',
                            style: pw.TextStyle(font: ttf)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Status: ${invoiceData!['BillStatus']}',
                            style: pw.TextStyle(font: ttf)),
                        pw.Text(
                            'Payment: ${invoiceData!['PaymentinDays']} days',
                            style: pw.TextStyle(font: ttf)),
                      ],
                    )
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text('Customer: ${customerData!['PartyName']}',
                    style: pw.TextStyle(
                        font: ttf, fontWeight: pw.FontWeight.bold)),
                pw.Text('Address: ${customerData!['BillingAddress'] ?? ''}',
                    style: pw.TextStyle(font: ttf)),
                pw.SizedBox(height: 8),
                pw.Text('Description: ${invoiceData!['BillDescription']}',
                    style: pw.TextStyle(font: ttf, color: PdfColors.grey700)),
                pw.Text('Notes: ${invoiceData!['Notes']}',
                    style: pw.TextStyle(font: ttf, color: PdfColors.grey700)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Product',
              'HSN',
              'MRP',
              'Qty',
              'Price',
              'Discount',
              'GST%',
              'Final',
              'Total'
            ],
            data: rows,
            cellStyle: pw.TextStyle(font: ttf, fontSize: 9),
            headerStyle: pw.TextStyle(
              font: ttf,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: pw.BoxDecoration(color: PdfColors.blueGrey800),
            border: pw.TableBorder.symmetric(
                inside: pw.BorderSide(color: PdfColors.grey500)),
          ),
          pw.SizedBox(height: 24),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Container(
              width: 300,
              padding: pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blueGrey100,
                borderRadius: pw.BorderRadius.circular(6),
                border: pw.Border.all(color: PdfColors.blueGrey700, width: 1.2),
                boxShadow: [
                  pw.BoxShadow(
                    blurRadius: 2,
                    color: PdfColors.grey400,
                    offset: const PdfPoint(1, 1),
                  )
                ],
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Subtotal', style: pw.TextStyle(font: ttf)),
                      pw.Text('₹${subtotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('GST', style: pw.TextStyle(font: ttf)),
                      pw.Text('₹${gstTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Additional Charges',
                          style: pw.TextStyle(font: ttf)),
                      pw.Text('₹${additionalCharges.toStringAsFixed(2)}',
                          style: pw.TextStyle(font: ttf)),
                    ],
                  ),
                  pw.Divider(thickness: 0.8, color: PdfColors.blueGrey700),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Grand Total',
                          style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.black)),
                      pw.Text('₹${grandTotal.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                              font: ttf,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.black)),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );

    return pdf.save();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd-MM-yyyy').format(timestamp.toDate());
    }
    return timestamp.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Print Invoice: ${widget.proformaNo}')),
      body: invoiceData == null || customerData == null || products.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.print),
                  label: Text('Generate PDF'),
                  onPressed: _printPdf,
                ),
              ),
            ),
    );
  }
}
