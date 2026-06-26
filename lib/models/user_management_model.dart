class UserManagementModel {
  final String userId;
  final String login;
  final String role;
  final String createdAt;

  String? firstName;
  String? lastName;
  String? patronymic;

  String? groupId; 
  String? profileId;

  UserManagementModel({
    required this.userId,
    required this.login,
    required this.role,
    required this.createdAt,
    this.firstName,
    this.lastName,
    this.patronymic,
    this.groupId,
    this.profileId,
  });

  factory UserManagementModel.fromJson(Map<String, dynamic> json) {
    return UserManagementModel(
      userId: json['userId']?.toString() ?? '',
      login: json['login']?.toString() ?? 'Неизвестно',
      role: json['role']?.toString() ?? 'Student',
      createdAt: json['createdAt']?.toString() ?? '',

      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      patronymic: json['patronymic']?.toString(),

      groupId: json['groupId']?.toString(),
    );
  }

  String get fullName {
    final parts = [lastName, firstName, patronymic]
        .where((e) => e != null && e!.isNotEmpty)
        .map((e) => e!)
        .toList();

    return parts.isEmpty ? login : parts.join(' ');
  }
}