// ignore_for_file: constant_identifier_names
enum Gender { male, female }

enum ResendOtpType { verify_phone, reset_password }

enum SuccessType { register, resetPassword }

enum PaymentMethods { cash, online }

enum VerificationTypes { register, reset_password }

enum StoreWorkingType { alwaysOpen, specificDays }

enum AdsType {
  cars,
  training,
  horse,
  stable,
  supplies,
  other;

  factory AdsType.fromValue(String value) {
    switch (value) {
      case 'cars':
        return AdsType.cars;
      case 'training':
        return AdsType.training;
      case 'horse':
        return AdsType.horse;
      case 'stable':
        return AdsType.stable;
      case 'supplies':
        return AdsType.supplies;
      case 'other':
        return AdsType.other;
      default:
        throw ArgumentError('Invalid AdType: $value');
    }
  }
}
