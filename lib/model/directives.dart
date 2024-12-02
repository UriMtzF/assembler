enum TokenType {
  binNumber,
  octNumber,
  decNumber,
  hexNumber,
  string,
  label,
  register,
  instruction, //Asigned instruction
  symbol, //Other instructions not assigned
  // Pseudoinstructions
  stackSegment,
  dataSegment,
  codeSegment,
  ends,
  defineByte,
  defineWord,
  equ,
  bytePtr,
  wordPtr,
  dup,
  bracket,
  model,
  unknown,
}

extension TokenTypeExtension on TokenType {
  String get description {
    switch (this) {
      case TokenType.decNumber:
        return 'Constante numérica decimal';
      case TokenType.binNumber:
        return 'Constante numérica binaria';
      case TokenType.hexNumber:
        return 'Constante numérica hexadecimal';
      case TokenType.octNumber:
        return 'Constante numérica octal';
      case TokenType.string:
        return 'Cadena';
      case TokenType.symbol:
        return 'Símbolo';
      case TokenType.instruction:
        return 'Instrucción';
      case TokenType.register:
        return 'Registro';
      case TokenType.label:
        return 'Etiqueta';
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
      case TokenType.defineByte:
        return 'Definición byte';
      case TokenType.defineWord:
        return 'Definición palabra';
      case TokenType.equ:
        return 'Definición de constante';
      case TokenType.ends:
        return 'Final';
      case TokenType.unknown:
        return 'Desconocido';
      default:
        return 'No asignado';
    }
  }
}

final binNumberRegExp = RegExp(r'^-?[01]+b\b');
final octNumberRegExp = RegExp(r'^-?[0-7]+o\b');
final decNumberRegExp = RegExp(r'^-?\d+d?\b');
final hexNumberRegExp = RegExp(r'^-?(0x|0)[a-f0-9]+h\b');
final labelRegExp = RegExp(r'^[a-zA-Z_][0-9a-zA-Z_]*:?$');

final Map<TokenType, RegExp> directiveRegExp = {
  TokenType.stackSegment: RegExp(r'^\.stack segment$'),
  TokenType.dataSegment: RegExp(r'^\.data segment$'),
  TokenType.codeSegment: RegExp(r'^\.code segment$'),
  TokenType.ends: RegExp(r'^ends$'),
  TokenType.defineByte: RegExp(r'^db$'),
  TokenType.defineWord: RegExp(r'^dw$'),
  TokenType.equ: RegExp(r'^equ$'),
  TokenType.bytePtr: RegExp(r'\bbyte\s+ptr\b'),
  TokenType.wordPtr: RegExp(r'\bword\s+ptr\b'),
  TokenType.dup: RegExp(r'\bdup\((.*?)\)'),
  TokenType.bracket: RegExp(r'^\[[^\]]+\]$'),
  TokenType.model: RegExp(r'^\.model small$'),
  TokenType.string: RegExp('(["\'])(.*?)(\\1)'),
};

final Set<String> symbolsSet = {
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
