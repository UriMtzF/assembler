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
      // Delete all comments, delete all blank spaces, make it lower case
      String modifiedLine =
          line.replaceAll(RegExp(r';.*$'), '').trim().toLowerCase();
      if (modifiedLine.isNotEmpty) {
        // If line is not empty save it
        tokenizedCode.add(modifiedLine);
      }
    }
    this.code = tokenizedCode;
    tokenize();
    identifyTypes();
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
    // Iterate all lines of tokens
    for (String token in tokens) {
      TokenType type;
      // If the token is in RegEx of PseudoInstructions set its type
      if (directiveRegExp.values.any((regex) => regex.hasMatch(token))) {
        type = TokenType.compundDirective;
        // If the token is in the Instruction Set, set it as Instruction
      } else if (instructions.contains(token)) {
        type = TokenType.instruction;
        // If the token is in the Register Set, set it as Register
      } else if (registers.contains(token)) {
        type = TokenType.register;
        // If the token is detected in the Number RegEx, set it as Number
      } else if (numberRegExp.hasMatch(token)) {
        type = TokenType.number;
        // If the token is detected in the Label RegEx, set it as Label
      } else if (labelRegExp.hasMatch(token)) {
        type = TokenType.label;
      } else {
        // If no other type is detected set it as unknown
        type = TokenType.unknown;
      }
      // Add the token type to the list
      types.add(type.description);
    }
    // Save the types to the attribute of the class
    if (types.isNotEmpty) {
      this.types = types;
    }
  }
}
