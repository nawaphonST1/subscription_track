# DP-5 Monitoring Plan (แบบ B) — แผนสำหรับ Claude Code

**ผู้รับผิดชอบ:** Nekokun2004 · **สร้างเมื่อ:** 4 ต.ค. 2026
**เป้าหมาย:** ระบบ monitoring ที่ใช้งานได้จริงสำหรับ demo สด: สถานะ server + กิจกรรมผู้ใช้ + log + แจ้งเตือน + Wazuh
**ขอบเขต:** DP-500…505 เท่านั้น (DP-6 / Android แยกแผนต่างหาก)

> ป้ายสถานะ: `VERIFIED` = เห็นหลักฐานแล้ว · `ASSUMED` = สมมติจากที่คุยกัน ต้องตรวจ · `TODO` = ยังไม่ได้ทำ

---

## 1. ข้อเท็จจริงและข้อสมมติ

| เรื่อง | สถานะ | รายละเอียด |
|---|---|---|
| VM Azure `<AZURE_VM_NAME>` | VERIFIED | 2 vCPU / 4 GiB, Ubuntu 24.04, Malaysia West, IP `<AZURE_VM_PUBLIC_IP>`, ล็อกอินด้วย SSH key เท่านั้น |
| VM อาจารย์ `mob07-mob` | VERIFIED | 4 vCPU / 5.8 GiB, ดิสก์ว่าง ~37 GB, ไม่มี swap, `sudo` + `docker` ใช้ได้ |
| ของเก่าบน VM อาจารย์ | VERIFIED | โปรเจกต์ `flash-sale-system` (path `/srv/project_backend/FlashSaleSystem`) มี Prometheus 3.5 / Grafana 12.1 / node-exporter รันอยู่ — **ใช้ config เป็นต้นแบบได้ แต่ห้ามลบก่อนสำรอง** |
| VM อาจารย์ → Azure SSH (พอร์ต 22) | VERIFIED | เข้าได้ด้วย key `~/.ssh/id_azure_tunnel` (NSG อนุญาต `<UNIVERSITY_EGRESS_IP>/32`) |
| VM อาจารย์ออกเน็ต | VERIFIED (มีเงื่อนไข) | ต้องล็อกอิน captive portal ของ ม. ด้วยตัวเอง (พิมพ์ user/password เอง) session อยู่ได้ ~1 วัน |
| ผู้ชม demo เข้า prod ได้ | ASSUMED | prod อยู่ Azure มี IP สาธารณะ → เปิดได้จากทุกเครือข่าย |
| Public IP ของ Azure เป็น static | ASSUMED | ตรวจด้วย `az network public-ip show` (ดูเฟส 0) |
| Prod stack บน Azure | TODO | ยังไม่ได้ deploy `docker-compose-prosuction.yml` (งาน nawaphonST1 / ต้องประสาน) |
| ข้อมูลในระบบ | VERIFIED | mock ทั้งหมด ไม่มีข้อมูลบัตร/บุคคลจริง |

---

## 2. สถาปัตยกรรม

```
   ผู้ชม / k6 (เครื่อง dev)
          │ HTTPS
          ▼
┌─────────────────────────── VM AZURE = PROD (public) ─────────────────────────┐
│ Caddy(TLS) → nginx → api, worker → postgres, redis                           │
│ exporters (ภายใน): node, cAdvisor, postgres, redis                            │
│ Grafana Alloy: scrape ในเครื่อง → remote_write + ส่ง log                       │
│        │ ส่งไปที่ 127.0.0.1:9090 (metrics) และ 127.0.0.1:3100 (logs)            │
│        └──────────── ปลายอีกด้านของ reverse tunnel ───────────────────┐        │
└──────────────────────────────────────────────────────────────────────┼────────┘
                                                                        │ SSH (เริ่มจากฝั่ง ม. ออกมา, key จำกัดสิทธิ์)
┌──────────────────── VM อาจารย์ = MONITORING (ใน subnet ม.) ────────────┼────────┐
│ tunnel container (autossh) ───────────────────────────────────────────┘        │
│   -R 127.0.0.1:9090 → prometheus:9090      -R 127.0.0.1:3100 → loki:3100       │
│ Prometheus (รับ remote_write) · Loki · Grafana (alerting → Discord)            │
│ blackbox_exporter: probe https://<โดเมน prod>/health/ready                      │
└────────────────────────────────────────────────────────────────────────────────┘

เครื่อง dev (เปิดเฉพาะช่วง demo)   ◀── Tailscale ──▶  Wazuh agent บน Azure
  Wazuh server (docker, single-node)
```

