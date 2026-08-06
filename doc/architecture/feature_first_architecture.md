# Feature-First Architecture

**Status:** Implemented  
**Last verified:** 6 August 2026

เอกสารนี้เป็น source of truth สำหรับโครงสร้างโค้ด Flutter ปัจจุบันของ
Subscription Track หลังย้ายจากการแยกตามชนิดไฟล์ (`screens/`, `providers/`,
`widgets/`) มาเป็น feature-first architecture

## Layer rules

แต่ละ feature ใช้เฉพาะ layer ที่จำเป็น:

```text
features/<feature>/
├── domain/        # entity และ contract ที่ไม่ import Flutter/Riverpod
├── data/          # implementation ของ repository หรือ data source
├── application/   # Riverpod controller/provider และ derived state
└── presentation/  # screen/tab และ widget เฉพาะ feature
```

- `presentation` ติดต่อ state/commands ผ่าน `application` และไม่ import `data`
  โดยตรง
- `application` ประสาน domain contract กับ data implementation
- `domain` ไม่พึ่ง Flutter, Riverpod, presentation หรือ data
- state ที่ feature อื่นต้องอ่านให้ expose ผ่าน public application contract
  ขนาดเล็ก ห้าม import internal layer ข้าม feature
- widget เข้า `core/widgets` เมื่อมีอย่างน้อยสอง feature ใช้จริง
- โปรเจกต์ใช้ Riverpod จึงใช้ชื่อ `application/` และไม่มี top-level `lib/bloc/`

## Current structure

```text
lib/
├── app/
│   ├── application/   # startup flow และ navigation state
│   ├── presentation/  # splash และ adaptive navigation shell
│   └── routing/       # GoRouter และ route constants
├── core/
│   ├── errors/
│   ├── layout/
│   ├── theme/
│   ├── utils/
│   └── widgets/
└── features/
    ├── auth/
    ├── dashboard/
    ├── notifications/
    ├── onboarding/
    ├── profile/
    ├── savings/
    ├── settings/
    └── subscriptions/
```

Dashboard และ Savings ไม่มี `domain/`/`data/` ของตนเองโดยตั้งใจ เพราะทั้งสอง
เป็น read model/derived UI state จาก subscription source of truth และยังไม่มี
business entity หรือ persistence contract เฉพาะ feature ส่วน Settings มีเพียง
application/presentation เพราะ reminder preference ยังเป็น session state ของ MVP

## State ownership decisions

| State/contract | Owner | เหตุผล |
|---|---|---|
| Subscription list, CRUD และ simulation selection | `features/subscriptions/application` | `Subscription.isSelected` เป็น selection source of truth เพียงจุดเดียว และ mutation ผ่าน controller |
| Search และ category filter | `features/subscriptions/application` | รวมอยู่ใน `SubscriptionFilterState` เดียว ป้องกัน filter state ขัดกัน |
| Subscription read model/commands | `features/subscriptions/application/subscription_read_model.dart` | เป็น public boundary ให้ Dashboard/Savings ใช้โดยไม่ import domain/data ภายใน |
| Dashboard summary | `features/dashboard/application` | เป็น derived state สำหรับ KPI, renewal และ unused alert เท่านั้น |
| Savings view state | `features/savings/application` | เป็น derived state; ไม่มี selection source ซ้ำใน Savings |
| Monthly income | `features/profile/application` | Profile เป็นผู้แก้ค่า ส่วน Dashboard อ่านไปคำนวณ creep score |
| Notification reminder preference | `features/settings/application` | เป็น user preference จาก Settings ไม่ใช่ scheduling/generation state ของ Notification Center |
| Notification inbox/filter | `features/notifications/application` | จัดการรายการ, filter และ read state ของ Notification Center |
| Auth state | `features/auth/application` | ซ่อน repository implementation หลัง domain contract และรองรับ override ใน test |
| Onboarding completion | `features/onboarding/application` | เป็น state ของ onboarding flow โดยตรง |
| Startup redirect และ current tab | `app/application` | เป็น orchestration ระดับแอป ไม่ใช่ business feature |

## Migration notes

- ลบ legacy `dashboard_screen.dart`, compatibility exports, unused shared widgets,
  service/provider scaffolding และ artifact ที่ไม่ถูกใช้งานแล้ว
- `ConfirmationDialog` อยู่ `core/widgets` เพราะ Subscriptions และ Savings ใช้ร่วมกัน
- preset package catalog อยู่ใน subscriptions domain เพราะเป็นข้อมูล catalog ที่ไม่
  พึ่ง framework; presentation อ่านผ่าน boundary ภายใน feature เดียวกัน
- generated files สร้างจาก source annotations เท่านั้นและไม่แก้ด้วยมือ
- test tree สะท้อน `app/`, `core/` และ `features/` ของ production source
- ขีด 200 บรรทัดใช้เป็น review signal ไม่ใช่เหตุผลเดียวในการแยกไฟล์ ปัจจุบัน
  production Dart source ที่ไม่ใช่ generated file ทุกไฟล์ต่ำกว่า 200 บรรทัด

## Verification guardrails

ก่อน merge การเปลี่ยน architecture หรือ state:

1. ตรวจว่าไม่มี import จาก legacy paths และไม่มี presentation import data โดยตรง
2. ตรวจว่า domain ไม่มี Flutter/Riverpod import
3. รัน `dart analyze`
4. รัน `flutter test`
5. รัน `flutter test --coverage` เมื่อเปลี่ยน business/application logic

Security/Biometric ยังอยู่นอก implementation scope ตาม YAGNI; แนวทางอนาคตบันทึก
ไว้ที่ `.private/docs/security_architecture_blueprint.md`

## Migration verification

ผลตรวจหลัง migration วันที่ 6 August 2026:

- architecture import/legacy path/200-line guardrails: ผ่าน
- `dart analyze`: ผ่าน ไม่มี issue
- `flutter test --coverage`: ผ่าน 33 tests
- LCOV line coverage: 59.86% (1,190/1,988 lines จาก 83 source files)
