# เฟส 1.5 — ชุดทดสอบการกู้ข้อมูลหลังขาดช่วง (backfill)

## คำถามที่ชุดนี้ต้องตอบ

เมื่อ tunnel หลุด (จะเกิดจริงในเฟส 3 ตอน session มหาวิทยาลัยหมด) Alloy ฝั่ง production จะเก็บ sample ไว้ใน WAL
แล้วส่งย้อนหลังเมื่อกลับมาต่อได้ **คำถามคือข้อมูลช่วงนั้นเข้า Prometheus ครบหรือไม่ และขึ้นกับค่า
`storage.tsdb.out_of_order_time_window` หรือเปล่า**

ชุดทดสอบนี้ออกแบบให้ตอบได้ทั้งสองทาง — ถ้าผลออกมาว่าไม่ต้องใช้ค่านี้ ก็เอาออกได้
**ห้ามสรุปล่วงหน้าทั้งสองทาง** จนกว่าจะมีตัวเลขจากรอบ A และ B

## ออกแบบการทดลอง

| ตัวแปร | รอบ A | รอบ B (ตัวควบคุมของการทดลอง) |
|---|---|---|
| config ของ Prometheus | `../../prometheus/prometheus.yml` (มี `out_of_order_time_window: 1h`) | `prometheus-no-ooo.yml` (ไม่มีบรรทัดนั้น = ค่าเริ่มต้น 0s) |
| อย่างอื่น | เหมือนกันทุกอย่าง | เหมือนกันทุกอย่าง |

สองไฟล์นี้ต่างกันแค่บล็อก `storage:` เท่านั้น (ตรวจด้วย `diff` ได้) และ **ไม่มีการแก้ไฟล์ config จริงของเฟส 1**
การสลับรอบทำผ่าน compose override (`docker-compose.round-b.yml`) ซึ่งเปลี่ยนเฉพาะ "ไฟล์ที่ถูก mount"
ไปที่ `/etc/prometheus/prometheus.yml` — mount อื่นและ volume `prom-data` ไม่ถูกแตะ

| กรณี | ทำอะไร | จำลองอะไร |
|---|---|---|
| **S1** | `docker compose stop prometheus` 180 วินาที แล้ว `start` | ปลายทางหายไปเลย (connection refused) — เหมือน tunnel ตาย |
| **S2** | `docker pause` prometheus 180 วินาที แล้ว `unpause` | ปลายทางรับสายแต่ไม่ตอบ (timeout) — เหมือนเน็ตค้าง |
| **S3** | stop prometheus แล้ว **restart `alloy-test` ระหว่างช่วงขาด** 1 ครั้ง | agent ฝั่ง prod ถูกรีสตาร์ตตอน tunnel ยังไม่กลับ — ทดสอบว่า WAL ใน named volume รอดไหม |

**ตัวควบคุมในการวัดแต่ละกรณี:** series `monitoring-host` ซึ่ง Prometheus scrape เอง *ต้อง* ขาดหายในช่วงเดียวกัน
ถ้าไม่ขาด แปลว่าเราไม่ได้สร้างช่วงขาดจริง → ผลกรณีนั้นเป็นโมฆะ (สคริปต์พิมพ์ให้เห็นชัด)

ข้อมูลทดสอบถูกแยกด้วย label `job="backfill_test"` และ `test="backfill"` ทุก sample จึงไม่ปนกับข้อมูลจริง

## ก่อนรัน

- stack เฟส 1 ต้องขึ้นอยู่แล้ว (`prometheus`, `node-exporter` รันอยู่)
- ต้องมี `curl`, `jq`, `awk`, `docker compose` v2 บนเครื่อง
- ถ้าใช้พอร์ตสำรอง ให้ตั้ง `PROM_URL` เช่น `PROM_URL=http://127.0.0.1:9091 ./run.sh A`

## วิธีรัน

```bash
cd infra/monitoring/tests/backfill
./run.sh A 2>&1 | tee /tmp/backfill-A.log     # ~25 นาที
./run.sh B 2>&1 | tee /tmp/backfill-B.log     # ~25 นาที
```

