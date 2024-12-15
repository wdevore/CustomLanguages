// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petitparser/petitparser.dart';

void main() {
  test('Basic leaf tests', () {
    final id = letter() & (letter() | digit()).star();

    final result1 = id.parse('yeah');
    if (kDebugMode) {
      print(result1);
    }
    final result2 = id.parse('f12');
    if (kDebugMode) {
      print(result2);
    }

    final id1 = letter() & word().star();
    final id2 = letter() & pattern('a-zA-Z0-9').star();
    final result3 = id1.parse('wi22w');
    if (kDebugMode) {
      print(result3);
    }
    final result4 = id2.parse('wi22w');
    if (kDebugMode) {
      print(result4);
    }

    final id3 = char('a') & char('z') & digit('9');
    final r5 = id3.parse('az9');
    if (kDebugMode) {
      print(r5);
    }

    final r6 = id3.parse('ab9');
    if (kDebugMode) {
      print('${r6.message}:${r6.position}');
    }

    var id4 = char('a') & digit().star() & char('b');
    var p1 = id4.parse('a1963b');
    if (kDebugMode) {
      print(p1);
    }
    p1 = id4.parse('a9c63b');
    if (kDebugMode) {
      print('${p1.message}:${p1.position}');
    }
    p1 = id4.parse('a1c');
    if (kDebugMode) {
      print('${p1.message}:${p1.position}');
    }
    // Grammar:
    // a + b
    String input = '11+22';
    var add2 = digit().star() & char('+') & digit().star();
    p1 = add2.parse(input);

    if (kDebugMode) {
      print(p1);
      var p = add2.pick(1);
      print(p.allMatches(input)); // '+'
    }

    final number = digit().plus().flatten().trim().map(int.parse);

    input = '98 33';
    var i = number.parse(input);

    if (kDebugMode) {
      print(i);
    }

    if (kDebugMode) {
      print('done');
    }
  });

  test('Basic grammer 1 test', () {
    final term = undefined();
    final prod = undefined();
    final prim = undefined();

    //                    Term
    //                     or
    //                 Add    Prod              Mul
    //               /  |  \                 /   |   \
    //           Prod  '+' Term          Prim   '*'   Prod
    //           or          or           or           or
    //       Mul   Prim  Add   Prod   Pars  Num     Mul  Prim
    //              or
    //          Pars   Num
    //      /    |   \
    //    '('  Term   ')'
    //          or
    //      Add   Prod

    // Add is Prod (which is evaluted to a constant) followed by '+' followed by
    // a term (which is either add or prod)
    // Thus add is defined recursively.
    final add =
        (prod & char('+').trim() & term).map((values) => values[0] + values[2]);
    // A Term is either add or prod
    term.set(add | prod);

    // Mul is a primitive followed by '*'
    final mul =
        (prim & char('*').trim() & prod).map((values) => values[0] * values[2]);
    // A Product is mul or primitive.
    prod.set(mul | prim);

    // Parens surround a term
    final parens =
        (char('(').trim() & term & char(')').trim()).map((values) => values[1]);
    // A number is primitive
    final number = digit().plus().flatten().trim().map(int.parse);
    // A Primitive is either a paren set of number (aka prim)
    prim.set(parens | number);

    final parser = term.end();

    if (kDebugMode) {
      print(parser.parse('1+2*3'));
      print(parser.parse('(1+2)*3'));
    }
  });

  test('Basic Expression builder', () {
    final builder = ExpressionBuilder<num>();

    builder.primitive(digit()
        .plus()
        .seq(char('.').seq(digit().plus()).optional())
        .flatten()
        .trim()
        .map(num.parse));

    // The parens have highest precedence so we define first.
    builder.group().wrapper(
        char('(').trim(), char(')').trim(), (left, value, right) => value);

    // now the next lower precedence, arithmetic operators.
    // Negation is a prefix operator.
    builder.group().prefix(char('-').trim(), (operator, value) => -value);

    // Power is right-associative.
    builder
        .group()
        .right(char('^').trim(), (left, operator, right) => pow(left, right));

    // Multiplication and addition are left-associative, multiplication has
    // higher priority than addition.
    builder.group()
      ..left(char('*').trim(), (left, operator, right) => left * right)
      ..left(char('/').trim(), (left, operator, right) => left / right);
    // Add is lower, so it is next.
    builder.group()
      ..left(char('+').trim(), (left, operator, right) => left + right)
      ..left(char('-').trim(), (left, operator, right) => left - right);

    // Finally build parser
    final parser = builder.build().end();

    if (kDebugMode) {
      print(parser.parse('-8')); // -8
      print(parser.parse('1+2*3')); // 7
      print(parser.parse('1*2+3')); // 5
      print(parser.parse('8/4/2')); // 1
      print(parser.parse('2^2^3')); // 256
    }
  });

  test('Grammer definitions test', () {
    final definition = ExpressionDefinition();
    final parser = definition.build();
    if (kDebugMode) {
      print(parser.parse('1 + 2 * 3')); // ['1', '+', ['2', '+', '3']]
    }
  });

  test('Evaluator definitions test', () {
    final definition = EvaluatorDefinition();
    final parser = definition.build();
    if (kDebugMode) {
      print(parser.parse('1 + 2 * 3')); // 7
    }
  });

  test('Yarn Complete using grammar defs', () {
    final parser = ExtendedExpressionGrammarDefinition().build();
    final result = parser.parse('(a > 2) | (b == 0 & c <= -2) | (d != 3)');
    if (kDebugMode) {
      if (result is Success) {
        print('Parsed successfully!');
        print(result.value);
      } else {
        print('Parsing failed.');
      }
    }
  });

  test('Yarn expression builder', () {
    Parser<dynamic> parser = _buildYarnParserGR();
    if (kDebugMode) {
      print(parser.parse('8')); // 8

      print(parser.parse('2 < 3')); // true
      print(parser.parse('5 < 4')); // false
      print(parser.parse('4 <= 4')); // true

      print(parser.parse('2 > 3')); // false
      print(parser.parse('3 >= 3')); // true
      print(parser.parse('(9 <= 10)')); // true

      print(parser.parse('(5 < 4) & (3 > 2)')); // true
    }
  });

  // testWidgets('Parser tests', (WidgetTester tester) async {});
}

