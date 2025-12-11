import 'package:flutter/cupertino.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  late io.Socket _socket;

  // Initialize connection to the server with authentication token
  Future<void> connect(String serverUrl) async {
    final token = await _getAccessToken();

    if (token == null) {
      debugPrint('Error: Una ble to retrieve access token.');
      return;
    }

    debugPrint('Connecting to server with token: $token');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket']) // Enable WebSocket transport
          .enableAutoConnect() // Automatically reconnect
          // .setExtraHeaders(
          //     {'Authorization': 'Bearer $token'}) // Send token in headers
          .setReconnectionDelay(5000) // Set reconnection delay
          .setAuth({'token': 'Bearer $token'})
          .build(),
    );

    // Listen for connection events
    _socket.onConnect((_) {
      debugPrint('Connected to the server');
    });

    _socket.onConnectError((data) {
      debugPrint('Connection Error: $data');
    });

    _socket.onDisconnect((_) {
      debugPrint('Disconnected from the server');
    });

    _socket.on('error', (data) {
      debugPrint('Socket error: $data');
    });
  }

  // Emit (send) data to the server
  void send(String event, dynamic data) {
    debugPrint('Attempting to send data: Event=$event, Data=$data');
    if (_socket.connected) {
      _socket.emit(event, data);
      debugPrint('Data sent successfully: Event=$event, Data=$data');
    } else {
      debugPrint(
        'Socket is not connected. Unable to send data: Event=$event, Data=$data',
      );
    }
  }

  // Listen for incoming data from the server
  void on(String event, Function(dynamic data) callback) {
    debugPrint('Listening for event: $event');
    _socket.on(event, (data) {
      debugPrint('Data received for event $event: $data');
      callback(data);
    });
  }

  // Remove a specific listener for an event
  void off(String event) {
    debugPrint('Removing listener for event: $event');
    _socket.off(event);
    debugPrint('Listener removed for event: $event');
  }

  // Disconnect the socket connection
  void disconnect() {
    debugPrint('Attempting to disconnect the socket...');
    try {
      if (_socket.connected) {
        _socket.disconnect();
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
    if (!_socket.connected) {
      _socket.connect();
      debugPrint('Reconnection attempt made.');
    } else {
      debugPrint('Socket is already connected. No need to reconnect.');
    }
  }

  // Check if the socket is connected
  bool isConnected() {
    final connected = _socket.connected;
    debugPrint(
      'Socket connection status: ${connected ? 'Connected' : 'Disconnected'}',
    );
    return connected;
  }

  // Retrieve access token
  Future<String?> _getAccessToken() async {
    // return await storage.read(key: 'access_token');
  }
}
