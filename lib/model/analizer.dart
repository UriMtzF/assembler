import 'package:assembler/model/directives.dart';

class Token {
  String value;
  TokenType type;
  int line;

  Token(this.value, this.type, this.line);
}

class Result {
  final int line;
  final bool isValid;
  final String message;
  Result(this.line, this.isValid, this.message);
}

class Symbol {
  final String name;
  final TokenType type;
  final String value;
  final String size;
  Symbol(this.name, this.type, this.value, this.size);
}

class Analizer {
  List<String> code = [];
  Map<int, String> cleanCode = {};
  List<Token> tokens = [];
  List<Result> analysis = [];
  List<Symbol> symbols = [];

  String _lowerCase(String line) {
    line = line.replaceAll(RegExp(r';.*$'), '').trim();

    RegExp regex = RegExp(r'''(["\']).*?\1''');

    List<String> parts = [];
    int lastIndex = 0;

    for (final match in regex.allMatches(line)) {
      if (lastIndex < match.start) {
        parts.add(line.substring(lastIndex, match.start).toLowerCase());
      }
      parts.add(match.group(0)!.trim());
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      parts.add(line.substring(lastIndex).toLowerCase().trim());
    }
    return parts.join();
  }

  void clearCode() {
    if (code.isEmpty) {
      return;
    }
    for (int i = 0; i < code.length; i++) {
      String line = code[i];
      String modifiedLine = _lowerCase(line);

      if (modifiedLine.isNotEmpty) {
        cleanCode[i] = modifiedLine;
      }
    }
  }

  void tokenize() {
    if (cleanCode.isEmpty) {
      return;
    }
    for (int i = 0; i < code.length; i++) {
      String line = cleanCode[i] ?? "";
      String modifiedLine = line;
      Map<String, String> compoundTokens = {};
      int tokenIndex = 0;

      for (MapEntry<TokenType, RegExp> entry in directiveRegExp.entries) {
        for (RegExpMatch match in entry.value.allMatches(line)) {
          String token = match.group(0)!;
          String placeholder = '__TOKEN_${tokenIndex}__';
          compoundTokens[placeholder] = token;
          modifiedLine = modifiedLine.replaceFirst(token, placeholder);
          tokenIndex++;
        }
      }

      List<String> tokens = modifiedLine
          .split(RegExp(r'[ ,:]'))
          .where((token) => token.isNotEmpty)
          .toList();

      for (int j = 0; j < tokens.length; j++) {
        if (compoundTokens.containsKey(tokens[j])) {
          tokens[j] = compoundTokens[tokens[j]]!;
        }
      }

      for (String token in tokens) {
        this.tokens.add(Token(token, TokenType.unknown, i));
      }
    }
  }

  void identifyTypes() {
    for (Token token in tokens) {
      TokenType type;

      type = directiveRegExp.entries
          .firstWhere(
            (entry) => entry.value.hasMatch(token.value),
            orElse: () => MapEntry(TokenType.unknown, RegExp(r'')),
          )
          .key;

      if (type == TokenType.unknown) {
        if (instructions.contains(token.value)) {
          type = TokenType.instruction;
        } else if (symbolsSet.contains(token.value)) {
          type = TokenType.symbol;
        } else if (registers.contains(token.value)) {
          type = TokenType.register;
        } else if (binNumberRegExp.hasMatch(token.value)) {
          type = TokenType.binNumber;
        } else if (octNumberRegExp.hasMatch(token.value)) {
          type = TokenType.octNumber;
        } else if (decNumberRegExp.hasMatch(token.value)) {
          type = TokenType.decNumber;
        } else if (hexNumberRegExp.hasMatch(token.value)) {
          type = TokenType.hexNumber;
        } else if (labelRegExp.hasMatch(token.value)) {
          type = TokenType.label;
        }
      }
      token.type = type;
    }
  }

  void analizeCode() {
    Token stackSegment = tokens.firstWhere(
        (token) => token.type == TokenType.stackSegment,
        orElse: () => Token("", TokenType.unknown, -1));
    Token dataSegment = tokens.firstWhere(
        (token) => token.type == TokenType.dataSegment,
        orElse: () => Token("", TokenType.unknown, -1));
    Token codeSegment = tokens.firstWhere(
        (token) => token.type == TokenType.codeSegment,
        orElse: () => Token("", TokenType.unknown, -1));
    if (stackSegment.line == -1 ||
        dataSegment.line == -1 ||
        codeSegment.line == -1) {
      for (int i = 0; i < code.length; i++) {
        analysis.add(
            Result(i, false, "Algún segmento no está presente en el código"));
      }
    }
  }
}
