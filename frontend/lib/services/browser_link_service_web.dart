// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

Future<bool> openBrowserLink(String url) async {
  if (url.trim().isEmpty) return false;
  html.window.open(url, '_blank');
  return true;
}
