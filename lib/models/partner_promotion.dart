class PartnerPromotion {
  final int id;
  final int establishmentId;
  final String establishmentName;
  final String establishmentCategory;
  final String establishmentCity;
  final String establishmentAddress;
  final double establishmentLatitude;
  final double establishmentLongitude;
  final double discountPercent;
  final DateTime startDate;
  final DateTime endDate;
  final String? description;
  final bool active;

  const PartnerPromotion({
    required this.id,
    required this.establishmentId,
    required this.establishmentName,
    required this.establishmentCategory,
    required this.establishmentCity,
    required this.establishmentAddress,
    required this.establishmentLatitude,
    required this.establishmentLongitude,
    required this.discountPercent,
    required this.startDate,
    required this.endDate,
    required this.description,
    required this.active,
  });

  factory PartnerPromotion.fromJson(Map<String, dynamic> json) {
    return PartnerPromotion(
      id: _requiredInt(json['id'], 'id'),
      establishmentId: _requiredInt(
        json['partnerEstablishmentId'],
        'partnerEstablishmentId',
      ),
      establishmentName: _requiredString(
        json['establishmentName'],
        'establishmentName',
      ),
      establishmentCategory: _requiredString(json['category'], 'category'),
      establishmentCity: _requiredString(json['city'], 'city'),
      establishmentAddress: _requiredString(json['address'], 'address'),
      establishmentLatitude: _requiredDouble(json['latitude'], 'latitude'),
      establishmentLongitude: _requiredDouble(json['longitude'], 'longitude'),
      discountPercent: _requiredDouble(
        json['discountPercent'],
        'discountPercent',
      ),
      startDate: _requiredDateTime(json['startDate'], 'startDate'),
      endDate: _requiredDateTime(json['endDate'], 'endDate'),
      description: json['description']?.toString(),
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

    throw FormatException('Champ $field invalide dans PartnerPromotion.');
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

    throw FormatException('Champ $field invalide dans PartnerPromotion.');
  }

  static String _requiredString(dynamic value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }

    throw FormatException('Champ $field invalide dans PartnerPromotion.');
  }

  static DateTime _requiredDateTime(dynamic value, String field) {
    if (value is String) {
      try {
        return DateTime.parse(value);
      } on FormatException {
        throw FormatException('Date $field invalide dans PartnerPromotion.');
      }
    }

    throw FormatException('Date $field invalide dans PartnerPromotion.');
  }

  static bool _requiredBool(dynamic value, String field) {
    if (value is bool) {
      return value;
    }

    throw FormatException('Champ $field invalide dans PartnerPromotion.');
  }
}
