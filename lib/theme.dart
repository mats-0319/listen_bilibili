import 'package:flutter/material.dart';

const Color _pageColor = Color.fromRGBO(210, 210, 190, 1); // z-index: 0
const Color _cardColor = Color.fromRGBO(240, 240, 220, 1); // z-index: 1
const Color _textColor = Colors.black; // 主文字
const Color _mutedTextColor = Colors.grey; // 次级文字

/// 主题的语义约定（改主题只改这里，业务代码只认角色，不认具体颜色）：
///
/// - 页面底色：`colorScheme.surface`
/// - 卡片/工具条/按钮底色：`colorScheme.surfaceContainerLow`
/// - 对话框底色：`colorScheme.surfaceContainerHigh`
/// - 主文字（卡片/页面上）：`colorScheme.onSurface`
/// - 次级文字（说明、版权、灰字）：`colorScheme.onSurfaceVariant`
/// - 图标/返回键强调色：`colorScheme.primary`
/// - 边框：`colorScheme.outline`
/// - 半透明遮罩上的文字：`Colors.white`（遮罩是自绘的黑色半透明层，不走主题）
ThemeData defaultThemeData() {
  final ColorScheme colorScheme = ColorScheme.fromSeed(
    seedColor: _pageColor,
    brightness: Brightness.light,
    primary: _textColor,
    onPrimary: _cardColor,
    surface: _pageColor,
    onSurface: _textColor,
    onSurfaceVariant: _mutedTextColor,
    surfaceContainerLow: _cardColor,
    surfaceContainerHigh: _cardColor,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    textTheme: _buildTextTheme(colorScheme),
    appBarTheme: const AppBarThemeData(
      backgroundColor: _cardColor,
      foregroundColor: _textColor,
      iconTheme: IconThemeData(size: 28, color: _textColor),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _cardColor,
      foregroundColor: _textColor,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _cardColor,
        foregroundColor: _textColor,
      ),
    ),
    cardTheme: const CardThemeData(color: _cardColor),
    dialogTheme: const DialogThemeData(backgroundColor: _cardColor),
  );
}

TextTheme _buildTextTheme(ColorScheme colorScheme) {
  TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    double height = 1.3,
  }) => TextStyle(
    color: colorScheme.onSurface,
    fontSize: size,
    fontWeight: weight,
    height: height,
  );

  return TextTheme(
    // display：最大的展示文字
    displayLarge: text(36, height: 1.2),
    displayMedium: text(32, height: 1.2),
    displaySmall: text(28, height: 1.2),
    // headline：区块/实例标题
    headlineLarge: text(32, weight: FontWeight.w600, height: 1.2),
    headlineMedium: text(28, weight: FontWeight.w500, height: 1.2),
    headlineSmall: text(24, weight: FontWeight.w500, height: 1.2),
    // title：页面与对话框标题
    titleLarge: text(24, weight: FontWeight.w700, height: 1.2),
    titleMedium: text(20, weight: FontWeight.w600, height: 1.2),
    titleSmall: text(18, weight: FontWeight.w600, height: 1.2),
    // body：正文
    bodyLarge: text(24),
    bodyMedium: text(20),
    bodySmall: text(16),
    // label：按钮、输入框标签
    labelLarge: text(20, weight: FontWeight.w500),
    labelMedium: text(16, weight: FontWeight.w500),
    labelSmall: text(12, weight: FontWeight.w500),
  );
}
