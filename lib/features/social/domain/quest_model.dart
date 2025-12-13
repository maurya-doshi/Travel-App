class Quest {
  final String id;
  final String city;
  final String title;
  final String description;
  final String reward;
  final List<QuestStep> steps;

  Quest({
    required this.id,
    required this.city,
    required this.title,
    required this.description,
    required this.reward,
    this.steps = const [],
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'] ?? '',
      city: json['city'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      reward: json['reward'] ?? '',
      steps: (json['steps'] as List?)?.map((s) => QuestStep.fromJson(s)).toList() ?? [],
    );
  }
}

class QuestStep {
  final String id;
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final String type; // culture, food, history, nature
  final String clue;
  final String mustTry;
  final int points;
  final bool isCompleted; // Client-side state

  QuestStep({
    required this.id,
    required this.title,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.clue,
    required this.mustTry,
    this.points = 50,
    this.isCompleted = false,
  });

  factory QuestStep.fromJson(Map<String, dynamic> json) {
    return QuestStep(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      type: json['type'] ?? '',
      clue: json['clue'] ?? '',
      mustTry: json['mustTry'] ?? '',
      points: json['points'] ?? 50,
      isCompleted: json['isCompleted'] ?? false,
    );
  }
  
  QuestStep copyWith({bool? isCompleted}) {
    return QuestStep(
      id: id,
      title: title,
      description: description,
      latitude: latitude,
      longitude: longitude,
      type: type,
      clue: clue,
      mustTry: mustTry,
      points: points,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
