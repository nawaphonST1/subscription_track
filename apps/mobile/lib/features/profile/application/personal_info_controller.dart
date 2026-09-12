import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subscription_track/features/auth/application/auth_provider.dart';

// 1. คลาสเก็บข้อมูล (ที่หายไป)
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

// 2. ตัวแปร Provider (ที่หายไป)
final personalInfoProvider = NotifierProvider<PersonalInfoController, PersonalInfo>(
  PersonalInfoController.new,
);

// 3. Controller (อัปเดตให้ดึงข้อมูลจาก Auth แล้ว)
class PersonalInfoController extends Notifier<PersonalInfo> {
  @override
  PersonalInfo build() {
    // ดึงค่าผู้ใช้จากระบบ Auth
    final authState = ref.watch(authProvider);
    final authName = authState.value?.name;

    String fName = 'ผู้ใช้งาน';
    String lName = '';

    // แยกชื่อและนามสกุลออกจากกัน (ถ้ามี)
    if (authName != null && authName.isNotEmpty) {
      final parts = authName.split(' ');
      fName = parts.first;
      if (parts.length > 1) {
        lName = parts.sublist(1).join(' ');
      }
    }

    // ตั้งค่าเริ่มต้น
    return PersonalInfo(
      firstName: fName,
      lastName: lName,
      phoneNumber: '0812345678', // เบอร์จำลอง
      nationalId: '1234567890123', // บัตรจำลอง
      birthDate: DateTime(1998, 8, 7), 
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