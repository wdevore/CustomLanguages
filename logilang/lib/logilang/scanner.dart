import '/logilang/logi_errors.dart';
import '/logilang/token.dart';
import '/logilang/token_type.dart';

class Scanner {
  late String source;
  final List<Token> tokens = [];

  final Map<String, TokenType> keywords = {
    // 'and': TokenType.and,
    // 'or': TokenType.or,
    'nil': TokenType.nil,
    'false': TokenType.bFalse,
    'true': TokenType.bTrue,
  };

  // The start and current fields are offsets that index into the string.
  int start = 0;
  int current = 0;
  // The line field tracks what source line current is on
  int line = 1;

  Scanner();

  factory Scanner.create(String source) {
    Scanner s = Scanner()..source = source;
    return s;
  }

  void reset() {
    source = '';
    line = 1;
    start = 0;
    current = 0;
    tokens.clear();
  }

  List<Token> scanTokens() {
    while (!isAtEnd) {
      // We are at the beginning of the next lexeme.
      start = current;
      scanToken();
    }

    // Finally append EOF for completeness.
    tokens.add(Token.create(TokenType.eof, '', Null, line));

    return tokens;
  }

  bool get isAtEnd => current >= source.length;

  void scanToken() {
    String c = advance();
    switch (c) {
      case '(':
        addToken(TokenType.leftParen);
        break;
      case ')':
        addToken(TokenType.rightParen);
        break;
      case '-':
        addToken(TokenType.minus);
        break;
      case '+':
        addToken(TokenType.plus);
        break;
      case '=':
        addToken(match('=') ? TokenType.equalEqual : TokenType.equal);
        break;
      case '<':
        addToken(match('=') ? TokenType.lessEqual : TokenType.less);
        break;
      case '>':
        addToken(match('=') ? TokenType.greaterEqual : TokenType.greater);
        break;
      case '&':
        addToken(match('&') ? TokenType.and : TokenType.bitAnd);
        break;
      case '|':
        addToken(match('|') ? TokenType.or : TokenType.bitOr);
        break;
      case '/':
        // '/' needs additional handling
        if (match('/')) {
          // A comment goes until the end of the line.
          while (peek() != '\n' && !isAtEnd) {
            advance();
          }
        } else {
          addToken(TokenType.slash);
        }
        break;
      // --------- White space characters -----------------------
      // When encountering whitespace, we simply go back to the beginning of the scan
      // loop. That starts a new lexeme after the whitespace character. For newlines, we
      // do the same thing, but we also increment the line counter. (This is why we used
      // peek() to find the newline ending a comment instead of match() . We want
      // that newline to get us here so we can update line .)
      case ' ':
      case '\r':
      case '\t':
        // Ignore whitespace.
        break;
      case '\n':
        line++;
        break;
      default:
        // --------------- Number literals --------------------------
        // It’s kind of tedious to add cases for every decimal digit, so we’ll
        // stuff it in the default case instead.
        if (isDigit(c)) {
          number();
        } else if (isAlpha(c)) {
          // ------------------ Reserved word ---------------------------------
          // Maximal-munch means we can’t easily detect a reserved word until
          // we’ve reached the end of what might instead be an identifier.
          // After all, a reserved word is an identifier, it’s just one that has
          // been claimed by the language for its own use. That’s where the term
          // reserved word comes from.
          identifier();
        } else {
          LogiErrors.error(line, "Unexpected character.");
        }
        break;
    }
  }

  /// The *advance* method consumes the next character in the source file and
  /// returns it.
  String advance() {
    current++;
    return source.substring(current - 1, current);
  }

  /// Grab the text of the current lexeme and creates a new token for it.
  void addToken(TokenType type) {
    addTokenLiteral(type, Null);
  }

  /// Grab the text of the current lexeme and creates a new token for it with
  /// provide [literal].
  void addTokenLiteral(TokenType type, Object literal) {
    String text = source.substring(start, current);
    tokens.add(Token.create(type, text, literal, line));
  }

  /// It’s like a conditional advance.
  /// Using *match* , we recognize these lexemes in two stages. When we reach,
  /// forexample, **!** , we jump to its switch case. That means we know the
  /// lexeme starts with **!** . Then we look at the next character to
  /// determine if we’re on a **!=** or merely a **!** .
  bool match(String expected) {
    if (isAtEnd) return false;
    if (source.substring(current, current + 1) != expected) return false;
    current++;
    return true;
  }

  void identifier() {
    while (isAlphaNumeric(peek())) {
      advance();
    }

    String text = source.substring(start, current);
    TokenType? type = keywords[text];

    type ??= TokenType.identifier;

    addToken(type);
  }

  bool isAlpha(String c) {
    int code = c.codeUnitAt(0);

    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool isAlphaNumeric(String? c) {
    return c == null ? false : isAlpha(c) || isDigit(c);
  }

  void number() {
    while (isDigit(peek())) {
      advance();
    }

    // Look for a fractional part.
    if (peek() == '.' && isDigit(peekNext())) {
      // Consume the "."
      advance();
      while (isDigit(peek())) {
        advance();
      }
    }

    addTokenLiteral(
        TokenType.number, double.parse(source.substring(start, current)));
  }

  bool isDigit(String? c) {
    if (c == null) return false;
    double? d = double.tryParse(c);
    return d == null ? false : d >= 0 && d <= 9;
  }

  String? peek() {
    if (isAtEnd) return null;
    return source.substring(current, current + 1);
  }

  String? peekNext() {
    if (current + 1 >= source.length) return null;
    return source.substring(current + 1, current + 2);
  }
}
