import 'package:flutter/foundation.dart';

import 'environment.dart';
import 'stmt.dart';
import 'token.dart';
import 'expr.dart';
import 'logi_errors.dart';
import 'token_type.dart';

// Our interpreter is doing a post-order traversal—each node evaluates its
// children before doing its own work.
class Interpreter implements ExprVisitor<Object>, StmtVisitor<void> {
  late Environment environment;

  Interpreter();

  factory Interpreter.create(Environment environmnt) {
    Interpreter itp = Interpreter()..environment = environmnt;
    return itp;
  }

  void interpret(List<Stmt> statements) {
    try {
      for (Stmt statement in statements) {
        execute(statement);
      }
    } on RuntimeError catch (error) {
      LogiErrors.runtimeError(error);
    }
  }

  void execute(Stmt stmt) {
    stmt.accept(this);
  }

  // -------------------------------------------------------------
  // -------- Expression visitors
  // -------------------------------------------------------------
  @override
  Object visitLiteralExpr(Literal expr) {
    // The parser took that value and stuck it in the literal tree node, so to
    // evaluate a literal, we simply pull it back out.
    return expr.value;
  }

  @override
  Object visitGroupingExpr(Grouping expr) {
    // To evaluate the grouping expression itself, we recursively evaluate that
    // subexpression and return it.
    return evaluate(expr.expression);
  }

  @override
  Object visitUnaryExpr(Unary expr) {
    Object right = evaluate(expr.right);

    switch (expr.operator.type) {
      case TokenType.bang:
        return !isTruthy(right);
      case TokenType.minus:
        checkNumberOperand(expr.operator, right);
        return -(right as double);
      default:
        return Null;
    }
  }

  @override
  Object visitBinaryExpr(Binary expr) {
    Object left = evaluate(expr.left);
    Object right = evaluate(expr.right);

    switch (expr.operator.type) {
      // ----------- Comparisons ----------------------
      case TokenType.greater:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) > (right as double);
      case TokenType.greaterEqual:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) >= (right as double);
      case TokenType.less:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) < (right as double);
      case TokenType.lessEqual:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) <= (right as double);
      case TokenType.bangEqual:
        return !isEqual(left, right);
      case TokenType.equal:
        return isEqual(left, right);
      // ----------- Terms ----------------------
      case TokenType.minus:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) - (right as double);
      case TokenType.plus:
        if (left is double && right is double) {
          return left + right;
        }
        if (left is String && right is String) {
          return left + right;
        }
        throw RuntimeError(
            expr.operator, "Operands must be two numbers or two strings.");
      case TokenType.and:
        if (left is bool && right is bool) {
          return left && right;
        }
        throw RuntimeError(expr.operator, "Operands must be two booleans.");
      case TokenType.or:
        if (left is bool && right is bool) {
          return left || right;
        }
        throw RuntimeError(expr.operator, "Operands must be two booleans.");
      case TokenType.slash:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) / (right as double);
      case TokenType.star:
        checkNumberOperands(expr.operator, left, right);
        return (left as double) * (right as double);
      default:
        return Null;
    }
  }

  // -------------------------------------------------------------
  // -------- Statement visitors
  // -------------------------------------------------------------
  @override
  void visitExpressionStmt(Expression stmt) {
    // Appropriately enough, we discard the value returned by evaluate() by
    // placing that call inside an expression statement.
    evaluate(stmt.expression);
  }

  @override
  void visitPrintStmt(Print stmt) {
    Object value = evaluate(stmt.expression);
    debugPrint(stringify(value));
  }

  // -------------------------------------------------------------
  // -------- Helpers
  // -------------------------------------------------------------
  Object evaluate(Expr expr) {
    return expr.accept(this);
  }

  /// *false* and *nil* are falsey and everything else is truthy.
  bool isTruthy(Object? object) {
    if (object == null) return false;
    if (object is bool) return object;
    return true;
  }

  bool isEqual(Object? a, Object? b) {
    // if (a == null && b == null) return true;
    // if (a == null) return false;
    return identical(a, b);
  }

  void checkNumberOperand(Token operator, Object operand) {
    if (operand is double) return;
    throw RuntimeError(operator, "Operand must be a number.");
  }

  void checkNumberOperands(Token operator, Object left, Object right) {
    if (left is double && right is double) return;
    throw RuntimeError(operator, "Operands must be numbers.");
  }

  String stringify(Object? object) {
    if (object == null) return "nil";

    if (object is double) {
      String text = object.toString();
      if (text.endsWith(".0")) {
        text = text.substring(0, text.length - 2);
      }
      return text;
    }

    return object.toString();
  }

  // ----------------------------------------------------
  // --- Environment State
  // ----------------------------------------------------
  @override
  void visitVarStmt(Var stmt) {
    Object? value;
    if (stmt.initializer != null) {
      value = evaluate(stmt.initializer!);
    }

    environment.define(stmt.name.lexeme, value);
  }

  @override
  Object visitVariableExpr(Variable expr) {
    Object? v = environment.access(expr.name);
    return v ?? Literal(TokenType.nil); // TODO maybe return Literal('nil')??
  }

  @override
  Object visitAssignExpr(Assign expr) {
    Object value = evaluate(expr.value);
    environment.assign(expr.name, value);
    return value;
  }
}
