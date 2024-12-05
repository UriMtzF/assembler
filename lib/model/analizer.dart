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
  int direction = 0x250;
  Result(this.isValid, this.message);
}

class Symbol {
  final Token token;
  final String name;
  final String type;
  final String value;
  final int size;
  int direction = 0;
  Symbol(this.name, this.type, this.value, this.size, this.token);
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
          .split(RegExp(r'[ ,]'))
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
        } else if (segments.contains(token.value)) {
          TokenType.segment;
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
    analysis = List.generate(code.length, (i) => Result(false, "No analizado"));
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
    _checkLabels();
    _setDirection();
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

    bool hasValidStackSegment = false;

    for (int i = stackSegmentIndex + 1; i < stackEndsIndex; i++) {
      Token currentToken = tokens[i];

      // Verify if the token is a dw
      if (!hasValidStackSegment && currentToken.type == TokenType.defineWord) {
        // Verify if the following tokens are a number and a dup
        if (i + 1 < stackEndsIndex &&
            numberTokens.contains(tokens[i + 1].type)) {
          if (i + 2 < stackEndsIndex && tokens[i + 2].type == TokenType.dup) {
            bool isValidNumber = _isValidUnsignedNumber(tokens[i + 1].value);
            bool isValidDupContent = _isValidNumber(tokens[i + 2]
                .value
                .substring(4, tokens[i + 2].value.length - 1));

            if (isValidNumber && isValidDupContent) {
              hasValidStackSegment = true;
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
        if (currentToken.value.endsWith(":")) {
          analysis[currentToken.line] = Result(false, "Etiqueta inválida");
          continue;
        }

        if (currentToken.value.length > 10) {
          analysis[currentToken.line] =
              Result(false, "Nombre de etiqueta muy grande");
          continue;
        }

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
              if (valueToken.type != TokenType.decNumber) {
                analysis[currentToken.line] =
                    Result(false, "El predecesor de un dup debe ser decimal");
              }
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

  void _checkCodeSegment() {
    int codeSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.codeSegment);
    int codeEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, codeSegmentIndex);

    analysis[tokens[codeSegmentIndex].line] = Result(true, "Válido");
    analysis[tokens[codeEndsIndex].line] = Result(true, "Válido");

    for (int i = codeSegmentIndex + 1; i < codeEndsIndex; i++) {
      Token currentToken = tokens[i];

      //Jump already asigned instructions
      if (analysis[currentToken.line].message != "No analizado") {
        continue;
      }

      if (!(currentToken.type == TokenType.instruction ||
          currentToken.type == TokenType.label)) {
        analysis[currentToken.line] = Result(false, "Inválido");
      }

      List<Token> labelTokens = tokens
          .where((token) =>
              token.line == currentToken.line &&
              token.type == TokenType.label &&
              token.value.substring(token.value.length - 1) == ':')
          .toList();

      if (labelTokens.length != 1) {
        analysis[currentToken.line] = Result(false, "Etiqueta invalida");
      } else {
        labelTokens[0].value.length > 11
            ? analysis[currentToken.line] =
                Result(false, "Nombre de etiqueta muy grande")
            : analysis[currentToken.line] = Result(true, "Etiqueta");
        continue;
      }

      if (currentToken.type == TokenType.instruction) {
        String tokenValue = currentToken.value;
        Set<String> noArgsIns = {
          "cld",
          "cli",
          "movsb",
          "movsw",
          "xlatb",
          "aaa"
        };

        List<Token> lineTokens =
            tokens.where((token) => token.line == currentToken.line).toList();

        // Instructions with no args
        if (noArgsIns.contains(tokenValue) && lineTokens.length == 1) {
          analysis[currentToken.line] = Result(true, "Válido");
          continue;
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }

        // Instructions with one arg
        if (i + 1 >= codeEndsIndex) {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
          continue;
        }

        TokenType firstArgType = tokens[i + 1].type;

        if ((tokenValue == "idiv" || tokenValue == "dec") &&
            firstArgType == TokenType.register) {
          analysis[currentToken.line] = Result(true, "Válido");
          continue;
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }

        if ((tokenValue == "pop" || tokenValue == "push") &&
            (firstArgType == TokenType.register ||
                firstArgType == TokenType.segment)) {
          analysis[currentToken.line] = Result(true, "Válido");
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }

        if ((tokenValue == "jae" ||
                tokenValue == "jcxz" ||
                tokenValue == "jl" ||
                tokenValue == "jnge" ||
                tokenValue == "jnp" ||
                tokenValue == "jp") &&
            firstArgType == TokenType.label &&
            tokens[i + 1].value.substring(tokens[i + 1].value.length - 1) !=
                ":") {
          analysis[currentToken.line] = Result(true, "Válido");
          continue;
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }

        // Instructions with two args
        if (i + 2 >= codeEndsIndex) {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
          continue;
        }

        TokenType secondArgType = tokens[i + 2].type;

        if (tokenValue == "ror" &&
            firstArgType == TokenType.register &&
            numberTokens.contains(secondArgType)) {
          analysis[currentToken.line] = Result(true, "Válido");
          continue;
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }

        if ((tokenValue == "sub" ||
                tokenValue == "xor" ||
                tokenValue == "and") &&
            ((firstArgType == TokenType.register &&
                    secondArgType == TokenType.register) ||
                (firstArgType == TokenType.label &&
                    secondArgType == TokenType.register) ||
                (firstArgType == TokenType.register &&
                    secondArgType == TokenType.label) ||
                (firstArgType == TokenType.register &&
                    numberTokens.contains(secondArgType)))) {
          analysis[currentToken.line] = Result(true, "Válido");
          continue;
        } else {
          analysis[currentToken.line] = Result(false, "Argumentos inválidos");
        }
      }
    }
  }

  void _checkLabels() {
    int dataSegmentIndex =
        tokens.indexWhere((token) => token.type == TokenType.dataSegment);
    int dataEndsIndex = tokens.indexWhere(
        (token) => token.type == TokenType.ends, dataSegmentIndex);
    Set<TokenType> definitionTypes = {
      TokenType.defineByte,
      TokenType.defineWord,
      TokenType.equ
    };
    List<Token> definitions = tokens
        .where((token) =>
            (definitionTypes.contains(token.type)) &&
            analysis[token.line].message == "Válido" &&
            tokens.indexOf(token) > dataSegmentIndex + 1 &&
            tokens.indexOf(token) < dataEndsIndex)
        .toList();

    for (Token token in definitions) {
      int tokenIndex = tokens.indexOf(token);
      Token name = tokens[tokenIndex - 1];
      Token value = tokens[tokenIndex + 1];
      Token? dup = tokens[tokenIndex + 2].type == TokenType.dup
          ? tokens[tokenIndex + 2]
          : null;

      if (symbols.any((symbol) => symbol.name == name.value)) {
        analysis[token.line] =
            Result(false, "Existe una variable con ese nombre");
        continue;
      }

      if (value.type == TokenType.string) {
        int size = _getSize(token.type,
            value.value.substring(1, value.value.length - 1).length);
        symbols.add(Symbol(tokens[tokenIndex - 1].value, _varType(name.type),
            value.value, size, token));
        continue;
      }

      if (dup != null) {
        try {
          int multiplier = 1;
          String dupSize = value.value.endsWith('d')
              ? value.value.substring(0, value.value.length - 1)
              : value.value;
          multiplier = int.parse(dupSize);
          int size = _getSize(token.type, multiplier);
          symbols.add(Symbol(name.value, _varType(token.type),
              dup.value.substring(1, dup.value.length - 1), size, token));
          continue;
        } catch (e) {
          analysis[token.line] = Result(false, "Definicion de dup inválida");
          continue;
        }
      }
      Result wrongSizeRes = Result(false, "Tamaño de valor inválido");

      if (token.type == TokenType.defineByte) {
        switch (value.type) {
          case TokenType.binNumber:
            try {
              int valueInt = int.parse(
                  value.value.substring(0, value.value.length - 1),
                  radix: 2);
              valueInt > 255
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 1, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
          case TokenType.octNumber:
            try {
              int valueInt = int.parse(
                  value.value.substring(0, value.value.length - 1),
                  radix: 8);
              valueInt > 255
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 1, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          case TokenType.decNumber:
            try {
              int valueInt = int.parse(
                  value.value.endsWith('d')
                      ? value.value.substring(0, value.value.length - 1)
                      : value.value,
                  radix: 10);
              valueInt > 255
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 1, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          case TokenType.hexNumber:
            try {
              String number = "";
              if (value.value.startsWith('0x')) {
                number = value.value.substring(2, value.value.length - 1);
              } else {
                number = value.value.substring(1, value.value.length - 1);
              }
              int valueInt = int.parse(number, radix: 16);
              valueInt > 255
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 1, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          default:
            analysis[token.line] == wrongSizeRes;
        }
        continue;
      }

      if (token.type == TokenType.defineWord) {
        switch (value.type) {
          case TokenType.binNumber:
            try {
              int valueInt = int.parse(
                  value.value.substring(0, value.value.length - 1),
                  radix: 2);
              valueInt > 65535
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 2, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
          case TokenType.octNumber:
            try {
              int valueInt = int.parse(
                  value.value.substring(0, value.value.length - 1),
                  radix: 8);
              valueInt > 65535
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 2, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          case TokenType.decNumber:
            try {
              int valueInt = int.parse(
                  value.value.endsWith('d')
                      ? value.value.substring(0, value.value.length - 1)
                      : value.value,
                  radix: 10);
              valueInt > 65535
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 2, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          case TokenType.hexNumber:
            try {
              String number = "";
              if (value.value.startsWith('0x')) {
                number = value.value.substring(2, value.value.length - 1);
              } else {
                number = value.value.substring(1, value.value.length - 1);
              }
              int valueInt = int.parse(number, radix: 16);
              valueInt > 65535
                  ? analysis[token.line] = wrongSizeRes
                  : symbols.add(Symbol(
                      name.value, _varType(token.type), value.value, 2, token));
            } catch (e) {
              analysis[token.line] =
                  Result(false, "Tamaño inválido de variable");
            }
            break;
          default:
            analysis[token.line] == wrongSizeRes;
        }
        continue;
      }
    }

    List<Token> validLabels = tokens
        .where((token) =>
            token.type == TokenType.label &&
            analysis[token.line].message == "Etiqueta")
        .toList();

    for (Token label in validLabels) {
      symbols.add(Symbol(label.value, "Etiqueta", "", 1, label));
    }
  }

  String _varType(TokenType type) {
    switch (type) {
      case TokenType.defineByte:
        return "Byte";
      case TokenType.defineWord:
        return "Palabra";
      case TokenType.equ:
        return "Constante";
      default:
        return "Variable";
    }
  }

  int _getSize(TokenType definition, int multiplier) {
    int size = 0;
    if (definition == TokenType.defineByte) {
      size = 1 * multiplier;
    } else if (definition == TokenType.defineWord) {
      size = 2 * multiplier;
    }
    return size;
  }

  void _setDirection() {
    int codeSegmentLine = tokens[
            tokens.indexWhere((token) => token.type == TokenType.codeSegment)]
        .line;

    List<Symbol> dataSegmentSymbols =
        symbols.where((symbol) => symbol.token.line < codeSegmentLine).toList();

    List<Symbol> codeSegmentSymbols =
        symbols.where((symbol) => symbol.token.line > codeSegmentLine).toList();

    int direction = 0x250;
    for (Symbol symbol in dataSegmentSymbols) {
      symbol.direction = direction;
      direction += symbol.size;
    }

    direction = 0x250;
    for (Symbol symbol in codeSegmentSymbols) {
      symbol.direction = direction;
      direction += symbol.size;
    }

    direction = 0x250;
    for (int i = 0; i < analysis.length; i++) {
      if (i < codeSegmentLine) {
        analysis[i].direction = direction;
        if (symbols.any((symbol) => symbol.token.line == i)) {
          direction =
              symbols.firstWhere((symbol) => symbol.token.line == i).direction;
        }
      } else {
        break;
      }
    }

    direction = 0x250;
    for (int i = 0; i < analysis.length; i++) {
      if (i > codeSegmentLine) {
        analysis[i].direction = direction;
        if (symbols.any((symbol) => symbol.token.line == i)) {
          direction =
              symbols.firstWhere((symbol) => symbol.token.line == i).direction;
        }
      } else {
        continue;
      }
    }
  }

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
