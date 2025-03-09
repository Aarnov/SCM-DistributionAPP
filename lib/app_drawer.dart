import 'package:distribution_management/customer/customer_page.dart';
import 'package:distribution_management/supplier/supplier_page.dart';
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Drawer Header with Profile Info
          _buildDrawerHeader(context),

          // Sidebar Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  title: 'Customer',
                  icon: Icons.group,
                       onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CustomerPage()),
            ),
                ),
                _buildMenuItem(
                  title: 'Supplier',
                  icon: Icons.business,
                       onTap: () => Navigator.push( context,    MaterialPageRoute(builder: (context) => SupplierPage()), ),
                ),

          

                // Items Section
                _buildExpansionTile(
                  title: 'Items',
                  icon: Icons.inventory,
                  children: [
                    _buildSubMenuItem('Products', () => _navigateTo(context, '/products')),
                    _buildSubMenuItem('Inventory', () => _navigateTo(context, '/inventory')),
                    _buildSubMenuItem('Godown', () => _navigateTo(context, '/godown')),
                  ],
                ),

                // Sales Section
                _buildExpansionTile(
                  title: 'Sales',
                  icon: Icons.shopping_cart,
                  children: [
                    _buildSubMenuItem('Sales Invoice', () => _navigateTo(context, '/salesInvoice')),
                    _buildSubMenuItem('Quotation / Estimate', () => _navigateTo(context, '/quotation')),
                    _buildSubMenuItem('Payment In', () => _navigateTo(context, '/paymentIn')),
                    _buildSubMenuItem('Sales Return', () => _navigateTo(context, '/salesReturn')),
                    _buildSubMenuItem('Credit Note', () => _navigateTo(context, '/creditNote')),
                    _buildSubMenuItem('Delivery Challan', () => _navigateTo(context, '/deliveryChallan')),
                    _buildSubMenuItem('Proforma Invoice', () => _navigateTo(context, '/createProformaInvoice')),
                  ],
                ),

                // Purchases Section
                _buildExpansionTile(
                  title: 'Purchases',
                  icon: Icons.shopping_bag,
                  children: [
                    _buildSubMenuItem('Purchase Invoice', () => _navigateTo(context, '/purchaseInvoice')),
                    _buildSubMenuItem('Payment Out', () => _navigateTo(context, '/paymentOut')),
                    _buildSubMenuItem('Purchase Return', () => _navigateTo(context, '/purchaseReturn')),
                    _buildSubMenuItem('Debit Note', () => _navigateTo(context, '/debitNote')),
                    _buildSubMenuItem('Purchase Orders', () => _navigateTo(context, '/purchaseOrders')),
                  ],
                ),

                // Logistics Management Section
                _buildExpansionTile(
                  title: 'Logistics Management',
                  icon: Icons.local_shipping,
                  children: [
                    _buildSubMenuItem('Stock Acceptance for Distribution', () => _navigateTo(context, '/stockAcceptance')),
                    _buildSubMenuItem('Distribution Monitoring', () => _navigateTo(context, '/distributionMonitoring')),
                    _buildSubMenuItem('Stock Return / Closing', () => _navigateTo(context, '/stockReturn')),
                  ],
                ),

                // Inventory Management Section
                _buildExpansionTile(
                  title: 'Inventory Management',
                  icon: Icons.warehouse,
                  children: [
                    _buildSubMenuItem('Stock Verification', () => _navigateTo(context, '/stockVerification')),
                    _buildSubMenuItem('Material Request', () => _navigateTo(context, '/materialRequest')),
                  ],
                ),

        

                // Reports Section
                _buildMenuItem(title: 'Reports', icon: Icons.analytics, onTap: () => _navigateTo(context, '/reports')),

                const Divider(),

                // Footer Menu Items
                _buildMenuItem(title: 'Contact Us', icon: Icons.contact_mail, onTap: () => _navigateTo(context, '/contact')),
                _buildMenuItem(title: 'Copyright & Terms', icon: Icons.description, onTap: () => _navigateTo(context, '/terms')),
                _buildMenuItem(title: 'Privacy Policy', icon: Icons.privacy_tip, onTap: () => _navigateTo(context, '/privacy')),

                const Divider(),

                // Signout and Help
                _buildMenuItem(title: 'Signout', icon: Icons.exit_to_app, onTap: () => _navigateTo(context, '/signout')),
                _buildMenuItem(title: 'Help', icon: Icons.help, onTap: () => _navigateTo(context, '/help')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // **Drawer Header with Profile**
  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Colors.blue),
      child: InkWell(
        onTap: () {
          _navigateTo(context, '/profile'); // Navigate to profile page
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            SizedBox(width: 16),
            // User info section side by side
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ram',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'ram@gmail.com',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // **Menu Item (Clickable)**
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  // **Expandable Menu Section**
  Widget _buildExpansionTile({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      children: children,
    );
  }

  // **Sub-menu Item (Inside Expandable Menu)**
  Widget _buildSubMenuItem(String title, VoidCallback onTap) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 14),
      ),
      leading: const SizedBox.shrink(),
      contentPadding: const EdgeInsets.only(left: 48),
      onTap: onTap,
    );
  }

  // **Navigation Helper**
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }
}
