import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

class MessageManager {
  late Map<String, String> _messages;

  MessageManager();

  // メッセージを読み込むメソッド
  Future<void> loadMessages({String? filePath, String? assetPath}) async {
    if (filePath != null) {
      await _loadMessagesFromFile(filePath);
    } else if (assetPath != null) {
      await _loadMessagesFromAsset(assetPath);
    } else {
      throw ArgumentError('filePathまたはassetPathのいずれかを指定する必要があります。');
    }
  }

  // ファイルからメッセージを読み込むための内部メソッド
  Future<void> _loadMessagesFromFile(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('ファイルが見つかりません: $filePath');
    }
    final jsonString = await file.readAsString();
    _messages = _parseJson(jsonString);
  }

  // アセットからメッセージを読み込むための内部メソッド
  Future<void> _loadMessagesFromAsset(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    _messages = _parseJson(jsonString);
  }

  // JSONを解析するための内部メソッド
  Map<String, String> _parseJson(String jsonString) {
    final parsedJson = json.decode(jsonString) as Map<String, dynamic>;
    return parsedJson.map((key, value) => MapEntry(key, value as String));
  }

  // メッセージを取得するメソッド
  String getMessage(String messageId, [List<Object> params = const []]) {
    if (!_messages.containsKey(messageId)) {
      return "メッセージID '$messageId' が見つかりません。";
    }
    final messageTemplate = _messages[messageId]!;
    return _formatMessage(messageTemplate, params);
  }

  // メッセージをフォーマットする内部メソッド
  String _formatMessage(String messageTemplate, List<Object> params) {
    var formattedMessage = messageTemplate;
    for (var i = 0; i < params.length; i++) {
      formattedMessage =
          formattedMessage.replaceAll("{$i}", params[i].toString());
    }
    return formattedMessage;
  }

  // メッセージを特定の値で変換するメソッド
  String replaceMessage(String messageId, String replaceValue) {
    if (!_messages.containsKey(messageId)) {
      return "メッセージID '$messageId' が見つかりません。";
    }
    final messageTemplate = _messages[messageId]!;
    return messageTemplate.replaceAll("@", replaceValue);
  }

  // ログ出力メソッド（情報レベル）
  void info(String messageId, [Object? param]) {
    _logMessage(messageId, 'INFO', param);
  }

  // ログ出力メソッド（警告レベル）
  void warn(String messageId, [Object? param]) {
    _logMessage(messageId, 'WARN', param);
  }

  // ログ出力メソッド（デバッグレベル）
  void debug(String messageId, [Object? param]) {
    _logMessage(messageId, 'DEBUG', param);
  }

  // ログ出力メソッド（エラーレベル）
  void error(String messageId, [Object? param]) {
    _logMessage(messageId, 'ERROR', param);
  }

  // 内部ログ出力メソッド
  void _logMessage(String messageId, String tag, [Object? param]) {
    String message;
    // replaceMessage メソッドを使用してメッセージを置換
    if (param is String) {
      message = replaceMessage(messageId, param);
    } else {
      final List<Object> params = param != null ? [param] : [];
      message = getMessage(messageId, params);
    }

    print('$tag: $message');
  }
}