**หลักการ**
1. **ทุกการเชื่อมต่อเริ่มจากฝั่ง ม. ออกมา** ไม่ต้องเปิดพอร์ตขาเข้าบน VM อาจารย์ และไม่ต้องติดตั้ง Tailscale บนเครื่องที่ไม่ใช่ของเรา
2. **Push จาก prod** ผ่าน reverse tunnel: ถ้า tunnel หลุด (session ม. หมด) Alloy เก็บข้อมูลชั่วคราวแล้วส่งต่อเมื่อกลับมา
3. **แยกบทบาท:** PROD (โดนโจมตีได้) / MONITORING / SIEM (Wazuh) คนละเครื่อง
4. ทุกอย่างเป็น Docker Compose ที่ย้ายเครื่องได้ **ทางสำรอง:** ถ้า VM อาจารย์ใช้ไม่ได้ ให้รัน monitoring stack ทั้งชุดบนเครื่อง dev (ปรับปลายทาง tunnel เป็น Tailscale)

**ข้อจำกัดที่ต้องรู้**
- Alert ถูกส่งออกจาก VM อาจารย์ → **ถ้า session ม. หมด Discord จะไม่ได้รับ alert** ต้องล็อกอินใหม่ตอนเช้าวัน demo และตรวจก่อนขึ้นพรีเซนต์
- Wazuh server กิน RAM/ดิสก์มาก (ประมาณ 4–8 GB RAM ยังไม่ยืนยันตัวเลขล่าสุด ตรวจเอกสาร Wazuh) → รันบนเครื่อง dev ที่ต้องเคลียร์ดิสก์ก่อน (เหลือ ~3.5 GB)

---

## 3. แผนผังพอร์ตและ tunnel

| ที่ | บริการ | พอร์ต | การเข้าถึง |
|---|---|---|---|
| Azure | api (NestJS) | 8080 | ภายใน Docker network เท่านั้น |
| Azure | `/metrics` ของ api, worker metrics | 8080 `/metrics`, worker `9464` | **ภายใน network เท่านั้น ห้ามผ่าน proxy สู่สาธารณะ** |
| Azure | node 9100, cAdvisor 8081, postgres-exp 9187, redis-exp 9121 | — | ภายใน network ให้ Alloy scrape |
| Azure | ปลาย tunnel Prometheus | `127.0.0.1:9090` | เฉพาะ loopback (Alloy `network_mode: host`) |
| Azure | ปลาย tunnel Loki | `127.0.0.1:3100` | เฉพาะ loopback |
| VM อาจารย์ | Prometheus 9090 · Loki 3100 · Grafana 3000 | — | **ไม่ publish ออกนอกเครื่อง** Grafana เข้าผ่าน `ssh -L 3000:localhost:3000` หรือ bind `127.0.0.1` |

**User `tunnel` บน Azure** (ไม่มี sudo ไม่มี shell) `authorized_keys`:

```
restrict,port-forwarding,permitlisten="127.0.0.1:3100",permitlisten="127.0.0.1:9090" ssh-ed25519 <public key ของ <TUNNEL_KEY_COMMENT>> <TUNNEL_KEY_COMMENT>
```

**tunnel container บน VM อาจารย์** (autossh, อยู่ใน compose network เดียวกับ prometheus/loki):

```
autossh -M 0 -N \
  -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o ExitOnForwardFailure=yes \
  -i /keys/id_azure_tunnel \
  -R 127.0.0.1:9090:prometheus:9090 \
  -R 127.0.0.1:3100:loki:3100 \
  <TUNNEL_USER>@<AZURE_VM_PUBLIC_IP>
```
`restart: unless-stopped`; mount private key แบบ read-only จากไฟล์ที่ไม่อยู่ใน git; ถ้า `permitlisten` ไม่ match ให้ดู `/var/log/auth.log` บน Azure และปรับตามนั้น

---

## 4. กติกาสำหรับ Claude Code (ต้องทำตามทุกเฟส)

