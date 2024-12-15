import 'package:flutter/foundation.dart';
import '/logilang/scanner.dart';
import '/logilang/token.dart';

class LogiLang {
  void run(String source) {
    Scanner scanner = Scanner.create(source);
    List<Token> tokens = scanner.scanTokens();
    // For now, just print the tokens.
    for (Token token in tokens) {
      if (kDebugMode) {
        print(token);
      }
    }
  }
}
