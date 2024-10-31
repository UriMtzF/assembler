import 'package:assembler/model/directives.dart';

class Analizer {
  List<String> code;
  List<String> tokens;
  List<String> types;

  Analizer({
    this.code = const [""],
    this.tokens = const [""],
    this.types = const [""],
  });

  set setCode(List<String> code) {
    List<String> tokenizedCode = [];
    for (String line in code) {
      String modifiedLine =
          line.replaceAll(RegExp(r';.*$'), '').trim().toLowerCase();
      if (modifiedLine.isNotEmpty) {
        tokenizedCode.add(modifiedLine);
      }
    }
    this.code = tokenizedCode;
    tokenize();
    identifyTypes();
  }

  void tokenize() {
    List<String> tokenizedCode = [];
    for (String line in code) {
      String modifiedLine = line;
      Map<String, String> compundTokens = {};
      int tokenIndex = 0;
      for (var entry in directiveRegExp.entries) {
        for (var match in entry.value.allMatches(line)) {
          String token = match.group(0)!;
          String placeholder = '__TOKEN_${tokenIndex}__';
          compundTokens[placeholder] = token;
          modifiedLine = modifiedLine.replaceFirst(token, placeholder);
          tokenIndex++;
        }
      }

      List<String> tokens = modifiedLine
          .split(RegExp(r'[ ,:]'))
          .where((token) => token.isNotEmpty)
          .toList();

      for (int i = 0; i < tokens.length; i++) {
        if (compundTokens.containsKey(tokens[i])) {
          tokens[i] = compundTokens[tokens[i]]!;
        }
      }

      tokenizedCode.addAll(tokens);
    }
    if (tokenizedCode.isNotEmpty) {
      tokens = tokenizedCode;
    }
  }

  void identifyTypes() {
    List<String> types = [];
    for (String token in tokens) {
      TokenType type;

      if (directiveRegExp.values.any((regex) => regex.hasMatch(token))) {
        type = TokenType.compundDirective;
      } else if (instructions.contains(token)) {
        type = TokenType.instruction;
      } else if (registers.contains(token)) {
        type = TokenType.register;
      } else if (numberRegExp.hasMatch(token)) {
        type = TokenType.number;
      } else if (labelRegExp.hasMatch(token)) {
        type = TokenType.label;
      } else {
        type = TokenType.unknown;
      }
      types.add(type.description);
    }
    if (types.isNotEmpty) {
      this.types = types;
    }
  }
}
