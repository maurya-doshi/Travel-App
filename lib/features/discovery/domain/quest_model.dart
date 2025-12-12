class QuestModel {
  final String id;
  final String city;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final int points;
  final bool isCompleted;

  QuestModel({
    required this.id,
    required this.city,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.points,
    this.isCompleted = false,
  });

  factory QuestModel.fromJson(Map<String, dynamic> json) {
    return QuestModel(
      id: json['id'],
      city: json['city'],
      name: json['name'],
      description: json['description'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      points: json['points'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
