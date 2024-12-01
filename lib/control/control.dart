import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'control.g.dart';

@riverpod
class FileState extends _$FileState {
  @override
  List<String> build() {
    return [];
  }

  void setContent(List<String> content) {
    state = content;
  }
}
