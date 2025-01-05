import 'expr.dart';
import 'logi_errors.dart';
import 'stmt.dart' as stmt;
import 'token.dart';
import 'token_type.dart';

/*
-----------------------------------------------------------------------
---------- Grammar
-----------------------------------------------------------------------
program      → declaration* EOF ;
declaration  → varDecl
               | statement ;
varDecl      → "var" IDENTIFIER ( "=" expression )? ";" ;
statement    → exprStmt
               | printStmt ;
exprStmt     → expression ";" ;
printStmt    → "print" expression ";" ;
expression   → assignment ;
assignment   → IDENTIFIER "=" assignment ;
               | logical ;
logical      → equality ( ( "||" | "&&" ) equality )* ;
equality     → comparison ( ( "!=" | "==" ) comparison )* ;
comparison   → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term         → factor ( ( "-" | "+" ) factor )* ;
factor       → unary ( ( "/" | "*" ) unary )* ;
unary        → ( "!" | "-" ) unary
               | primary ;
primary      → "true" | "false" | "nil"
               | NUMBER | STRING 
               | "(" expression ")"
               | IDENTIFIER ;

*/

class Parser {
  final List<Token> tokens;
  List<String> _errors = [];

  int current = 0;

  Parser(this.tokens);

  factory Parser.create(List<Token> tokens) {
    Parser p = Parser(tokens);
    return p;
  }

  void reset() {
    current = 0;
  }

  List<String> get errors => _errors;

  List<stmt.Stmt> parse() {
    List<stmt.Stmt> statements = <stmt.Stmt>[];
    while (!_isAtEnd) {
      stmt.Stmt? decl = _declaration();
      if (decl != null) statements.add(decl);
    }
    return statements;
  }

  // ---------------------------------------------------------
  // BNF: declaration  → varDecl | statement ;
  // ---------------------------------------------------------
  stmt.Stmt? _declaration() {
    try {
      if (match([TokenType.sVar])) return _varDeclaration();
      return _statement();
    } on ParseError catch (error) {
      _errors.add(error.error());
      // print(error);

      _synchronize();
      return null;
    }
  }

  stmt.Stmt? _varDeclaration() {
    Token name = _consume(TokenType.identifier, "Expect variable name.");

    Expr? initializer;
    if (match([TokenType.equal])) {
      initializer = _expression();
    }

    _consume(TokenType.semiColon, "Expect ';' after variable declaration.");

    return stmt.Var(name, initializer);
  }

// ---------------------------------------------------------
// BNF: statement → exprStmt | printStmt ;
// ---------------------------------------------------------
  stmt.Stmt _statement() {
    if (match([TokenType.print])) return printStatement();
    return expressionStatement();
  }

  stmt.Stmt printStatement() {
    Expr value = _expression();
    _consume(TokenType.semiColon, "Expect ';' after value.");
    return stmt.Print(value);
  }

  /// Parse an expression followed by a semicolon. We wrap that Expr in a
  /// Stmt of the right type and return it.
  stmt.Stmt expressionStatement() {
    Expr expr = _expression();
    _consume(TokenType.semiColon, "Expect ';' after expression.");
    return stmt.Expression(expr);
  }

// ---------------------------------------------------------
// BNF: expression → assignment ;
// ---------------------------------------------------------
// The first rule, expression , simply expands to the logical rule,
// so that’s straightforward.
  Expr _expression() {
    return _assignment();
  }

