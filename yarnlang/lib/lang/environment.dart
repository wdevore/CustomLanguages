import 'logi_errors.dart';
import 'token.dart';

class Environment {
  Map<String, Object?> _values = {};
  String _lastError = '';

  void clear() {
    _values = {};
  }

  String get lastError => _lastError;

  void clearLastError() => _lastError = '';

  bool get hasError => _lastError.isNotEmpty;

  void setError(String error) => _lastError = error;

  /// A variable definition binds a new [name] to a [value] primitive.
  void define(String name, Object? value) {
    if (value is int) {
      value = value.toDouble();
    }
    _values[name] = value;
  }

  /// Once a variable exists, we need a way to look it up.
  Object? access(Token name) {
    _lastError = '';
    if (_values.containsKey(name.lexeme)) {
      return _values[name.lexeme];
    }

    _lastError = 'Undefined variable "${name.lexeme}".';
    throw RuntimeError.create(name, _lastError);
  }

  Object? accessByLexeme(String name) {
    if (_values.containsKey(name)) {
      return _values[name];
    }

    return null;
  }

  void assign(Token name, Object value) {
    _lastError = '';
    if (_values.containsKey(name.lexeme)) {
      _values[name.lexeme] = value;
      return;
    }

    _lastError = 'Undefined variable "${name.lexeme}".';
    throw RuntimeError.create(name, _lastError);
  }

  void unDefine(String name) {
    if (_values.containsKey(name)) {
      _values[name] = null;
    }
  }
}
