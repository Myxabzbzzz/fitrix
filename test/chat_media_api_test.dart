import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitrix/features/chat/data/services/chat_api_service.dart';

void main() {
  test('the API puts images in the body and surfaces 413', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final bodies = <Map<String, dynamic>>[];
    var status = 200;
    server.listen((req) async {
      bodies.add(jsonDecode(await utf8.decoder.bind(req).join()));
      req.response.statusCode = status;
      req.response.headers.contentType = ContentType.json;
      if (status == 200) {
        req.response.write('${jsonEncode({'delta': 'a'})}\n'
            '${jsonEncode({'done': true})}\n');
      } else {
        req.response.write(jsonEncode({'message': 'Photo too large'}));
      }
      await req.response.close();
    });
    final api =
        ChatApiService(baseUrl: 'http://${server.address.host}:${server.port}');

    await api.streamMessage('hi', 'c', images: ['QUJD']).toList();
    expect(bodies.single['images'], ['QUJD']);

    await api.streamMessage('hi', 'c').toList();
    expect(bodies.last.containsKey('images'), isFalse);

    status = 413;
    expect(
      api.streamMessage('hi', 'c', images: ['QUJD']).toList(),
      throwsA(isA<ChatException>()
          .having((e) => e.failure, 'failure', ChatFailure.photoUnavailable)
          .having((e) => e.detail, 'detail', contains('Photo too large'))),
    );
  });
}
