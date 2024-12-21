import 'package:flutter/foundation.dart';
import 'package:logilang/logilang/environment.dart';

import 'scanner.dart';
import 'token.dart';
import 'interpreter.dart';
import 'parser.dart';
import 'stmt.dart';

class LogiLang {
  Environment env = Environment();

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

    // Parser parser = Parser.create(tokens);

    // Expr? expression = parser.parse();

    // if (expression == null) return;

    // AstPrinter printer = AstPrinter();
    // String output = printer.print(expression);
    // print(output);
  }

  void define(String name, Object? value) {
    env.define(name, value);
  }

  void interpret(String source) {
    Scanner scanner = Scanner.create(source);
    List<Token> tokens = scanner.scanTokens();

    Parser parser = Parser.create(tokens);

    List<Stmt> statements = parser.parse();

    if (statements.isEmpty) return;

    Interpreter interpreter = Interpreter.create(env);
    interpreter.interpret(statements);
  }

  // void interpret(String source) {
  //   Scanner scanner = Scanner.create(source);
  //   List<Token> tokens = scanner.scanTokens();

  //   Parser parser = Parser.create(tokens);

  //   Expr? expression = parser.parse();

  //   if (expression == null) return;

  //   Interpreter interpreter = Interpreter();
  //   interpreter.interpret(expression);
  // }
}
