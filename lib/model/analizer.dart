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

  // Setter for code
  set setCode(List<String> code) {
    List<String> tokenizedCode = [];
    // Iterates all lines of code
    for (String line in code) {
      String modifiedLine = _lowerCase(line);
      // Delete all comments, delete all blank spaces, make it lower case
      if (modifiedLine.isNotEmpty) {
        // If line is not empty save it
        tokenizedCode.add(modifiedLine);
      }
    }
    this.code = tokenizedCode;
    tokenize();
    identifyTypes();
  }

  String _lowerCase(String line) {
    line = line.replaceAll(RegExp(r';.*$'), '').trim();

    RegExp regex = RegExp(r'''(["\']).*?\1''');

    List<String> parts = [];
    int lastIndex = 0;

    for (final match in regex.allMatches(line)) {
      if (lastIndex < match.start) {
        parts.add(line.substring(lastIndex, match.start).toLowerCase());
      }
      parts.add(match.group(0)!);
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      parts.add(line.substring(lastIndex).toLowerCase());
    }
    return parts.join();
  }

  // Make tokens of code
  void tokenize() {
    List<String> tokenizedCode = [];
    // Iterates all lines of code
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

      type = directiveRegExp.entries
          .firstWhere(
            (entry) => entry.value.hasMatch(token),
            orElse: () => MapEntry(TokenType.unknown, RegExp(r'')),
          )
          .key;

      if (type == TokenType.unknown) {
        if (registers.contains(token)) {
          type = TokenType.instruction;
        } else if (symbols.contains(token)) {
          type = TokenType.symbol;
        } else if (registers.contains(token)) {
          type = TokenType.register;
        } else if (decNumberRegExp.hasMatch(token)) {
          type = TokenType.decNumber;
        } else if (binNumberRegExp.hasMatch(token)) {
          type = TokenType.binNumber;
        } else if (hexNumberRegExp.hasMatch(token)) {
          type = TokenType.hexNumber;
        } else if (labelRegExp.hasMatch(token)) {
          type = TokenType.label;
        }
      }

      types.add(type.description);
    }

    if (types.isNotEmpty) {
      this.types = types;
    }
  }
}
