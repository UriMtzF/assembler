enum TokenType {
  instruction,
  symbol,
  register,
  decNumber,
  binNumber,
  hexNumber,
  label,
  compundDirective,
  model,
  codeSegment,
  dataSegment,
  stackSegment,
  bytePtr,
  wordPtr,
  dup,
  bracket,
  doubleQuotes,
  singleQuotes,
  defineByte,
  defineWord,
  end,
  unknown,
}

// Set the description for each token type
extension TokenTypeExtension on TokenType {
  String get description {
    switch (this) {
      case TokenType.symbol:
        return 'Símbolo';
      case TokenType.instruction:
        return 'Instrucción';
      case TokenType.register:
        return 'Registro';
      case TokenType.decNumber:
        return 'Número decimal';
      case TokenType.binNumber:
        return 'Número binario';
      case TokenType.hexNumber:
        return 'Número hexadecimal';
      case TokenType.label:
        return 'Etiqueta';
      case TokenType.compundDirective:
        return 'Pseudoinstrucción';
      case TokenType.model:
        return 'Modelo';
      case TokenType.codeSegment:
        return 'Segmento de código';
      case TokenType.dataSegment:
        return 'Segmento de datos';
      case TokenType.stackSegment:
        return 'Segmento de datos';
      case TokenType.bytePtr:
        return 'Puntero de byte';
      case TokenType.wordPtr:
        return 'Puntero de palabra';
      case TokenType.dup:
        return 'Dup';
      case TokenType.bracket:
        return 'Corchetes';
      case TokenType.doubleQuotes:
        return 'Cadena (comilla dobles)';
      case TokenType.singleQuotes:
        return 'Cadena (comillas simples)';
      case TokenType.defineByte:
        return 'Definición byte';
      case TokenType.defineWord:
        return 'Definición palabra';
      case TokenType.end:
        return 'Final';
      case TokenType.unknown:
        return 'Desconocido';
      default:
        return 'Desconocido';
    }
  }
}

// Map each pseudoinstruction type with its Regular Expresion
final Map<TokenType, RegExp> directiveRegExp = {
  TokenType.model: RegExp(r'\.model small\b'),
  TokenType.codeSegment: RegExp(r'\.code segment\b'),
  TokenType.dataSegment: RegExp(r'\.data segment\b'),
  TokenType.stackSegment: RegExp(r'\.stack segment\b'),
  TokenType.bytePtr: RegExp(r'\bbyte ptr\b'),
  TokenType.wordPtr: RegExp(r'\bword ptr\b'),
  TokenType.dup: RegExp(r'dup\([^)]+\)'),
  TokenType.bracket: RegExp(r'\[[^\]]+\]'),
  TokenType.doubleQuotes: RegExp(r'"[^"]*"'),
  TokenType.singleQuotes: RegExp(r"'[^']*'"),
  TokenType.defineByte: RegExp(r'db'),
  TokenType.defineWord: RegExp(r'dw'),
  TokenType.end: RegExp(r'ends\b'),
};

// List all instructions
final Set<String> symbols = {
  "aad",
  "aam",
  "aas",
  "adc",
  "add",
  "call",
  "cbw",
  "clc",
  "cmc",
  "cmp",
  "cmpsb",
  "cmpsw",
  "cwd",
  "daa",
  "das",
  "div",
  "hlt",
  "imul",
  "in",
  "inc",
  "int",
  "into",
  "iret",
  "ja",
  "jb",
  "jbe",
  "jc",
  "je",
  "jg",
  "jge",
  "jle",
  "jmp",
  "jna",
  "jnae",
  "jnb",
  "jnbe",
  "jnc",
  "jne",
  "jng",
  "jnl",
  "jnle",
  "jno",
  "jns",
  "jnz",
  "jo",
  "jpe",
  "jpo",
  "js",
  "jz",
  "lahf",
  "lds",
  "lea",
  "les",
  "lodsb",
  "lodsw",
  "loop",
  "loope",
  "loopne",
  "loopnz",
  "loopz",
  "mov",
  "mul",
  "neg",
  "nop",
  "not",
  "or",
  "out",
  "popa",
  "popf",
  "pusha",
  "pushf",
  "rcl",
  "rcr",
  "rep",
  "repe",
  "repne",
  "repnz",
  "repz",
  "ret",
  "retf",
  "rol",
  "sahf",
  "sal",
  "sar",
  "sbb",
  "scasb",
  "scasw",
  "shl",
  "shr",
  "stc",
  "std",
  "sti",
  "stosb",
  "stosw",
  "test",
  "xchg",
};

final Set<String> instructions = {
  "cld",
  "cli",
  "movsb",
  "movsw",
  "xlatb",
  "aaa",
  "pop",
  "idiv",
  "push",
  "dec",
  "ror",
  "sub",
  "xor",
  "and",
  "jae",
  "jcxz",
  "jl",
  "jnge",
  "jnp",
  "jp"
};

// List all registers
final Set<String> registers = {
  'ax',
  'bx',
  'cx',
  'dx',
  'sp',
  'bp',
  'si',
  'di',
  'ah',
  'al',
  'bh',
  'bl',
  'ch',
  'cl',
  'dh',
  'dl'
};

// Regular Expresion for number types (Hex, Dec, Bin)
final RegExp decNumberRegExp = RegExp(r'^-?\d+');
final RegExp binNumberRegExp = RegExp(r'^-?[01]+b\b$');
final RegExp hexNumberRegExp = RegExp(r'^-?(0x|0)[a-f0-9]+h\b');
// Regular Expresion for valid labels
final RegExp labelRegExp = RegExp(r'\b[a-zA-Z_][a-zA-Z0-9_]*(:?)');
