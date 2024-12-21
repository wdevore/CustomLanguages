import 'logi_errors.dart';
import 'token.dart';

class Environment {
  Map<String, Object?> _values = {};

  void clear() {
    _values = {};
  }

  /// A variable definition binds a new [name] to a [value].
  void define(String name, Object? value) {
    _values[name] = value;
  }

  /// Once a variable exists, we need a way to look it up.
  Object? access(Token name) {
    if (_values.containsKey(name.lexeme)) {
      return _values[name.lexeme];
    }

    throw RuntimeError.create(name, 'Undefined variable "${name.lexeme}".');
  }

  Object? accessByLexeme(String name) {
    if (_values.containsKey(name)) {
      return _values[name];
    }

    return null;
  }

  void assign(Token name, Object value) {
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    throw RuntimeError.create(name, 'Undefined variable "${name.lexeme}".');
  }
}
