import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManualTicketPage extends StatefulWidget {
  const ManualTicketPage({super.key});

  @override
  State<ManualTicketPage> createState() => _ManualTicketPageState();
}

class _ManualTicketPageState extends State<ManualTicketPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _stops = [];
  String? _selectedStart;
  String? _selectedDestination;
  double? _ticketPrice;

  int _fullCount = 0;
  int _halfCount = 0;

  double? _totalPrice;
  final int _leaf = 0; 

  bool _useLeaf = false;
  double _discount = 0.0;

  bool _isLoadingStops = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchBusStops();
  }

  Future<void> fetchBusStops() async {
    try {
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
        _isLoadingStops = false;
      });
    } catch (e) {
      setState(() => _isLoadingStops = false);
      debugPrint('Failed to fetch bus stops: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load bus stops')),
      );
    }
  }

  Future<void> fetchTicketPrice() async {
    if (_selectedStart == null || _selectedDestination == null) return;

    final routeId = "${_selectedStart!}_${_selectedDestination!}";
    final reverseRouteId = "${_selectedDestination!}_${_selectedStart!}";

    try {
      final doc = await _firestore.collection('fares').doc(routeId).get();
      if (doc.exists) {
        setState(() {
          _ticketPrice = (doc.data()?['price'] ?? 0).toDouble();
        });
        calculateTotalPrice();
      } else {
        final reverseDoc = await _firestore.collection('fares').doc(reverseRouteId).get();
        if (reverseDoc.exists) {
          setState(() {
            _ticketPrice = (reverseDoc.data()?['price'] ?? 0).toDouble();
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
    } catch (e) {
      debugPrint('Error fetching ticket price: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch ticket price')),
      );
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

  String _generateRefNumber() {
    final rand = Random();
    String randStr = '';
    for (int i = 0; i < 8; i++) {
      randStr += rand.nextInt(10).toString();
    }
    return randStr;
  }

  Future<void> saveManualTicket() async {
    if (_selectedStart == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and destination')),
      );
      return;
    }
    if (_fullCount == 0 && _halfCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ticket quantity')),
      );
      return;
    }
    if (_totalPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ticket price not calculated')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final refNumber = _generateRefNumber();

    final ticketData = {
      'start': _selectedStart,
      'destination': _selectedDestination,
      'full': _fullCount,
      'half': _halfCount,
      'amount': _totalPrice,
      'refNumber': refNumber,
      'leafReward': 0,
      'usedLeaves': _useLeaf ? _discount.toInt() : 0,
      'paid': false,
      'manual': true,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      debugPrint('Saving ticket: $ticketData');
      await _firestore.collection('manual_tickets').doc(refNumber).set(ticketData);

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Manual ticket saved!\nRef: $refNumber")),
      );

      // Clear form
      setState(() {
        _selectedStart = null;
        _selectedDestination = null;
        _fullCount = 0;
        _halfCount = 0;
        _totalPrice = null;
        _discount = 0.0;
        _useLeaf = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      debugPrint('Failed to save ticket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save ticket: $e")),
      );
    }
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
            prefixIcon: Icon(icon, color: Colors.green.shade800),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Manual Ticketing"),
        centerTitle: true,
        backgroundColor: Colors.green.shade800,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: _isLoadingStops
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStyledAutocomplete(
                      label: "Start Location",
                      icon: Icons.location_on,
                      value: _selectedStart,
                      onSelected: (val) {
                        setState(() => _selectedStart = val);
                        fetchTicketPrice();
                      },
                    ),

                    const SizedBox(height: 16),

                    _buildStyledAutocomplete(
                      label: "Destination",
                      icon: Icons.flag,
                      value: _selectedDestination,
                      onSelected: (val) {
                        setState(() => _selectedDestination = val);
                        fetchTicketPrice();
                      },
                    ),

                    const SizedBox(height: 20),

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

                    if (_totalPrice != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Ticket Price: Rs. ${_ticketPrice!.toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                            Text(
                              "Total Price: Rs. ${_totalPrice!.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            if (_discount > 0)
                              Text(
                                "Leaf Discount: Rs. ${_discount.toStringAsFixed(2)}",
                                style: TextStyle(color: Colors.teal.shade700),
                              ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : saveManualTicket,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_alt),
                      label: Text(_isSaving ? "Saving..." : "Save Ticket (Cash)"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade800,
                        foregroundColor: Colors.white, 
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
