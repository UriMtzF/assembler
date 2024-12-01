import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ignore: depend_on_referenced_packages
import 'package:flutter_highlight/themes/atom-one-dark.dart';

class Explorer extends ConsumerStatefulWidget {
  const Explorer({super.key});

  @override
  ConsumerState<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends ConsumerState<Explorer> {
  CodeController codeController = CodeController();

  DataTableSource tokenDataSource = TokenDataSource();
  DataTableSource symbolDataSource = SymbolDataSource();
  DataTableSource analysisDataSource = AnalysisDataSource();

  @override
  Widget build(BuildContext context) {
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
                      icon: Icon(Icons.table_rows_rounded),
                      text: "Tabla de símbolos",
                    ),
                    Tab(
                      icon: Icon(Icons.table_chart),
                      text: "Tabla de tokens",
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
                      SymbolTable(dataSource: symbolDataSource),
                      TokenTable(dataSource: tokenDataSource),
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
    return const Placeholder();
  }
}

class TokenTable extends StatelessWidget {
  const TokenTable({super.key, required this.dataSource});

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class AnalysisTable extends StatelessWidget {
  const AnalysisTable({super.key, required this.dataSource});

  final DataTableSource dataSource;

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

class TokenDataSource extends DataTableSource {
  @override
  // TODO implement get rowCount
  int get rowCount => throw UnimplementedError();

  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => throw UnimplementedError();

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => throw UnimplementedError();
}

class SymbolDataSource extends DataTableSource {
  @override
  // TODO implement get rowCount
  int get rowCount => throw UnimplementedError();

  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => throw UnimplementedError();

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => throw UnimplementedError();
}

class AnalysisDataSource extends DataTableSource {
  @override
  // TODO implement get rowCount
  int get rowCount => throw UnimplementedError();

  @override
  DataRow? getRow(int index) {
    // TODO: implement getRow
    throw UnimplementedError();
  }

  @override
  // TODO: implement isRowCountApproximate
  bool get isRowCountApproximate => throw UnimplementedError();

  @override
  // TODO: implement selectedRowCount
  int get selectedRowCount => throw UnimplementedError();
}
