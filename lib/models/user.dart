class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String username;
  final String address;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.username,
    required this.address,
  });

  String get fullName => '$firstName $lastName';

  factory User.fromJson(Map<String, dynamic> json) {
    final fullName =
        (json['fullName'] ?? '').toString().trim();

    String firstName = '';
    String lastName = '';

    if (fullName.isNotEmpty) {
      final parts = fullName.split(' ');

      firstName = parts.first;

      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    return User(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse(
                (json['id'] ?? '0').toString(),
              ) ??
              0,

      firstName: firstName,

      lastName: lastName,

      email: (json['email'] ?? '').toString(),

      phone: (json['phoneNumber'] ?? '').toString(),

      username: (json['username'] ?? '').toString(),

      address: (json['address'] ?? '').toString(),
    );
  }
}