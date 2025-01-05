import 'token.dart';

// -----------------------------------------------------------
// Warning! This code was generated by tools/generate_ast.dart
// -----------------------------------------------------------
    
abstract class ExprVisitor<R> {
  R visitAssignExpr(Assign expr);
  R visitBinaryExpr(Binary expr);
  R visitGroupingExpr(Grouping expr);
  R visitLiteralExpr(Literal expr);
  R visitUnaryExpr(Unary expr);
  R visitVariableExpr(Variable expr);
}

abstract class Expr {
  R accept<R>(ExprVisitor<R> visitor);
}

class Assign extends Expr {
  final Token name;
  final Expr value;

  Assign( this.name, this.value);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitAssignExpr(this);
  }
}

class Binary extends Expr {
  final Expr left;
  final Token operator;
  final Expr right;

  Binary( this.left, this.operator, this.right);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitBinaryExpr(this);
  }
}

class Grouping extends Expr {
  final Expr expression;

  Grouping( this.expression);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitGroupingExpr(this);
  }
}

class Literal extends Expr {
  final Object value;

  Literal( this.value);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitLiteralExpr(this);
  }
}

class Unary extends Expr {
  final Token operator;
  final Expr right;

  Unary( this.operator, this.right);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitUnaryExpr(this);
  }
}

class Variable extends Expr {
  final Token name;

  Variable( this.name);

  @override
  R accept<R>(ExprVisitor<R> visitor) {
    return visitor.visitVariableExpr(this);
  }
}