1. ทำ **ทีละเฟส** จบเฟสแล้วหยุด แสดง diff + ผลตรวจตามเกณฑ์เสร็จ **รอผู้ใช้ยืนยัน** ก่อนเริ่มเฟสถัดไป
2. ห้ามอ่าน/พิมพ์/commit: `.env*`, `~/.ssh/*` (private key), webhook URL, token, รหัสผ่าน ใช้ตัวแปรสภาพแวดล้อม/ไฟล์ที่อยู่ใน `.gitignore` และเขียน `*.example` แทน
3. config ทั้งหมดอยู่ใน `infra/monitoring/` เท่านั้น (compose, prometheus, loki, alloy, grafana/provisioning, alert rules) ต้อง rebuild ได้จาก git
4. ห้ามแตะ stack อื่นบนเครื่อง (โดยเฉพาะ `flash-sale-system`) ห้าม `docker system prune`, `docker volume prune`, `down -v`
5. ห้ามแก้พอร์ต/firewall/NSG/sshd เอง ให้ **เสนอคำสั่งให้ผู้ใช้รัน**
6. ทุก container ตั้ง `mem_limit` และ `restart: unless-stopped`; image ปักเวอร์ชัน (ห้าม `latest`)
7. การแก้ `apps/server/` ให้เป็น PR/commit แยก ขนาดเล็ก พร้อมเทสต์ที่มีอยู่ต้องผ่าน (unit 216 ตัว)
8. ห้ามใส่ข้อมูลส่วนบุคคล (อีเมล, PIN, token, password) ลงใน log หรือ metric label และห้ามใช้ user id เป็น label
9. ทุกคำสั่งที่เปลี่ยนสถานะระบบ ต้องบอกก่อนว่าจะทำอะไรและย้อนกลับอย่างไร

---

## 5. เฟสงาน

### เฟส 0 — ความปลอดภัยและพื้นฐาน (ผู้ใช้ทำเอง ~15 นาที)

| งาน | ที่ไหน |
|---|---|
| สร้าง user `<TUNNEL_USER>` + จำกัด key ตามข้อ 3 แล้วลบบรรทัด `<TUNNEL_KEY_COMMENT>` ออกจาก `authorized_keys` ของ `<VM_ADMIN_USER>` | Azure |
| ตรวจ Public IP: `az network public-ip show -g <RESOURCE_GROUP> -n <PUBLIC_IP_RESOURCE> --query "{ip:ipAddress, alloc:publicIPAllocationMethod, sku:sku.name}" -o table` ต้องเป็น Static/Standard | Cloud Shell |
| ตั้ง DNS name label (เช่น `<AZURE_DNS_LABEL>`) → ได้โดเมน `*.malaysiawest.cloudapp.azure.com` | Portal |
| NSG: เปิด 80/443 สาธารณะ; พอร์ต 22 จำกัด IP; **ห้ามเปิด 9090/3100/3000** | Portal |
| สำรอง config เก่า: `cp -r /srv/project_backend/FlashSaleSystem ~/flash-sale-backup` (ไม่ลบอะไร) | VM อาจารย์ |
| `docker stop flash-sale-system-nginx-1` (รีสตาร์ทวนเพราะ upstream `api-3` หาย) | VM อาจารย์ |
| ตั้ง swap 2–4 GB บน VM อาจารย์ (ถ้าไม่ผิดนโยบายเครื่อง) | VM อาจารย์ |
| clone repo บน Azure (ที่ Claude Code ทำงาน) และบน VM อาจารย์ (`git pull` ใช้ deploy) | ทั้งสอง |

**เสร็จเมื่อ:** tunnel user ทดสอบแล้วทำได้แค่ port forward (เข้า shell ไม่ได้), โดเมนเปิดถึง Azure, สำรองของเก่าแล้ว

### เฟส 1 — Monitoring stack บน VM อาจารย์ (DP-500, DP-501)
- `infra/monitoring/docker-compose.yml`: prometheus (เปิด `--web.enable-remote-write-receiver`, retention 7–15 วัน), loki (retention 7 วัน, filesystem storage), grafana (provision datasources/dashboards เป็นไฟล์), blackbox_exporter, tunnel (ยังไม่เปิดใช้จนกว่าเฟส 3)
- ทุกพอร์ต bind `127.0.0.1` หรือไม่ publish; Grafana admin password จาก env; สร้างบัญชี viewer แยก
- เพิ่ม scrape ตัวเอง (prometheus, node-exporter ของเครื่อง) เพื่อพิสูจน์ว่ากราฟขึ้น
- นำ dashboard/config ที่ใช้ได้จาก `flash-sale-system` มาปรับ (ตรวจเวอร์ชันก่อนก๊อป)

