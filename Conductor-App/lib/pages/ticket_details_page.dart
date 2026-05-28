import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gconductor/pages/qr_verification_page.dart';
import 'package:intl/intl.dart';

class TicketDetailsPage extends StatefulWidget {
  final Map<String, dynamic> ticketData;

  const TicketDetailsPage({super.key, required this.ticketData});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  bool ticketExists = false;
  bool isPaid = false;
  bool isLoading = true;
  bool isChecked = false;

  @override
  void initState() {
    super.initState();
    checkTicketStatus();
  }

  Future<void> checkTicketStatus() async {
    final ref = widget.ticketData['refNumber'];
    final doc = await FirebaseFirestore.instance
        .collection('verify_tickets')
        .doc(ref)
        .get();

    if (doc.exists) {
      setState(() {
        ticketExists = true;
        isPaid = doc.data()?['paid'] == true;
        isLoading = false;
      });
    } else {
      setState(() {
        ticketExists = false;
        isLoading = false;
      });
    }
  }

  Future<void> confirmOrCollectTicket() async {
    final ref = widget.ticketData['refNumber'];

    try {
      final docRef =
          FirebaseFirestore.instance.collection('verify_tickets').doc(ref);
      final doc = await docRef.get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ticket not found in verify_tickets")),
        );
        return;
      }

      // Copy to confirmed_tickets
      await FirebaseFirestore.instance
          .collection('confirmed_tickets')
          .doc(ref)
          .set(doc.data()!);

      // Delete from verify_tickets
      await docRef.delete();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ticket confirmed successfully!")),
      );

      // Optional: Go back or refresh
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const QRVerificationPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketData = widget.ticketData;

    final String refNumber = ticketData['refNumber'] ?? 'N/A';
    final String start = ticketData['start'] ?? '-';
    final String destination = ticketData['destination'] ?? '-';
    final int amount = ticketData['amount']?.toInt() ?? 0;
    final bool paidOnline = ticketData['paid'] == true;
    final int full = ticketData['full'] ?? 0;
    final int half = ticketData['half'] ?? 0;

    // Format timestamp
    String datePart = 'Not available';
    String timePart = '';
    if (ticketData['timestamp'] != null) {
      try {
        final timestamp = ticketData['timestamp'].toDate();
        final formatted = DateFormat('yyyy-MM-dd hh:mm a').format(timestamp);
        final parts = formatted.split(' ');
        if (parts.length >= 3) {
          datePart = parts[0];
          timePart = '${parts[1]} ${parts[2]}';
        } else {
          datePart = formatted;
          timePart = '';
        }
      } catch (e) {
        datePart = ticketData['timestamp'].toString();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ticket Details"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      headerWithIcon(Icons.qr_code, "Reference No: $refNumber"),
                      divider(),
                      detailWithIcon(Icons.location_on, "From", start),
                      detailWithIcon(Icons.flag, "To", destination),
                      detailWithIcon(Icons.attach_money, "Amount", "Rs. $amount"),
                      detailWithIcon(Icons.confirmation_number, "Full Tickets", "$full"),
                      detailWithIcon(Icons.confirmation_num_outlined, "Half Tickets", "$half"),
                      detailWithIcon(Icons.payment, "Payment Mode", paidOnline ? "Online" : "Cash"),
                      detailDateTime("Date & Time", datePart, timePart),
                    ],
                  ),
                ),
                if (isLoading)
                  const CircularProgressIndicator()
                else if (ticketExists)
                  Column(
                    children: [
                      if (!isPaid) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: isChecked,
                              onChanged: (val) => setState(() => isChecked = val!),
                            ),
                            const Text("Confirm cash collected"),
                          ],
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.money),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 60),
                          ),
                          onPressed: isChecked ? confirmOrCollectTicket : null,
                          label: const Text(
                            "Collected Money",
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ] else ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: confirmOrCollectTicket,
                          label: const Text(
                            "Confirm",
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget divider() => const Divider(thickness: 1.5, height: 25);

  Widget headerWithIcon(IconData icon, String text) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              softWrap: true,
            ),
          ),
        ],
      );

  Widget detailWithIcon(IconData icon, String title, String value) => Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "$title: $value",
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );

  Widget detailDateTime(String title, String date, String time) => Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_today, color: Colors.grey[700]),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$title:",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  Text(date, style: const TextStyle(fontSize: 14)),
                  Text(time, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      );
}
