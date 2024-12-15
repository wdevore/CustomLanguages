import 'package:flutter/foundation.dart';

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
}
