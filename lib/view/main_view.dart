import 'dart:io';

import 'package:assembler/control/control.dart';
import 'package:assembler/view/explorer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MainView extends StatelessWidget {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: MainBar(),
      body: Explorer(),
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
          onPressed: () => _pickFile(context, ref),
          icon: const Icon(Icons.file_open),
          tooltip: "Abrir archivo",
        ),
      ],
    );
  }
}

void _showError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text("No seleccionaste un archivo válido"),
      duration: Duration(seconds: 5),
    ),
  );
}

void _pickFile(BuildContext context, WidgetRef ref) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: ['ens'],
    dialogTitle: "Selecciona un archivo ensamblador",
  );

  if (result == null) {
    return;
  }

  File file = File(result.files.single.path!);

  if (file.path.endsWith('.ens')) {
    ref
        .read(fileStateProvider.notifier)
        .setContent(File(result.files.single.path!).readAsLinesSync());
  } else {
    if (context.mounted) {
      _showError(context);
    }
  }
}
