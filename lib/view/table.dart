import 'dart:io';

import 'package:assembler/control/controller.dart';
import 'package:assembler/model/analizer.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:highlight/languages/x86asm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TokenTable extends ConsumerStatefulWidget {
  const TokenTable({super.key});

  @override
  ConsumerState<TokenTable> createState() => _TokenTableState();
}

class _TokenTableState extends ConsumerState<TokenTable> {
  Analizer analizer = Analizer();
  List<String> codeLines = [""];
  List<String> tokenLines = [""];
  List<String> typeLines = [""];

  List<List<String>> paginatedCode = [];
  List<List<String>> paginatedToken = [];
  List<List<String>> paginatedType = [];

  int currentCodePage = 0;
  int currentTokenPage = 0;
  int currentTypePage = 0;

  CodeController? codeController;
  CodeController? tokenController;
  CodeController? typeController;

  @override
  void initState() {
    super.initState();
    paginateText();
  }

  List<String> _loadFileContent(File file) {
    return file.readAsLinesSync();
  }

  void paginateText() {
    paginatedCode.clear();
    paginatedToken.clear();
    paginatedType.clear();
    for (int i = 0; i < codeLines.length; i += 15) {
      paginatedCode.add(codeLines.sublist(
          i, (i + 15 > codeLines.length) ? codeLines.length : i + 15));
    }
    for (int i = 0; i < tokenLines.length; i += 15) {
      paginatedToken.add(tokenLines.sublist(
          i, (i + 15 > tokenLines.length) ? tokenLines.length : i + 15));
    }
    for (int i = 0; i < typeLines.length; i += 15) {
      paginatedType.add(typeLines.sublist(
          i, (i + 15 > typeLines.length) ? typeLines.length : i + 15));
    }
  }

  void nextPageCode() {
    setState(() {
      if (currentCodePage < paginatedCode.length - 1) {
        currentCodePage++;
      }
    });
  }

  void previousPageCode() {
    setState(() {
      if (currentCodePage > 0) {
        currentCodePage--;
      }
    });
  }

  void nextPageToken() {
    setState(() {
      if (currentTokenPage < paginatedToken.length - 1) {
        currentTokenPage++;
      }
    });
  }

  void previousPageToken() {
    setState(() {
      if (currentTokenPage > 0) {
        currentTokenPage--;
      }
    });
  }

  void nextPageType() {
    setState(() {
      if (currentTypePage < paginatedType.length - 1) {
        currentTypePage++;
      }
    });
  }

  void previousPageType() {
    setState(() {
      if (currentTypePage > 0) {
        currentTypePage--;
      }
    });
  }

  void updateLines(List<String> codeNewLines, List<String> tokenNewLines,
      List<String> typeNewLines) {
    setState(() {
      codeLines = codeNewLines;
      tokenLines = tokenNewLines;
      typeLines = typeNewLines;
      paginateText();
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.watch(fileProvider);
    if (file != null) {
      final newLines = _loadFileContent(file);
      if (newLines != codeLines) {
        analizer.setCode = newLines;
        updateLines(analizer.code, analizer.tokens, analizer.types);
      }
    }
    codeController = CodeController(
      text: paginatedCode[currentCodePage].join('\n'),
      language: x86Asm,
    );
    tokenController = CodeController(
      text: paginatedToken[currentTokenPage].join('\n'),
    );
    typeController = CodeController(
      text: paginatedType[currentTypePage].join('\n'),
    );

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CodeField(
                    controller: codeController!,
                    maxLines: 15,
                    readOnly: true,
                    lineNumbers: false,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: previousPageCode,
                      label: const Icon(Icons.arrow_left),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text('Página ${currentCodePage + 1}'),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: nextPageCode,
                      label: const Icon(Icons.arrow_right),
                    ),
                  ],
                )
              ],
            ),
          ),
          const VerticalDivider(width: 20.0),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CodeField(
                    controller: tokenController!,
                    maxLines: 15,
                    readOnly: true,
                    lineNumbers: false,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: previousPageToken,
                      label: const Icon(Icons.arrow_left),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text('Página ${currentTokenPage + 1}'),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: nextPageToken,
                      label: const Icon(Icons.arrow_right),
                    ),
                  ],
                )
              ],
            ),
          ),
          const VerticalDivider(width: 20.0),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: CodeField(
                    controller: typeController!,
                    maxLines: 15,
                    readOnly: true,
                    lineNumbers: false,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: previousPageType,
                      label: const Icon(Icons.arrow_left),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Text('Página ${currentTokenPage + 1}'),
                    const SizedBox(
                      width: 20,
                    ),
                    ElevatedButton.icon(
                      onPressed: nextPageType,
                      label: const Icon(Icons.arrow_right),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
