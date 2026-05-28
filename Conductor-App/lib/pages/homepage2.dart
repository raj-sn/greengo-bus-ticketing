import 'package:flutter/material.dart';
import 'package:gconductor/pages/check_ticket_page.dart';
import 'package:gconductor/pages/qr_verification_page.dart';
import 'package:gconductor/pages/manual_ticket_page.dart';

class HomePage2 extends StatelessWidget {
  const HomePage2({super.key});

  void _onCheckTicketsPressed(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => CheckTicketPage()));
  }

  void _onScanTicketsPressed(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => QRVerificationPage()));
  }

  void _onManualTicketingPressed(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => ManualTicketPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      appBar: AppBar(
        title: const Text('Ticket Scanning & Issuing'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildFeatureCard(
              context,
              icon: Icons.confirmation_num_outlined,
              label: 'Check Tickets',
              color: Colors.blue[600]!,
              onTap: _onCheckTicketsPressed,
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              icon: Icons.qr_code_scanner_rounded,
              label: 'Scan Tickets',
              color: Colors.deepPurple[600]!,
              onTap: _onScanTicketsPressed,
            ),
            const SizedBox(height: 20),
            _buildFeatureCard(
              context,
              icon: Icons.receipt_long_rounded,
              label: 'Manual Ticketing',
              color: Colors.teal[700]!,
              onTap: _onManualTicketingPressed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Function(BuildContext) onTap,
  }) {
    return InkWell(
      onTap: () => onTap(context),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
