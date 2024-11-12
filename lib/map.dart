import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRole {
  static const String carOwner = 'car_owner';
  static const String student = 'student';
}

class CarpoolMapPage extends StatefulWidget {
  const CarpoolMapPage({super.key});

  @override
  State<CarpoolMapPage> createState() => _CarpoolMapPageState();
}

class _CarpoolMapPageState extends State<CarpoolMapPage> {
  late final MapController _mapController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String? _userEmail = FirebaseAuth.instance.currentUser?.email;

  String? _userRole;
  LatLng? _currentLocation;
  List<Map<String, dynamic>> _carpoolLocations = [];
  bool _isLoading = true;
  bool _isSearching = false;
  double _searchRadius = 5.0;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initialize();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    if (_userEmail == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
        Navigator.pop(context);
      }
      return;
    }

    await _getCurrentLocation();

    if (mounted) {
      await _showRoleSelectionDialog();
    }

    if (_currentLocation != null && _userRole != null) {
      if (_userRole == UserRole.student) {
        await _searchNearbyCarpools();
      } else {
        await _saveCarOwnerLocation();
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showRoleSelectionDialog() async {
    String? selectedRole = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Your Role'),
          content: const Text(
              'Are you a car owner offering rides or a student looking for a ride?'),
          actions: [
            TextButton(
              child: const Text('Car Owner'),
              onPressed: () => Navigator.pop(context, UserRole.carOwner),
            ),
            TextButton(
              child: const Text('Student'),
              onPressed: () => Navigator.pop(context, UserRole.student),
            ),
          ],
        );
      },
    );

    if (selectedRole != null && mounted) {
      setState(() => _userRole = selectedRole);
    } else {
      if (mounted) {
        await _showRoleSelectionDialog();
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enable location services in your browser.'),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied by browser.'),
              ),
            );
          }
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Please allow location access in your browser settings.'),
          ),
        );
      }
    }
  }

  Future<void> _saveCarOwnerLocation() async {
    if (_currentLocation == null || _userEmail == null) return;

    try {
      await _firestore.collection('nearby_locations').doc(_userEmail).set({
        'email': _userEmail,
        'location':
            GeoPoint(_currentLocation!.latitude, _currentLocation!.longitude),
        'role': UserRole.carOwner,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'available', // New field for driver availability
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Your location has been saved. Students can now find you!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving location: $e')),
        );
      }
    }
  }

  Future<void> _searchNearbyCarpools() async {
    if (_currentLocation == null) return;

    setState(() => _isSearching = true);

    try {
      // Query all active car owners
      QuerySnapshot snapshot = await _firestore
          .collection('nearby_locations')
          .where('role', isEqualTo: UserRole.carOwner)
          .where('status', isEqualTo: 'available')
          .get();

      List<Map<String, dynamic>> locations = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final GeoPoint location = data['location'] as GeoPoint;
        final carLocation = LatLng(location.latitude, location.longitude);

        final distanceInKm = const Distance().as(
          LengthUnit.Kilometer,
          _currentLocation!,
          carLocation,
        );

        if (distanceInKm <= _searchRadius) {
          locations.add({
            'email': data['email'] as String,
            'location': location,
            'distance': distanceInKm,
            'timestamp': data['timestamp'],
            'status': data['status'] ?? 'available',
          });
        }
      }

      // Sort locations by distance
      locations.sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

      if (mounted) {
        setState(() {
          _carpoolLocations = locations;
          _isSearching = false;
        });

        if (_carpoolLocations.isNotEmpty && _isMapReady) {
          _zoomToRelevantArea();

          // Show summary of found drivers
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Found ${_carpoolLocations.length} available drivers within $_searchRadius km',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (_carpoolLocations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No available car owners found within $_searchRadius km. Try increasing the search radius.',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        print(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for carpools: $e')),
        );
        setState(() => _isSearching = false);
      }
    }
  }

  void _zoomToRelevantArea() {
    if (_currentLocation == null || _carpoolLocations.isEmpty || !_isMapReady) {
      return;
    }

    final points = [
      _currentLocation!,
      ..._carpoolLocations.map((e) {
        final location = e['location'] as GeoPoint;
        return LatLng(location.latitude, location.longitude);
      })
    ];

    final latitudes = points.map((p) => p.latitude);
    final longitudes = points.map((p) => p.longitude);

    final southWest = LatLng(
      latitudes.reduce(min),
      longitudes.reduce(min),
    );
    final northEast = LatLng(
      latitudes.reduce(max),
      longitudes.reduce(max),
    );

    final bounds = LatLngBounds(southWest, northEast);
    final padded = _addPadding(bounds, 0.1);

    final zoom = _calculateZoomLevel(padded);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _isMapReady) {
        _mapController.move(padded.center, zoom);
      }
    });
  }

  List<Marker> _buildMarkers() {
    List<Marker> markers = [];

    // Add current user's marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: _currentLocation!,
          child: Column(
            children: [
              Icon(
                _userRole == UserRole.carOwner
                    ? Icons.directions_car
                    : Icons.person,
                color: Colors.blue,
                size: 40,
              ),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Add markers for all nearby drivers
    for (var index = 0; index < _carpoolLocations.length; index++) {
      final carpool = _carpoolLocations[index];
      final location = carpool['location'] as GeoPoint;
      final point = LatLng(location.latitude, location.longitude);
      final distance = carpool['distance'] as double;

      markers.add(
        Marker(
          width: 80.0,
          height: 80.0,
          point: point,
          child: GestureDetector(
            onTap: () => _showCarpoolDetails(carpool),
            child: Column(
              children: [
                Stack(
                  children: [
                    const Icon(
                      Icons.directions_car,
                      color: Colors.red,
                      size: 40,
                    ),
                    if (carpool['status'] == 'available')
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${distance.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  void _showCarpoolDetails(Map<String, dynamic> carpool) {
    if (_currentLocation == null) return;

    final distance = carpool['distance'] as double;
    final timestamp = carpool['timestamp'] as Timestamp?;
    final lastUpdated = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp.millisecondsSinceEpoch)
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Driver Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Driver Email: ${carpool['email']}'),
              Text('Distance: ${distance.toStringAsFixed(2)} km'),
              if (lastUpdated != null)
                Text('Last Updated: ${_formatTimestamp(lastUpdated)}'),
              Text('Status: ${carpool['status'] ?? 'unknown'}'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Contact Driver'),
              onPressed: () {
                Navigator.pop(context);
                _contactDriver(carpool['email']);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Future<void> _showRadiusDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        double tempRadius = _searchRadius;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Search Radius'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                      'Set search radius (in kilometers): ${tempRadius.toStringAsFixed(1)}'),
                  Slider(
                    value: tempRadius,
                    min: 1,
                    max: 20,
                    divisions: 38,
                    onChanged: (double value) {
                      setState(() => tempRadius = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Apply'),
                  onPressed: () {
                    this.setState(() => _searchRadius = tempRadius);
                    Navigator.pop(context);
                    _searchNearbyCarpools();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  double _calculateZoomLevel(LatLngBounds bounds) {
    const maxZoom = 15.0;
    const minZoom = 3.0;

    final latDiff =
        (bounds.northEast.latitude - bounds.southWest.latitude).abs();
    final lngDiff =
        (bounds.northEast.longitude - bounds.southWest.longitude).abs();

    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;
    double zoom = 15 - (maxDiff * 25);

    return zoom.clamp(minZoom, maxZoom);
  }

  LatLngBounds _addPadding(LatLngBounds bounds, double padding) {
    final lat =
        (bounds.northEast.latitude - bounds.southWest.latitude) * padding;
    final lng =
        (bounds.northEast.longitude - bounds.southWest.longitude) * padding;

    return LatLngBounds(
      LatLng(bounds.southWest.latitude - lat, bounds.southWest.longitude - lng),
      LatLng(bounds.northEast.latitude + lat, bounds.northEast.longitude + lng),
    );
  }

  void _contactDriver(String driverEmail) {
    // Implement your contact logic here
    // For example, you could launch an email client or show a contact form
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Contact Driver'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Contact details for: $driverEmail'),
              const SizedBox(height: 16),
              const TextField(
                decoration: InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Message sent to $driverEmail'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Send Message'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentLocation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Carpool Map')),
        body: const Center(
          child:
              Text('Unable to get location. Please enable location services.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userRole == UserRole.carOwner
            ? 'Your Location'
            : 'Find Nearby Carpools'),
        actions: [
          if (_userRole == UserRole.student)
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Adjust Search Radius',
              onPressed: _showRadiusDialog,
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () async {
              await _getCurrentLocation();
              if (_userRole == UserRole.student) {
                await _searchNearbyCarpools();
              } else {
                await _saveCarOwnerLocation();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on My Location',
            onPressed: () {
              if (_currentLocation != null && _isMapReady) {
                _mapController.move(_currentLocation!, 15);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation!,
              initialZoom: 13.0,
              onMapReady: () {
                setState(() => _isMapReady = true);
                if (_carpoolLocations.isNotEmpty) {
                  _zoomToRelevantArea();
                }
              },
              onPositionChanged: (position, hasGesture) {
                // You could add custom behavior when map position changes
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              MarkerLayer(markers: _buildMarkers()),
            ],
          ),
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Searching for nearby drivers...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_userRole == UserRole.student && !_isSearching)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: _searchNearbyCarpools,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Search'),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper functions
double min(double a, double b) => a < b ? a : b;
double max(double a, double b) => a > b ? a : b;
