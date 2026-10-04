# k6 load test (DP-5 เฟส 7)

พิสูจน์ว่าระบบรับโหลดได้แค่ไหน และทำให้กราฟ RED ใน Grafana ขยับจริงตอน demo

> **รันจากเครื่อง dev เท่านั้น** ห้ามรันบน VM production (generator จะแย่ง 2 vCPU เดียวกันกับแอป
> ผลที่ได้จะวัด k6 เองไม่ใช่แอป) และ **ห้ามยิงใส่ระบบอื่นเด็ดขาด** — เป้าหมายคือ VM Azure ของเราเท่านั้น

## 1. เตรียมก่อน

| ต้องมี | ทำไม |
|---|---|
| k6 ≥ 1.3 (`docker run grafana/k6:1.3.0` ก็ได้) | ตัวรันเทสต์ |
| บัญชีทดสอบจริงใน prod (`TEST_EMAIL` / `TEST_PASSWORD`) | สคริปต์ล็อกอินจริง ไม่มีการ bypass auth |
| บัญชีนั้นต้องมี **payment card อย่างน้อย 1 ใบ** | subscription ต้องผูกกับการ์ด ถ้าไม่มี สคริปต์จะข้ามขั้น create/delete แล้วนับไว้ที่ `create_skipped_no_card` |
| prod ตอบ `GET /health/ready` = 200 | `setup()` เช็กก่อน ถ้าไม่พร้อมจะ `fail` ทันที ไม่ยิงโหลดใส่ระบบที่ยังไม่พร้อม |

สร้างบัญชีทดสอบ (ครั้งเดียว ใช้ข้อมูล mock ล้วน):

```bash
curl -sX POST "$BASE_URL/auth/register" -H 'Content-Type: application/json' \
  -d '{"email":"loadtest@example.com","password":"<random>","name":"k6 load test"}'
```

## 2. รัน

```bash
export BASE_URL=https://<prod-domain>
export TEST_EMAIL=loadtest@example.com
export TEST_PASSWORD='<password>'

k6 run infra/loadtest/loadtest.js

# หรือแบบ docker (ไม่ต้องติดตั้ง k6)
docker run --rm -i \
  -e BASE_URL -e TEST_EMAIL -e TEST_PASSWORD \
  -v "$PWD/infra/loadtest:/scripts:ro" \
  grafana/k6:1.3.0 run /scripts/loadtest.js
```

## 3. โปรไฟล์โหลดและ threshold

| stage | เวลา | VUs | ความหมาย |
|---|---|---|---|
| warm-up | 1m | 10 | ให้ JIT / connection pool / Prisma อุ่นเครื่องก่อน |
| nominal | 2m | 50 | โหลดที่คาดว่าจะเจอจริง |
| peak | 2m | 100 | โหลดสูงสุดที่ออกแบบไว้ |
| stress | 1m | 150 | **เกิน** ขนาดเครื่องตั้งใจ เพื่อหาจุดที่เริ่มพัง |
| cooldown | 2m | 0 | ให้กราฟใน Grafana เห็นการฟื้นตัว ไม่ใช่หน้าผา |

threshold: `http_req_failed < 1%`, `p(95) < 1000ms` รวม และแยกราย endpoint
(`POST /auth/login` ผ่อนไว้ที่ 2000ms เพราะเป็น bcrypt ดูข้อ 4) บวก `flow_completed > 95%`

ทุก request ติด tag `name` เป็น **route template** (`DELETE /subscriptions/:id`) ไม่ใช่ URL จริง
เพื่อให้เทียบกับ label `route` ของฝั่ง API ได้ตรงๆ และไม่ระเบิด cardinality ทั้งสองฝั่ง

## 4. bcrypt: เหตุผลที่ไม่ล็อกอินทุกรอบโดยปริยาย

`POST /auth/login` คือการเทียบ bcrypt หนึ่งครั้ง ซึ่งกิน CPU มากกว่าอีก 4 request รวมกันบนเครื่อง
2 vCPU ถ้าล็อกอินทุก iteration ที่ 100 VUs เทสต์นี้จะวัด bcrypt ล้วนๆ ไม่ได้บอกอะไรเกี่ยวกับ
endpoint ของ subscription เลย

ค่า default จึงเป็น **VU ละหนึ่ง token** (ล็อกอินใหม่เมื่อเจอ 401) อยากได้ flow ตามตัวอักษรให้ตั้ง:

```bash
LOGIN_EACH_ITERATION=true k6 run infra/loadtest/loadtest.js
```

ถือเป็นการทดลองคนละตัว: อันนั้นวัดเพดานของ auth อันนี้วัดเพดานของ API ที่เหลือ

## 5. ข้อควรรู้: B2als v2 เป็น burstable (สำคัญมากกับการอ่านผล)

VM production คือ **Standard B2als v2 — 2 vCPU / 4 GiB แบบ burstable** นั่นแปลว่า CPU ที่ใช้ได้
จริงมีสองระดับ: baseline (ประมาณ 30% ของ 2 vCPU) กับ burst ที่ดึงจาก **CPU credit ที่สะสมไว้**
เมื่อ credit หมด เครื่องจะถูกบีบลงมาที่ baseline ทันที

