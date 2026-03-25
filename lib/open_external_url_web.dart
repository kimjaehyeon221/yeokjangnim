// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'package:flutter/material.dart';

Future<void> openExternalUrlImpl(BuildContext _, String url) async {
  html.window.open(url, '_blank');
}
