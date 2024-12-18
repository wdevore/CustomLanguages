import 'package:flutter/foundation.dart';
import 'package:logilang/logilang/token.dart';

import 'token_type.dart';

class LogiErrors {
  static bool hadError = false;

  static bool hadRuntimeError = false;

  static void error(int line, String message) {
    report(line, "", message);
  }

  static void report(int line, String where, String message) {
    if (kDebugMode) {
      print('[line: $line] Error-> $where : $message');
    }
    LogiErrors.hadError = true;
  }

  static void errorToken(Token token, String message) {
    if (token.type == TokenType.eof) {
      report(token.line, " at end", message);
    } else {
      report(token.line, ' at (${token.lexeme})', message);
    }
  }

  static void runtimeError(RuntimeError error) {
    if (kDebugMode) {
      print('[line ${error.token.line}] => ${error.message}');
    }
    hadRuntimeError = true;
  }
}

/// When we want to synchronize, we *throw* the ParseError object.
/// Higher up in the method for the grammar rule we are synchronizing to,
/// we’ll catch it.
/// We synchronize on *statement* boundaries.
///
class ParseError implements Exception {
  String error() => 'Parse exception';
}

class RuntimeError implements Exception {
  final Token token;

  /// A message describing the format error.
  final String message;

  RuntimeError(this.token, this.message);

  factory RuntimeError.create(Token token, String message) {
    RuntimeError re = RuntimeError(token, message);
    return re;
  }
}
