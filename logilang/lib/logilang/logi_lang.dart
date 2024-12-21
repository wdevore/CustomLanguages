import 'package:logilang/logilang/environment.dart';

import 'scanner.dart';
import 'token.dart';
import 'interpreter.dart';
import 'parser.dart';
import 'stmt.dart';

class LogiLang {
  late Environment env;
  late Interpreter interpreter;

  LogiLang();

  factory LogiLang.create() {
    LogiLang ll = LogiLang();
    ll.env = Environment();
    ll.interpreter = Interpreter.create(ll.env);
    return ll;
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

    interpreter.interpret(statements);
  }
}
