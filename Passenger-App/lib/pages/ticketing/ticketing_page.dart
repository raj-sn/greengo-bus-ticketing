import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ticket_qr_page.dart';
import 'qr_scanner_page.dart';

class TicketingPage extends StatefulWidget {
  const TicketingPage({super.key});

  @override
  State<TicketingPage> createState() => _TicketingPageState();
}

class _TicketingPageState extends State<TicketingPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<String> _stops = [];
  String? _selectedStart;
  String? _selectedDestination;
  double? _ticketPrice;
  int _fullCount = 0;
  int _halfCount = 0;
  double? _totalPrice;
  double? _balance;
  String? _userId;
  String? _username;
  bool _isLoading = true;
  int _leaf = 0;
  bool _useLeaf = false;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _userId = _auth.currentUser?.uid;
    fetchBusStops();
    if (_userId != null) {
      fetchUserBalance();
      fetchUserName();
    }
    _fullCount = 0;
    _halfCount = 0;
    _totalPrice = null;
    _discount = 0.0;
  }

  Future<void> fetchBusStops() async {
    final snapshot = await _firestore.collection('fares').get();
    Set<String> busStops = {};
    for (var doc in snapshot.docs) {
      final parts = doc.id.split('_');
      if (parts.length == 2) {
        busStops.add(parts[0]);
        busStops.add(parts[1]);
      }
    }
    setState(() {
      _stops = busStops.toList()..sort();
      _isLoading = false;
    });
  }

  Future<void> fetchTicketPrice() async {
    if (_selectedStart == null || _selectedDestination == null) return;

    final routeId = "${_selectedStart!}_${_selectedDestination!}";
    final reverseRouteId = "${_selectedDestination!}_${_selectedStart!}";

    final doc = await _firestore.collection('fares').doc(routeId).get();
    if (doc.exists) {
      setState(() {
        _ticketPrice = doc['price']?.toDouble() ?? 0.0;
      });
      calculateTotalPrice();
    } else {
      final reverseDoc = await _firestore.collection('fares').doc(reverseRouteId).get();
      if (reverseDoc.exists) {
        setState(() {
          _ticketPrice = reverseDoc['price']?.toDouble() ?? 0.0;
        });
        calculateTotalPrice();
      } else {
        setState(() {
          _ticketPrice = null;
          _totalPrice = null;
          _discount = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No fare found for selected route')),
        );
      }
    }
  }

  void calculateTotalPrice() {
    if (_ticketPrice != null && (_fullCount > 0 || _halfCount > 0)) {
      final baseTotal = (_ticketPrice! * _fullCount) + (_ticketPrice! * 0.5 * _halfCount);
      double discount = 0.0;
      if (_useLeaf) {
        discount = _leaf >= baseTotal ? baseTotal : _leaf.toDouble();
      }
      setState(() {
        _discount = discount;
        _totalPrice = baseTotal - discount;
      });
    } else {
      setState(() {
        _discount = 0.0;
        _totalPrice = null;
      });
    }
  }

  Future<void> fetchUserBalance() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists) {
        setState(() {
          _balance = userDoc['balance']?.toDouble() ?? 0.0;
          _leaf = userDoc['leaf'] ?? 0;
        });
      }
    } catch (e) {
      print("Failed to fetch balance or leaf: $e");
    }
  }

  Future<void> fetchUserName() async {
    try {
      final userDoc = await _firestore.collection('users').doc(_userId).get();
      if (userDoc.exists && userDoc.data()!.containsKey('name')) {
        setState(() {
          _username = userDoc['name'];
        });
      }
    } catch (e) {
      print("Failed to fetch username: $e");
    }
  }

  Future<void> purchaseTicket(String busId, bool isOnlinePayment) async {
    if (_userId == null || _totalPrice == null || _balance == null || _username == null) return;

    int leafReward = 0;
    if (_totalPrice! >= 500) {
      leafReward = 10;
    } else if (_totalPrice! >= 100) {
      leafReward = 3;
    } else if (_totalPrice! >= 50) {
      leafReward = 2;
    } else if (_totalPrice! >= 30) {
      leafReward = 1;
    }

    final updatedBalance = isOnlinePayment ? (_balance! - _totalPrice!) : _balance!;
    final refNumber = "${_username!.substring(0, 3).toUpperCase()}${DateTime.now().millisecondsSinceEpoch}";

    final ticketData = {
      'userId': _userId,
      'username': _username,
      'busId': busId,
      'start': _selectedStart,
      'destination': _selectedDestination,
      'full': _fullCount,
      'half': _halfCount,
      'amount': _totalPrice,
      'refNumber': refNumber,
      'leafReward': leafReward,
      'usedLeaves': _useLeaf ? _discount.toInt() : 0,
      'paid': isOnlinePayment,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await _firestore.collection('verify_tickets').doc(refNumber).set(ticketData);

      if (isOnlinePayment) {
        await _firestore.collection('users').doc(_userId).update({
          'balance': updatedBalance,
        });
        setState(() => _balance = updatedBalance);
      }

      if (_useLeaf && _discount > 0) {
        int leavesToDeduct = _discount.toInt();
        await _firestore.collection('users').doc(_userId).update({
          'leaf': FieldValue.increment(-leavesToDeduct),
        });
        setState(() => _leaf -= leavesToDeduct);
      }

      if (leafReward > 0) {
        await _firestore.collection('users').doc(_userId).update({
          'leaf': FieldValue.increment(leafReward),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isOnlinePayment
            ? "Ticket purchased! Used $_discount leaf${_discount > 1 ? 's' : ''}, earned $leafReward 🍃"
            : "Ticket saved! Conductor will collect cash"),
      ));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TicketQRPage(ticketID: busId, refNumber: refNumber),
        ),
      );
    } catch (e) {
      print("Error uploading ticket: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to upload ticket")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 22, 97, 14),
      appBar: AppBar(
        title: const Text("BUY TICKET", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Choose Your Bus Stops",
                        style: TextStyle(color: Color.fromARGB(255, 22, 97, 14), fontSize: 16)),
                    const SizedBox(height: 20),

                    // Start Station
                    _buildStyledAutocomplete(
                      label: "Start Location",
                      icon: Icons.location_on,
                      value: _selectedStart,
                      onSelected: (val) {
                        setState(() => _selectedStart = val);
                        fetchTicketPrice();
                      },
                    ),

                    const SizedBox(height: 15),

                    // End Station
                    _buildStyledAutocomplete(
                      label: "Destination",
                      icon: Icons.flag,
                      value: _selectedDestination,
                      onSelected: (val) {
                        setState(() => _selectedDestination = val);
                        fetchTicketPrice();
                      },
                    ),

                    const SizedBox(height: 10),

                    Align(
                      alignment: Alignment.centerRight,
                      child: FloatingActionButton.small(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        onPressed: () {
                          setState(() {
                            final temp = _selectedStart;
                            _selectedStart = _selectedDestination;
                            _selectedDestination = temp;
                          });
                          fetchTicketPrice();
                        },
                        child: const Icon(Icons.swap_vert),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ticket counts
                    Row(
                      children: [
                        Expanded(
                          child: _buildTicketInput("Full Tickets", _fullCount, (val) {
                            setState(() => _fullCount = val);
                            calculateTotalPrice();
                          }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildTicketInput("Half Tickets", _halfCount, (val) {
                            setState(() => _halfCount = val);
                            calculateTotalPrice();
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Summary Card inside container
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          if (_ticketPrice != null)
                            Text("Ticket Price: Rs. ${_ticketPrice!.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.green)),
                          if (_totalPrice != null)
                            Text("Total: Rs. ${_totalPrice!.toStringAsFixed(2)}",
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue)),
                          if (_balance != null)
                            Text("Available Balance: Rs. ${_balance!.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.green)),
                          CheckboxListTile(
                            value: _useLeaf,
                            onChanged: (val) {
                              setState(() => _useLeaf = val ?? false);
                              calculateTotalPrice();
                            },
                            title: Text("Use leaves (Available: $_leaf)",
                                style: const TextStyle(color: Colors.green)),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_discount > 0)
                            Text("Leaf Discount: Rs. ${_discount.toStringAsFixed(2)}",
                                style: const TextStyle(color: Colors.teal)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _totalPrice != null &&
                                    _balance != null &&
                                    _balance! >= _totalPrice!
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => QRScannerPage(
                                          onScan: (busId) =>
                                              purchaseTicket(busId, true),
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 22, 97, 14),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Pay with Wallet"),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QRScannerPage(
                                    onScan: (busId) =>
                                        purchaseTicket(busId, false),
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade300,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Pay with Cash"),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStyledAutocomplete({
    required String label,
    required IconData icon,
    required String? value,
    required void Function(String) onSelected,
  }) {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return _stops.where((stop) => stop.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
        controller.text = value ?? '';
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: Colors.white,
            prefixIcon: Icon(icon, color: Colors.green),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
    );
  }

  Widget _buildTicketInput(String label, int value, void Function(int) onChanged) {
    return TextFormField(
      initialValue: value == 0 ? '' : value.toString(),
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (val) => onChanged(int.tryParse(val) ?? 0),
    );
  }
}
