import 'package:flutter/material.dart';

const kFont = 'MadeEvolve';

class C {
  static const text = Color(0xFFF5F5F7);
  static const muted = Color(0xFF9A9AA3);
  static const glassBorder = Color(0x29FFFFFF);
  static const green = Color(0xFF4ADE80);
  static const amber = Color(0xFFFBBF24);
  static const red = Color(0xFFF87171);
}

const kRarity = <String, Color>{
  'forgotten': Color(0xFF9A8F93),
  'secret': Color(0xFF20C997),
  'mythic': Color(0xFFFF375F),
  'legendary': Color(0xFFFFD700),
  'epic': Color(0xFFC026A0),
  'rare': Color(0xFF3B82F6),
  'uncommon': Color(0xFF30D158),
  'common': Color(0xFF94A3B8),
};

const kHighRarity = ['forgotten', 'secret', 'mythic', 'legendary'];

Color rarityColor(String? r) =>
    kRarity[(r ?? 'common').toLowerCase()] ?? Colors.white;

const goldGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Color(0xFFFFF3B0), Color(0xFFFFC400), Color(0xFFB8860B)],
  stops: [0, 0.55, 1],
);

const titleGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [Colors.white, Color(0xFF777777)],
);

ThemeData buildTheme() {
  final base = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    fontFamily: kFont,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: const ColorScheme.dark(primary: Colors.white),
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(bodyColor: C.text, displayColor: C.text, fontFamily: kFont),
  );
}
