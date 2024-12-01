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
        const Expanded(
          child: DefaultTabController(
            length: 4,
            initialIndex: 0,
            child: Column(
              children: [
                TabBar(
                  tabs: [
                    Tab(
                      icon: Icon(Icons.table_rows_rounded),
                    ),
                    Tab(
                      icon: Icon(Icons.table_chart),
                    ),
                    Tab(
                      icon: Icon(Icons.table_rows_outlined),
                    ),
                    Tab(
                      icon: Icon(Icons.file_open),
                    ),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      Center(
                        child: Text("It's cloudy here"),
                      ),
                      Center(
                        child: Text("It's rainy here"),
                      ),
                      Center(
                        child: Text("It's sunny here"),
                      ),
                      Center(
                        child: Text("It's stormy here"),
                      ),
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
