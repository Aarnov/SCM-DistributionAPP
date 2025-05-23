import 'package:distribution_management/sales/proforma_invoice/create_proforma_invoive.dart';
import 'package:distribution_management/sales/proforma_invoice/edit_proforma_invoice.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:distribution_management/sales/proforma_invoice/print_proforma_invoice.dart';

class ProformaListPage extends StatefulWidget {
  @override
  _ProformaListPageState createState() => _ProformaListPageState();
}

class _ProformaListPageState extends State<ProformaListPage> {
  Map<String, String> customerNames = {};

  @override
  void initState() {
    super.initState();
    _fetchCustomerNames();
  }

  Future<void> _fetchCustomerNames() async {
    var snapshot =
        await FirebaseFirestore.instance.collection('PartyMaster').get();
    Map<String, String> tempNames = {};
    for (var doc in snapshot.docs) {
      tempNames[doc.id] = doc['PartyName'] ?? 'Unknown';
    }
    setState(() {
      customerNames = tempNames;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Proforma Invoices"),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Create Proforma Invoice"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateProformaInvoice(),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ProformaMaster')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var invoices = snapshot.data!.docs;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (Set<MaterialState> states) => Colors.blue,
                    ),
                    headingTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: const [
                      DataColumn(label: Text("Proforma No")),
                      DataColumn(label: Text("Date")),
                      DataColumn(label: Text("Customer Name")),
                      DataColumn(label: Text("Bill Amount")),
                      DataColumn(label: Text("GST Amount")),
                      DataColumn(label: Text("Additional Charges")),
                      DataColumn(label: Text("Expiry Date")),
                      DataColumn(label: Text("Status")),
                      DataColumn(label: Text("Actions")),
                    ],
                    rows: List<DataRow>.generate(
                      invoices.length,
                      (index) {
                        var invoice = invoices[index];
                        var data = invoice.data() as Map<String, dynamic>;
                        String partyId = data['PartyId'] ?? '';
                        String customerName =
                            customerNames[partyId] ?? "Fetching...";

                        return DataRow(
                          color: MaterialStateProperty.resolveWith<Color?>(
                            (Set<MaterialState> states) {
                              return index % 2 == 0
                                  ? Colors.grey.shade100
                                  : null;
                            },
                          ),
                          cells: [
                            DataCell(Text(data['ProformaNo'] ?? 'N/A')),
                            DataCell(Text(_formatDate(data['ProformaDate']))),
                            DataCell(Text(customerName)),
                            DataCell(Text(
                                "₹${(data['BillAmountwithoutGST'] ?? 0).toStringAsFixed(2)}")),
                            DataCell(Text(
                                "₹${(data['GSTAmount'] ?? 0).toStringAsFixed(2)}")),
                            DataCell(Text(
                                "₹${(data['AdditionalCharges'] ?? 0).toStringAsFixed(2)}")),
                            DataCell(Text(_formatDate(data['ExpiryDate']))),
                            DataCell(
                              Text(
                                data['BillStatus'] ?? 'N/A',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: data['BillStatus'] == "Final"
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  if (data['BillStatus'] == "Draft")
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Colors.blue),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditProformaInvoice(
                                              proformaData: data,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  if (data['BillStatus'] == "Final")
                                    IconButton(
                                      icon: const Icon(Icons.print,
                                          color: Colors.black),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                PrintProformaInvoice(
                                              proformaNo: data['ProformaNo'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('dd MMM yyyy').format(timestamp.toDate());
    }
    return timestamp.toString();
  }
}
