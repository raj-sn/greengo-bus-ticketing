import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:gticketing/pages/home_page.dart'; // your homepage import
import '../../config/secrets.dart'; // your Google Maps API key

class TrackingPage extends StatefulWidget {
  const TrackingPage({super.key});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  LatLng _passengerLocation = const LatLng(7.8731, 80.7718);

  List<String> allBusStops = []; // all bus stops for autocomplete
  String? selectedBusStop;

  // Routes containing the selected bus stop
  List<String> filteredRoutes = [];

  // Live bus markers and positions
  final Map<String, Marker> _busMarkers = {};
  final Map<String, LatLng> _currentBusPositions = {};
  final Map<String, LatLng> _oldBusPositions = {};
  final Map<PolylineId, Polyline> _polylines = {};
  final Map<String, String> _busETA = {};
  final Map<String, String> _stopETA = {}; // New map for ETA to selected bus stop

  final Map<String, AnimationController> _animationControllers = {};

  final apiKey = Secrets.googleMapsApiKey;

  bool _initialZoomDone = false;

  String? _selectedBusId;

  Timer? _debounceCameraTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _determinePosition();
      await _fetchAllBusStops();

      // Zoom to user location on map once ready
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_passengerLocation, 14),
        );
      }
    });
  }

  int? _extractMinutes(String text) {
    final regex = RegExp(r'(\d+)\s*min');
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }


  Future<void> _fetchStopETA(LatLng busPosition, LatLng stopPosition, String busId) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/distancematrix/json?"
          "origins=${busPosition.latitude},${busPosition.longitude}"
          "&destinations=${stopPosition.latitude},${stopPosition.longitude}"
          "&key=$apiKey";

      var response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) throw Exception("Failed to fetch");

      var data = json.decode(response.body);
      var eta = _extractETA(data);

      if (!mounted) return;

      setState(() {
        _stopETA[busId] = eta != null
            ? "To Bus Stop: $eta"
            : "Stop ETA unavailable";
      });

    } catch (e) {
      print("Error fetching stop ETA: $e");
      if (!mounted) return;
      setState(() {
        _stopETA[busId] = "Stop ETA error";
      });

    }
  }


  Future<LatLng?> _getBusStopLocation(String busStopName) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('bus_stops')
        .doc(busStopName)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      return LatLng(data['latitude'], data['longitude']);
    }
  } catch (e) {
    print('Error fetching bus stop location: $e');
  }
  return null;
}

