enum Directive {
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
}

enum TokenType {
  instruction,
  register,
  number,
  label,
  directive,
  compundDirective,
  unknown,
}

extension TokenTypeExtension on TokenType {
  String get description {
    switch (this) {
      case TokenType.instruction:
        return 'Instrucción';
      case TokenType.register:
        return 'Registro';
      case TokenType.number:
        return 'Número';
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

final Map<Directive, RegExp> directiveRegExp = {
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
};

final Set<String> instructions = {
  "aaa",
  "aad",
  "aam",
  "aas",
  "adc",
  "add",
  "and",
  "call",
  "cbw",
  "clc",
  "cld",
  "cli",
  "cmc",
  "cmp",
  "cmpsb",
  "cmpsw",
  "cwd",
  "daa",
  "das",
  "dec",
  "div",
  "hlt",
  "idiv",
  "imul",
  "in",
  "inc",
  "int",
  "into",
  "iret",
  "ja",
  "jae",
  "jb",
  "jbe",
  "jc",
  "jcxz",
  "je",
  "jg",
  "jge",
  "jl",
  "jle",
  "jmp",
  "jna",
  "jnae",
  "jnb",
  "jnbe",
  "jnc",
  "jne",
  "jng",
  "jnge",
  "jnl",
  "jnle",
  "jno",
  "jnp",
  "jns",
  "jnz",
  "jo",
  "jp",
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
  "movsb",
  "movsw",
  "mul",
  "neg",
  "nop",
  "not",
  "or",
  "out",
  "pop",
  "popa",
  "popf",
  "push",
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
  "ror",
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
  "sub",
  "test",
  "xchg",
  "xlatb",
  "xor"
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

final RegExp numberRegExp =
    RegExp(r'^\d+d?$|^[01]+b$|^0x[0-9a-f]+$|^[0-9a-f]+h$');
final RegExp labelRegExp = RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$');
