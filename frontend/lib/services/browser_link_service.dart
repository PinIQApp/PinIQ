import 'browser_link_service_stub.dart'
    if (dart.library.html) 'browser_link_service_web.dart' as impl;

Future<bool> openBrowserLink(String url) => impl.openBrowserLink(url);
