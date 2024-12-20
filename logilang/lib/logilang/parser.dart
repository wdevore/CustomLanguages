import 'expr.dart';
import 'logi_errors.dart';
import 'stmt.dart' as stmt;
import 'token.dart';
import 'token_type.dart';

/*
Without considering precedence.

expression → literal
           | unary
           | binary
           | grouping ;
literal    → NUMBER | STRING | "true" | "false" | "nil" ;
grouping   → "(" expression ")" ;
unary      → ( "-" | "!" ) expression ;
binary     → expression operator expression ;
operator   → "==" | "!=" | "<" | "<=" | ">" | ">="
           | "+" | "-" | "*" | "/" ;

--------------------------------------------------
Considering precedence:
1) Precedence is from low to high (or top to bottom)
2) All higher productions use a "flat sequence" rather than left-recursive
   in order to avoid parsing challenges.

expression → equality ;
equality   → comparison ( ( "!=" | "==" ) comparison )* ;
comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term       → factor ( ( "-" | "+" ) factor )* ;
factor     → unary ( ( "/" | "*" ) unary )* ;
unary      → ( "!" | "-" ) unary
           | primary ;
primary    → NUMBER | STRING | "true" | "false" | "nil"
           | "(" expression ")" ;

=============== With logicals ================
expression → logical ;
logical    → equality ( ( "||" | "&&" ) equality )* ;
equality   → comparison ( ( "!=" | "==" ) comparison )* ;
comparison → term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
term       → factor ( ( "-" | "+" ) factor )* ;
factor     → unary ( ( "/" | "*" ) unary )* ;
unary      → ( "!" | "-" ) unary
           | primary ;
primary    → NUMBER | STRING | "true" | "false" | "nil"
           | "(" expression ")" ;

=============== With Statements ================
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

  int current = 0;

  Parser(this.tokens);

  factory Parser.create(List<Token> tokens) {
    Parser p = Parser(tokens);
    return p;
  }

  void reset() {
    current = 0;
  }

  List<stmt.Stmt> parse() {
    List<stmt.Stmt> statements = <stmt.Stmt>[];
    while (!isAtEnd) {
      stmt.Stmt? decl = declaration();
      if (decl != null) statements.add(decl);
    }
    return statements;
  }

  // ---------------------------------------------------------
  // BNF: declaration  → varDecl | statement ;
  // ---------------------------------------------------------
  stmt.Stmt? declaration() {
    try {
      if (match([TokenType.sVar])) return varDeclaration();
      return statement();
    } on ParseError catch (error) {
      synchronize();
      return null;
    }
  }

  stmt.Stmt? varDeclaration() {
    Token name = consume(TokenType.identifier, "Expect variable name.");

    Expr? initializer;
    if (match([TokenType.equal])) {
      initializer = expression();
    }

    consume(TokenType.semiColon, "Expect ';' after variable declaration.");

    return stmt.Var(name, initializer);
  }

// ---------------------------------------------------------
// BNF: statement → exprStmt | printStmt ;
// ---------------------------------------------------------
  stmt.Stmt statement() {
    if (match([TokenType.print])) return printStatement();
    return expressionStatement();
  }

  stmt.Stmt printStatement() {
    Expr value = expression();
    consume(TokenType.semiColon, "Expect ';' after value.");
    return stmt.Print(value);
  }

  /// Parse an expression followed by a semicolon. We wrap that Expr in a
  /// Stmt of the right type and return it.
  stmt.Stmt expressionStatement() {
    Expr expr = expression();
    consume(TokenType.semiColon, "Expect ';' after expression.");
    return stmt.Expression(expr);
  }

// ---------------------------------------------------------
// BNF: expression → assignment ;
// ---------------------------------------------------------
// The first rule, expression , simply expands to the logical rule,
// so that’s straightforward.
  Expr expression() {
    return assignment();
  }

  // ---------------------------------------------------------
  // BNF: assignment   → IDENTIFIER "=" assignment ;
  //                   | logical ;
  // ---------------------------------------------------------
  // We want the syntax tree to reflect that an l-value isn’t evaluated like a normal
  // expression. That’s why the Expr.Assign node has a Token for the left-hand side,
  // not an Expr. The problem is that the parser doesn’t know it’s parsing an l-value
  // until it hits the = . In a complex l-value, that may occur many tokens later:
  Expr assignment() {
    Expr expr = logical();

    if (match([TokenType.equal])) {
      Token equals = previous;
      Expr value = assignment();

      if (expr is Variable) {
        Token name = expr.name;
        return Assign(name, value);
      }

      error(equals, "Invalid assignment target.");
    }

    return expr;
  }

  // ---------------------------------------------------------
  // BNF: logical    → equality ( ( "||" | "&&" ) equality )* ;
  // ---------------------------------------------------------
  Expr logical() {
    Expr expr = equality();
    while (match([TokenType.and, TokenType.or])) {
      Token operator = previous;
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
      Token operator = previous;
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
      Token operator = previous;
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
      Token operator = previous;
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
      Token operator = previous;
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
      Token operator = previous;
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
      return Literal(previous.literal);
    }

    if (match([TokenType.identifier])) {
      return Variable(previous);
    }

    if (match([TokenType.leftParen])) {
      Expr expr = expression();
      consume(TokenType.rightParen, "Expect ')' after expression.");
      return Grouping(expr);
    }

    throw error(peek, 'Expect expression');
  }

// ---------------------------------------------------------
// Helpers
// ---------------------------------------------------------
// Returns the most recently consumed token.
// The latter makes it easier to use match() and then access the just-matched
// token.
  Token get previous => tokens.elementAt(current - 1);

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
    return peek.type == type;
  }

// The advance() method consumes the current token and returns it, similar to
// how the scanner consumes.
  Token advance() {
    if (!isAtEnd) current++;
    return previous;
  }

// Checks if we’ve run out of tokens to parse.
  bool get isAtEnd => peek.type == TokenType.eof;

// peek() returns the current token we have yet to consume.
  Token get peek => tokens.elementAt(current);

  Token consume(TokenType type, String message) {
    if (check(type)) return advance();
    throw error(peek, message);
  }

  ParseError error(Token token, String message) {
    LogiErrors.errorToken(token, message);
    return ParseError();
  }

  void synchronize() {
    advance();

    while (!isAtEnd) {
      if (previous.type == TokenType.semiColon) return;

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
