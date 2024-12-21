# Description
This is a very simple language used by Yarn Reader/Writer. It is for the persona (aka timeline) calculations.

The language only has Global scope for variables.

It has 5 reserved keywords:
- '**true**'
- '**false**'
- '**nil**'
- '**var**'
- '**print**'

Usage:
First you construct the language:
```dart
LogiLang logi = LogiLang.create();
```
Then you can define any needed variables in one of two ways:
```dart
  // Magically manifest variables into existance ;-)
  // The four lines below are directly equivalent to calling define(...):
  // var a = 1;
  // var b = 2;
  // var c = 3;
  // var badge = 9;
  logi.define('a', 1);
  logi.define('b', 2);
  logi.define('c', 3);
  logi.define('badge', 9);
```
Now you can call the interpreter to execute your expressions:
```dart
  logi.interpret("""
print a < 3 && (b < 1 || a == 1);
"""); // output: true

  print('--------------------------');
  logi.interpret("""
print c < 1 && badge < 10;
print c < 5 && badge < 10;
"""); // output: false,true

  print('--------------------------');
  logi.interpret("""
print c < -5 && badge < 10;
print badge;
"""); // output: false, 9

  logi.interpret("""
var fooled = c <= 3 && badge > 5;
"""); // output: nothing

  logi.interpret("""
print c <= 3 && badge > c;
"""); // output: true

  logi.interpret("""
print fooled;
"""); // output: true

  Object? fooled = logi.access('fooled');
  debugPrint('fooled is: $fooled'); // output: true
```

# Building language
First run the AST generator tool. This will create both the 'expr.dart' and 'stmt.dart' visitors.

```sh
dart run generate_ast.dart ../lib/logilang
```

That's it.