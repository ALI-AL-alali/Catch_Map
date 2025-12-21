import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map/core/const/endpoint.dart';

import '../../models/driver_available_model.dart';
import '../../services/io_socket_services.dart';


import 'package:geolocator/geolocator.dart';

class SocketEvents {
  final SocketService _socketService;

  // Initialize it in the constructor
  SocketEvents() : _socketService = SocketService();

  var currentState = 'online';

  Future<void> openSocketConnection(final String event, final String status) async {
    try {
      await _socketService.connect('${EndPoint.socketUrl}', event, status);
      debugPrint('🔌 Socket connected to ${EndPoint.socketUrl}');

      // Send event only if the connection is successful
      if (_socketService.isConnected()) {
        _socketService.send(event, {'status': status});
      } else {
        debugPrint('Socket is not connected. Unable to send data.');
      }

      startListeningToSocketEvents(event, status);
    } catch (e, stackTrace) {
      debugPrint('❌ openSocketConnection error: $e');
      debugPrint('📌 StackTrace: $stackTrace');
      rethrow;
    }
  }

  Future<void> openSocketCustomerConnection() async {
    await _socketService.connect(
      EndPoint.socketUrl,
      'bid:placed',
      'placed',
      onConnected: () {
        // 👈 الآن الاتصال جاهز 100%
        _socketService.send('bid:placed', {'status': 'placed'});

      },
    );

    listenToAvailableDrivers();
  }


  // Start listening to events
  void startListeningToSocketEvents(String eventName, String status) {
    _socketService.on(eventName, (data) {
      debugPrint('$eventName: $data');
      // Send additional data if necessary
      _socketService.send(eventName, {'status': status});
    });
  }

  // Add this method to handle location updates
  void listenToLocationUpdates() {
    // Request location permission first
    _checkLocationPermission();

    // Start listening to the location stream
    Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,  // Updates when location changes by 5 meters
        timeLimit: Duration(seconds: 20),  // Interval between updates
      ),
    ).listen((Position position) {
      // Handle location updates
      _socketService.send('driver:location:update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'ride_id': 'currentRideId',  // Pass the ride ID dynamically
        'heading': position.heading,
        'speed': position.speed
      });
      debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
    });
  }

  // Check for location permissions
  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
    }
  }

  void closeSocketConnection() {
    _socketService.disconnect();
  }

  void sendCustomerPickupLocation({
    required double pickupLat,
    required double pickupLng,
  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket not connected');
      return;
    }

    debugPrint('📤 Sending pickup location');

    _socketService.send(
      'customer:availableDrivers',
      {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
      },
    );
  }


  void listenToAvailableDrivers() {
    _socketService.on(
      'availableDrivers:response',
          (data) {
        debugPrint('📥 Available drivers response: $data');

        final response = AvailableDriversResponse.fromJson(data);

        if (response.success) {
          debugPrint('✅ ${response.meta.totalFound} drivers found');

          for (final item in response.data) {
            debugPrint(
              '🚗 ${item.driver.name} | '
                  '${item.distanceKm} km | '
                  'ETA: ${item.estimatedArrival}',
            );
          }
        } else {
          debugPrint('❌ ${response.message}');
        }
      },
    );
  }





}



