import 'dart:io';

import 'package:assembler/control/controller.dart';
import 'package:assembler/model/analizer.dart';
import 'package:assembler/view/view_type.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: depend_on_referenced_packages
import 'package:highlight/languages/x86asm.dart';
// ignore: depend_on_referenced_packages, unused_import
import 'package:flutter_highlight/themes/atom-one-light.dart';
// ignore: depend_on_referenced_packages, unused_import
import 'package:flutter_highlight/themes/atom-one-dark.dart';

List<String> _tokens = [];
List<String> _types = [];
List<Symbol> _symbols = [];

class Explorer extends ConsumerStatefulWidget {
  const Explorer({super.key});

  @override
  ConsumerState<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends ConsumerState<Explorer> {
  Analizer analizer = Analizer();
  List<String> codeLines = [];

  CodeController codeController = CodeController(language: x86Asm);

  DataTableSource tokenDataSource = TokenDataSource();
  DataTableSource symbolDataSource = SymbolDataSource();

  @override
  void initState() {
    super.initState();
  }

  List<String> _loadFileContent(File file) {
    return file.readAsLinesSync();
  }

  @override
  Widget build(BuildContext context) {
    final file = ref.watch(fileProvider);
    final viewType = ref.watch(viewProvider);
    if (file != null) {
      final newLines = _loadFileContent(file);
      if (newLines != codeLines) {
        codeLines = newLines;
        codeController.text = codeLines.join('\n');
        analizer.setCode = newLines;
        _tokens = analizer.tokens;
        _types = analizer.typesString;
        analizer.checkLines();
        _symbols = analizer.symbolsDetail;
        tokenDataSource = TokenDataSource();
      }
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                "Código",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Expanded(
                child: CodeTheme(
                  data: const CodeThemeData(styles: atomOneDarkTheme),
                  child: CodeField(
                    controller: codeController,
                    expands: true,
                    readOnly: true,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: viewType == ViewType.lineAnalysis
              ? LineAnalysis(
                  analysisResult: analizer.analysis,
                )
              : viewType == ViewType.symbolTable
                  ? SymbolTable(dataSource: symbolDataSource)
                  : TokenTable(dataSource: tokenDataSource),
        ),
        // Expanded(
        //   child: TokenTable(dataSource: dataSource),
        // ),
      ],
    );
  }
}

class LineAnalysis extends StatelessWidget {
  final List<Result> analysisResult;
  const LineAnalysis({super.key, required this.analysisResult});

  @override
  Widget build(BuildContext context) {
    String analysis = analysisResult
        .map((Result element) =>
            element.isValid ? element.message : 'Error: ${element.message}')
        .toList()
        .join('\n');
    CodeController controller = CodeController(text: analysis);

    return Column(
      children: [
        const Text(
          "Análisis línea por línea",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Expanded(
          child: CodeTheme(
            data: const CodeThemeData(styles: atomOneLightTheme),
            child: CodeField(
              controller: controller,
              expands: true,
              horizontalScroll: true,
              readOnly: true,
            ),
          ),
        )
      ],
    );
  }
}

class SymbolTable extends StatelessWidget {
  const SymbolTable({
    super.key,
    required this.dataSource,
  });

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Tabla de símbolos",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Flexible(
          child: PaginatedDataTable2(
            columns: const [
              DataColumn(
                label: Text("Símbolo"),
              ),
              DataColumn(
                label: Text("Tipo"),
              ),
              DataColumn(
                label: Text("Valor"),
              ),
              DataColumn(
                label: Text("Tamaño"),
              ),
            ],
            source: dataSource,
          ),
        ),
      ],
    );
  }
}

class TokenTable extends StatelessWidget {
  const TokenTable({
    super.key,
    required this.dataSource,
  });

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Tokens y tipos",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Flexible(
          child: PaginatedDataTable2(
            columns: const [
              DataColumn(
                label: Text("Tokens"),
              ),
              DataColumn(
                label: Text("Tipo"),
              )
            ],
            source: dataSource,
          ),
        ),
      ],
    );
  }
}

class TokenDataSource extends DataTableSource {
  @override
  int get rowCount => _tokens.length;

  @override
  DataRow? getRow(int index) {
    if (_tokens.isEmpty || _types.isEmpty) {
      return null;
    }
    return DataRow(
      cells: [
        DataCell(
          Text(_tokens[index]),
        ),
        DataCell(
          Text(_types[index]),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class SymbolDataSource extends DataTableSource {
  @override
  int get rowCount => (_symbols.length / 2).ceil();

  @override
  DataRow? getRow(int index) {
    if (_symbols.isEmpty) {
      return null;
    }
    return DataRow(
      cells: [
        DataCell(
          Text(_symbols[index].name),
        ),
        DataCell(
          Text(_symbols[index].type.name),
        ),
        DataCell(
          Text(_symbols[index].value),
        ),
        DataCell(
          Text(_symbols[index].size),
        ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
