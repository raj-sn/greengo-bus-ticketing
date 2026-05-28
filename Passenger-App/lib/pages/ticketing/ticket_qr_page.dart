import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketQRPage extends StatelessWidget {
  final String refNumber;

  const TicketQRPage({super.key, required this.refNumber, required String ticketID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 97, 14),
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('verify_tickets')
              .doc(refNumber)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Ticket not found.'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;

            final String start = data['start'] ?? 'N/A';
            final String destination = data['destination'] ?? 'N/A';
            final dynamic amount = data['amount'] ?? '0';
            final bool paidOnline = data['paid'] == true;
            final int full = data['full'] ?? 0;
            final int half = data['half'] ?? 0;

            return Center(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: ClipPath(
                  clipper: TicketClipper(),
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "YOUR TICKET",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Please show it to Conductor",
                          style: TextStyle(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Column(
                          children: [
                            const Text("CHECK-IN CODE", style: TextStyle(fontSize: 12)),
                            Text(
                              refNumber,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        QrImageView(
                          data: refNumber,
                          version: QrVersions.auto,
                          size: 200,
                        ),
                        const SizedBox(height: 30),
                        Divider(thickness: 2, color: Colors.grey.shade300),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Column(
                                children: [
                                  const Text("From → To", style: TextStyle(fontSize: 12)),
                                  Text(
                                    "$start → $destination",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildTicketInfo(Icons.attach_money, "Amount", "Rs. $amount"),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  paidOnline ? Icons.check_circle : Icons.cancel,
                                  color: paidOnline ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  paidOnline ? "Online Payment" : "Cash Payment",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: paidOnline ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildTicketInfo(Icons.confirmation_number, "Full Tickets", "$full"),
                            _buildTicketInfo(Icons.confirmation_number_outlined, "Half Tickets", "$half"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildTicketInfo(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.black87),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double notchRadius = 16.0;
    Path path = Path();

    path.moveTo(0, 0);
    path.lineTo(size.width, 0); 
    path.lineTo(size.width, size.height * 0.55 - notchRadius);
    path.arcToPoint(
      Offset(size.width, size.height * 0.55 + notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(size.width, size.height); 
    path.lineTo(0, size.height); 
    path.lineTo(0, size.height * 0.55 + notchRadius);
    path.arcToPoint(
      Offset(0, size.height * 0.55 - notchRadius),
      radius: Radius.circular(notchRadius),
      clockwise: false,
    );
    path.lineTo(0, 0); 
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
