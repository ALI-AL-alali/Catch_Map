import 'package:flutter/cupertino.dart';
import 'package:map/core/const/endpoint.dart';
import 'package:map/core/utils/cachenetwork.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;

  // Initialize connection to the server with authentication token
  Future<void> connect(
    String serverUrl,
    String event,
    String status, {
    VoidCallback? onConnected,
  }) async {
    final token1 = token;

    if (token1 == null) {
      debugPrint('Error: Una ble to retrieve access token.');
      return;
    }

    debugPrint('Connecting to server with token: $token1');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Enable WebSocket transport
          .enableAutoConnect() // Automatically reconnect
          .setExtraHeaders({
            'Authorization': 'Bearer $token1',
          }) // Send token in headers
          .setReconnectionDelay(5000) // Set reconnection delay
          .setAuth({'token': 'Bearer $token1'})
          .build(),
    );

    // Listen for connection events
    _socket?.onConnect((_) {
      debugPrint('Connected to the server');
      _socket?.emit('bid:created', {'status': 'pending'});
      _socket?.emit(event, {'status': status});
    });
    _socket!.onConnect((_) {
      debugPrint('✅ Connected to the server');
      onConnected?.call();
    });

    _socket?.onConnectError((data) {
      debugPrint('Connection Error: $data');
    });

    _socket?.onDisconnect((_) {
      debugPrint('Disconnected from the server');
    });

    _socket?.on('error', (data) {
      debugPrint('Socket error: $data');
    });
  }

  // Emit (send) data to the server
  // void send(String event, dynamic data) {
  //   debugPrint('Attempting to send data: Event=$event, Data=$data');
  //   if (_socket.connected) {
  //     _socket.emit(event, data);
  //     debugPrint('Data sent successfully: Event=$event, Data=$data');
  //   } else {
  //     debugPrint(
  //       'Socket is not connected. Unable to send data: Event=$event, Data=$data',
  //     );
  //   }
  // }

  void send(String event, dynamic data) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('❌ Socket not connected. Cannot send $event');
      return;
    }

    debugPrint('Attempting to send data: Event=$event, Data=$data');
    _socket!.emit(event, data);
  }

  // Listen for incoming data from the server
  // void on(String event, Function(dynamic data) callback) {
  //   debugPrint('Listening for event: $event');
  //   _socket.on(event, (data) {
  //     debugPrint('Data received for event $event: $data');
  //     callback(data);
  //   });
  // }
  void on(String event, Function(dynamic data) callback) {
    if (_socket == null) {
      debugPrint('❌ Socket not initialized yet. Cannot listen to $event');
      return;
    }

    debugPrint('Listening for event: $event');
    _socket!.on(event, (data) {
      debugPrint('Data received for event $event: $data');
      callback(data);
    });
  }

  // Remove a specific listener for an event
  void off(String event) {
    debugPrint('Removing listener for event: $event');
    _socket?.off(event);
    debugPrint('Listener removed for event: $event');
  }

  // Disconnect the socket connection
  void disconnect() {
    debugPrint('Attempting to disconnect the socket...');
    try {
      if (_socket!.connected) {
        _socket?.disconnect();
        debugPrint('Socket connection disconnected.');
      } else {
        debugPrint('Socket was not connected. No action taken.');
      }
    } catch (e) {
      debugPrint('socket disconnecting exception: $e');
    }
  }

  // Reconnect the socket manually if needed
  void reconnect() {
    debugPrint('Attempting to reconnect the socket...');
    if (!_socket!.connected) {
      _socket?.connect();
      debugPrint('Reconnection attempt made.');
    } else {
      debugPrint('Socket is already connected. No need to reconnect.');
    }
  }

  // Check if the socket is connected
  // bool isConnected() {
  //   final connected = _socket.connected;
  //   debugPrint(
  //     'Socket connection status: ${connected ? 'Connected' : 'Disconnected'}',
  //   );
  //   return connected;
  // }
  bool isConnected() {
    return _socket?.connected ?? false;
  }
}
