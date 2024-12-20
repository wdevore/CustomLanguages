import 'logi_errors.dart';
import 'token.dart';

class Environment {
  Map<String, Object?> values = {};

  /// A variable definition binds a new [name] to a [value].
  void define(String name, Object? value) {
    values[name] = value;
  }

  /// Once a variable exists, we need a way to look it up.
  Object? access(Token name) {
    if (values.containsKey(name.lexeme)) {
      return values[name.lexeme];
    }

    throw RuntimeError.create(name, 'Undefined variable "${name.lexeme}".');
  }

  void assign(Token name, Object value) {
    if (values.containsKey(name.lexeme)) {
      values[name.lexeme] = value;
      return;
    }

    throw RuntimeError.create(name, 'Undefined variable "${name.lexeme}".');
  }
}
