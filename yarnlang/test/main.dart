import 'package:test/test.dart';
import 'package:yarnlang/lang/ast_printer.dart';
import 'package:yarnlang/lang/expr.dart';
import 'package:yarnlang/lang/token.dart';
import 'package:yarnlang/lang/token_type.dart';
import 'package:yarnlang/lang/yarn_lang.dart';

void main() {
  // ------------------------------------------------------------
  // Low level tests. They require importing internal objects
  // for testing. Usage of Yarnlang would only require importing
  // Yarnlang.
  // ------------------------------------------------------------
  group('ASTPrinter', () {
    test('Manual creation Expression "1+2"', () {
      Expr expression = Binary(
        Literal(1),
        Token.create(TokenType.plus, "+", Null, 1),
        Literal(2),
      );

      AstPrinter printer = AstPrinter();
      String result = printer.print(expression);
      expect(result == '(+ 1 2)', isTrue);

      // print(printer.print(expression));
    });

    test('Expression "(1+2) + (4 + 5)"', () {
      Expr expression1 = Binary(
        Literal(1),
        Token.create(TokenType.plus, "+", Null, 1),
        Literal(2),
      );

      Expr group1 = Grouping(expression1);

      Expr expression2 = Binary(
        Literal(4),
        Token.create(TokenType.plus, "+", Null, 1),
        Literal(5),
      );

      Expr group2 = Grouping(expression2);

      Expr expression3 = Binary(
        group1,
        Token.create(TokenType.plus, "+", Null, 1),
        group2,
      );

      AstPrinter printer = AstPrinter();

      String result = printer.print(expression3);
      expect(result == '(+ (group (+ 1 2)) (group (+ 4 5)))', isTrue);

      // print(printer.print(expression3));
    });
  });

  // ------------------------------------------------------------
  // Create Yarn language environment
  // ------------------------------------------------------------
  YarnLang logi = YarnLang.create();

  logi.clear();
  logi.interpret("""
var a = 1;
var b = 2;
var c = 3;
var badge = 9;
""");

  group('Variables', () {
    // Demostrates defining variables using the language itself.
    test('Via `var` statement', () {
      Object? a = logi.access('a');
      expect(a, isNotNull, reason: 'Expected a is not Null');
      expect(a, 1);

      Object? b = logi.access('b');
      expect(b, isNotNull, reason: 'Expected b is not Null');
      expect(b, 2);

      Object? c = logi.access('c');
      expect(c, isNotNull, reason: 'Expected c is not Null');
      expect(c, 3);

      Object? badge = logi.access('badge');
      expect(badge, isNotNull, reason: 'Expected badge is not Null');
      expect(badge, 9);

      Object? undefined = logi.access('undefined');
      expect(undefined, isNull, reason: 'Expected undefined is Null');
    });

    // Demostrates defining variables using the environment directly. This is
    // typically how the reader/writer would operate.
    test('Via define statement', () {
      logi.clear();
      logi.define('a', 1);
      logi.define('b', 2);
      logi.define('c', 3);
      logi.define('badge', 9);

      Object? a = logi.access('a');
      expect(a, isNotNull, reason: 'Expected a is not Null');
      expect(a, 1);

      Object? b = logi.access('b');
      expect(b, isNotNull, reason: 'Expected b is not Null');
      expect(b, 2);

      Object? c = logi.access('c');
      expect(c, isNotNull, reason: 'Expected c is not Null');
      expect(c, 3);

      Object? badge = logi.access('badge');
      expect(badge, isNotNull, reason: 'Expected badge is not Null');
      expect(badge, 9);

      Object? undefined = logi.access('undefined');
      expect(undefined, isNull, reason: 'Expected undefined is Null');
    });
  });

  logi.clear();
  logi.interpret("""
var a = 1;
var b = 2;
var c = 3;
var badge = 9;
""");

  group('Expressions', () {
    test('Var undefined', () {
      bool? result = logi.interpretExpr('j < 3');
      expect(result, isFalse, reason: 'Expected result to be False');
      expect(logi.hasError, isTrue, reason: 'Expected error.');
      expect(
        logi.lastError == 'Undefined variable "j".',
        isTrue,
        reason: 'Expected undefined variable exception.',
      );
    });

    test('a == 1', () {
      // 'a == 1' is comparing a's value (1.0) with the constant (1) which
      // are not identical.
      bool? result = logi.interpretExpr('a == 1');
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('a < 3 == true', () {
      bool? result = logi.interpretExpr('a < 3');
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('c < a', () {
      bool? result = logi.interpretExpr('c < a');
      expect(result, isFalse, reason: 'Expected expression to be False');
    });

    test('c < a == false', () {
      bool? result = logi.interpretExpr('c < a == false');
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('c < 1 && badge < 10', () {
      bool? result = logi.interpretExpr('c < 1 && badge < 10');
      expect(result, isFalse, reason: 'Expected expression to be False');
    });

    test('c < 5 && badge < 10', () {
      bool? result = logi.interpretExpr('c < 5 && badge < 10');
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('c <= 3 && badge > a', () {
      bool? result = logi.interpretExpr('c <= 3 && badge > a');
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('a < 3 && (b < 1 || a == 1)', () {
      bool? result = logi.interpretExpr('a < 3 && (b < 1 || a == 1)');
      // a<3=True && (b<1==false || a==1=True)
      //    True  &&             True
      // = True
      expect(result, isTrue, reason: 'Expected expression to be True');
    });

    test('a < badge && (b < 1 || a == 1)', () {
      bool? result = logi.interpretExpr('a > badge && (b < 1 || a == 1)');
      // a>badge=False && (b<1==false || a==1=True)
      //    False  &&             True
      // = False
      expect(result, isFalse, reason: 'Expected expression to be False');
    });

    test('Conditional with negative', () {
      bool? result = logi.interpretExpr('c < -5 && badge < 10');
      // c is not < -5
      expect(result, isFalse, reason: 'Expected expression to be False');
    });
  });

  group('Assignments', () {
    test('variable fooled is true', () {
      logi.interpret('var fooled = c <= 3 && badge > 5;');
      Object? fooled = logi.access('fooled');
      expect(fooled, isTrue, reason: 'Expected assignment to be True');
    });

    test('variable fooled is false', () {
      logi.interpret('var fooled = c <= 3 && badge <= 5;');
      Object? fooled = logi.access('fooled');
      expect(fooled, isFalse, reason: 'Expected assignment to be False');
    });

    test('j = 1', () {
      logi.interpret('var j = 1;');
      Object? j = logi.access('j');
      expect(j, 1.0, reason: 'Expected assignment to be 1');
    });

    test('boolean assignment is false', () {
      logi.interpret('var dead = false;');
      Object? dead = logi.access('dead');
      expect(dead, isFalse, reason: 'Expected assignment to be False');
    });

    test('boolean assignment is true', () {
      logi.interpret('var alive = true;');
      Object? alive = logi.access('alive');
      expect(alive, isTrue, reason: 'Expected assignment to be True');
    });
  });

  group('Math', () {
    test('Add one to c', () {
      logi.interpret('c = c + 1;');
      Object? c = logi.access('c');
      expect(c, 4, reason: 'Expected count to = 4');
    });

    test('Multiply c by 2', () {
      logi.interpret('c = c * 2;');
      Object? c = logi.access('c');
      expect(c, 8, reason: 'Expected count to = 8');
    });

    test('Divide c by 2', () {
      logi.interpret('c = c / 2;');
      Object? c = logi.access('c');
      expect(c, 4, reason: 'Expected count to = 4');
    });

    test('Negate c', () {
      logi.interpret('c = -c;');
      Object? c = logi.access('c');
      expect(c, -4, reason: 'Expected count to = -4');
    });
  });

  group('Bad Syntax', () {
    test('Invalid var name', () {
      logi.interpret('c = c + 1g;');
      String e = logi.staticError;
      expect(e == "[line: 1] Error->  at (g) : Expect ';' after expression.",
          isTrue,
          reason: 'Expected parse exception message.');
    });
  });
}
