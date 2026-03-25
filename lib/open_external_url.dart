import 'package:flutter/material.dart';

import 'open_external_url_stub.dart'
    if (dart.library.html) 'open_external_url_web.dart';

/// 외부 브라우저·새 탭으로 열기 (웹은 [dart:html] 기반으로 동작 보장).
Future<void> openExternalUrl(BuildContext context, String url) async {
  await openExternalUrlImpl(context, url);
}
