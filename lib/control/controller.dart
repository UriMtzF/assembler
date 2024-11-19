import 'dart:io';

import 'package:assembler/view/view_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Saves state of the file and its properties
class FileState extends StateNotifier<File?> {
  FileState() : super(null);

  void setFile(File? file) {
    state = file;
  }
}

class ViewTypeState extends StateNotifier<ViewType?> {
  ViewTypeState() : super(ViewType.tokenTable);

  void setView(ViewType newView) {
    state = newView;
  }
}

final fileProvider =
    StateNotifierProvider<FileState, File?>((ref) => FileState());

final viewProvider =
    StateNotifierProvider<ViewTypeState, ViewType?>((ref) => ViewTypeState());
