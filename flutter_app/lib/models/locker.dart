class Locker {
  const Locker({
    required this.id,
    required this.code,
    this.description,
  });

  final int id;
  final String code;
  final String? description;

  factory Locker.fromJson(Map<String, dynamic> json) {
    return Locker(
      id: json['id'] as int,
      code: json['code'] as String,
      description: json['description'] as String?,
    );
  }
}
