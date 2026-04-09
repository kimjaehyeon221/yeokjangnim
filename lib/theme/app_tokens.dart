import 'package:flutter/material.dart';

class AC {
  static const paper = Color(0xFFF6F1E8);
  static const paper2 = Color(0xFFEEE7DA);
  static const paper3 = Color(0xFFE4DBCB);
  static const ink = Color(0xFF17120E);
  static const ink2 = Color(0xFF342D26);
  static const ink3 = Color(0xFF706458);
  static const ink4 = Color(0xFFB0A598);

  static const stamp = Color(0xFF1B3A6B);
  static const stampDim = Color(0x1A1B3A6B);
  static const gold = Color(0xFFC8A967);
  static const goldDim = Color(0x21C8A967);
  static const border = Color(0x1A17120E);

  static const night = Color(0xFF111827);
  static const night2 = Color(0xFF182338);
  static const night3 = Color(0xFF223454);
  static const surfaceDark = Color(0xFF1D2A43);
  static const surfaceDark2 = Color(0xFF243655);

  static const success = Color(0xFF2F9E6E);
  static const warning = Color(0xFFE59D2F);
  static const danger = Color(0xFFCF5A5A);
}

class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double screen = 20;
}

class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}

class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const elevated = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 32,
      offset: Offset(0, 14),
    ),
  ];

  static const darkCard = [
    BoxShadow(
      color: Color(0x2A000000),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];
}
