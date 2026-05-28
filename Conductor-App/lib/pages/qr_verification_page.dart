import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gconductor/pages/ticket_details_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRVerificationPage extends StatefulWidget {
  const QRVerificationPage({super.key});

  @override
  State<QRVerificationPage> createState() => _QRVerificationPageState();
}

class _QRVerificationPageState extends State<QRVerificationPage> {
  bool _isScanned = false;

  void _verifyTicket(String refNumber) async {
    final docSnapshot = await FirebaseFirestore.instance
        .collection('verify_tickets')
        .doc(refNumber)
        .get();

    if (!mounted) return;

    if (docSnapshot.exists) {
      final data = docSnapshot.data()!;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketDetailsPage(ticketData: data),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket not found: $refNumber')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text("Scan Ticket QR"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),
          const Icon(Icons.qr_code_scanner, size: 60, color: Colors.green),
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
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: MobileScanner(
                  fit: BoxFit.cover,
                  controller: MobileScannerController(
                    facing: CameraFacing.back,
                    torchEnabled: false,
                  ),
                  onDetect: (capture) async {
                    if (_isScanned) return;
                    _isScanned = true;

                    final barcode = capture.barcodes.first;
                    final String refNumber = barcode.rawValue ?? '';

                    if (refNumber.isNotEmpty) {
                      _verifyTicket(refNumber);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid QR Code')),
                      );
                      Navigator.pop(context);
                    }
                  },
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