**เสร็จเมื่อ:** เปิด Grafana ผ่าน SSH tunnel เห็น metrics ของ VM อาจารย์เอง; `docker stats` ทุก container ไม่เกิน mem_limit; รวม RAM ที่ใช้ < ~1.5 GB (ตัวเลขประมาณการ วัดจริงแล้วบันทึก)

### เฟส 2 — Instrument backend (`apps/server/`) (ฐานของ DP-501/502/503)
1. **`/metrics`** ด้วย `prom-client` หรือ `@willsoto/nestjs-prometheus`: ใส่ `@Public()`; label เป็น **route pattern** (`/subscriptions/:id`); มี default metrics (event loop, heap)
2. **Business metrics** (เป็นข้อมูลรวม): `auth_login_total{result}`, `subscriptions_created_total`, `http_requests_total{route,method,status}`, `http_request_duration_seconds` (histogram), gauge จำนวนผู้ใช้ active (นับจาก session/token ใน window ไม่ใช่ label รายคน)
3. **Worker:** เปิด metrics endpoint ภายใน (พอร์ต 9464) และ export queue `renewal-reminder`: waiting/active/failed/delayed จาก `getJobCounts()`
4. **Logging:** `nestjs-pino` เป็น JSON, มี `requestId`, redact `authorization`, `password`, `pin`, `token`; ระดับ log ตาม env
5. **Health:** แยก `/health/live` และ `/health/ready`; ready ตรวจ Postgres + Redis (ยัง `@Public()`)
6. **Sentry (DP-503):** `@sentry/nestjs` เปิดเมื่อมี `SENTRY_DSN` เท่านั้น; ใช้ SaaS free tier; ตั้ง `beforeSend` ตัดข้อมูลอ่อนไหว
7. **ห้ามให้ proxy ส่ง `/metrics` ออกสาธารณะ:** เพิ่มกฎ block ใน nginx (`location = /metrics { return 404; }`) และไม่ publish พอร์ต api

**เสร็จเมื่อ:** `curl` ภายใน network ได้ `/metrics`; `curl https://<โดเมน>/metrics` ได้ 404; unit/e2e เดิมผ่าน; log เป็น JSON และไม่มีค่าอ่อนไหว

### เฟส 3 — ฝั่ง prod + เชื่อมสองเครื่อง (DP-500, DP-501)
- (ประสานกับ nawaphonST1) deploy prod stack บน Azure + **HTTPS** (แนะนำ Caddy ด้านหน้า nginx ใช้โดเมน Azure; ข้อสุดท้ายต้องตัดสินใจร่วมกับทีม)
- `infra/monitoring/prod-agent/docker-compose.yml`: node_exporter, cAdvisor, postgres_exporter, redis_exporter, Alloy (`network_mode: host`) — Alloy scrape api/worker/exporters → `remote_write` `http://127.0.0.1:9090/api/v1/write`; tail log ของ container + nginx → Loki `http://127.0.0.1:3100`
- nginx เปลี่ยน access log เป็น JSON (มี `remote_addr`, `status`, `request_time`, `request`) เพื่อใช้ดูที่มาของ traffic
- เปิด tunnel container บน VM อาจารย์ (ผู้ใช้ล็อกอิน PSU ก่อน)
- ทดสอบตัด tunnel (`docker stop tunnel` 3 นาที แล้วเปิดใหม่): ข้อมูลช่วงนั้นต้องกลับมา (บันทึกว่ากลับมาได้ครบหรือไม่)

**เสร็จเมื่อ:** Grafana เห็น metrics + log ของ prod ที่ส่งมาจริง; ทำ request ทดสอบแล้วเห็นใน Explore ภายใน 1 นาที

### เฟส 4 — Dashboard (DP-502) · provision เป็นไฟล์ JSON ใน git
1. **Host & Containers** (node + cAdvisor): CPU, RAM, ดิสก์, network, restart
2. **API (RED):** Rate, Errors (5xx %), Duration p50/p95/p99, แยก route
3. **ผู้ใช้:** login สำเร็จ/ล้มเหลว, subscription ที่สร้าง, ผู้ใช้ active, top endpoints, ที่มา traffic จาก nginx log (Loki)
4. **Data stores & Queue:** Postgres connections/transactions, Redis memory/ops, BullMQ waiting/failed
5. **Logs:** Explore/dashboard log แยก level, ตัวกรอง requestId

