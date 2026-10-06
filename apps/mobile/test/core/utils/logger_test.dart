import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:subscription_track/core/utils/logger.dart';

/// ล็อกไว้ว่าการปิด log ในบิลด์ที่ไม่ใช่ debug เป็น "พฤติกรรมของเรา"
/// ไม่ใช่ค่า default ของ `package:logger` ที่เปลี่ยนตอนอัปเกรดแล้วเงียบ ๆ ได้
void main() {
  group('buildLogFilter', () {
    test('debug build ใช้ DevelopmentFilter', () {
      expect(buildLogFilter(isDebugMode: true), isA<DevelopmentFilter>());
    });

    test('non-debug build ใช้ SilentLogFilter', () {
      expect(buildLogFilter(isDebugMode: false), isA<SilentLogFilter>());
    });

    test('non-debug build ต้องไม่ใช่ ProductionFilter ของ package', () {
      // ProductionFilter ของ package:logger แปลว่า "log แม้ใน production"
      // ถ้าใครเผลอสลับมาใช้ตัวนั้น log จะหลุดออก release build
      expect(
        buildLogFilter(isDebugMode: false),
        isNot(isA<ProductionFilter>()),
      );
    });
  });

  group('SilentLogFilter', () {
    test('ไม่ปล่อย log ทุกระดับ แม้ระดับสูงสุด', () {
      final filter = SilentLogFilter()..level = Level.trace;

      for (final level in [
        Level.trace,
        Level.debug,
        Level.info,
        Level.warning,
        Level.error,
        Level.fatal,
      ]) {
        expect(
          filter.shouldLog(LogEvent(level, 'ข้อความทดสอบ')),
          isFalse,
          reason: 'level $level ต้องไม่ถูกปล่อยออกใน non-debug build',
        );
      }
    });
  });

  group('DevelopmentFilter (สาขา debug)', () {
    test('ปล่อย log เมื่อ assert ทำงาน (คือตอนรันเทสต์นี้)', () {
      final filter = DevelopmentFilter()..level = Level.trace;

      expect(
        filter.shouldLog(LogEvent(Level.info, 'ข้อความทดสอบ')),
        isTrue,
        reason: 'เทสต์รันในโหมด debug จึงต้องปล่อย log '
            '— ถ้า assert ไหน ๆ ใน shouldLog ถูกถอดออก เทสต์นี้จะจับได้',
      );
    });
  });
}