// -----------------------------------------------------------
Parser<dynamic> _buildYarnParserGR() {
  // These will refer to each other
  final rela = undefined(); // '<' etc.
  final prim = undefined(); // Parens or primitive (aka number)
  final bool = undefined(); // Parens or primitive (aka number)

  // A number is primitive
  final number = digit().plus().flatten().trim().map(int.parse);

  // Productions(s) are: '<', '<=' etc.
  final lt =
      (prim & char('<').trim() & rela).map((values) => values[0] < values[2]);

  final lte = (prim & string('<=').trim() & rela)
      .map((values) => values[0] <= values[2]);

  final gt =
      (prim & char('>').trim() & rela).map((values) => values[0] > values[2]);

  final gte = (prim & string('>=').trim() & rela)
      .map((values) => values[0] >= values[2]);

  final and =
      (prim & char('&').trim() & rela).map((values) => values[0] && values[2]);

  bool.set(prim | rela);

  rela.set(lt | lte | gt | gte | prim);

  // Parens surround a term
  final parens =
      (char('(').trim() & rela & char(')').trim()).map((values) => values[1]);

  // A Primitive is either a paren set or number (aka prim)
  prim.set(parens | number);

  final parser = bool.end();

  return parser;
}

// -----------------------------------------------------------
//
//                      &&
//                    /    \
//                 5 < 4  3 > 2

// a,b,c,d are variables
// Expression: (a > 2) | (b == 0 & c <= -2) | (d != 3)