**เสร็จเมื่อ:** 5 dashboard โหลดได้จากการ provision (ลบแล้วสร้างใหม่ได้จาก git)

### เฟส 5 — Alert (DP-504 ปรับเป็น Grafana alerting; **ตัด Alertmanager แยก**)
Contact point: Discord webhook (เก็บ URL ใน env/secret ของ Grafana, ไม่ commit) + อีเมลเป็นตัวเสริม (ถ้ามี SMTP)

| Alert | เงื่อนไข (เริ่มต้น ปรับตามจริง) | ระดับ |
|---|---|---|
| API ล่ม | blackbox probe `/health/ready` ล้ม > 2 นาที | critical |
| 5xx สูง | 5xx > 5% ใน 5 นาที | critical |
| Latency สูง | p95 > 1 วินาที ต่อเนื่อง 5 นาที | warning |
| ดิสก์ใกล้เต็ม | > 85% | warning |
| RAM/CPU สูง | RAM ว่าง < 10% / CPU > 90% 10 นาที | warning |
| Container restart ถี่ | restart > 3 ใน 10 นาที | warning |
| Postgres/Redis ล่ม | exporter รายงาน down | critical |
| BullMQ failed เพิ่ม | failed jobs เพิ่มต่อเนื่อง | warning |
| ข้อมูลจาก prod หาย | ไม่มี sample > 5 นาที (**แยกจาก "API ล่ม"** เพราะอาจเป็น tunnel/session หลุด) | warning |

ตั้ง `noDataState` ให้ถูกต้อง เพื่อไม่ให้เตือนผิดตอน session ม. หมด
**เสร็จเมื่อ:** `docker stop` api บน Azure → alert เข้า Discord ภายในเวลาที่คาด; กลับมาแล้วมีข้อความ resolved

### เฟส 6 — Sentry (DP-503)
สร้างโปรเจกต์ Sentry (SaaS) ใส่ DSN ผ่าน env บน prod; ยิง error ทดสอบ; ส่งแจ้งเตือนเข้า Discord/อีเมลจาก Sentry; (Flutter ค่อยทำเมื่อแอปเชื่อม backend)

### เฟส 7 — Load test ด้วย k6 (รันจากเครื่อง dev ไม่ใช่บน prod)
- สคริปต์ใน `infra/loadtest/`: login → list subscriptions → create/delete; มี ramp-up (เช่น 10 → 50 → 100 VUs, ปรับตามจริง) และ threshold (`http_req_failed < 1%`, `p(95) < 1s`)
- ใช้ผู้ใช้ทดสอบ/ข้อมูล mock เท่านั้น **ห้ามรันกับระบบอื่น**
- สังเกต CPU credit ของ B-series ใน Azure ระหว่างทดสอบ (burstable อาจถูกบีบ) และพิจารณา resize ล่วงหน้า (ไม่ใช่วัน demo; ต้อง deallocate และตรวจโควตา)

**เสร็จเมื่อ:** รัน k6 แล้วกราฟ RED พุ่งตามโหลดใน Grafana และบันทึกผล (RPS, p95, error%, จุดที่เริ่มช้า)

### เฟส 8 — Wazuh (DP-505)
- **Server:** บนเครื่อง dev ด้วย Wazuh Docker single-node (ตรวจเอกสารทางการ, ตั้ง `vm.max_map_count` ตามที่กำหนด) **เคลียร์ดิสก์เครื่อง dev ก่อน**
- **เชื่อม:** ติดตั้ง Tailscale บนเครื่อง dev + Azure (เครื่องของเราทั้งคู่); agent เชื่อมไป manager ผ่าน IP ของ Tailscale (พอร์ต 1514/1515 ไม่เปิดสู่สาธารณะ)
- **Agent บน Azure:** เก็บ auth log (SSH), nginx/Caddy log, File Integrity Monitoring ของโฟลเดอร์ config
- **Use case สำหรับ demo:** SSH brute-force, สแกนพอร์ต/พาธแปลกๆ จาก nginx log, การแก้ไฟล์ config สำคัญ
- **จำลองโจมตีเฉพาะระบบของเราเอง** (Azure) จากเครื่องที่ควบคุมได้ — **ห้ามยิงใส่ VM อาจารย์หรือเครือข่าย ม.**
- ถ้าเวลาไม่พอ: ทำเฉพาะ agent + log ส่งเข้า Loki และอธิบายว่า server เต็มรูปแบบเป็นงานต่อยอด

