// Note: not all tokens are actually used. They are present just for
// preservation.
enum TokenType {
  // Single character tokens
  leftParen,
  rightParen,
  minus,
  plus,
  slash,
  star,

  // One or two character tokens
  bang,
  bangEqual,
  equal,
  equalEqual,
  greater,
  greaterEqual,
  less,
  lessEqual,

  // Literals
  identifier,
  number,
  string,
  nil,

  // Keywords
  and,
  bitAnd,
  or,
  bitOr,
  bFalse,
  bTrue,
  xor,

  // Statements
  semiColon,
  print,
  sVar, // var

  eof,
}
