import 'package:assembler/model/directives.dart';

class Result {
  final bool isValid;
  final String message;

  Result(
    this.isValid,
    this.message,
  );
}

class Symbol {
  final String name;
  final TokenType type;
  final String value;
  final String size;
  Symbol(
    this.name,
    this.type,
    this.value,
    this.size,
  );
}

class Analizer {
  List<String> code;
  List<String> tokens;
  List<String> typesString;
  List<TokenType> types;
  List<int> codeLineIndex;
  List<int> tokenLineIndex;
  List<Result> analysis;
  List<Symbol> symbolsDetail = [];

  Analizer({
    this.code = const [""],
    this.tokens = const [""],
    this.typesString = const [""],
    this.types = const [],
    this.codeLineIndex = const [],
    this.tokenLineIndex = const [],
    this.analysis = const [],
  });

  // Setter for code
  set setCode(List<String> code) {
    List<String> tokenizedCode = [];
    List<int> tempLineIndex = [];
    List<Result> tempAnalysis = [];
    // Iterates all lines of code
    for (int i = 0; i < code.length; i++) {
      String line = code[i];

      String modifiedLine = _lowerCase(line);
      // Delete all comments, delete all blank spaces, make it lower case

      tempAnalysis.add(Result(true, "✅"));

      if (modifiedLine.isNotEmpty) {
        // If line is not empty save it
        tokenizedCode.add(modifiedLine);
        tempLineIndex.add(i);
      }
    }
    this.code = tokenizedCode;
    codeLineIndex = tempLineIndex;
    analysis = tempAnalysis;
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
      parts.add(match.group(0)!.trim());
      lastIndex = match.end;
    }