  // ---------------------------------------------------------
  // BNF: assignment   → IDENTIFIER "=" assignment ;
  //                   | logical ;
  // ---------------------------------------------------------
  // We want the syntax tree to reflect that an l-value isn’t evaluated like a normal
  // expression. That’s why the Expr.Assign node has a Token for the left-hand side,
  // not an Expr. The problem is that the parser doesn’t know it’s parsing an l-value
  // until it hits the = . In a complex l-value, that may occur many tokens later:
  Expr _assignment() {
    Expr expr = _logical();

    if (match([TokenType.equal])) {
      Token equals = _previous;
      Expr value = _assignment();

      if (expr is Variable) {
        Token name = expr.name;
        return Assign(name, value);
      }

      _error(equals, "Invalid assignment target.");
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: logical    → equality ( ( "||" | "&&" ) equality )* ;
  // ---------------------------------------------------------
  Expr _logical() {
    Expr expr = _equality();
    while (match([TokenType.and, TokenType.or])) {
      Token operator = _previous;
      Expr right = _equality();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

// ---------------------------------------------------------
// BNF: equality   → comparison ( ( "!=" | "==" ) comparison )* ;
// ---------------------------------------------------------
// In that way, this method matches an equality operator or anything of
// higher precedence.
  Expr _equality() {
    // The first comparison nonterminal in the body translates
    // to the first call to comparison() in the method.
    Expr expr = _comparison();

    // We need to know when to exit that loop. We can see that inside the rule,
    // we must first find either a != or == token. So, if we don’t see one of
    // those, we must be done with the sequence of equality operators. We
    // express that check using a handy match() method.
    while (match([TokenType.bangEqual, TokenType.equalEqual])) {
      // We have found a != or == operator and must be parsing an equality
      // expression.
      // We grab the matched operator token so we can track which kind of equality
      // expression we have.
      Token operator = _previous;
      Expr right = _comparison();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

// ---------------------------------------------------------
// BNF: comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
// ---------------------------------------------------------
  Expr _comparison() {
    Expr expr = _term();

    while (match([
      TokenType.greater,
      TokenType.greaterEqual,
      TokenType.less,
      TokenType.lessEqual
    ])) {
      Token operator = _previous;
      Expr right = _term();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

// ---------------------------------------------------------
// BNF: term       → factor ( ( "-" | "+" ) factor )* ;
// ---------------------------------------------------------
  Expr _term() {
    Expr expr = _factor();

    while (match([TokenType.minus, TokenType.plus])) {
      Token operator = _previous;
      Expr right = _factor();
      expr = Binary(expr, operator, right);
    }

    return expr;
  }

// ---------------------------------------------------------
// BNF: factor     → unary ( ( "/" | "*" ) unary )* ;
// ---------------------------------------------------------
  Expr _factor() {
    Expr expr = _unary();
    while (match([TokenType.slash, TokenType.star])) {
      Token operator = _previous;
      Expr right = _unary();
      expr = Binary(expr, operator, right);
    }
    return expr;
  }

// ---------------------------------------------------------
// BNF: unary      → ( "!" | "-" ) unary
//                 | primary ;
// ---------------------------------------------------------
  Expr _unary() {
    if (match([TokenType.bang, TokenType.minus])) {
      Token operator = _previous;
      Expr right = _unary();
      return Unary(operator, right);
    }

    return _primary();
  }

  Expr _primary() {
    if (match([TokenType.bFalse])) return Literal(false);
    if (match([TokenType.bTrue])) return Literal(true);
    if (match([TokenType.nil])) return Literal(Null);
    if (match([TokenType.number, TokenType.string])) {
      return Literal(_previous.literal);
    }

    if (match([TokenType.identifier])) {
      return Variable(_previous);
    }

    if (match([TokenType.leftParen])) {
      Expr expr = _expression();
      _consume(TokenType.rightParen, "Expect ')' after expression.");
      return Grouping(expr);
    }

    throw _error(_peek, 'Expect expression');
  }

// ---------------------------------------------------------
// Helpers
// ---------------------------------------------------------
// Returns the most recently consumed token.
// The latter makes it easier to use match() and then access the just-matched
// token.
  Token get _previous => tokens.elementAt(current - 1);

// Checks to see if the current token has any of the given types. If so, it
// consumes the token and returns true . Otherwise, it returns false and leaves
// the current token alone.
  bool match(List<TokenType> types) {
    for (TokenType type in types) {
      if (_check(type)) {
        _advance();
        return true;
      }
    }
    return false;
  }

// Check() method returns true if the current token is of the given type.
  bool _check(TokenType type) {
    if (_isAtEnd) return false;
    return _peek.type == type;
  }

// The advance() method consumes the current token and returns it, similar to
// how the scanner consumes.
  Token _advance() {
    if (!_isAtEnd) current++;
    return _previous;
  }

// Checks if we’ve run out of tokens to parse.
  bool get _isAtEnd => _peek.type == TokenType.eof;

// peek() returns the current token we have yet to consume.
  Token get _peek => tokens.elementAt(current);

  Token _consume(TokenType type, String message) {
    if (_check(type)) return _advance();
    throw _error(_peek, message);
  }

  ParseError _error(Token token, String message) {
    LogiErrors.errorToken(token, message);
    return ParseError();
  }

  void _synchronize() {
    _advance();

    while (!_isAtEnd) {
      if (_previous.type == TokenType.semiColon) return;

      // ---- Maybe someday we will add more language features -----
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

      _advance();
    }
  }
}
