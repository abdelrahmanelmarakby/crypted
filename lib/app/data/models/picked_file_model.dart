import 'package:flutter/foundation.dart';

class PickedFile {
  final Uint8List uint8list;
  String? type;
  String? name;
  String? path;
  PickedFile({
    required this.uint8list,
    this.type,
    this.name,
    this.path,
  });

  PickedFile copyWith({
    Uint8List? uint8list,
    String? type,
    String? name,
    String? path,
  }) {
    return PickedFile(
      uint8list: uint8list ?? this.uint8list,
      type: type ?? this.type,
      name: name ?? this.name,
      path: path ?? this.path,
    );
  }

  @override
  String toString() {
    return 'PickedFile(uint8list: $uint8list, type: $type, name: $name, path: $path)';
  }

  @override
  bool operator ==(covariant PickedFile other) {
    if (identical(this, other)) return true;

    return other.uint8list == uint8list &&
        other.type == type &&
        other.name == name &&
        other.path == path;
  }

  @override
  int get hashCode {
    return uint8list.hashCode ^ type.hashCode ^ name.hashCode ^ path.hashCode;
  }
}