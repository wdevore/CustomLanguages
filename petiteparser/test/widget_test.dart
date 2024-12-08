// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petitparser/petitparser.dart';

void main() {
  testWidgets('Parser tests', (WidgetTester tester) async {
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

    _simpleGrammer1();

    if (kDebugMode) {
      print('done');
    }
  });
}

void _simpleGrammer1() {
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
}