    if (lastIndex < line.length) {
      parts.add(line.substring(lastIndex).toLowerCase().trim());
    }
    return parts.join();
  }

  // Make tokens of code
  void tokenize() {
    List<String> tokenizedCode = [];
    List<int> tokenLineIndex = [];
    // Iterates all lines of code
    for (int i = 0; i < code.length; i++) {
      String line = code[i];
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

      for (int j = 0; j < tokens.length; j++) {
        if (compundTokens.containsKey(tokens[j])) {
          tokens[j] = compundTokens[tokens[j]]!;
        }
      }

      tokenizedCode.addAll(tokens);

      if (codeLineIndex.isNotEmpty && i < codeLineIndex.length) {
        tokenLineIndex.addAll(List.filled(tokens.length, codeLineIndex[i]));
      } else {
        tokenLineIndex.addAll(List.filled(tokens.length, i));
      }
    }
    if (tokenizedCode.isNotEmpty) {
      tokens = tokenizedCode;
      this.tokenLineIndex = tokenLineIndex;
    }
  }

  void identifyTypes() {
    List<String> typesString = [];
    List<TokenType> types = [];

    for (String token in tokens) {
      TokenType type;

      type = directiveRegExp.entries
          .firstWhere(
            (entry) => entry.value.hasMatch(token),
            orElse: () => MapEntry(TokenType.unknown, RegExp(r'')),
          )
          .key;

      if (type == TokenType.unknown) {
        if (instructions.contains(token)) {
          type = TokenType.instruction;
        } else if (symbols.contains(token)) {
          type = TokenType.symbol;
        } else if (registers.contains(token)) {
          type = TokenType.register;
        } else if (hexNumberRegExp.hasMatch(token)) {
          type = TokenType.hexNumber;
        } else if (binNumberRegExp.hasMatch(token)) {
          type = TokenType.binNumber;
        } else if (decNumberRegExp.hasMatch(token)) {
          type = TokenType.decNumber;
        } else if (labelRegExp.hasMatch(token)) {
          type = TokenType.label;
        }
      }

      typesString.add(type.description);
      types.add(type);
    }

    if (typesString.isNotEmpty) {
      this.typesString = typesString;
      this.types = types;
    }
  }

  void checkLines() {
    if (checkOrder()) {
      checkStackSegment();
      checkDataSegment();
      checkCodeSegment();
      checkUnknown();
      checkLabels();
    }
  }

  void checkLabels() {
    for (int i = types.indexOf(TokenType.dataSegment);
        i < types.indexOf(TokenType.codeSegment) - 1;
        i++) {
      if (analysis[i].isValid && types[i] == TokenType.label) {
        String name = tokens[i];
        TokenType type = types[i];
        String value = tokens[i + 2];
        String size = types[i + 1] == TokenType.defineByte ? "Byte" : "Palabra";
        symbolsDetail.add(Symbol(name, type, value, size));
      }
    }
  }

  bool checkOrder() {
    int stackSegmentPos = types.indexOf(TokenType.stackSegment);
    int dataSegmentPos = types.indexOf(TokenType.dataSegment);
    int codeSegmentPos = types.indexOf(TokenType.codeSegment);
    if (!(stackSegmentPos < dataSegmentPos) &&
        !(dataSegmentPos < codeSegmentPos)) {
      analysis.replaceRange(
        0,
        analysis.length,
        List.generate(
          analysis.length,
          (int index) => Result(
              false, "Los segmentos de pila, datos y código no están orden"),
        ),
      );
      return false;
    }
    return true;
  }

  void checkUnknown() {
    if (types.contains(TokenType.unknown)) {
      List<int> unknowns = [];
      for (int i = 0; i < types.length; i++) {
        if (types[i] == TokenType.unknown) {
          unknowns.add(tokenLineIndex[i]);
        }
      }
      for (int i = 0; i < unknowns.length; i++) {
        analysis[unknowns[i]] = Result(false, "Instrucción no reconocida");
      }
    }
  }

  void checkStackSegment() {
    int stackSegmentPos = types.indexOf(TokenType.stackSegment);
    int dataSegmentPos = types.indexOf(TokenType.dataSegment);
    int endsPos = dataSegmentPos - 1;

    if (types[endsPos] != TokenType.end) {
      analysis[tokenLineIndex[stackSegmentPos]] =
          Result(false, "El segmento de datos no tiene un ends");
    }

    int dwPos = stackSegmentPos + 1;
    int numConsPos = dwPos + 1;
    int dupPos = numConsPos + 1;

    if (types[dwPos] != TokenType.defineWord) {
      analysis[tokenLineIndex[dwPos]] =
          Result(false, "El segmento de pila debe iniciar con dw");
    }

    if (types[numConsPos] != TokenType.decNumber &&
        types[numConsPos] != TokenType.binNumber &&
        types[numConsPos] != TokenType.hexNumber) {
      analysis[tokenLineIndex[numConsPos]] = Result(
          false, "Después de dw debe haber una constante numérica positiva");
    }

    if (tokens[numConsPos].startsWith('-')) {
      analysis[tokenLineIndex[numConsPos]] = Result(
          false, "Después de dw debe haber una constante numérica positiva");
    }

    if (types[dupPos] != TokenType.dup) {
      analysis[tokenLineIndex[dupPos]] =
          Result(false, "Después de la constante numérica debe ir un dup");
    }

    String dupContent = tokens[dupPos].substring(4).replaceFirst(r')', "");
    if (!decNumberRegExp.hasMatch(dupContent) &&
        !binNumberRegExp.hasMatch(dupContent) &&
        !hexNumberRegExp.hasMatch(dupContent)) {
      analysis[tokenLineIndex[dupPos]] = Result(
          false, "El contenido del dup debe ser una constante numérica válida");
    }

    if (endsPos != dupPos + 1) {
      analysis.replaceRange(
        dupPos,
        endsPos,
        List.generate(
          endsPos - dupPos,
          (int i) => Result(false,
              "Existe más elementos de los necesarios en el segmento de pila"),
        ),
      );
    }
  }

  void checkDataSegment() {
    int dataSegmentPos = types.indexOf(TokenType.dataSegment);
    int codeSegmentPos = types.indexOf(TokenType.codeSegment);
    int endsPos = codeSegmentPos - 1;

    if (types[codeSegmentPos - 1] != TokenType.end) {
      analysis[tokenLineIndex[dataSegmentPos]] =
          Result(false, "El segmento de datos no tiene un ends de cierre");
    }

    final Set<TokenType> definitionTypes = {
      TokenType.defineByte,
      TokenType.defineWord,
      TokenType.equ,
    };

    final Set<TokenType> constantTypes = {
      TokenType.decNumber,
      TokenType.binNumber,
      TokenType.hexNumber,
      TokenType.singleQuotes,
      TokenType.doubleQuotes,
    };

    final Set<TokenType> numberType = {
      TokenType.decNumber,
      TokenType.binNumber,
      TokenType.hexNumber,
    };

    for (int i = dataSegmentPos + 1; i < endsPos; i++) {
      final tokenType = types[i];
      if (tokenType == TokenType.label &&
          !definitionTypes.contains(types[i + 1])) {
        analysis[tokenLineIndex[i]] = Result(
            false, "Una etiqueta debe estar sucedida por un db, dw o equ");
      }
      if (definitionTypes.contains(tokenType)) {
        if (types[i - 1] != TokenType.label) {
          analysis[tokenLineIndex[i]] = Result(
              false, "Una etiqueta debe existir antes de un db, dw o equ");
        }
        if (!constantTypes.contains(types[i + 1])) {
          analysis[tokenLineIndex[i]] = Result(false,
              "Un número o cadena debe existir después de la definición");
        }
      }
      if (constantTypes.contains(tokenType)) {
        if (!definitionTypes.contains(types[i - 1])) {
          analysis[tokenLineIndex[i]] = Result(
              false, "Una constante debe estar precedida por una definición");
        }
        if (types[i + 2] != TokenType.dup) {
          if (types[i - 1] == TokenType.defineByte) {
            if (tokenType == TokenType.binNumber && tokens[i].length != 9) {
              analysis[tokenLineIndex[i]] =
                  Result(false, "Tamaño incorrecto de constante numérica");
            }
            if (tokenType == TokenType.hexNumber && tokens[i].length != 4) {
              analysis[tokenLineIndex[i]] =
                  Result(false, "Tamaño incorrecto de constante numérica");
            }
          }
          if (types[i - 1] == TokenType.defineWord) {
            if (tokenType == TokenType.binNumber && tokens[i].length != 17) {
              analysis[tokenLineIndex[i]] =
                  Result(false, "Tamaño incorrecto de constante numérica");
            }
            if (tokenType == TokenType.hexNumber && tokens[i].length != 6) {
              analysis[tokenLineIndex[i]] =
                  Result(false, "Tamaño incorrecto de constante numérica");
            }
          }
        }
      }
      if (tokenType == TokenType.dup) {
        if (!numberType.contains(types[i - 1])) {
          analysis[tokenLineIndex[i]] = Result(
              false, "Un dup debe estar precedido por una constante numérica");
        }
        if (numberType.contains(types[i - 1]) &&
            tokens[i - 1].substring(0, 1) == "-") {
          analysis[tokenLineIndex[i]] = Result(false,
              "Un dup debe estar precedido por una constante numérica positiva");
        }
        String dupContent = tokens[i].substring(4).replaceFirst(r')', '');
        if (!(decNumberRegExp.hasMatch(dupContent) ||
            binNumberRegExp.hasMatch(dupContent) ||
            hexNumberRegExp.hasMatch(dupContent))) {
          analysis[tokenLineIndex[i]] = Result(
              false, "El contenido del dup debe ser una constante numérica");
        }
      }
    }
  }

  void checkCodeSegment() {
    int codeSegmentPos = types.indexOf(TokenType.codeSegment);
    int endsPos = types.length - 1;
    if (types[endsPos] == TokenType.end) {
      for (int i = codeSegmentPos + 1; i < endsPos; i++) {
        Result result =
            Result(false, "La instrucción tiene argumentos inválidos");
        List<String> labels = [];
        if (types[i] == TokenType.label) {
          labels.add(tokens[i]);
        }

        if (types[i] == TokenType.instruction) {
          Set<String> noArgsIns = {
            "cld",
            "cli",
            "movsb",
            "movsw",
            "xlatb",
            "aaa"
          };
          Set<String> regArgIns = {"pop", "push", "idiv", "dec"};
          Set<String> regNumArgsIns = {"ror", "sub", "xor", "and"};
          Set<String> jumpIns = {"jae", "jcxz", "jl", "jnge", "jnp", "jp"};
          Set<TokenType> numberTypes = {
            TokenType.decNumber,
            TokenType.binNumber,
            TokenType.hexNumber
          };

          if (noArgsIns.contains(tokens[i])) {
            analysis[i] = result;
          }
          if (regArgIns.contains(tokens[i]) &&
              types[i + 1] != TokenType.register) {
            analysis[i] = result;
          }
          if (regNumArgsIns.contains(tokens[i]) &&
              (types[i + 1] != TokenType.register ||
                  !numberTypes.contains(types[i + 2]))) {
            analysis[i] = result;
          }
          if (jumpIns.contains(tokens[i])) {
            if (types[i + 1] != TokenType.label) {
              analysis[i] = result;
            } else {
              if (!labels.contains(tokens[i + 1])) {
                analysis[i] = Result(false, "La etiqueta no está definida");
              }
            }
          }
        }
      }
    } else {
      analysis[codeSegmentPos] =
          Result(false, "El segmento de código no tiene un ends");
    }
  }
}
