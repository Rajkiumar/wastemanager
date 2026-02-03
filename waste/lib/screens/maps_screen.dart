import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLocation;
  final Set<Marker> _markers = {};
  final Set<Polygon> _polygons = {};
  bool _showTrucks = true;
  bool _showZones = true;
  bool _showUserLocation = true;
  bool _showAllUsers = true;

  StreamSubscription<QuerySnapshot>? _usersLocationSubscription;
  StreamSubscription<QuerySnapshot>? _driversLocationSubscription;
  StreamSubscription<Position>? _positionStreamSubscription;

  String get _currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Collection zones (sample data - replace with Firestore queries)
  final List<Map<String, dynamic>> _collectionZones = [
    {
      'name': 'Zone A - Downtown',
      'center': const LatLng(37.7749, -122.4194),
      'points': [
        const LatLng(37.7749, -122.4194),
        const LatLng(37.7849, -122.4194),
        const LatLng(37.7849, -122.4094),
        const LatLng(37.7749, -122.4094),
      ],
    },
    {
      'name': 'Zone B - North',
      'center': const LatLng(37.7849, -122.4294),
      'points': [
        const LatLng(37.7849, -122.4294),
        const LatLng(37.7949, -122.4294),
        const LatLng(37.7949, -122.4194),
        const LatLng(37.7849, -122.4194),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
    _startLocationUpdates();
    _loadTruckLocations();
    _loadCollectionZones();
    _subscribeToAllUsersLocations();
    _subscribeToDriversLocations();
  }

  @override
  void dispose() {
    _usersLocationSubscription?.cancel();
    _driversLocationSubscription?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  /// Start continuous location updates and sync to Firestore
  void _startLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _updateMyLocationInFirestore(position);
            setState(() {
              _userLocation = LatLng(position.latitude, position.longitude);
            });
          },
        );
  }

  /// Update current user's location in Firestore
  Future<void> _updateMyLocationInFirestore(Position position) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Get user profile to check role
      final profileDoc = await FirebaseFirestore.instance
          .collection('userProfiles')
          .doc(user.uid)
          .get();

      final role = profileDoc.data()?['role'] as String? ?? 'user';
      final displayName =
          profileDoc.data()?['displayName'] as String? ??
          user.email?.split('@').first ??
          'User';

      // Store in userLocations collection
      await FirebaseFirestore.instance
          .collection('userLocations')
          .doc(user.uid)
          .set({
            'userId': user.uid,
            'displayName': displayName,
            'email': user.email,
            'role': role,
            'latitude': position.latitude,
            'longitude': position.longitude,
            'timestamp': FieldValue.serverTimestamp(),
            'isOnline': true,
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating location in Firestore: $e');
    }
  }

  /// Subscribe to all users' locations (real-time)
  void _subscribeToAllUsersLocations() {
    _usersLocationSubscription = FirebaseFirestore.instance
        .collection('userLocations')
        .where('role', isEqualTo: 'user')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          if (!_showAllUsers) return;

          // Remove old user markers
          _markers.removeWhere(
            (m) =>
                m.markerId.value.startsWith('user_') &&
                m.markerId.value != 'user_location',
          );

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final lat = data['latitude'] as double?;
            final lng = data['longitude'] as double?;
            final displayName = data['displayName'] as String? ?? 'User';
            final isCurrentUser = doc.id == _currentUserId;

            if (lat != null && lng != null && !isCurrentUser) {
              _markers.add(
                Marker(
                  markerId: MarkerId('user_${doc.id}'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: displayName,
                    snippet: 'Community Member',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueAzure,
                  ),
                ),
              );
            }
          }

          if (mounted) setState(() {});
        });
  }

  /// Subscribe to all drivers' locations (real-time)
  void _subscribeToDriversLocations() {
    _driversLocationSubscription = FirebaseFirestore.instance
        .collection('userLocations')
        .where('role', isEqualTo: 'driver')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
          if (!_showTrucks) return;

          // Remove old driver markers
          _markers.removeWhere((m) => m.markerId.value.startsWith('driver_'));

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final lat = data['latitude'] as double?;
            final lng = data['longitude'] as double?;
            final displayName = data['displayName'] as String? ?? 'Driver';

            if (lat != null && lng != null) {
              _markers.add(
                Marker(
                  markerId: MarkerId('driver_${doc.id}'),
                  position: LatLng(lat, lng),
                  infoWindow: InfoWindow(
                    title: '🚛 $displayName',
                    snippet: 'Waste Collection Driver',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueGreen,
                  ),
                ),
              );
            }
          }

          if (mounted) setState(() {});
        });
  }

  Future<void> _getUserLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      if (_userLocation != null && _showUserLocation) {
        _addUserLocationMarker();
        if (_mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation!));
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get your location: $e')),
        );
      }
    }
  }

  void _addUserLocationMarker() {
    if (_userLocation == null) return;

    _markers.add(
      Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  Future<void> _loadTruckLocations() async {
    if (!_showTrucks) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('trucks')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        // Note: You need to store lat/lng in truck documents
        // For now, using sample coordinates
        final neighborhood = data['neighborhood'] as String?;
        final status = data['status'] as String?;

        _markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: _generateRandomLocationNearby(),
            infoWindow: InfoWindow(
              title: neighborhood ?? 'Truck',
              snippet: 'Status: $status',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(_getStatusHue(status)),
          ),
        );
      }

      setState(() {});
    } catch (e) {
      debugPrint('Error loading truck locations: $e');
    }
  }

  void _loadCollectionZones() {
    if (!_showZones) return;

    for (final zone in _collectionZones) {
      _polygons.add(
        Polygon(
          polygonId: PolygonId(zone['name']),
          points: List<LatLng>.from(zone['points']),
          geodesic: true,
          strokeColor: Colors.green,
          strokeWidth: 2,
          fillColor: Colors.green.withValues(alpha: 0.15),
        ),
      );

      _markers.add(
        Marker(
          markerId: MarkerId(zone['name']),
          position: zone['center'],
          infoWindow: InfoWindow(title: zone['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    setState(() {});
  }

  LatLng _generateRandomLocationNearby() {
    // Generate random location near San Francisco (for demo)
    final random = DateTime.now().millisecond;
    return LatLng(
      37.7749 + (random % 100) / 10000,
      -122.4194 + (random % 100) / 10000,
    );
  }

  double _getStatusHue(String? status) {
    switch (status?.toLowerCase()) {
      case 'on time':
        return BitmapDescriptor.hueBlue;
      case 'early':
        return BitmapDescriptor.hueGreen;
      case 'late':
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  void _toggleTrucks() {
    setState(() => _showTrucks = !_showTrucks);
    if (_showTrucks) {
      _loadTruckLocations();
      _subscribeToDriversLocations();
    } else {
      _markers.removeWhere(
        (m) =>
            m.markerId.value.startsWith('truck_') ||
            m.markerId.value.startsWith('driver_'),
      );
    }
  }

  void _toggleZones() {
    setState(() => _showZones = !_showZones);
    if (_showZones) {
      _loadCollectionZones();
    } else {
      _polygons.clear();
    }
  }

  void _toggleUserLocation() {
    setState(() => _showUserLocation = !_showUserLocation);
    if (_showUserLocation && _userLocation != null) {
      _addUserLocationMarker();
    } else {
      _markers.removeWhere((m) => m.markerId.value == 'user_location');
    }
  }

  void _toggleAllUsers() {
    setState(() => _showAllUsers = !_showAllUsers);
    if (_showAllUsers) {
      _subscribeToAllUsersLocations();
    } else {
      _markers.removeWhere(
        (m) =>
            m.markerId.value.startsWith('user_') &&
            m.markerId.value != 'user_location',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: (controller) {
              setState(() => _mapController = controller);
            },
            initialCameraPosition: CameraPosition(
              target: _userLocation ?? const LatLng(37.7749, -122.4194),
              zoom: 13,
            ),
            markers: _markers,
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Custom Controls
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _buildMapControlButton(
                  icon: Icons.my_location,
                  onPressed: _getUserLocation,
                  tooltip: 'Center on my location',
                ),
                const SizedBox(height: 8),
                _buildMapControlButton(
                  icon: Icons.layers,
                  onPressed: _showLayerMenu,
                  tooltip: 'Map layers',
                ),
              ],
            ),
          ),

          // Legend
          Positioned(
            bottom: 16,
            left: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_showUserLocation)
                      _buildLegendItem('Blue', 'Your Location'),
                    if (_showAllUsers)
                      _buildLegendItem('Cyan', 'Community Members'),
                    if (_showTrucks) ...[
                      _buildLegendItem('Green', 'Drivers'),
                      _buildLegendItem('Orange', 'Trucks'),
                    ],
                    if (_showZones)
                      _buildLegendItem('Green Area', 'Collection Zone'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return FloatingActionButton(
      mini: true,
      heroTag: tooltip,
      onPressed: onPressed,
      tooltip: tooltip,
      child: Icon(icon),
    );
  }

  Widget _buildLegendItem(String color, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getLegendColor(color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Color _getLegendColor(String color) {
    switch (color.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'cyan':
        return Colors.cyan;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'red':
        return Colors.red;
      case 'green area':
        return Colors.green.withValues(alpha: 0.3);
      default:
        return Colors.grey;
    }
  }

  void _showLayerMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Map Layers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Show My Location'),
              subtitle: const Text('Your current position'),
              value: _showUserLocation,
              onChanged: (_) => {Navigator.pop(context), _toggleUserLocation()},
            ),
            CheckboxListTile(
              title: const Text('Show All Users'),
              subtitle: const Text('Community members on the map'),
              value: _showAllUsers,
              onChanged: (_) => {Navigator.pop(context), _toggleAllUsers()},
            ),
            CheckboxListTile(
              title: const Text('Show Drivers'),
              subtitle: const Text('Waste collection drivers'),
              value: _showTrucks,
              onChanged: (_) => {Navigator.pop(context), _toggleTrucks()},
            ),
            CheckboxListTile(
              title: const Text('Show Collection Zones'),
              subtitle: const Text('Waste collection areas'),
              value: _showZones,
              onChanged: (_) => {Navigator.pop(context), _toggleZones()},
            ),
          ],
        ),
      ),
    );
  }
}
