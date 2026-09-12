---
name: tree-repo
description: Automatically generate and overwrite the repository tree overview file (.agents/tree_repo/tree_repo.md) using standard tree commands while strictly honoring .gitignore and .dockerignore rules, with intelligent inline file annotations written by the AI Agent. Use whenever project structure changes, files/folders are added, removed, or refactored, or upon user request to refresh the repo tree.
---

# 🌳 Tree Repo Skill (AI-Driven Repository Overview)

## Purpose

The `tree-repo` skill instructs the **AI Agent** to maintain and update [`.agents/tree_repo/tree_repo.md`](../../tree_repo/tree_repo.md). 

Unlike rigid static scripts that rely on hardcoded dictionaries, the **AI Agent utilizes its deep contextual understanding of the codebase** (architecture layers, Riverpod state management, domain models, business logic, and UI behavior) to write clear, meaningful, and accurate inline annotations for every single file.

---

## 📋 Required Output Specification & Format

Whenever this skill executes, the Agent MUST overwrite `.agents/tree_repo/tree_repo.md` with the following 4 sections:

### 1. Header Metadata
- **📅 วันที่อัปเดต:** Timestamp ของการรัน (รูปแบบ `YYYY-MM-DD HH:MM:SS`)
- **👤 อัปเดตโดย:** ผู้ที่รันคำสั่ง (ดึงจาก `git config user.name` หรือ `Antigravity Agent`)
- **💻 คำสั่งที่ใช้:** คำสั่งคงที่ที่ใช้ดึง Tree จริงจากระบบ
- **⚠️ หมายเหตุ:** คำเตือนที่ระบุอย่างเคร่งครัดว่า:
  > โครงสร้างไฟล์ในเอกสารนี้สร้างขึ้นโดยเคารพกฎการยกเว้นอย่างเคร่งครัด จะไม่อัปเดตไฟล์หรือโฟลเดอร์ที่ถูกระบุไว้ใน `.gitignore` และ `.dockerignore` (หากมี) โดยเด็ดขาด ไม่ว่ากรณีใดๆ ทั้งสิ้น เพื่อป้องกันไม่ให้ Temporary files, Build artifacts, Caches, Secrets หรือไฟล์ Generated ที่ไม่จำเป็นถูกนำเข้ามาบันทึกไว้ในผังโครงการ

### 2. Annotated Directory Tree Block
- Fenced code block (` ```text ... ``` `)
- **📌 สำคัญที่สุด — คำอธิบายไฟล์โดย AI Agent (Inline File Annotations):**  
  ให้ Agent นำโครงสร้างต้นไม้จริงที่ได้จากคำสั่ง `tree` มาเติม Comment อธิบายหน้าที่สั้นๆ ต่อท้ายแต่ละไฟล์ด้วย `# <คำอธิบายเชิงสถาปัตยกรรมและหน้าที่จริงของไฟล์>` 
  - อธิบายตามหน้าที่จริงของโค้ดในโปรเจกต์ ไม่ใช่แค่เดาจากชื่อไฟล์ เช่น:
    - `payment_card_linking_controller.dart` → `# Controller จัดการผูกบัตรธนาคาร และตรวจจับ subscription เรียกเก็บซ้ำอัตโนมัติ`
    - `user_income_controller.dart` → `# คำนวณรายได้/ยอดเงินรวมของผู้ใช้โดยคำนวณจากยอดคงเหลือในบัตรที่ผูกไว้`
    - `pin_verification_dialog.dart` → `# Dialog ยืนยันรหัส PIN 6 หลัก พร้อม Shake Animation เมื่อกรอกผิด`
    - `subscription_appearance_selector.dart` → `# วิดเจ็ตเลือกสีประจำบริการและไอคอนสำหรับ Subscription ใหม่`
  - จัดระยะย่อหน้า (column alignment) ให้เครื่องหมาย `#` อยู่ในแนวเดียวกันอย่างสวยงาม เป็นระเบียบและอ่านง่าย

### 3. Key Directories Overview
- ตารางสรุปหน้าที่ความรับผิดชอบของโฟลเดอร์หลักในระดับบน (`.agents/`, `doc/`, `lib/app/`, `lib/core/`, `lib/features/`, `test/`)

---

## ⚙️ Standard Fixed Tree Command

Agent ต้องรันคำสั่งคงที่นี้เพื่อดึงโครงสร้างไฟล์ที่แท้จริง:

```bash
tree -a -I ".git|android|ios|linux|macos|windows|web" --gitignore --dirsfirst
```

### Strict Ignore Handling:
- `--gitignore`: สั่งให้คำสั่ง `tree` กรองไฟล์ตามกฎของ `.gitignore` ทุกข้อโดยอัตโนมัติ (ข้าม `build/`, `.dart_tool/`, `.pub-cache/`, `.history/` ฯลฯ)
- `-I ".git|android|ios|linux|macos|windows|web"`: ยกเว้นโฟลเดอร์ `.git` และโฟลเดอร์ Platform boilerplate ของแต่ละ OS เพื่อมุ่งเน้นที่ Dart/Flutter Architecture, Logic, Docs และ Tests
- `.dockerignore`: หากมีไฟล์ `.dockerignore` ในโปรเจกต์ ให้ Agent นำ pattern ที่ระบุในนั้นมารวมใน `-I` ด้วยเสมอ

---

## 🤖 Agent Execution Workflow

เมื่อผู้ใช้สั่งให้อัปเดต `tree_repo` หรือโครงสร้างโปรเจกต์มีการเปลี่ยนแปลง Agent ต้องดำเนินการตามขั้นตอนดังนี้:

1. **ดึงโครงสร้างไฟล์จริง:**  
   รันคำสั่ง `tree -a -I ".git|android|ios|linux|macos|windows|web" --gitignore --dirsfirst`
2. **ดึง Metadata:**  
   ดึงวันเวลาปัจจุบัน และชื่อผู้ใช้จาก `git config user.name`
3. **วิเคราะห์และเขียนคำอธิบาย (AI Comprehension):**  
   อ่านโครงสร้างไฟล์ และใช้ความเข้าใจในโปรเจกต์เขียนคำอธิบายสั้นๆ (Short Description) กำกับแต่ละไฟล์ โดยเฉพาะไฟล์ที่เพิ่มเข้ามาใหม่
4. **จัด Alignment:**  
   จัดช่องว่าง Padding ให้เครื่องหมาย `#` ตรงกันทุกบรรทัด
5. **บันทึกทับ (Overwrite):**  
   เขียนทับไฟล์ `.agents/tree_repo/tree_repo.md` ให้เสร็จสมบูรณ์
6. **ตรวจสอบความถูกต้อง (Verification):**  
   ตรวจดูว่าไม่มีไฟล์ชั่วคราวหรือโฟลเดอร์ที่ติด ignore หลุดเข้ามา และข้อความอธิบายครบถ้วนทุกไฟล์
