import 'token_type.dart';

class Token {
  late TokenType type;
  late String lexeme;
  late Object literal;
  late int line;

  Token();

  factory Token.create(
      TokenType type, String lexeme, Object literal, int line) {
    Token t = Token()
      ..type = type
      ..lexeme = lexeme
      ..literal = literal
      ..line = line;

    return t;
  }

  @override
  String toString() {
    return '$type $lexeme $literal';
  }
}
