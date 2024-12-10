
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _listenCurrentLocation();
  }

  late GoogleMapController _googleMapController;
  Position? _position;

  LatLng? _latLng;
  final Set<Marker> _marker = {};

  Future<void> _getCurrentLocation() async {
    final isGranted = await _isLocationPermissionGranted();
    if (isGranted) {
      final isEnable = await _checkGPSServiceEnable();
      if (isEnable) {
        Position currentPosition = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              timeLimit: Duration(seconds: 10),
              accuracy: LocationAccuracy.bestForNavigation),
        );
        _position = currentPosition;
        _marker.add(
          Marker(
            markerId: const MarkerId('current-location'),
            position: LatLng(_position!.latitude, _position!.longitude),
            infoWindow: const InfoWindow(title: 'My current location'),
          ),
        );
        setState(() {});
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await _requestLocationPermission();
      if (result) {
        _getCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }

  Future<bool> _isLocationPermissionGranted() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _requestLocationPermission() async {
    LocationPermission locationPermission =
    await Geolocator.requestPermission();
    if (locationPermission == LocationPermission.always ||
        locationPermission == LocationPermission.whileInUse) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _checkGPSServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Google Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
      ),
      body: GoogleMap(
        onTap: (LatLng latLng) {
          _marker.add(
            Marker(
                draggable: true,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue),
                markerId: const MarkerId('tap-marker'),
                position: latLng,
                infoWindow: InfoWindow(
                    title: '${latLng.latitude},${latLng.longitude}')),
          );
          _latLng = latLng;
          setState(() {});
        },
        onMapCreated: (GoogleMapController controller) {
          _googleMapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(0, 0),
        ),
        trafficEnabled: true,
        markers: _marker,
        polylines: <Polyline>{
          if (_position != null && _latLng != null)
            Polyline(
              color: Colors.blue,
              width: 3,
              jointType: JointType.mitered,
              polylineId: const PolylineId('initial-polyline'),
              points: <LatLng>[
                LatLng(_position!.latitude, _position!.longitude),
                LatLng(_latLng!.latitude, _latLng!.longitude),
              ],
            ),
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  FloatingActionButton _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: () async {
        if (_position == null) {
          await _getCurrentLocation();
        }
        if (_position != null) {
          _googleMapController.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                zoom: 16,
                target: LatLng(_position!.latitude, _position!.longitude),
              ),
            ),
          );
        }
      },
      backgroundColor: Colors.blue,
      child: const Icon(Icons.my_location),
    );
  }

  Future<void> _listenCurrentLocation() async {
    final isGranted = await _isLocationPermissionGranted();
    if (isGranted) {
      final isEnable = await _checkGPSServiceEnable();
      if (isEnable) {
        Geolocator.getPositionStream().listen((pos) {
          print(pos);
        });
      } else {
        Geolocator.openLocationSettings();
      }
    } else {
      final result = await _requestLocationPermission();
      if (result) {
        _getCurrentLocation();
      } else {
        Geolocator.openAppSettings();
      }
    }
  }
}