String _buildBusInfoSnippet(String busId) {
  String toUser = _busETA[busId] ?? "ETA to You: Loading...";
  String toStop = _stopETA[busId] ?? "ETA to Stop: Loading...";
  return "$toUser\n$toStop\nTap to refresh";
}




  Future<void> _determinePosition() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permission permanently denied. Enable from settings.",
          ),
        ),
      );
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _passengerLocation = LatLng(position.latitude, position.longitude);
      });

      // If map already created, move camera to user location
      if (_mapController != null && !_initialZoomDone) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_passengerLocation, 14),
        );
        _initialZoomDone = true;
      }

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to get current location.")),
      );
    }
  }

  Future<void> _fetchAllBusStops() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('routes').get();

      Set<String> stopsSet = {};
      for (var doc in querySnapshot.docs) {
        final busStops = List<String>.from(doc['busStops'] ?? []);
        stopsSet.addAll(busStops);
      }

      setState(() {
        allBusStops = stopsSet.toList()..sort();
      });

      print('All bus stops fetched: $allBusStops');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch bus stops: $e')));
    }
  }

  Future<void> _onBusStopSelected(String busStop) async {
    setState(() {
      _selectedBusId = null;
      selectedBusStop = busStop;
      filteredRoutes.clear();
      _busMarkers.clear();
      _currentBusPositions.clear();
      _oldBusPositions.clear();
      _polylines.clear();
      _busETA.clear();
      _stopETA.clear();
    });

    LatLng? selectedStopLatLng = await _getBusStopLocation(busStop);

    if (selectedStopLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Coordinates for $busStop not found.")),
      );
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .where('busStops', arrayContains: busStop)
          .get();

      List<String> routes = querySnapshot.docs.map((d) => d.id).toList();

      setState(() {
        filteredRoutes = routes;
      });

      _listenToBusLocations(selectedStopLatLng);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch routes: $e')),
      );
    }
  }



  Future<BitmapDescriptor> _getBusIcon() async {
    final ByteData data = await rootBundle.load('assets/image/busmap.png');
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: 75,
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  void _listenToBusLocations(LatLng destinationLatLng) async {
    if (filteredRoutes.isEmpty) {
      setState(() {
        _busMarkers.clear();
        _currentBusPositions.clear();
        _oldBusPositions.clear();
        _polylines.clear();
        _busETA.clear();
      });
      return;
    }

    List<List<String>> chunks = [];
    int chunkSize = 10;
    for (var i = 0; i < filteredRoutes.length; i += chunkSize) {
      chunks.add(
        filteredRoutes.sublist(
          i,
          i + chunkSize > filteredRoutes.length
              ? filteredRoutes.length
              : i + chunkSize,
        ),
      );
    }

    _busMarkers.clear();
    _currentBusPositions.clear();
    _oldBusPositions.clear();
    _polylines.clear();
    _busETA.clear();

    for (var chunk in chunks) {
      FirebaseFirestore.instance
          .collection('bus_tracking')
          .where('route', whereIn: chunk)
          .snapshots()
          .listen((snapshot) async {
        BitmapDescriptor busIcon = await _getBusIcon();

        for (var doc in snapshot.docs) {
          String busId = doc.id;
          LatLng newPosition = LatLng(doc['latitude'], doc['longitude']);
          // ignore: unused_local_variable
          String route = doc['route'];

          _oldBusPositions[busId] = _currentBusPositions[busId] ?? newPosition;
          _currentBusPositions[busId] = newPosition;

          _animateBusMovement(busId, busIcon);
          _fetchETA(newPosition, busId); // ETA to user's current location
          _fetchStopETA(newPosition, destinationLatLng, busId); // ETA to selected stop
        }
      });
    }
  }

  

  void _animateBusMovement(String busId, BitmapDescriptor busIcon) {
    LatLng? oldPos = _oldBusPositions[busId];
    LatLng? newPos = _currentBusPositions[busId];
    if (oldPos == null || newPos == null) return;

    // Dispose existing animation controller if any
    _animationControllers[busId]?.dispose();

    AnimationController controller = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    );

    Animation<double> animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.linear));

    animation.addListener(() {
      if (!mounted) return;
      final double lat = ui.lerpDouble(oldPos.latitude, newPos.latitude, animation.value)!;
      final double lng = ui.lerpDouble(oldPos.longitude, newPos.longitude, animation.value)!;
      final double bearing = _calculateBearing(oldPos, newPos);

      // Update marker position smoothly
      setState(() {
        _busMarkers[busId] = Marker(
          markerId: MarkerId(busId),
          position: LatLng(lat, lng),
          icon: busIcon,
          rotation: bearing,
          infoWindow: InfoWindow(
            title: "Bus $busId",
            snippet: _buildBusInfoSnippet(busId),
            onTap: () async {
              await _fetchETA(newPos, busId);

              if (selectedBusStop != null) {
                LatLng? stopLoc = await _getBusStopLocation(selectedBusStop!);
                if (stopLoc != null) {
                  await _fetchStopETA(newPos, stopLoc, busId);
                }
              }

              if (!mounted) return;
              setState(() {
                _busMarkers[busId] = Marker(
                  markerId: MarkerId(busId),
                  position: newPos,
                  icon: busIcon,
                  rotation: _calculateBearing(oldPos, newPos),
                  infoWindow: InfoWindow(
                    title: "Bus $busId",
                    snippet: _buildBusInfoSnippet(busId),
                  ),
                  onTap: () {
                    setState(() {
                      _selectedBusId = busId;
                    });
                    _fetchRoute(newPos, busId);
                  },

                );
              });
            },
          ),
          onTap: () {
            setState(() {
              _selectedBusId = busId;
            });
            _fetchRoute(newPos, busId);
          },

        );
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        _animationControllers.remove(busId);
      }
    });

    _animationControllers[busId] = controller;
    controller.forward();
  }


  Future<void> _fetchETA(LatLng busPosition, String busId) async {
    try {
      String baseUrl =
          "https://maps.googleapis.com/maps/api/distancematrix/json?"
          "origins=${busPosition.latitude},${busPosition.longitude}"
          "&destinations=${_passengerLocation.latitude},${_passengerLocation.longitude}"
          "&key=$apiKey";

      var response = await http.get(
        Uri.parse("$baseUrl&mode=transit&transit_mode=bus"),
      );
      if (response.statusCode != 200) {
        throw Exception('API error with status: ${response.statusCode}');
      }

      var data = json.decode(response.body);
      var eta = _extractETA(data);

      if (eta == null) {
        response = await http.get(
          Uri.parse("$baseUrl&mode=driving&avoid=highways"),
        );
        if (response.statusCode == 200) {
          data = json.decode(response.body);
          eta = _extractETA(data);
        }
      }

      if (!mounted) return;
      setState(() {
        _busETA[busId] = eta != null ? "Arrives in $eta" : "ETA unavailable";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busETA[busId] = "Error fetching ETA";
      });
      print('Error fetching ETA for bus $busId: $e');
    }
  }

  String? _extractETA(dynamic data) {
    if (data["rows"].isNotEmpty &&
        data["rows"][0]["elements"].isNotEmpty &&
        data["rows"][0]["elements"][0]["status"] == "OK") {
      return data["rows"][0]["elements"][0]["duration"]["text"];
    }
    return null;
  }

  Future<void> _fetchRoute(LatLng busPosition, String busId) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?"
        "origin=${busPosition.latitude},${busPosition.longitude}"
        "&destination=${_passengerLocation.latitude},${_passengerLocation.longitude}"
        "&mode=transit"
        "&transit_mode=bus"
        "&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);

      if (response.statusCode == 200 && data["routes"].isNotEmpty) {
        List<LatLng> points = _decodePolyline(
          data["routes"][0]["overview_polyline"]["points"],
        );
        setState(() {
          _polylines[PolylineId(busId)] = Polyline(
            polylineId: PolylineId(busId),
            color: Colors.green,
            width: 5,
            points: points,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error fetching route: $e")));
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return points;
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * pi / 180;
    double startLng = start.longitude * pi / 180;
    double endLat = end.latitude * pi / 180;
    double endLng = end.longitude * pi / 180;

    double deltaLng = endLng - startLng;
    double y = sin(deltaLng) * cos(endLat);
    double x =
        cos(startLat) * sin(endLat) -
        sin(startLat) * cos(endLat) * cos(deltaLng);

    double bearing = atan2(y, x);
    return (bearing * 180 / pi + 360) % 360;
  }

  @override
  void dispose() {
    _debounceCameraTimer?.cancel();
    _mapController?.dispose();
    for (var controller in _animationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Track Your Bus"),
        backgroundColor: const Color.fromARGB(255, 22, 97, 14),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const homepage()),
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text == '') {
                  return const Iterable<String>.empty();
                }
                return allBusStops.where(
                  (stop) => stop.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  ),
                );
              },
              onSelected: (String selection) {
                _onBusStopSelected(selection);
              },
              fieldViewBuilder: (
                context,
                controller,
                focusNode,
                onFieldSubmitted,
              ) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Search Bus Stop',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                );
              },
            ),
          ),

          // 🟡 ETA section shown only when a bus is selected and ETA exists
          if (_selectedBusId != null &&
              _stopETA.containsKey(_selectedBusId) &&
              _busETA.containsKey(_selectedBusId)) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        "Live ETA Details:",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.grey.shade100,
                    child: ListTile(
                      leading: const Icon(Icons.directions_bus, color: Colors.blue),
                      title: Text(
                        "Bus $_selectedBusId",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_circle,
                                  color: Colors.orange, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _busETA[_selectedBusId!] ?? "Arrives in --",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_pin,
                                  color: Colors.green, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _stopETA[_selectedBusId!] ?? "To Bus Stop: --",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.timelapse,
                                  color: Colors.purple, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                () {
                                  int stopMins = _extractMinutes(
                                          _stopETA[_selectedBusId!] ?? "") ??
                                      0;
                                  int arriveMins = _extractMinutes(
                                          _busETA[_selectedBusId!] ?? "") ??
                                      0;
                                  return "Total Travel Time: ${stopMins + arriveMins} min";
                                }(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],



          Expanded(
            child: GoogleMap(
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: _passengerLocation,
                zoom: 14,
              ),
              markers: _busMarkers.values.toSet(),
              polylines: _polylines.values.toSet(),
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.my_location),
        onPressed: () async {
          Position position = await Geolocator.getCurrentPosition();
          LatLng newLoc = LatLng(position.latitude, position.longitude);
          setState(() => _passengerLocation = newLoc);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(newLoc, 14),
          );
        },
      ),
    );
  }

}
