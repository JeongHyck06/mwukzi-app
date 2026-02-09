import 'room_sse_client_stub.dart'
    if (dart.library.html) 'room_sse_client_web.dart'
    if (dart.library.io) 'room_sse_client_io.dart';

abstract class RoomSseClient {
  Stream<String> get messages;
  void close();
}

RoomSseClient createRoomSseClient(String url) => createClient(url);