Parser<num> _buildYarnParserEB() {
  final builder = ExpressionBuilder<num>();

  // Must have at least one primitive
  final number = digit().plus().flatten().trim().map(int.parse);

  builder.primitive(number);

  // ----------------------------------------------------------------
  // Start at highest precedence
  // ----------------------------------------------------------------

  // The parens have highest precedence so they are defined first.
  builder.group().wrapper(
      char('(').trim(), char(')').trim(), (left, value, right) => value);

  // builder.group().left(
  //       string('&').trim(),
  //       (left, operator, right) => left & right ? 1 : 0,
  //     );

  // Boolean operators are next.
  // '<' '<=' is left associative meaning when evaluating an expression with multiple
  // "less than or equal to" operations, the calculation is done from
  // left to right.
  builder.group()
    ..left(
      string('<=').trim(),
      (left, operator, right) => left <= right ? 1 : 0,
    )
    ..left(
      char('<').trim(),
      (left, operator, right) => left < right ? 1 : 0,
    )
    ..left(
      string('>=').trim(),
      (left, operator, right) => left >= right ? 1 : 0,
    )
    ..left(
      char('>').trim(),
      (left, operator, right) => left > right ? 1 : 0,
    );

  // Finally build parser
  final parser = builder.build().end();

  return parser;
}

class ExtendedExpressionGrammarDefinition extends GrammarDefinition {
  @override
  Parser start() => ref0(expression).end();

  Parser expression() => ref0(orExpression);

  Parser orExpression() => ref0(andExpression).separatedBy(char('|').trim());

  Parser andExpression() =>
      ref0(comparisonExpression).separatedBy(char('&').trim());

  Parser comparisonExpression() => ref0(term).separatedBy((string('>') |
          string('<') |
          string('=') |
          string('>=') |
          string('<=') |
          string('!='))
      .trim());

  Parser term() => ref0(variable) | ref0(number) | ref0(parentheses);

  Parser variable() => letter().plus().flatten().trim();

  Parser number() =>
      (char('-').optional() & digit().plus()).flatten().trim().map(int.parse);

  Parser parentheses() =>
      char('(').trim() & ref0(expression) & char(')').trim();
}

class ExpressionEvaluator extends ExtendedExpressionGrammarDefinition {
  final Map<String, dynamic> variables;

  ExpressionEvaluator(this.variables);

  bool evaluate(dynamic result) {
    // if (result is List) {
    //   if (result.length == 3) {
    //     final left = evaluate(result[0]);
    //     final operator = result[1];
    //     final right = evaluate(result[2]);
    //     switch (operator) {
    //       case '>':
    //         return left > right;
    //       case '<':
    //         return left < right;
    //       case '=':
    //         return left == right;
    //       case '>=':
    //         return left >= right;
    //       case '<=':
    //         return left <= right;
    //       case '!=':
    //         return left != right;
    //       case '&':
    //         return left && right;
    //       case '|':
    //         return left || right;
    //     }
    //   } else if (result.length == 2) {
    //     return evaluate(result[1]);
    //   }
    // } else if (result is String) {
    //   return variables[result];
    // } else if (result is int) {
    //   return result;
    // }
    return false;
  }
}

class ExpressionDefinition extends GrammarDefinition {
  Parser start() => ref0(term).end();

  // To refer to a production defined in the same definition use ref0 with the
  // function reference as the argument. The 0 at the end of ref0 means that
  // the production reference isn't parametrized
  // (zero argument production method).
  Parser term() => ref0(add) | ref0(prod);
  Parser add() => ref0(prod) & char('+').trim() & ref0(term);

  Parser prod() => ref0(mul) | ref0(prim);
  Parser mul() => ref0(prim) & char('*').trim() & ref0(prod);

  Parser prim() => ref0(parens) | ref0(number);
  Parser parens() => char('(').trim() & ref0(term) & char(')').trim();

  Parser number() => digit().plus().flatten().trim();
}

class EvaluatorDefinition extends ExpressionDefinition {
  Parser add() => super.add().map((values) => values[0] + values[2]);
  Parser mul() => super.mul().map((values) => values[0] * values[2]);
  Parser parens() => super.parens().castList<num>().pick(1);
  Parser number() => super.number().map((value) => int.parse(value));
}
