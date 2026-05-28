// ignore_for_file: camel_case_types

import 'package:flutter/material.dart';
import 'package:gticketing/pages/ComplaintPage.dart';
import 'package:gticketing/pages/ticketing/PendingTicketsPage.dart';
import 'package:gticketing/pages/SettingsPage.dart';
import 'package:gticketing/auth/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gticketing/pages/ticketing/purchased_tickets_page.dart';
import 'package:gticketing/pages/wallet_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gticketing/pages/tracking/tracking_page.dart';
import 'package:gticketing/pages/ticketing_page.dart';

class homepage extends StatelessWidget {
  const homepage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String name = '';
  String email = '';
  double balance = 0.0;
  int leaf = 0;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final uid = user.uid;
        final docSnapshot =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (docSnapshot.exists) {
          final data = docSnapshot.data()!;
          setState(() {
            name = data['name'] ?? '';
            email = data['email'] ?? '';
            balance = (data['balance'] ?? 0).toDouble();
            leaf = (data['leaf'] ?? 0).toInt();
          });
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),

            // User card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Container(
                padding: EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color.fromARGB(255, 22, 97, 14), Colors.green],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          const Icon(
                            Icons.eco,
                            color: Colors.white70,
                            size: 48,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'leafs',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '$leaf',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          IconButton(
                            onPressed: () async {
                              setState(() => name = "Loading...");
                              await fetchUserData(); // refresh leaf and balance
                            },
                            icon: const Icon(
                              Icons.refresh,
                              color: Colors.white,
                            ),
                            tooltip: "Refresh",
                            iconSize: 20,
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.person, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Rs. ${balance.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Icon(Icons.email, color: Colors.white70),
                            SizedBox(width: 10),
                            Text(
                              email,
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 10),

            // Grid menu
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              crossAxisSpacing: 25,
              mainAxisSpacing: 10,
              physics: NeverScrollableScrollPhysics(),
              children: [
                _buildGridItem(
                  context,
                  Icons.receipt_long_rounded,
                  'Buy Tickets',
                  TicketingPage(),
                ),
                _buildGridItem(
                  context,
                  Icons.credit_card,
                  'Top-Up',
                  WalletPage(),
                ),
                _buildGridItem(
                  context,
                  Icons.dangerous_rounded,
                  'Complaint',
                  ComplaintPage(),
                ),
              ],
            ),

            SizedBox(height: 20),

            // History and logout
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.history, color: const Color.fromARGB(255, 22, 97, 14)),
                title: Text('Purchased Tickets'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PurchasedTicketsPage()),
                    ),
              ),
            ),
            SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.bus_alert_rounded, color: Colors.orange),
                title: Text('Pending Tickets'),
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => PendingTicketsPage()),
                    ),
              ),
            ),
            SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: Icon(Icons.logout_rounded, color: Colors.black),
                title: Text('Logout'),
                onTap:
                    () => showDialog(
                      context: context,
                      builder:
                          (dialogContext) => AlertDialog(
                            title: Text("Confirm Logout"),
                            content: Text("Are you sure you want to log out?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(dialogContext); // Close dialog
                                  await FirebaseAuth.instance.signOut();
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.clear();
                                  if (mounted) {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LoginPage(),
                                      ),
                                    );
                                  }
                                },
                                child: Text("Logout"),
                              ),
                            ],
                          ),
                    ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation + FAB
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 10,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomItem(Icons.location_on_rounded, "Map", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TrackingPage()),
                );
              }),
              SizedBox(width: 40),
              _buildBottomItem(Icons.settings, "Settings", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SettingsPage()),
                );
              }),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 80,
        width: 80,
        child: RawMaterialButton(
          fillColor: const Color.fromARGB(255, 22, 97, 14),
          shape: CircleBorder(),
          elevation: 6,
          child: Icon(
            Icons.receipt_long_rounded,
            size: 40,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TicketingPage()),
            );
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    IconData icon,
    String label,
    Widget page,
  ) {
    return SizedBox(
      height: 100,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 5,
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => page),
              ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: const Color.fromARGB(255, 22, 97, 14)),
                SizedBox(height: 6),
                Text(label, style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: const Color.fromARGB(255, 22, 97, 14)),
          SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
