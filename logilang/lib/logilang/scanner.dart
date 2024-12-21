import 'logi_errors.dart';
import 'token.dart';
import 'token_type.dart';

class Scanner {
  late String _source;
  final List<Token> _tokens = [];

  final Map<String, TokenType> _keywords = {
    // --- Primitives ----
    'nil': TokenType.nil,
    'false': TokenType.bFalse,
    'true': TokenType.bTrue,
    // --- Statements ----
    'print': TokenType.print,
    'var': TokenType.sVar,
  };

  // The start and current fields are offsets that index into the string.
  int _start = 0;
  int _current = 0;
  // The line field tracks what source line *current* is on
  int line = 1;

  Scanner();

  factory Scanner.create(String source) {
    Scanner s = Scanner().._source = source;
    return s;
  }

  void reset() {
    _source = '';
    line = 1;
    _start = 0;
    _current = 0;
    _tokens.clear();
  }

  List<Token> scanTokens() {
    while (!_isAtEnd) {
      // We are at the beginning of the next lexeme.
      _start = _current;
      _scanToken();
    }

    // Finally append EOF for completeness.
    _tokens.add(Token.create(TokenType.eof, '', Null, line));

    return _tokens;
  }

  bool get _isAtEnd => _current >= _source.length;

  void _scanToken() {
    String c = _advance();
    switch (c) {
      case '(':
        _addToken(TokenType.leftParen);
        break;
      case ')':
        _addToken(TokenType.rightParen);
        break;
      case '-':
        _addToken(TokenType.minus);
        break;
      case '+':
        _addToken(TokenType.plus);
        break;
      case ';':
        _addToken(TokenType.semiColon);
        break;
      case '=':
        _addToken(match('=') ? TokenType.equalEqual : TokenType.equal);
        break;
      case '<':
        _addToken(match('=') ? TokenType.lessEqual : TokenType.less);
        break;
      case '>':
        _addToken(match('=') ? TokenType.greaterEqual : TokenType.greater);
        break;
      case '&':
        _addToken(match('&') ? TokenType.and : TokenType.bitAnd);
        break;
      case '|':
        _addToken(match('|') ? TokenType.or : TokenType.bitOr);
        break;
      case '/':
        // '/' needs additional handling
        if (match('/')) {
          // A comment goes until the end of the line.
          while (_peek() != '\n' && !_isAtEnd) {
            _advance();
          }
        } else {
          _addToken(TokenType.slash);
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
      case '"':
        _string();
        break;
      default:
        // --------------- Number literals --------------------------
        // It’s kind of tedious to add cases for every decimal digit, so we’ll
        // stuff it in the default case instead.
        if (_isDigit(c)) {
          _number();
        } else if (_isAlpha(c)) {
          // ------------------ Reserved word ---------------------------------
          // Maximal-munch means we can’t easily detect a reserved word until
          // we’ve reached the end of what might instead be an identifier.
          // After all, a reserved word is an identifier, it’s just one that has
          // been claimed by the language for its own use. That’s where the term
          // reserved word comes from.
          _identifier();
        } else {
          LogiErrors.error(line, 'Unexpected character: "$c"');
        }
        break;
    }
  }

  /// The *advance* method consumes the next character in the source file and
  /// returns it.
  String _advance() {
    _current++;
    return _source.substring(_current - 1, _current);
  }

  /// Grab the text of the current lexeme and creates a new token for it.
  void _addToken(TokenType type) {
    _addTokenLiteral(type, Null);
  }

  /// Grab the text of the current lexeme and creates a new token for it with
  /// provide [literal].
  void _addTokenLiteral(TokenType type, Object literal) {
    String text = _source.substring(_start, _current);
    _tokens.add(Token.create(type, text, literal, line));
  }

  /// It’s like a conditional advance.
  /// Using *match* , we recognize these lexemes in two stages. When we reach,
  /// for example, **!** , we jump to its switch case. That means we know the
  /// lexeme starts with **!** . Then we look at the next character to
  /// determine if we’re on a **!=** or merely a **!** .
  bool match(String expected) {
    if (_isAtEnd) return false;
    if (_source.substring(_current, _current + 1) != expected) return false;
    _current++;
    return true;
  }

  void _identifier() {
    while (_isAlphaNumeric(_peek())) {
      _advance();
    }

    String text = _source.substring(_start, _current);
    TokenType? type = _keywords[text];

    type ??= TokenType.identifier;

    _addToken(type);
  }

  bool _isAlpha(String c) {
    int code = c.codeUnitAt(0);

    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  bool _isAlphaNumeric(String? c) {
    return c == null ? false : _isAlpha(c) || _isDigit(c);
  }

  void _number() {
    while (_isDigit(_peek())) {
      _advance();
    }

    // Look for a fractional part.
    if (_peek() == '.' && _isDigit(_peekNext())) {
      // Consume the "."
      _advance();
      while (_isDigit(_peek())) {
        _advance();
      }
    }

    _addTokenLiteral(
        TokenType.number, double.parse(_source.substring(_start, _current)));
  }

  void _string() {
    while (_peek() != '"' && !_isAtEnd) {
      if (_peek() == '\n') line++;
      _advance();
    }

    if (_isAtEnd) {
      LogiErrors.error(line, "Unterminated string.");
      return;
    }

    // The closing quote.
    _advance();

    // Trim the surrounding quotes.
    String value = _source.substring(_start + 1, _current - 1);
    _addTokenLiteral(TokenType.string, value);
  }

  bool _isDigit(String? c) {
    if (c == null) return false;
    double? d = double.tryParse(c);
    return d == null ? false : d >= 0 && d <= 9;
  }

  String? _peek() {
    if (_isAtEnd) return null;
    return _source.substring(_current, _current + 1);
  }

  String? _peekNext() {
    if (_current + 1 >= _source.length) return null;
    return _source.substring(_current + 1, _current + 2);
  }
}
