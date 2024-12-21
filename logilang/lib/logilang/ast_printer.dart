import 'expr.dart';

/// Simple tool for printing AST.
class AstPrinter implements ExprVisitor<String> {
  String print(Expr expr) {
    return expr.accept(this);
  }

  @override
  String visitBinaryExpr(Binary expr) {
    return parenthesize(expr.operator.lexeme, [expr.left, expr.right]);
  }

  @override
  String visitGroupingExpr(Grouping expr) {
    return parenthesize("group", [expr.expression]);
  }

  @override
  String visitLiteralExpr(Literal expr) {
    if (expr.value == Null) return "nil";
    return expr.value.toString();
  }

  @override
  String visitUnaryExpr(Unary expr) {
    return parenthesize(expr.operator.lexeme, [expr.right]);
  }

  String parenthesize(String name, List<Expr> exprs) {
    StringBuffer buffer = StringBuffer();

    buffer.write("($name");
    for (Expr expr in exprs) {
      buffer.write(" ");
      buffer.write(expr.accept(this));
    }
    buffer.write(")");

    return buffer.toString();
  }

  @override
  String visitVariableExpr(Variable expr) {
    // TODO: implement visitVariableExpr
    throw UnimplementedError();
  }

  @override
  String visitAssignExpr(Assign expr) {
    // TODO: implement visitAssignExpr
    throw UnimplementedError();
  }
}
