import 'dart:io';

import 'package:assembler/control/controller.dart';
import 'package:assembler/model/analizer.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:highlight/languages/x86asm.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

List<String> _tokens = [];
List<String> _types = [];

class Explorer extends ConsumerStatefulWidget {
  const Explorer({super.key});

  @override
  ConsumerState<Explorer> createState() => _ExplorerState();
}

class _ExplorerState extends ConsumerState<Explorer> {
  Analizer analizer = Analizer();
  List<String> codeLines = [];

  CodeController codeController = CodeController(language: x86Asm);

  DataTableSource dataSource = DataSource();

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
    if (file != null) {
      final newLines = _loadFileContent(file);
      if (newLines != codeLines) {
        codeLines = newLines;
        codeController.text = codeLines.join('\n');
        analizer.setCode = newLines;
        _tokens = analizer.tokens;
        _types = analizer.types;
        dataSource = DataSource();
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
                  data: const CodeThemeData(styles: atomOneLightTheme),
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
        Expanded(
          child: Column(
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
          ),
        ),
      ],
    );
  }
}

class DataSource extends DataTableSource {
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
