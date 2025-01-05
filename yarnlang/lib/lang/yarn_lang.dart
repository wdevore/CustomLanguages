import 'package:yarnlang/lang/logi_errors.dart';

import 'environment.dart';
import 'scanner.dart';
import 'token.dart';
import 'interpreter.dart';
import 'parser.dart';
import 'stmt.dart';

// --------------------------------------------------------------------
// This is the language and API
// --------------------------------------------------------------------
class YarnLang {
  late Environment _env;
  late Interpreter _interpreter;

  YarnLang();

  factory YarnLang.create() {
    YarnLang ll = YarnLang()
      .._env = Environment()
      ..clear();
    ll._interpreter = Interpreter.create(ll._env);
    return ll;
  }

  String get lastError => _env.lastError;
  bool get hasError => _env.hasError;
  String get staticError => LogiErrors.staticError;

  /// Deletes global variables.
  void clear() {
    _env.clear();
    _env.define('result', false);
  }

  /// Manifest variables instead of using 'var' keyword.
  void define(String name, Object? value) {
    _env.define(name, value);
  }

  /// Remove or undefine a single variable.
  void unDefine(String name) {
    _env.unDefine(name);
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

    if (parser.errors.isNotEmpty) {
      // TODO handle all errors.
      _env.setError(parser.errors.first);
      return;
    }

    if (statements.isEmpty) return;

    _env.clearLastError();
    _interpreter.interpret(statements);
  }

  bool? interpretExpr(String expression) {
    _env.clearLastError();
    interpret('result = $expression;');

    Object? result = access('result');

    if (result is bool) {
      return result;
    }

    return null;
  }
}