ผลกับเทสต์นี้โดยตรง:

- รัน 8 นาทีเต็มโปรไฟล์ **อาจเผา credit จนหมดระหว่างทาง** แล้ว p95 จะพุ่งขึ้นในช่วงหลัง
  **โดยที่โค้ดไม่ได้ช้าลงเลย** ถ้าตีความผิดจะไปไล่แก้โค้ดที่ไม่ได้ผิด
- ให้ดู `node_cpu_seconds_total` คู่กับผล k6 เสมอ และถ้าเป็นไปได้ให้ดู CPU credit metric ของ Azure
  (`az monitor metrics list ... --metric "CPU Credits Remaining"`) ควบคู่กัน
- **เว้นอย่างน้อย 30 นาทีระหว่างการรันแต่ละรอบ** เพื่อให้ credit สะสมกลับ ไม่งั้นรอบที่สองจะดูแย่กว่า
  รอบแรกเสมอ

### RUNBOOK: ขยายเครื่องชั่วคราวก่อน demo — `NOT-EXECUTED-LOCALLY`

ทำ **ล่วงหน้า ไม่ใช่วัน demo** (ต้อง deallocate = ดับเครื่อง และโควตาอาจไม่พอ) และย้ายกลับหลังเสร็จ
เพื่อไม่ให้เครดิต Azure for Students หมด

```bash
# 0) ตรวจโควตาก่อน — ถ้าไม่พอจะล้มตอน start ไม่ใช่ตอน resize
az vm list-usage --location <REGION> -o table | grep -i "standard d.*v5\|total regional"

# 1) จดขนาดเดิมไว้ (ไว้ย้ายกลับ)
az vm show -g <RESOURCE_GROUP> -n <AZURE_VM_NAME> --query hardwareProfile.vmSize -o tsv

# 2) ดับเครื่อง -> resize -> เปิด  (ดาวน์ไทม์จริง ไม่ใช่ live resize)
az vm deallocate -g <RESOURCE_GROUP> -n <AZURE_VM_NAME>
az vm resize     -g <RESOURCE_GROUP> -n <AZURE_VM_NAME> --size Standard_D2s_v5
az vm start      -g <RESOURCE_GROUP> -n <AZURE_VM_NAME>

# 3) สตาร์ต stack กลับ (compose ตั้ง restart: unless-stopped ไว้แล้ว แต่ยืนยันอีกที)
ssh <VM_ADMIN_USER>@<AZURE_VM_PUBLIC_IP> 'cd ~/subscription_track && docker compose -f docker-compose-prosuction.yml ps'

# 4) ย้ายกลับหลัง demo
az vm deallocate -g <RESOURCE_GROUP> -n <AZURE_VM_NAME>
az vm resize     -g <RESOURCE_GROUP> -n <AZURE_VM_NAME> --size Standard_B2als_v2
az vm start      -g <RESOURCE_GROUP> -n <AZURE_VM_NAME>
```

> ถ้าไม่ resize ก็ยัง demo ได้ — แค่ต้องอธิบายกราฟให้ถูกว่าช่วงท้ายคือ CPU credit หมด ไม่ใช่โค้ดช้า
> ซึ่งเป็นคำอธิบายที่ดีกว่าการมีกราฟสวยแต่ไม่เข้าใจที่มาด้วยซ้ำ

## 6. ดูผลที่ไหน

ระหว่างรัน เปิด Grafana (`ssh -L 3000:localhost:3000` ไป VM อาจารย์) แล้วดู 3 dashboard พร้อมกัน:

| dashboard | ดูอะไร |
|---|---|
| **API — Rate, Errors, Duration** | RPS ขึ้นตาม stage, 5xx, p95/p99 แยก route |
| **System & Containers** | CPU host ชนเพดานตอนไหน, container memory เทียบ limit |
| **Business Activity** | login/นาที, subscription created/deleted, BullMQ waiting |

บันทึกผลที่ควรเก็บ: RPS สูงสุดที่ยัง `http_req_failed < 1%`, p95 ที่แต่ละ stage,
จุด VU ที่ error เริ่มขึ้น, และ CPU% ตอนนั้น

## 7. เก็บกวาดถ้ารันค้าง

สคริปต์ลบ subscription ที่สร้างในรอบเดียวกันเสมอ ถ้า k6 ถูกฆ่ากลางคัน อาจมีแถวชื่อ `k6-load-*` ค้าง:

```sql
-- บน prod, ผ่าน psql ใน container postgres
DELETE FROM "Subscription" WHERE name LIKE 'k6-load-%';
```

## 8. ที่เทสต์นี้ไม่ได้ครอบคลุม

- ไม่ได้ทดสอบ worker/BullMQ โดยตรง (job เกิดจาก schedule ไม่ใช่จาก HTTP) — ดูผลทางอ้อมที่ panel คิว
- ไม่ได้ทดสอบ WebSocket / push notification
- ไม่ได้จำลองผู้ใช้หลายคน — ทุก VU ใช้บัญชีเดียวกัน ดังนั้น `active_users` จะเป็น 1 ไม่ใช่ 100
  (ตั้งใจ: ไม่อยากสร้างบัญชีขยะร้อยบัญชีใน prod)
