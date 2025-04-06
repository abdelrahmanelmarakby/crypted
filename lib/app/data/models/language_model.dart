class LanguageModel {
  final String imagePath;
  final String name;
  final String code;

  const LanguageModel({
    required this.imagePath,
    required this.name,
    required this.code,
  });

  @override
  String toString() {
    return 'LanguageModel{imagePath: $imagePath}';
  }

  Map<String, dynamic> toMap() {
    return {
      'imagePath': imagePath,
      'name': name,
      'code': code,
    };
  }

  factory LanguageModel.fromMap(Map<String, dynamic> map) {
    return LanguageModel(
      imagePath: map['imagePath'] as String,
      name: map['name'] as String,
      code: map['code'] as String,
    );
  }
}
