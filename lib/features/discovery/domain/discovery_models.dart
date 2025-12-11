class Quest {
  final String id;
  final String title;
  final String description;
  final int pointsReward;
  final String type; // 'check-in', 'qr-code'
  final double? targetLat;
  final double? targetLng;
  final String? secretCode; 
  bool isCompleted;

  Quest({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsReward,
    required this.type,
    this.targetLat,
    this.targetLng,
    this.secretCode,
    this.isCompleted = false,
  });

  factory Quest.fromJson(Map<String, dynamic> json) {
    return Quest(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      pointsReward: json['pointsReward'],
      type: json['type'],
      targetLat: json['targetLat'],
      targetLng: json['targetLng'],
      secretCode: json['secretCode'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Hotel {
  final String id;
  final String name;
  final String address;
  final double pricePerNight;
  final double rating;
  final String imageUrl;
  final double lat;
  final double lng;

  const Hotel({
    required this.id,
    required this.name,
    required this.address,
    required this.pricePerNight,
    required this.rating,
    required this.imageUrl,
    required this.lat,
    required this.lng,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      pricePerNight: (json['pricePerNight'] as num).toDouble(),
      rating: (json['rating'] as num).toDouble(),
      imageUrl: json['imageUrl'] ?? 'https://placehold.co/600x400',
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
