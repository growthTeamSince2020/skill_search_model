import 'package:flutter/material.dart';
import 'constData.dart'; // 数値定義はすべてこちらを参照

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,

      // システム全体のメインカラーを constData から引用
      primaryColor: constData.themeGreen,
      colorScheme: ColorScheme.fromSeed(
        seedColor: constData.themeGreen,
        primary: constData.themeGreen,
        brightness: Brightness.light,
      ),

      // デフォルトフォントの設定
      fontFamily: 'sans-serif',

      // テキストスタイルの一括定義（すべて constData の定数を参照）
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
            fontSize: constData.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: Colors.black87
        ),
        titleLarge: TextStyle(
            fontSize: constData.fontSizeLarge,
            fontWeight: FontWeight.bold,
            color: Colors.black87
        ),
        bodyMedium: TextStyle(
            fontSize: constData.fontSizeMedium,
            color: Colors.black87
        ),
        bodySmall: TextStyle(
            fontSize: constData.fontSizeSmall,
            color: Colors.grey
        ),
      ),

      // 入力フォーム（TextField）のデザイン一括管理
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          // 角丸の数値を constData から参照
          borderRadius: BorderRadius.circular(constData.borderRadius),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(constData.borderRadius),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),

      // ボタンのデザイン一括管理
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: constData.themeGreen,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            // 角丸の数値を constData から参照
            borderRadius: BorderRadius.circular(constData.borderRadius),
          ),
        ),
      ),
    );
  }
}