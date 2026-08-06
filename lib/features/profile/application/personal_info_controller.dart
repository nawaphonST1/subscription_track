import 'package:flutter_riverpod/flutter_riverpod.dart';

class PersonalInfo {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String nationalId;
  final DateTime? birthDate;

  const PersonalInfo({
    this.firstName = 'เน',
    this.lastName = 'ศรีทอง',
    this.phoneNumber = '0812345678',
    this.nationalId = '1234567890123',
    this.birthDate,
  });

  PersonalInfo copyWith({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? nationalId,
    DateTime? birthDate,
  }) {
    return PersonalInfo(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationalId: nationalId ?? this.nationalId,
      birthDate: birthDate ?? this.birthDate,
    );
  }

  int get age {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    if (today.month < birthDate!.month ||
        (today.month == birthDate!.month && today.day < birthDate!.day)) {
      age--;
    }
    return age;
  }
}

final personalInfoProvider = NotifierProvider<PersonalInfoController, PersonalInfo>(
  PersonalInfoController.new,
);

class PersonalInfoController extends Notifier<PersonalInfo> {
  @override
  PersonalInfo build() {
    return PersonalInfo(
      birthDate: DateTime(1998, 8, 7), // Default birth date
    );
  }

  void updateInfo({
    required String firstName,
    required String lastName,
    required String phoneNumber,
    required String nationalId,
    required DateTime? birthDate,
  }) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      nationalId: nationalId,
      birthDate: birthDate,
    );
  }
}
