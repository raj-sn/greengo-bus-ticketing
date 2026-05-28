import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CheckTicketPage extends StatefulWidget {
  const CheckTicketPage({super.key});

  @override
  State<CheckTicketPage> createState() => _CheckTicketPageState();
}

class _CheckTicketPageState extends State<CheckTicketPage> {
  bool _isScanned = false;
  String _statusMessage = '';
  Color _statusColor = Colors.black;

  void _checkTicket(String refNumber) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('confirmed_tickets')
        .doc(refNumber)
        .get();

    if (!mounted) return;

    if (docSnapshot.exists) {
      setState(() {
        _statusMessage = '✅ Ticket available on server.';
        _statusColor = Colors.green;
      });
    } else {
      setState(() {
        _statusMessage = '❌ Ticket not available on server.';
        _statusColor = Colors.red;
      });
    }
  }

  void _handleQRScan(String refNumber) {
    if (refNumber.isNotEmpty) {
      _checkTicket(refNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR Code')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // light background
      appBar: AppBar(
        title: const Text("Check Ticket"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.confirmation_num_outlined, size: 60, color: Colors.green),
          const SizedBox(height: 12),
          const Text(
            'Point camera at passenger QR code',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green, width: 4),
                      ),
                      child: MobileScanner(
                        fit: BoxFit.cover,
                        onDetect: (capture) {
                          if (_isScanned) return;
                          _isScanned = true;

                          final barcode = capture.barcodes.first;
                          final String refNumber = barcode.rawValue ?? '';

                          _handleQRScan(refNumber);
                        },
                      ),
                    ),
                    if (_isScanned)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _statusMessage,
                                style: TextStyle(fontSize: 22, color: _statusColor),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 30),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _isScanned = false;
                                    _statusMessage = '';
                                    _statusColor = Colors.black;
                                  });
                                },
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(255, 22, 97, 14),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
