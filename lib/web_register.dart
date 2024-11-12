import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Data Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LocationDataScreen(),
    );
  }
}

class LocationDataScreen extends StatefulWidget {
  const LocationDataScreen({super.key});

  @override
  State<LocationDataScreen> createState() => _LocationDataScreenState();
}

class _LocationDataScreenState extends State<LocationDataScreen> {
  bool _isLoading = false;
  String _status = '';

  // Dummy location data
  final List<Map<String, dynamic>> dummyLocations = [
    {
      "email": "driver1@example.com",
      "location": const GeoPoint(37.7858, -122.4064),
      "role": "car_owner",
      "timestamp": FieldValue.serverTimestamp(),
    },
    {
      "email": "driver2@example.com",
      "location": const GeoPoint(37.7944, -122.3942),
      "role": "car_owner",
      "timestamp": FieldValue.serverTimestamp(),
    },
    {
      "email": "driver3@example.com",
      "location": const GeoPoint(37.7749, -122.4194),
      "role": "car_owner",
      "timestamp": FieldValue.serverTimestamp(),
    },
    {
      "email": "driver4@example.com",
      "location": const GeoPoint(37.7866, -122.4000),
      "role": "car_owner",
      "timestamp": FieldValue.serverTimestamp(),
    },
    {
      "email": "driver5@example.com",
      "location": const GeoPoint(37.7920, -122.4100),
      "role": "car_owner",
      "timestamp": FieldValue.serverTimestamp(),
    },
  ];

  Future<void> addDummyData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _status = 'Adding dummy data...';
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      for (final location in dummyLocations) {
        final docRef =
            firestore.collection('nearby_locations').doc(location['email']);
        batch.set(docRef, location);
      }

      await batch.commit();

      setState(() {
        _status = 'Successfully added dummy data!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error adding dummy data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> clearAllData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _status = 'Clearing all data...';
    });

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('nearby_locations').get();
      final batch = firestore.batch();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      setState(() {
        _status = 'Successfully cleared all data!';
      });
    } catch (e) {
      setState(() {
        _status = 'Error clearing data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Data Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : addDummyData,
              child: const Text('Add Dummy Data'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : clearAllData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear All Data'),
            ),
            const SizedBox(height: 24),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:
                        _status.contains('Error') ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
