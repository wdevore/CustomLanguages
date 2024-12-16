// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:logilang/logilang/ast_printer.dart';
import 'package:logilang/logilang/expr.dart';
import 'package:logilang/logilang/token.dart';
import 'package:logilang/logilang/token_type.dart';

void main() {
  test('Test AST printer "1+2"', () {
    // Expression: "1 + 2"
    Expr expression = Binary(
      Literal(1),
      Token.create(TokenType.plus, "+", Null, 1),
      Literal(2),
    );

    AstPrinter printer = AstPrinter();
    print(printer.print(expression));
  });

  test('Test AST printer "(1+2) + (4 + 5)"', () {
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
    print(printer.print(expression3));
  });

  // testWidgets('Counter increments smoke test', (WidgetTester tester) async {
  //   // Build our app and trigger a frame.
  //   await tester.pumpWidget(const MyApp());

  //   // Verify that our counter starts at 0.
  //   expect(find.text('0'), findsOneWidget);
  //   expect(find.text('1'), findsNothing);

  //   // Tap the '+' icon and trigger a frame.
  //   await tester.tap(find.byIcon(Icons.add));
  //   await tester.pump();

  //   // Verify that our counter has incremented.
  //   expect(find.text('0'), findsNothing);
  //   expect(find.text('1'), findsOneWidget);
  // });
}
