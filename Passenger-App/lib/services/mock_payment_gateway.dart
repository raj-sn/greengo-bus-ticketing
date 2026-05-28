import 'package:flutter/material.dart';

class MockPaymentGateway extends StatefulWidget {
  final double amount;

  const MockPaymentGateway({super.key, required this.amount});

  @override
  State<MockPaymentGateway> createState() => _MockPaymentGatewayState();
}

class _MockPaymentGatewayState extends State<MockPaymentGateway> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  bool _isProcessing = false;

  void _simulatePayment() async {
    final card = _cardNumberController.text.trim();
    final expiry = _expiryController.text.trim();
    final cvv = _cvvController.text.trim();

    if (card.isEmpty || expiry.isEmpty || cvv.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all card details')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isProcessing = false;
    });

    Navigator.pop(context, true); // Payment success
  }

  @override
  Widget build(BuildContext context) {
    const greenColor = Color.fromARGB(255, 22, 97, 14);
    const whiteColor = Colors.white;

    return Scaffold(
      backgroundColor: greenColor,
      appBar: AppBar(
        title: const Text("Mock Payment Gateway"),
        backgroundColor: greenColor,
        foregroundColor: whiteColor,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child:
                _isProcessing
                    ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: greenColor),
                        SizedBox(height: 20),
                        Text(
                          "Processing payment...",
                          style: TextStyle(color: greenColor),
                        ),
                      ],
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.credit_card,
                          size: 70,
                          color: greenColor,
                        ),
                        const SizedBox(height: 10),

                        // Logos
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/image/visa.png',
                              height: 40,
                              width: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 40,
                                  width: 60,
                                  alignment: Alignment.center,
                                  color: Colors.grey[300],
                                  child: const Text("Visa"),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            Image.asset(
                              'assets/image/mastercard.png',
                              height: 40,
                              width: 60,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 40,
                                  width: 60,
                                  alignment: Alignment.center,
                                  color: Colors.grey[300],
                                  child: const Text("Master"),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Pay Rs. ${widget.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: greenColor,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextField(
                          controller: _cardNumberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Card Number',
                            prefixIcon: Icon(
                              Icons.credit_card,
                              color: greenColor,
                            ),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: greenColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryController,
                                keyboardType: TextInputType.datetime,
                                decoration: const InputDecoration(
                                  labelText: 'MM/YY',
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: greenColor,
                                  ),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greenColor),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  prefixIcon: Icon(
                                    Icons.lock,
                                    color: greenColor,
                                  ),
                                  border: OutlineInputBorder(),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: greenColor),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 25),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Pay Now"),
                          onPressed: _simulatePayment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: greenColor,
                            foregroundColor: whiteColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 18),
                          ),
                        ),

                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context, false); // Cancel
                          },
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text(
                            "Cancel Payment",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                        const Divider(thickness: 1),
                        const SizedBox(height: 8),
                        const Text(
                          "Your payment is securely processed by GreenGOPay™.\n"
                          "By proceeding, you agree to our Terms & Privacy Policy.",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
