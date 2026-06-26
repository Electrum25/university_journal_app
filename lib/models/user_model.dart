class UserProfile {
  final String userId;
  final String login;
  final String role;
  final String? businessId; 

  UserProfile({
    required this.userId,
    required this.login,
    required this.role,
    this.businessId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: json['userId'],
      login: json['login'],
      role: json['role'],
      businessId: json['businessId'],
    );
  }
}