**เสร็จเมื่อ:** agent ขึ้น Active ใน dashboard Wazuh และเห็น alert จากการทดสอบอย่างน้อย 1 กรณี

### เฟส 9 — เอกสารและ backlog
- อัปเดต `system_architecture_v2.md` (§5, §7, §8): topology แบบ B, monitoring จริง, สิ่งที่เปลี่ยนจาก backlog
- แก้ sheet: DP-500 (ไม่ใช้ Helm/K8s), DP-501/502 (ไม่ใช้ Traefik), DP-504 (Grafana alerting แทน Alertmanager), DP-503 (SaaS), สถานะจริงของ DP-500…505
- README หัวข้อ "Monitoring": วิธีเปิด/ปิด, วิธีเข้า Grafana, วิธี recovery เมื่อ tunnel หลุด

---

## 6. เช็กลิสต์ก่อน demo (วัน demo เช้า)

- [ ] ล็อกอิน PSU บน VM อาจารย์ (session หมดอายุ ~1 วัน)
- [ ] tunnel ต่ออยู่, Grafana เห็นข้อมูลใหม่ในช่วง 1 นาทีที่ผ่านมา
- [ ] `https://<โดเมน>` เปิดได้จากมือถือเน็ตมือถือ (ไม่ใช่ Wi-Fi ม.)
- [ ] ส่ง alert ทดสอบเข้า Discord สำเร็จ
- [ ] Wazuh server ขึ้นบนเครื่อง dev และ agent ออนไลน์
- [ ] k6 ทดสอบสั้นๆ 1 รอบ ใช้ได้
- [ ] ถอด Claude Code และ key ที่ไม่จำเป็นออกจาก VM prod (ถ้าตั้งใจ) / เปลี่ยนรหัสผ่านที่ใช้ระหว่างพัฒนา
- [ ] แผนสำรอง: monitoring ทั้งชุดรันบนเครื่อง dev ได้ (ทดสอบแล้ว)
- [ ] หลัง demo: ลบกฎ NSG `Allow-SSH-PSU-VM`, ลบ user/key ชั่วคราว, ลด/ปิด VM เพื่อประหยัดเครดิต

## 7. ความเสี่ยงที่ยังเปิดอยู่

| ความเสี่ยง | ผลกระทบ | ทางลด |
|---|---|---|
| Session ม. หมดระหว่าง demo | alert ไม่ออก, tunnel หลุด | ล็อกอินใหม่ก่อนขึ้นพรีเซนต์; autossh ต่อใหม่เอง; ตรวจเช็กลิสต์ |
| IP ออกเน็ตของ ม. เปลี่ยน | NSG บล็อก SSH | ตรวจ `curl ifconfig.me` ก่อน demo แล้วอัปเดต NSG |
| B2als v2 (burstable) CPU credit หมดตอน load test | ผลทดสอบต่ำกว่าจริง | ดูเมตริก CPU credit; พิจารณา resize ก่อนล่วงหน้า |
| RAM VM อาจารย์ 5.8 GB ไม่มี swap | OOM | mem_limit ทุก container, swap, ปิดของเก่าที่ไม่ใช้ |
| ดิสก์เครื่อง dev เต็ม | Wazuh รันไม่ได้ | เคลียร์ก่อนเฟส 8 |
| แก้ `apps/server/` กระทบงานทีม | conflict | PR เล็ก แจ้งทีมก่อน |
| รหัส PSU / key รั่ว | เข้าถึงเครือข่าย/เครื่อง | พิมพ์รหัสเอง ไม่เก็บในสคริปต์; key ไม่เข้า git; ใช้ user `tunnel` สิทธิ์ต่ำ |

## 8. ประเด็นที่ยังต้องตัดสินใจ

1. **HTTPS บน prod:** Caddy หน้า nginx หรือเปลี่ยนเป็น Caddy ล้วน (ต้องคุยกับ nawaphonST1)
2. **ใครเป็นคน deploy prod stack บน Azure** และเมื่อไหร่ (เฟส 3 ต้องใช้)
3. **ปรับขนาด Azure VM ก่อน demo ไหม** (ตรวจโควตา/ราคาในหน้า Azure ก่อน ยังไม่ได้ยืนยันตัวเลข)
4. **Sentry:** SaaS ใช้ org/บัญชีของใคร
