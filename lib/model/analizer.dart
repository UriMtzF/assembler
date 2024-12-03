import 'package:assembler/model/directives.dart';

class Token {
  String value;
  TokenType type;
  int line;

  Token(this.value, this.type, this.line);
}

class Result {
  final bool isValid;
  final String message;
  Result(this.isValid, this.message);
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
    // Check if the segments are valid, if not set all code as wrong, else continue the analysis
    analysis = List.generate(code.length, (i) => Result(true, "No analizado"));
    if (!_verifySegments()) {
      analysis = List.generate(
        code.length,
        (i) => Result(
            false, "Alguno de los segmentos no existe o no tiene un cierre"),
      );
      return;
    }
    _checkOutsideSegments();
    _checkStackSegment();
    _checkDataSegment();
    _checkCodeSegment();
  }

  void _checkOutsideSegments() {
    int stackSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.stackSegment);
    int stackEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, stackSegmentIndex);

    int dataSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.dataSegment);
    int dataEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, dataSegmentIndex);

    int codeSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.codeSegment);
    int codeEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, codeSegmentIndex);

    Result result = Result(false, "Fuera de segmentos");

    // All code before stack segment is wrong
    for (int i = 0; i < stackSegmentIndex; i++) {
      analysis[tokens[i].line] = result;
    }

    // All code between stack ends and data segment is wrong
    for (int i = stackEndsIndex + 1; i < dataSegmentIndex; i++) {
      analysis[tokens[i].line] = result;
    }

    // All code between data ends and code segment is wrong
    for (int i = dataEndsIndex + 1; i < codeSegmentIndex; i++) {
      analysis[tokens[i].line] = result;
    }

    // All code after code ends is wrong
    for (int i = codeEndsIndex + 1; i < tokens.length; i++) {
      analysis[tokens[i].line] = result;
    }
  }

  void _checkStackSegment() {
    int stackSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.stackSegment);
    int stackEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, stackSegmentIndex);

    analysis[tokens[stackSegmentIndex].line] = Result(true, "Válido");
    analysis[tokens[stackEndsIndex].line] = Result(true, "Válido");

    for (int i = stackSegmentIndex + 1; i < stackEndsIndex; i++) {
      Token currentToken = tokens[i];

      // Verify if the token is a dw
      if (currentToken.type == TokenType.defineWord) {
        // Verify if the following tokens are a number and a dup
        if (i + 1 < stackEndsIndex &&
            numberTokens.contains(tokens[i + 1].type)) {
          if (i + 2 < stackEndsIndex && tokens[i + 2].type == TokenType.dup) {
            bool isValidNumber = _isValidUnsignedNumber(tokens[i + 1].value);
            bool isValidDupContent = _isValidNumber(tokens[i + 2]
                .value
                .substring(4, tokens[i + 2].value.length - 1));

            if (isValidNumber && isValidDupContent) {
              analysis[currentToken.line] = Result(true, "Válido");
              i += 2;
              continue;
            }
          }
          analysis[currentToken.line] =
              Result(false, "Definición de pila inválido");
          continue;
        }
        // If the following tokens after dw are invalid, set the line as wrong
        analysis[currentToken.line] =
            Result(false, "Formato de definición de pila inválido");
        continue;
      }

      //If the token does not contains a valid start, set the line as wrong
      analysis[currentToken.line] =
          Result(false, "Contenido inválido para segmento de pila");
      continue;
    }
  }

  bool _isValidNumber(String token) {
    return binNumberRegExp.hasMatch(token) ||
        octNumberRegExp.hasMatch(token) ||
        decNumberRegExp.hasMatch(token) ||
        hexNumberRegExp.hasMatch(token);
  }

  bool _isValidUnsignedNumber(String token) {
    if (_isValidNumber(token)) {
      return token.substring(0, 1) != '-';
    }
    return false;
  }

  void _checkDataSegment() {
    int dataSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.dataSegment);
    int dataEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, dataSegmentIndex);

    analysis[tokens[dataSegmentIndex].line] = Result(true, "Válido");
    analysis[tokens[dataEndsIndex].line] = Result(true, "Válido");

    for (int i = dataSegmentIndex + 1; i < dataEndsIndex; i++) {
      Token currentToken = tokens[i];

      if (analysis[currentToken.line].message != "No analizado") {
        continue;
      }

      // The variables must follow the following rules:
      // label dx value || dup(value)
      // If dup is present, value must be positive
      if (currentToken.type == TokenType.label) {
        // If the next token is outside segment
        // the label has no definition and its wrong
        if (i + 1 >= dataEndsIndex) {
          analysis[currentToken.line] =
              Result(false, "Etiqueta sin definición");
          continue;
        }

        // If the next token is not a definition,
        // the variable is wrong
        Token nextToken = tokens[i + 1];
        if (![TokenType.defineByte, TokenType.defineWord, TokenType.equ]
            .contains(nextToken.type)) {
          analysis[currentToken.line] =
              Result(false, "Etiqueta sin definición");
          continue;
        }

        // Case 1: db
        if (nextToken.type == TokenType.defineByte) {
          // After the definition there is no value so its wrong
          if (i + 2 >= dataEndsIndex) {
            analysis[currentToken.line] =
                Result(false, "Las definiciones requieren un valor");
            continue;
          }

          Token valueToken = tokens[i + 2];
          // After de definition there is not a string or number
          if (!(numberTokens.contains(valueToken.type) ||
              directiveRegExp[TokenType.string]!.hasMatch(valueToken.value))) {
            analysis[currentToken.line] =
                Result(false, "db solo acepta cadenas o números");
            continue;
          }

          // The value token is a string
          if (directiveRegExp[TokenType.string]!.hasMatch(valueToken.value)) {
            analysis[currentToken.line] = Result(true, "Válido");
            continue;
          }

          // The value token is a number
          if (numberTokens.contains(valueToken.type)) {
            // Temporarily set as valid, but if a dup is found
            // rewrite the Result
            analysis[currentToken.line] = Result(true, "Válido");

            Token dupToken = tokens[i + 3];
            // A dup token is found
            if (dupToken.type == TokenType.dup) {
              // The value token must be positive if a dup is present
              if (!_isValidUnsignedNumber(valueToken.value)) {
                analysis[currentToken.line] =
                    Result(false, "dup debe ser positivo");
                continue;
              }

              // The content of the dup must be a String or a number
              String dupContent =
                  dupToken.value.substring(0, dupToken.value.length - 1);
              // The content of the dup is not valid
              if (!(directiveRegExp[TokenType.string]!.hasMatch(dupContent) ||
                  _isValidNumber(dupContent))) {
                analysis[currentToken.line] =
                    Result(false, "El contenido del dup no es válido");
                continue;
              }
            }
            continue;
          }
        }

        if (nextToken.type == TokenType.defineWord) {
          // There is no value after dw
          if (i + 2 >= dataEndsIndex) {
            analysis[currentToken.line] = Result(false, "dw requiere un valor");
            continue;
          }

          // The value after dw is not a number
          Token valueToken = tokens[i + 2];
          if (!numberTokens.contains(valueToken.type)) {
            analysis[currentToken.line] =
                Result(false, "dw sólo acepta números");
            continue;
          }

          // The value token is a number
          if (numberTokens.contains(valueToken.type)) {
            // Temporarily set as valid, but if a dup is found
            // rewrite the Result
            analysis[currentToken.line] = Result(true, "Válido");

            Token dupToken = tokens[i + 3];
            // A dup token is found
            if (dupToken.type == TokenType.dup) {
              // The value token must be positive if a dup is present
              if (!_isValidUnsignedNumber(valueToken.value)) {
                analysis[currentToken.line] =
                    Result(false, "dup debe ser positivo");
                continue;
              }

              // The content of the dup must be a number
              String dupContent =
                  dupToken.value.substring(0, dupToken.value.length - 1);
              // The content of the dup is not valid
              if (!_isValidNumber(dupContent)) {
                analysis[currentToken.line] =
                    Result(false, "El contenido del dup no es válido");
                continue;
              }
            }
            continue;
          }
        }

        if (nextToken.type == TokenType.equ) {
          if (i + 2 >= dataEndsIndex) {
            analysis[currentToken.line] =
                Result(false, "equ requiere un valor");
            continue;
          }

          Token valueToken = tokens[i + 2];
          if (!numberTokens.contains(valueToken.type)) {
            analysis[currentToken.line] =
                Result(false, "equ sólo acepta números");
          }
        }
      }
    }
  }

  void _checkCodeSegment() {}

  bool _verifySegments() {
    int stackSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.stackSegment);
    int stackEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, stackSegmentIndex);

    int dataSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.dataSegment);
    int dataEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, dataSegmentIndex);

    int codeSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.codeSegment);
    int codeEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, codeSegmentIndex);

    return stackSegmentIndex != -1 &&
        stackEndsIndex != -1 &&
        dataSegmentIndex != -1 &&
        dataEndsIndex != -1 &&
        codeSegmentIndex != -1 &&
        codeEndsIndex != -1 &&
        stackSegmentIndex < stackEndsIndex &&
        stackEndsIndex < dataSegmentIndex &&
        dataSegmentIndex < dataEndsIndex &&
        dataEndsIndex < codeSegmentIndex &&
        codeSegmentIndex < codeEndsIndex;
  }
}