รันทีละรอบ (สคริปต์รับรอบเดียวต่อครั้งโดยตั้งใจ จะได้หยุดดูผลกลางทางได้) ถ้าอยากทดสอบกรณีเดียว:

```bash
./run.sh A "S1"
```

ปรับเวลาได้ด้วย env: `BASELINE` (ค่าเริ่มต้น 120s), `OUTAGE` (180s), `SETTLE` (240s), `PASS_PCT` (90)

**เวลาที่ใช้:** `BASELINE + จำนวนกรณี × (OUTAGE + SETTLE + ~40s)` ≈ **25 นาทีต่อรอบ** (สคริปต์พิมพ์ค่าประมาณให้ตอนเริ่ม) บวกเวลา recreate/รอ ready อีกเล็กน้อย → สองรอบประมาณ **50–55 นาที**
ระหว่างนั้น Prometheus จะถูก stop/pause เป็นช่วงๆ รวมประมาณ 9 นาทีต่อรอบ (Grafana จะมีกราฟขาดช่วงตามนั้น เป็นเรื่องปกติ)

## สคริปต์วัดอะไรบ้าง

1. **ความครบของข้อมูลในช่วงขาด** — `count_over_time(up{job="backfill_test",test="backfill"}[ช่วง] @ เวลาจบ)`
   เทียบกับจำนวนที่ควรมี (`ช่วง ÷ 15 วินาที`) พิมพ์ทั้งตัวเลขดิบและเปอร์เซ็นต์ เกณฑ์ผ่านเริ่มต้น **≥ 90%**
   และวัดซ้ำด้วย series ที่สอง (`node_time_seconds`) กันกรณี `up` ถูกจัดการต่างจาก sample ปกติ
2. **ตัวควบคุม** — จำนวน sample ของ `monitoring-host` ในช่วงเดียวกัน (ควรเป็น ~0)
3. **counter ฝั่ง Prometheus** — **ไม่ได้ฮาร์ดโค้ดชื่อ metric** สคริปต์อ่าน `/metrics` ของ Prometheus ที่กำลังรันจริง
   แล้วคัดเฉพาะชื่อที่ตรงกับรูปแบบ `out_of_order|too_old|out_of_bound|samples_appended` จากนั้นพิมพ์ส่วนต่างก่อน/หลัง
   (ในเวอร์ชัน v3.5.5 ที่ปักไว้ ชุดนี้คือ `prometheus_tsdb_head_out_of_order_samples_appended_total`,
   `prometheus_tsdb_out_of_order_samples_total`, `prometheus_tsdb_too_old_samples_total`,
   `prometheus_tsdb_out_of_bound_samples_total`, `prometheus_tsdb_head_samples_appended_total`
   — แต่ตัวเลขที่รายงานมาจากของจริงที่อ่านได้ ไม่ใช่จากรายการนี้)
4. **counter ฝั่ง Alloy** — อ่าน `/metrics` ของ alloy-test เช่นกัน คัดชื่อที่ตรงกับ
   `prometheus_remote_(storage|write)_*` ที่มีคำว่า samples/failed/dropped/retried/pending/highest

## ค่าที่ทำให้ Alloy ทิ้งข้อมูลเอง (บันทึกไว้ ตรวจจากเอกสารของ v1.20.1)

| ค่า | ค่าเริ่มต้น | ผลต่อการทดสอบ |
|---|---|---|
| `endpoint > queue_config > sample_age_limit` | `0s` = ปิดการทิ้งตามอายุ | ตั้งไว้ชัดเจนใน `config.alloy` → Alloy จะไม่ทิ้ง sample เพราะเก่า |
| `wal > truncate_frequency` | `2h` | ทุก 2 ชั่วโมง WAL ส่วนเก่าสองในสามจะถูกตัดทิ้งและส่งไม่ได้อีก |
| `wal > min_keepalive_time` | `5m` | sample จะไม่ถูกลบก่อนอายุเท่านี้ |
| `wal > max_keepalive_time` | `8h` | เกินนี้ถูกลบแน่นอน |

