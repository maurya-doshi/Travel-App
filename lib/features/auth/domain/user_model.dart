class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final int explorerPoints;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.explorerPoints = 0,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String,
      photoUrl: map['photoUrl'] as String?,
      explorerPoints: map['explorerPoints'] as int? ?? 0,
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
    };
  }
}
