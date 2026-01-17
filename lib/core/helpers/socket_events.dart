import 'dart:async';

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

  // Start listening to events
  void startListeningToSocketEvents(String eventName, String status) {
    _socketService.on(eventName, (data) {
      debugPrint('$eventName: $data');
      // Send additional data if necessary
      _socketService.send(eventName, {'status': status});
    });
  }

  void closeSocketConnection() {
    _socketService.disconnect();
  }

  void emit(String event, Map<String, dynamic> data) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket not connected, cannot emit $event');
      return;
    }

    debugPrint('📤 EMIT => $event | DATA => $data');
    _socketService.send(event, data);
  }
  //////// open socket for customer /////////

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
      'new:ride',
      'new',
      onConnected: () {

        _socketService.send('new:ride', {'status': 'new'});

      },
    );

    // listenToAvailableDrivers();
  }


  /////////// make ride order ////////
  //// api
  void requestRideBids({
    required int rideId,
    required double price,
    required Function(dynamic data) onData,
  }) async {
    if (!_socketService.isConnected()) {
      // تأكد من الاتصال بالـ Socket قبل بدء الاستماع
      await _socketService.connect(
        EndPoint.socketUrl,
        'bid:created',
        'created',
      );
    }

    // إلغاء أي استماع قديم على الـ Event
    _socketService.off('bid:created');

    // استماع للـ Event عند استلام البيانات الجديدة
    _socketService.on('bid:created', (data) {
      debugPrint('📥 BID EVENT RECEIVED => $data');
      onData(data);  // إرسال البيانات إلى الدالة التي تتعامل معها
    });
  }

///// event
  void newRide({
    required String pickupAddress,
    required String dropOffAddress,
    required double distance,
    required int estimatedDuration,
    required double estimatedPrice,
  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket not connected');
      return;
    }

    debugPrint('📤 Sending new ride');

    _socketService.send(
      'new:ride',
      {
        'pickup_address': pickupAddress,
        'dropoff_address': dropOffAddress,
        'distance': distance,
        'estimated_duration': estimatedDuration,
        'estimated_price': estimatedPrice,
      },
    );
  }

  ////// listen to driver location /////

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
      _socketService.send('ride:tracking:update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'ride_id': 'currentRideId',  // Pass the ride ID dynamically
        // 'heading': position.heading,
        // 'speed': position.speed
      });
      debugPrint('Location updated: ${position.latitude}, ${position.longitude}');
    });
  }

  StreamSubscription<Position>? _posSub;
  int? _activeRideId;
  String? _driverId;

  Future<void> startLocationTracking({
    required int rideId,
    required String driverId,
  }) async {
    _activeRideId = rideId;
    _driverId = driverId;

    await _checkLocationPermission();

    final settings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    await _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(locationSettings: settings)
        .listen((Position position) {
      final id = _activeRideId;
      final dId = _driverId;
      if (id == null || dId == null) return;

      _socketService.send('ride:tracking:update', {
        'lat': position.latitude,
        'lng': position.longitude,
        'ride_id': id,
        'driver_id': dId,
      });
    });
  }

  void stopLocationTracking() {
    _activeRideId = null;
    _driverId = null;
    _posSub?.cancel();
    _posSub = null;
  }

  void listenToDriverTracking(void Function(dynamic data) onData) {
    _socketService.on('ride:tracking:update', (data) => onData(data));
  }







  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permission denied forever');
    }
  }

  //////// accept bid from customer ///////

  void acceptBid({
    required int rideId,
    required String bidId,
    required String driverId,
    required int customerId,
    required double price,
  }) {
    emit(
      'ride:bid:accept',
      {
        'ride_id': rideId,
        'bid_id': bidId,
        'driver_id': driverId,
        'customer_id': customerId,
        'price': price,
      },
    );
  }

 //////// update bid price ///////

  void updatePrice({
    required double newPrice,
    required int rideId,
    required String bidId,
  }) {
    emit(
      'ride:price-update',
      {
        'new_price': newPrice,
        'bid_id': bidId,
        'ride_id': rideId,

      },
    );
  }

  void listenToUpdatePrice(Function(dynamic data) onData) {
    _socketService.off('ride:price-update');

    _socketService.on('ride:price-update', (data) {
      debugPrint('✅ Price update => $data');
      onData(data);
    });
  }

  ///////// accept ride from customer ////////

  void acceptRide({
    required int rideId,
    required String driverId,
    required int finalPrice,
  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket NOT connected. ride:accepted not sent.');
      return;
    }

    final payload = {
      'ride_id': rideId,
      'driver_id': driverId,
      'final_price': finalPrice,
      'status': 'accepted',
    };

    debugPrint('📤 Emitting ride:accepted => $payload');

    try {
      _socketService.send('ride:acc', payload);
      debugPrint('✅ ride:accepted emitted successfully');
    } catch (e) {
      debugPrint('❌ Error emitting ride:accepted => $e');
    }
  }
   /////// listen to ride accepted from driver//////

  void listenToRideAccepted(Function(dynamic data) onData) {
    _socketService.off('ride:acc');

    _socketService.on('ride:acc', (data) {
      debugPrint('🎉 RIDE ACCEPTED EVENT => $data');

      if (data != null) {
        debugPrint('📩 MESSAGE => ${data['message']}');
        debugPrint('🆔 RIDE ID => ${data['ride_id']}');
        debugPrint('💰 BID ID => ${data['bid_id']}');
        debugPrint('🚗 DRIVER ID => ${data['driver_id']}');
        debugPrint('💵 FINAL PRICE => ${data['final_price']}');
        debugPrint('📌 STATUS => ${data['status']}');
      } else {
        debugPrint('⚠️ Backend data is null');
      }

      onData(data);
    });
  }