ช่วงขาด 3 นาทีของการทดสอบอยู่ห่างจากขอบเหล่านี้มาก → **ถ้าข้อมูลหาย ไม่ใช่เพราะ WAL หมดอายุ**
(ถ้าในเฟส 3 ของจริงขาดนานเกิน ~2 ชั่วโมง ต้องกลับมาทบทวน `truncate_frequency` อีกที)

## ตีความผล

| ผลที่ได้ | แปลว่า | ทำอะไรต่อ |
|---|---|---|
| A ผ่าน · B ล้ม | `out_of_order_time_window` **จำเป็น** | เก็บค่าไว้ใน config เฟส 1 บันทึกตัวเลขลงเอกสาร |
| A ผ่าน · B ผ่าน | **ไม่จำเป็น** | เสนอถอดออกเพื่อลดความซับซ้อน แล้วรันซ้ำยืนยันอีกรอบ |
| A ล้ม | สมมติฐานพื้นฐานผิด | **หยุด** อย่าเพิ่งสรุป ส่งผลดิบทั้งหมดมาวิเคราะห์ร่วมกัน |
| คอลัมน์ "ตัวควบคุม" ไม่ขึ้นว่า "ยืนยันว่าขาดจริง" | กรณีนั้นไม่ได้สร้างช่วงขาดจริง | ผลเป็นโมฆะ รันกรณีนั้นใหม่ |

## ล้างหลังทดสอบ

```bash
cd infra/monitoring
docker compose -f docker-compose.yml -f tests/backfill/docker-compose.backfill.yml \
  --profile backfilltest rm -sf alloy-test
docker volume rm subscription-monitoring_alloy-test-data
```

> ใช้ `rm -sf alloy-test` แทน `down` โดยตั้งใจ — `docker compose ... down` จะลบ container ของ **ทั้ง stack**
> (prometheus/loki/grafana ด้วย) ซึ่งไม่ใช่สิ่งที่ต้องการแค่เก็บกวาดตัวทดสอบ

**อย่าลบข้อมูลทดสอบใน Prometheus** ปล่อยให้หมดอายุเองตาม retention (10 วัน) — series ทั้งหมดมี label
`test="backfill"` จึงกรองออกจาก dashboard ได้ตลอดเวลา

ถ้าเคยรันรอบ B ค้างไว้ ให้คืน Prometheus กลับสู่ config ของเฟส 1 ด้วย:

```bash
docker compose -f docker-compose.yml up -d prometheus
```

## ต้นทุนของชุดทดสอบ

| อย่าง | ขนาด |
|---|---|
| RAM | `alloy-test` `mem_limit` 256 MiB (รวมเฟส 1 แล้วเป็น 1792 MiB เฉพาะช่วงที่รันทดสอบ) |
| ดิสก์ | image `grafana/alloy:v1.20.1` **946 MB** (วัดจาก `docker images` จริง) + WAL ใน volume ไม่กี่ MB (1 target, 15s, ไม่กี่สิบนาที) |
| ข้อมูลใน Prometheus | series ของ node-exporter 1 ชุด × ~1 ชั่วโมง — เล็กมากเทียบกับโควตา 3 GB |

## ข้อจำกัด / UNVERIFIED

- สคริปต์ยังไม่เคยรันจริง (รันบนเครื่อง production ไม่ได้ตามกติกา) — ตรวจแล้วเฉพาะ `bash -n`, `shellcheck` (สะอาด),
  `docker compose config` ทั้งสองรอบ, `promtool check config` ทั้งสองไฟล์ และ `alloy validate` ของ `config.alloy`
- ตัวเลข "ควรมี = ช่วง ÷ 15s" เป็นค่าในอุดมคติ ความคลาดเคลื่อน ±1 sample ที่ขอบช่วงถือเป็นเรื่องปกติ
  (เกณฑ์ 90% เผื่อไว้แล้ว)
