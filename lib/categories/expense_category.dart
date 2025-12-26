class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.emoji,
  });

  final String id;
  final String name;
  final String emoji;

  String get label => emoji.isNotEmpty ? '$emoji $name' : name;

  Map<String, dynamic> toMap() => {
    'name': name,
    'emoji': emoji,
  };

  factory ExpenseCategory.fromMap(String id, Map<String, dynamic> map) {
    return ExpenseCategory(
      id: id,
      name: (map['name'] ?? '').toString(),
      emoji: (map['emoji'] ?? '').toString(),
    );
  }
}
