enum TokenType {
  // Single character tokens
  leftParen,
  rightParen,
  minus,
  plus,
  slash,

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

  // keywords
  and,
  or,
  bFalse,
  bTrue,
  xor,

  nil,
  eof,
}
