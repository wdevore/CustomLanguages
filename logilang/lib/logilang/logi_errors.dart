import 'package:flutter/foundation.dart';
import 'package:logilang/logilang/token.dart';

import 'token_type.dart';

class LogiErrors {
  static bool hadError = false;

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
}
