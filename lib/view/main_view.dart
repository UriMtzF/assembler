import 'dart:io';

import 'package:assembler/control/controller.dart';
import 'package:assembler/view/table.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MainBar(),
      body: TokenTable(),
    );
  }
}

class MainBar extends ConsumerWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  const MainBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      title: const Text("Ensamblador"),
      actions: [
        IconButton(
          onPressed: () async {
            FilePickerResult? result = await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions: ['ens'],
              dialogTitle: "Selecciona un archivo ensamblador",
            );

            if (result != null) {
              ref
                  .read(fileProvider.notifier)
                  .setFile(File(result.files.single.path!));
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("No seleccionaste un archivo válido"),
                    duration: Duration(seconds: 5),
                  ),
                );
              }
            }
          },
          icon: const Icon(Icons.file_open),
        ),
      ],
    );
  }
}
