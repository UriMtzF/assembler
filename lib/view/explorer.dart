import 'package:assembler/control/control.dart';
import 'package:assembler/model/analizer.dart';
import 'package:assembler/model/directives.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_highlight/themes/atom-one-dark.dart';

List<Token> _tokens = [];
List<Result> _analysis = [];
List<Symbol> _symbols = [];
Map<int, String> _code = {};

class Explorer extends ConsumerStatefulWidget {
  const Explorer({super.key});

  @override
  ConsumerState<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends ConsumerState<Explorer> {
  Analizer analizer = Analizer();

  CodeController codeController = CodeController();

  DataTableSource tokenDataSource = TokenDataSource();
  DataTableSource symbolDataSource = SymbolDataSource();
  DataTableSource analysisDataSource = AnalysisDataSource();

  @override
  Widget build(BuildContext context) {
    List<String> newCode = ref.watch(codeStateProvider);
    codeController.text = newCode.join('\n');
    if (newCode != analizer.code) {
      analizer = Analizer();

      analizer.code = newCode;
      analizer.clearCode();
      analizer.tokenize();
      analizer.identifyTypes();
      analizer.analizeCode();
      _code = analizer.cleanCode;
      _tokens = analizer.tokens;
      _analysis = analizer.analysis;
      _symbols = analizer.symbols;
      tokenDataSource = TokenDataSource();
      symbolDataSource = SymbolDataSource();
      analysisDataSource = AnalysisDataSource();
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                "Código",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20.0),
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
              )
            ],
          ),
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: DefaultTabController(
            length: 3,
            initialIndex: 0,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.table_chart),
                      text: "Tabla de tokens",
                    ),
                    Tab(
                      icon: Icon(Icons.table_rows_rounded),
                      text: "Tabla de símbolos",
                    ),
                    Tab(
                      icon: Icon(Icons.table_rows_outlined),
                      text: "Análisis línea a línea",
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      TokenTable(dataSource: tokenDataSource),
                      SymbolTable(dataSource: symbolDataSource),
                      AnalysisTable(dataSource: analysisDataSource),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SymbolTable extends StatelessWidget {
  const SymbolTable({super.key, required this.dataSource});

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
//Nombre, tipo, valor, tamaño, dirección
    return PaginatedDataTable2(
      columns: const [
        DataColumn(
          label: Text("Nombre"),
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
        DataColumn(
          label: Text("Dirección"),
        ),
      ],
      source: dataSource,
      rowsPerPage: 9,
    );
  }
}

class TokenTable extends StatelessWidget {
  const TokenTable({super.key, required this.dataSource});

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable2(
      columns: const [
        DataColumn(
          label: Text("Tokens"),
        ),
        DataColumn(
          label: Text("Tipo"),
        ),
      ],
      source: dataSource,
      rowsPerPage: 9,
    );
  }
}

class AnalysisTable extends StatelessWidget {
  const AnalysisTable({super.key, required this.dataSource});

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return PaginatedDataTable2(
      columns: const [
        DataColumn(label: Text("Contador")),
        DataColumn(label: Text("Código")),
        DataColumn(label: Text("Resultado")),
      ],
      source: dataSource,
      rowsPerPage: 9,
    );
  }
}

class TokenDataSource extends DataTableSource {
  @override
  int get rowCount => _tokens.length;

  @override
  DataRow? getRow(int index) {
    return DataRow(cells: [
      DataCell(
        Text(_tokens[index].value),
      ),
      DataCell(
        Text(_tokens[index].type.description),
      ),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class SymbolDataSource extends DataTableSource {
  @override
  int get rowCount => _symbols.length;

  @override
  DataRow? getRow(int index) {
    String value =
        _symbols[index].type == "Etiqueta" ? "" : _symbols[index].value;
    String size = _symbols[index].type == "Etiqueta"
        ? ""
        : _symbols[index].size.toString();

    return DataRow(cells: [
      DataCell(Text(_symbols[index].name)),
      DataCell(Text(_symbols[index].type)),
      DataCell(Text(value)),
      DataCell(Text(size)),
      DataCell(Text("${_symbols[index].direction.toRadixString(16)}h")),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}

class AnalysisDataSource extends DataTableSource {
  @override
  int get rowCount => _analysis.length;

  @override
  DataRow? getRow(int index) {
    String analysis = "";
    if (_analysis[index].isValid) {
      analysis = _analysis[index].message.toUpperCase();
    } else if (_analysis[index].message.contains("No analizado")) {
      analysis = "";
    } else {
      analysis = "ERROR: ${_analysis[index].message}";
    }

    return DataRow(cells: [
      DataCell(
        Text("${_analysis[index].direction.toRadixString(16)}h".toUpperCase()),
      ),
      DataCell(Text(_code[index] ?? "")),
      DataCell(Text(analysis)),
    ]);
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;
}
