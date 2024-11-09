// Enumerate all the pseudoinstruction types
enum Directive {
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
}

// Enumerate all token types
enum TokenType {
  instruction,
  symbol,
  register,
  decNumber,
  binNumber,
  hexNumber,
  label,
  directive,
  compundDirective,
  unknown,
}

// Set the description for each token type
extension TokenTypeExtension on TokenType {
  String get description {
    switch (this) {
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
      case TokenType.directive:
        return 'Directiva';
      case TokenType.compundDirective:
        return 'Pseudoinstrucción';
      case TokenType.unknown:
        return 'Desconocido';
      default:
        return 'Desconocido';
    }
  }
}

// Map each pseudoinstruction type with its Regular Expresion
final Map<Directive, RegExp> directiveRegExp = {
  Directive.model: RegExp(r'\.model small\b'),
  Directive.codeSegment: RegExp(r'\.code segment\b'),
  Directive.dataSegment: RegExp(r'\.data segment\b'),
  Directive.stackSegment: RegExp(r'\.stack segment\b'),
  Directive.bytePtr: RegExp(r'\bbyte ptr\b'),
  Directive.wordPtr: RegExp(r'\bword ptr\b'),
  Directive.dup: RegExp(r'dup\([^)]+\)'),
  Directive.bracket: RegExp(r'\[[^\]]+\]'),
  Directive.doubleQuotes: RegExp(r'"[^"]*"'),
  Directive.singleQuotes: RegExp(r"'[^']*'"),
  Directive.defineByte: RegExp(r'db'),
  Directive.defineWord: RegExp(r'dw'),
  Directive.end: RegExp(r'ends\b'),
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
final RegExp decNumberRegExp = RegExp(r'\d{3}|\d{5}');
final RegExp binNumberRegExp = RegExp(r'^[01]{8}b|^[01]{16}b$');
final RegExp hexNumberRegExp =
    RegExp(r'\b(0x[a-f0-9]{2}|0x[a-f0-9]{4}|0[a-f0-9]{2}|0[a-f0-9]{4})h\b');
// Regular Expresion for valid labels
final RegExp labelRegExp = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*:$');
