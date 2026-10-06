import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Filter ที่ไม่ปล่อย log ออกเลย ใช้ในบิลด์ที่ไม่ใช่ debug
///
/// ⚠️ อย่าสับสนกับ `ProductionFilter` ของ `package:logger` — ตัวนั้นหมายถึง
/// "log แม้อยู่ใน production" (ดู doc ของมันเอง: *Prints all logs with
/// `level >= Logger.level` even in production*) ซึ่งตรงข้ามกับที่เราต้องการ
class SilentLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => false;
}

/// เลือก filter ตามโหมดบิลด์
///
/// แยกเป็นฟังก์ชันแทนที่จะเขียน inline เพราะ `Logger._filter` เป็น private
/// (`logger-2.7.0/lib/src/logger.dart:36`) จึงอ่านกลับจาก instance ไม่ได้ —
/// เทสต์ต้องเรียกฟังก์ชันนี้ตรง ๆ ถึงจะ assert ได้ทั้งสองสาขา
///
/// ก่อนหน้านี้ไฟล์นี้ไม่ได้ระบุ `filter:` เลย จึงตกไปใช้ `DevelopmentFilter`
/// ที่เป็นค่า default ของ package ซึ่งกาง log ไว้ด้วย `assert` — ได้ผลถูกต้อง
/// แต่เป็นพฤติกรรมของ dependency ไม่ใช่ของเรา และไม่มีเทสต์จับถ้ามันเปลี่ยน
LogFilter buildLogFilter({required bool isDebugMode}) {
  return isDebugMode ? DevelopmentFilter() : SilentLogFilter();
}

final logger = Logger(
  filter: buildLogFilter(isDebugMode: kDebugMode),
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
  ),
);
