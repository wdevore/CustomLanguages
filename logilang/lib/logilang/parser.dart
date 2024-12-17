import 'expr.dart';
import 'logi_errors.dart';
import 'token.dart';
import 'token_type.dart';

class Parser {
  final List<Token> tokens;

  int current = 0;

  Parser(this.tokens);

  Expr? parse() {
    try {
      return expression();
    } on ParseError catch (error) {
      return null;
    }
  }

  // The first rule, expression , simply expands to the logical rule,
  // so that’s straightforward.
  Expr expression() {
    return logical();
  }

  // ---------------------------------------------------------
  // BNF: logical    → equality ( ( "||" | "&&" ) equality )* ;
  // ---------------------------------------------------------
  Expr logical() {
    Expr expr = equality();
    while (match([TokenType.and, TokenType.or])) {
      Token operator = previous();
      Expr right = equality();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: equality   → comparison ( ( "!=" | "==" ) comparison )* ;
  // ---------------------------------------------------------
  // In that way, this method matches an equality operator or anything of
  // higher precedence.
  Expr equality() {
    // The first comparison nonterminal in the body translates
    // to the first call to comparison() in the method.
    Expr expr = comparison();

    // We need to know when to exit that loop. We can see that inside the rule,
    // we must first find either a != or == token. So, if we don’t see one of
    // those, we must be done with the sequence of equality operators. We
    // express that check using a handy match() method.
    while (match([TokenType.bangEqual, TokenType.equalEqual])) {
      // We have found a != or == operator and must be parsing an equality
      // expression.
      // We grab the matched operator token so we can track which kind of equality
      // expression we have.
      Token operator = previous();
      Expr right = comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  // ---------------------------------------------------------
  Expr comparison() {
    Expr expr = term();

    while (match([
      TokenType.greater,
      TokenType.greaterEqual,
      TokenType.less,
      TokenType.lessEqual
    ])) {
      Token operator = previous();
      Expr right = term();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: term       → factor ( ( "-" | "+" ) factor )* ;
  // ---------------------------------------------------------
  Expr term() {
    Expr expr = factor();

    while (match([TokenType.minus, TokenType.plus])) {
      Token operator = previous();
      Expr right = factor();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: factor     → unary ( ( "/" | "*" ) unary )* ;
  // ---------------------------------------------------------
  Expr factor() {
    Expr expr = unary();
    while (match([TokenType.slash, TokenType.star])) {
      Token operator = previous();
      Expr right = unary();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

  // ---------------------------------------------------------
  // BNF: unary      → ( "!" | "-" ) unary
  //                 | primary ;
  // ---------------------------------------------------------
  Expr unary() {
    if (match([TokenType.bang, TokenType.minus])) {
      Token operator = previous();
      Expr right = unary();
      return Unary(operator, right);
    }

    return primary();
  }

  Expr primary() {
    if (match([TokenType.bFalse])) return Literal(false);
    if (match([TokenType.bTrue])) return Literal(true);
    if (match([TokenType.nil])) return Literal(Null);
    if (match([TokenType.number, TokenType.string])) {
      return Literal(previous().literal);
    }
    if (match([TokenType.leftParen])) {
      Expr expr = expression();
      consume(TokenType.rightParen, "Expect ')' after expression.");
      return Grouping(expr);
    }
    if (match([TokenType.leftParen])) {
      Expr expr = expression();
      consume(TokenType.rightParen, "Expect ')' after expression.");
      return Grouping(expr);
    }
    // return Literal(Null); // TODO should we return a Null
    throw error(peek(), 'Expect expression');
  }

  // ---------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------
  // Returns the most recently consumed token.
  // The latter makes it easier to use match() and then access the just-matched
  // token.
  Token previous() {
    return tokens.elementAt(current - 1);
  }

  // Checks to see if the current token has any of the given types. If so, it
  // consumes the token and returns true . Otherwise, it returns false and leaves
  // the current token alone.
  bool match(List<TokenType> types) {
    for (TokenType type in types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  // Check() method returns true if the current token is of the given type.
  bool check(TokenType type) {
    if (isAtEnd) return false;
    return peek().type == type;
  }

  // The advance() method consumes the current token and returns it, similar to
  // how the scanner’s
  Token advance() {
    if (!isAtEnd) current++;
    return previous();
  }

  // Checks if we’ve run out of tokens to parse.
  bool get isAtEnd => peek().type == TokenType.eof;

  // peek() returns the current token we have yet to consume.
  Token peek() {
    return tokens.elementAt(current);
  }

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();
    throw error(peek(), message);
  }

  ParseError error(Token token, String message) {
    LogiErrors.errorToken(token, message);
    return ParseError();
  }

  void synchronize() {
    advance();

    while (!isAtEnd) {
      if (previous().type == TokenType.semiColon) return;

      // switch (peek().type) {
      //   case CLASS:
      //   case FUN:
      //   case VAR:
      //   case FOR:
      //   case IF:
      //   case WHILE:
      //   case PRINT:
      //   case RETURN:
      //     return;
      //   default:
      //     return;
      // }

      advance();
    }
  }
}

/// When we want to synchronize, we *throw* the ParseError object.
/// Higher up in the method for the grammar rule we are synchronizing to,
/// we’ll catch it.
/// We synchronize on *statement* boundaries.
///
class ParseError implements Exception {
  String error() => 'Parse exception';
}
