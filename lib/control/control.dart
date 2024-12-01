import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'control.g.dart';

@riverpod
class FileState extends _$FileState {
  @override
  File? build() {
    return null;
  }

  void setFile(File? file) {
    state = file;
  }
}
