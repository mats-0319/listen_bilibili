import 'package:flutter/material.dart';

ThemeData defaultThemeData() {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Color.fromRGBO(210, 208, 186, 1),
      surface: Color.fromRGBO(210, 208, 186, 1),
      // background
      onSurface: Color.fromRGBO(240, 239, 226, 1),
      // items background
      primary: Colors.black,
      secondary: Colors.grey,
      tertiary: Colors.white,
      error: Color.fromRGBO(214, 87, 81, 0.8),
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
      bodyMedium: TextStyle(color: Colors.black, fontSize: 24),
    ),
  );
}

TextStyle blackText(int fontSizeOffset) {
  return TextStyle(color: Colors.black, fontSize: 24 + fontSizeOffset * 4);
}

TextStyle greyText(int fontSizeOffset) {
  return TextStyle(color: Colors.grey, fontSize: 24 + fontSizeOffset * 4);
}
