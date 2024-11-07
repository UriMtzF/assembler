import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Saves state of the file and its properties
class FileState extends StateNotifier<File?> {
  FileState() : super(null);

  void setFile(File? file) {
    state = file;
  }
}

final fileProvider =
    StateNotifierProvider<FileState, File?>((ref) => FileState());