///////// listen to ride ended from driver ///////

  void listenToRideEnded(Function(dynamic data) onData) {
    _socketService.off('ride:progress:ended');

    _socketService.on('ride:progress:ended', (data) {
      debugPrint('✅ Ride Ended => $data');
      onData(data);
    });
  }

  //////// listen to accept bid from driver //////

  void listenToBidAccepted(Function(dynamic data) onData) {
    _socketService.off('ride:bid:accepted');

    _socketService.on('ride:bid:accepted', (data) {
      debugPrint('✅ BID ACCEPTED => $data');
      onData(data);
    });
  }

  /////// send customer tracking location ///////

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

  void sendCustomerLocation({
    required int customerId,
    required double lat,
    required double lng,
    required int rideId,

  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket not connected. Cannot send location.');
      return;
    }

    final payload = {
      'customer_id': customerId,
      'lat': lat,
      'lng': lng,
      'ride_id': rideId,

    };

    debugPrint('📍 Emitting Customer:loc => $payload');

    try {
      debugPrint('socket connected = ${_socketService.isConnected()}');

      _socketService.send('customer:loc', payload);
      debugPrint('✅ Location emitted successfully');
    } catch (e) {
      debugPrint('❌ Error emitting location => $e');
    }
  }

//////// nearby driver ////////

  void getNearbyDrivers({
    required double pickUpLat,
    required double pickUpLng,
  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket not connected');
      return;
    }

    debugPrint('📤 Sending drivers nearby');

    _socketService.send(
      'drivers:nearby',
      {
        'pickup_lat': pickUpLat,
        'pickup_lng': pickUpLng,
      },
    );
  }

  void listenToNearbyDrivers(Function(dynamic data) onData) {
    _socketService.off('drivers:nearby');

    _socketService.on('drivers:nearby', (data) {
      debugPrint('✅ Nearby Drivers => $data');
      onData(data);
    });
  }




  ////// Join ride room //////
  Future<void> joinRide({
    required int rideId,
  }) async {
    try {
      // تأكد من الاتصال
      if (!_socketService.isConnected()) {
        debugPrint('⚠️ Socket not connected, connecting now...');
        await _socketService.connect(
          EndPoint.socketUrl,
          'ride:join',
          'join',
        );
      }

      debugPrint('📤 Joining ride room: $rideId');

      // إرسال الحدث
      _socketService.send(
        'ride:join',
        {
          'ride_id': rideId,
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ joinRide error: $e');
      debugPrint('📌 StackTrace: $stackTrace');
    }
  }


  //////// tracking events /////////


  void updateRideStatus({
    required int rideId,
    required String driverId,
    required String status,

  }) {
    if (!_socketService.isConnected()) {
      debugPrint('❌ Socket NOT connected. ride:status-updated not sent.');
      return;
    }

    final payload = {
      'ride_id': rideId,
      'driver_id': driverId,
      'status': status,
    };

    debugPrint('📤 Emitting ride:status-updated => $payload');

    try {
      _socketService.send('ride:status-updated', payload);
      debugPrint('✅ ride:status-updated emitted successfully');
    } catch (e) {
      debugPrint('❌ Error emitting ride:status-updated => $e');
    }
  }

  void listenToRideUpdates(Function(dynamic data) onData) {
    _socketService.off('ride:status-updated');

    _socketService.on('ride:status-updated', (data) {
      debugPrint('🎉 RIDE updated EVENT => $data');

      if (data != null) {
        debugPrint('📩 MESSAGE => ${data['message']}');

      } else {
        debugPrint('⚠️ Backend data is null');
      }

      onData(data);
    });
  }


}



