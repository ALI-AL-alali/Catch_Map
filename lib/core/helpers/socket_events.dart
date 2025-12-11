import 'package:flutter/foundation.dart';

import '../../services/io_socket_services.dart';

class SocketEvents {
  late final SocketService _socketService;
  // Private method to handle socket events

  var currentState = 'online';
  void updateState(String newState) {
    currentState = newState;
  }

  Future<void> openSocketConnection() async {
    await _socketService.connect(
      // ServerConfig.baseUrl + ServerConfig.socketTrackingUri
      '',
    );

    // Listen to socket events
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Allow time for initialization
    startListeningToSocketEvents();
  }

  void startListeningToSocketEvents() {
    // final MapController mapController = Get.find();

    _socketService.on('trip_request', (data) {
      debugPrint('the driverHaveRequest data: $data');
      final tripData = data['trip'];
      // updateState('trip_request');
      // currentTrip.value = Trip.fromJson(tripData);
      // showNewOrder();
      // animationController.forward();

      // shiftController.showNewOrder();

      // final AcceptTripRequestModel trip = AcceptTripRequestModel.fromJson(data);
      // updateMapStage(moveAhead: true);
      // tripId = trip.id;
      // if (trip.driver != null) {
      //   driverSocketInfoModel = trip.driver!;
      //   debugPrint('Driver Name: ${trip.driver?.name}');
      //   debugPrint('Driver Phone: ${trip.driver?.phoneNumber}');
      //   addDriverMarkerWhenFindOne(mapController);
      // }
      // if (trip.shift != null) {
      //   shiftInfoModel = trip.shift!;
      //   debugPrint(
      //       'Driver vehicle number: ${trip.shift?.vehicle?.vehicleNumber}');
      //   debugPrint('Driver vehicle model: ${trip.shift?.vehicle?.model}');
      // }
    });
    _socketService.on('driverArrivedToPickup', (data) {
      debugPrint('the driverArrivedToPickup data: $data');
      // updateState('driverArrivedToPickup');
    });
    // _socketService.on('driverStartTransit', (data) {
    //   debugPrint('the driverStartTransit data: $data');
    //
    //   updateState('eta');
    // });
    _socketService.on('driverCompleteTrip', (data) {
      // tripMetricsResponse = TripMetricsResponse.fromJson(data);
      // debugPrint('the driverCompleteTrip data: $data');
      // updateState('driverCompleteTrip');
      // shiftController.endTrip();
    });
  }

  // Close the socket connection
  void closeSocketConnection() {
    _socketService.disconnect();
  }
}
