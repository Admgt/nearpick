import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'text/plain;charset=utf-8',
}) async {
  final blob = web.Blob(
    <JSAny>[content.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';

  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
