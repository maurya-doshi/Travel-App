class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int explorerPoints;
  final String? phoneNumber;
  final String? emergencyContact;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.explorerPoints = 0,
    this.phoneNumber,
    this.emergencyContact,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      explorerPoints: map['explorerPoints'] as int? ?? 0,
      phoneNumber: map['phoneNumber'] as String?,
      emergencyContact: map['emergencyContact'] as String?,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> map) => UserModel.fromMap(map);

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'explorerPoints': explorerPoints,
      'phoneNumber': phoneNumber,
      'emergencyContact': emergencyContact,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    int? explorerPoints,
    String? phoneNumber,
    String? emergencyContact,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      explorerPoints: explorerPoints ?? this.explorerPoints,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      emergencyContact: emergencyContact ?? this.emergencyContact,
    );
  }
}
