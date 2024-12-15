import 'package:flutter/foundation.dart';
import '/logilang/scanner.dart';
import '/logilang/token.dart';

class LogiLang {
  void run(String source, {int debugLevel = 0}) {
    Scanner scanner = Scanner.create(source);
    List<Token> tokens = scanner.scanTokens();

    if (debugLevel == 1) {
      // For now, just print the tokens.
      for (Token token in tokens) {
        if (kDebugMode) {
          print(token);
        }
      }
    }
  }
}
