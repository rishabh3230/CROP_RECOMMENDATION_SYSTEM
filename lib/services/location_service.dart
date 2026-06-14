import 'package:geolocator/geolocator.dart';
import 'dart:async';

/// A service to handle location-related operations using the geolocator package.
class LocationService {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: Duration(seconds: 15),
  );

  /// Checks permissions and returns the current position.
  /// Throws a descriptive exception if location services are disabled or permissions are denied.
  Future<Position> getCurrentLocation() async {
    // Test if location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception(
          'Location services are disabled. Please enable GPS in your device settings.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions were denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Open app settings so user can manually grant the permission.
      await Geolocator.openAppSettings();
      throw Exception(
          'Location permissions are permanently denied. Please grant them in App Settings.');
    }

    // Permissions granted — fetch the position.
    return await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    );
  }

  /// Returns a stream of position updates.
  Stream<Position> startTracking() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }
}
