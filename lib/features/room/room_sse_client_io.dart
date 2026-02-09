import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'room_sse_client.dart';

class RoomSseClientIo implements RoomSseClient {
  final StreamController<String> _controller = StreamController.broadcast();
  final http.Client _client = http.Client();
  StreamSubscription<String>? _subscription;

  RoomSseClientIo(String url) {
    _connect(url);
  }

  void _connect(String url) async {
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await _client.send(request);
      _subscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleLine, onError: _controller.addError);
    } catch (error) {
      _controller.addError(error);
    }
  }

  String? _buffer;

  void _handleLine(String line) {
    if (line.isEmpty) {
      if (_buffer != null) {
        _controller.add(_buffer!);
        _buffer = null;
      }
      return;
    }
    if (line.startsWith('data:')) {
      final data = line.substring(5).trim();
      _buffer = (_buffer == null) ? data : '${_buffer!}\n$data';
    }
  }

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void close() {
    _subscription?.cancel();
    _client.close();
    _controller.close();
  }
}

RoomSseClient createClient(String url) => RoomSseClientIo(url);
