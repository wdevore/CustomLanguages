import 'environment.dart';
import 'scanner.dart';
import 'token.dart';
import 'interpreter.dart';
import 'parser.dart';
import 'stmt.dart';

class LogiLang {
  late Environment _env;
  late Interpreter _interpreter;

  LogiLang();

  factory LogiLang.create() {
    LogiLang ll = LogiLang()
      .._env = Environment()
      ..clear();
    ll._interpreter = Interpreter.create(ll._env);
    return ll;
  }

  /// Deletes global variables.
  void clear() {
    _env.clear();
    _env.define('result', false);
  }

  /// Manifest variables instead of using 'var' keyword.
  void define(String name, Object? value) {
    _env.define(name, value);
  }

  /// Returns variable specified by [name] otherwise null.
  Object? access(String name) {
    return _env.accessByLexeme(name);
  }

  void interpret(String source) {
    Scanner scanner = Scanner.create(source);
    List<Token> tokens = scanner.scanTokens();

    Parser parser = Parser.create(tokens);

    List<Stmt> statements = parser.parse();

    if (statements.isEmpty) return;

    _interpreter.interpret(statements);
  }

  bool interpretExpr(String expression) {
    expression = 'result = $expression';
    interpret(expression);
    Object? result = access('result');
    if (result is bool) {
      return result;
    }

    if (result == null) {
      return false;
    }

    return false;
  }
}
