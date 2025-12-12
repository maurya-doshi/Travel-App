class DestinationPin {
  final String id;
  final double latitude;
  final double longitude;
  final String? groupId; 
  final String type; // 'destination', 'hotel', 'quest'
  final String? name; 
  final String? city; // "Paris", "London"
  final int activeVisitorCount;
  final DateTime createdAt;

  const DestinationPin({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.groupId,
    this.type = 'destination',
    this.name,
    this.city,
    this.activeVisitorCount = 0,
    required this.createdAt,
  });

  factory DestinationPin.fromMap(Map<String, dynamic> map, String id) {
    return DestinationPin(
      id: id,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      groupId: map['groupId'] as String?,
      type: map['type'] as String? ?? 'destination',
      name: map['name'] as String?,
      city: map['city'] as String?,
      activeVisitorCount: map['activeVisitorCount'] as int? ?? 0,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now(),
    );
  }

  factory DestinationPin.fromJson(Map<String, dynamic> map) {
    return DestinationPin.fromMap(map, map['id'] as String);
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'groupId': groupId,
      'type': type,
      'name': name,
      'city': city,
      'activeVisitorCount': activeVisitorCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
