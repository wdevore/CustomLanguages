import 'package:flutter/foundation.dart';
import '/logilang/scanner.dart';
import '/logilang/token.dart';
import 'ast_printer.dart';
import 'expr.dart';
import 'parser.dart';

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

*/
class LogiLang {
  void run(String source, {int debugLevel = 0}) {
    Scanner scanner = Scanner.create(source);
    List<Token> tokens = scanner.scanTokens();

    if (debugLevel == 1) {
      // For now, just print the tokens.
      for (Token token in tokens) {
        if (kDebugMode) {
          print(token);
        }
      }
    }

    Parser parser = Parser(tokens);

    Expr? expression = parser.parse();

    if (expression == null) return;

    AstPrinter printer = AstPrinter();
    String output = printer.print(expression);
    print(output);
  }
}
