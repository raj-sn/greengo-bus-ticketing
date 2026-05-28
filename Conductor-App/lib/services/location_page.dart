import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gconductor/auth/login_page.dart';
import 'package:gconductor/pages/homepage2.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final TextEditingController _routeController = TextEditingController();
  final TextEditingController _busIDController = TextEditingController();
  String? savedRoute;
  String? savedBusID;
  bool isTracking = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _checkPermissions();
  }

  Future<void> _loadSavedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      savedRoute = prefs.getString("bus_route") ?? "";
      savedBusID = prefs.getString("bus_id") ?? "";
      _routeController.text = savedRoute!;
      _busIDController.text = savedBusID!;
    });
  }

  Future<void> _saveData(String route, String busID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("bus_route", route);
    await prefs.setString("bus_id", busID);
    setState(() {
      savedRoute = route;
      savedBusID = busID;
    });
  }

  Future<void> _checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      LocationPermission request = await Geolocator.requestPermission();
      if (request == LocationPermission.denied ||
          request == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("GPS Permission is required!")),
        );
      }
    }
  }

  void _startTracking() async {
    if (savedRoute == null ||
        savedRoute!.isEmpty ||
        savedBusID == null ||
        savedBusID!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both Bus Route & Bus ID!")),
      );
      return;
    }

    final service = FlutterBackgroundService();
    setState(() => isTracking = true);
    service.startService();
    _sendLocationUpdates();

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HomePage2()),
    );
  }

  void _stopTracking() async {
    final service = FlutterBackgroundService();
    service.invoke("stopService");
    setState(() {
      isTracking = false;
    });
  }

  Future<void> _sendLocationUpdates() async {
    while (isTracking) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (savedBusID != null && savedBusID!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection("bus_tracking")
            .doc(savedBusID)
            .set({
          "bus_id": savedBusID,
          "route": savedRoute,
          "latitude": position.latitude,
          "longitude": position.longitude,
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      await Future.delayed(const Duration(seconds: 3));
    }
  }

  void _logout() async {
    // Stop background service
    final service = FlutterBackgroundService();
    service.invoke("stopService");

    // Sign out from Firebase
    await FirebaseAuth.instance.signOut();

    // Show message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logged out successfully')),
    );

    // Navigate to login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: const Text(
          "Conductor Ride Tracker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height -
                kToolbarHeight -
                48,
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Enter Ride Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _busIDController,
                      decoration: InputDecoration(
                        labelText: "Bus ID",
                        prefixIcon: const Icon(Icons.directions_bus_filled_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        _saveData(_routeController.text, value);
                      },
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _routeController,
                      decoration: InputDecoration(
                        labelText: "Bus Route",
                        prefixIcon: const Icon(Icons.alt_route),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onChanged: (value) {
                        _saveData(value, _busIDController.text);
                      },
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton.icon(
                      onPressed: _startTracking,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text("Start Ride"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _stopTracking,
                      icon: const Icon(Icons.stop_circle_outlined),
                      label: const Text("End Ride"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
