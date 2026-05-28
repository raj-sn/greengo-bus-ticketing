import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/mock_payment_gateway.dart';
import 'package:gticketing/pages/home_page.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  double _balance = 0.0;
  bool _isLoading = true;

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    fetchWalletBalance();
  }

  Future<void> fetchWalletBalance() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!mounted) return;

      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('balance')) {
          setState(() {
            _balance = data['balance']?.toDouble() ?? 0.0;
            _isLoading = false;
          });
        } else {
          await _firestore.collection('users').doc(user.uid).update({'balance': 0.0});
          if (!mounted) return;
          setState(() {
            _balance = 0.0;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('User document not found');
      }
    } catch (e) {
      debugPrint('Error fetching wallet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading wallet')),
      );
    }
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    final parentContext = context;

    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Top-up Wallet'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Enter Amount',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amountText = amountController.text.trim();
                final amount = double.tryParse(amountText);
                if (amount != null && amount > 0) {
                  Navigator.pop(dialogContext);

                  final result = await Navigator.push(
                    parentContext,
                    MaterialPageRoute(
                      builder: (context) => MockPaymentGateway(amount: amount),
                    ),
                  );

                  if (!mounted) return;

                  if (result == true) {
                    await _topUpWallet(amount);
                  } else {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      const SnackBar(content: Text('Payment failed or cancelled')),
                    );
                  }
                } else {
                  if (!mounted) return;
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(content: Text('Enter a valid amount')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
              ),
              child: const Text('Top-up'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _topUpWallet(double amount) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final uid = user.uid;
      final email = user.email ?? "unknown";

      await _firestore.collection('users').doc(uid).update({
        'balance': FieldValue.increment(amount),
      });

      await _firestore.collection('transactions').add({
        'userId': uid,
        'email': email,
        'amount': amount,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _balance += amount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully topped up Rs. ${amount.toStringAsFixed(2)}')),
      );
    } catch (e) {
      debugPrint('Error topping up wallet: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to top-up wallet')),
      );
    }
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Light green background
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goHome,
        ),
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white, // White card
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 40, color: Colors.green[800]),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Available Balance',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Rs. ${_balance.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Top-up Wallet'),
                      onPressed: _showTopUpDialog,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
