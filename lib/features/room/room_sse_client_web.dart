import 'dart:async';
import 'dart:html';

import 'room_sse_client.dart';

class RoomSseClientWeb implements RoomSseClient {
  final EventSource _eventSource;
  final StreamController<String> _controller = StreamController.broadcast();

  RoomSseClientWeb(String url) : _eventSource = EventSource(url) {
    _eventSource.onMessage.listen((event) {
      if (event.data is String) {
        _controller.add(event.data as String);
      }
    });
    _eventSource.onError.listen((_) {
      _controller.addError(StateError('SSE 연결 오류'));
    });
  }

  @override
  Stream<String> get messages => _controller.stream;

  @override
  void close() {
    _eventSource.close();
    _controller.close();
  }
}

RoomSseClient createClient(String url) => RoomSseClientWeb(url);
