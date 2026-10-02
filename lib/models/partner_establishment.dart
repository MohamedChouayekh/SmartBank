class PartnerEstablishment {
  final int id;
  final String name;
  final String category;
  final String city;
  final String address;
  final double latitude;
  final double longitude;
  final bool active;

  const PartnerEstablishment({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.active,
  });

  factory PartnerEstablishment.fromJson(Map<String, dynamic> json) {
    return PartnerEstablishment(
      id: _requiredInt(json['id'], 'id'),
      name: _requiredString(json['name'], 'name'),
      category: _requiredString(json['category'], 'category'),
      city: _requiredString(json['city'], 'city'),
      address: _requiredString(json['address'], 'address'),
      latitude: _requiredDouble(json['latitude'], 'latitude'),
      longitude: _requiredDouble(json['longitude'], 'longitude'),
      active: _requiredBool(json['active'], 'active'),
    );
  }

  static int _requiredInt(dynamic value, String field) {
    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Champ $field invalide dans PartnerEstablishment.');
  }

  static double _requiredDouble(dynamic value, String field) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }

    throw FormatException('Champ $field invalide dans PartnerEstablishment.');
  }

  static String _requiredString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Champ $field invalide dans PartnerEstablishment.');
  }

  static bool _requiredBool(dynamic value, String field) {
    if (value is bool) {
      return value;
    }

    throw FormatException('Champ $field invalide dans PartnerEstablishment.');
  }
}
