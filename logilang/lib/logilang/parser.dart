import 'expr.dart';
import 'token.dart';

class Parser {
  final List<Token> tokens;

  int current = 0;

  Parser(this.tokens);

  // The first rule, expression , simply expands to the equality rule,
  // so that’s straightforward.
  Expr expression() {
    return equality();
  }

  Expr equality() {}
}
