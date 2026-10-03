# Monitoring stack (DP-5 เฟส 1)

Prometheus + Loki + Grafana + blackbox-exporter + node-exporter สำหรับ **VM monitoring (เครื่องอาจารย์)**
ตามแผน [`doc/architecture/DP5_monitoring_plan.md`](../../doc/architecture/DP5_monitoring_plan.md) เฟส 1

> stack นี้ **ไม่ได้ออกแบบให้รันบน VM production (Azure)** ฝั่ง production จะมีชุดของตัวเอง
> (`infra/monitoring/prod-agent/` — exporters + Grafana Alloy) ซึ่งเป็นงานของเฟส 3

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | หน้าที่ |
|---|---|
| `docker-compose.yml` | นิยาม service ทั้งหมด (project name: `subscription-monitoring`) |
| `.env.example` | แม่แบบของ `.env` — คัดลอกแล้วเติมค่าจริงบนเครื่อง (ไม่เข้า git) |
| `prometheus/prometheus.yml` | scrape ตัวเอง + node-exporter + blackbox probe; เปิดรับ remote_write จาก production (เฟส 3) |
| `loki/loki-config.yml` | single-binary, filesystem storage, retention 7 วัน |
| `blackbox/blackbox.yml` | module `http_2xx` |
| `grafana/provisioning/` | datasource (Prometheus/Loki) + ตัวโหลด dashboard — provision จากไฟล์ล้วน |
| `grafana/dashboards/host-overview.json` | dashboard สุขภาพเครื่อง 6 panel |
| `tunnel/Dockerfile` | autossh สำหรับ reverse tunnel ไป Azure (เฟส 3 เท่านั้น) |

## 1. เตรียม `.env`

```bash
cd infra/monitoring
cp .env.example .env
openssl rand -base64 24          # เอาค่าที่ได้ไปใส่ GRAFANA_ADMIN_PASSWORD
$EDITOR .env
```

`.env` ถูก git-ignore ทั้งในไฟล์นี้และที่ root — **ห้าม commit** ถ้าไม่ตั้ง `GRAFANA_ADMIN_PASSWORD`
docker compose จะปฏิเสธการสตาร์ตพร้อมข้อความบอก ไม่มีรหัสผ่านเริ่มต้นแอบอยู่ในไฟล์ไหนทั้งสิ้น

`AZURE_HOST` ใช้เฉพาะ service `tunnel` (เฟส 3) ระหว่างเฟส 1 ใส่ค่า placeholder ไว้ก่อนได้

## 2. ดึง image ล่วงหน้า (ตอนที่ยังล็อกอิน PSU อยู่)

เครื่องนี้ออกเน็ตได้เฉพาะหลังล็อกอิน captive portal (session ~1 วัน) ให้ดึง image ตอนที่เน็ตยังใช้ได้
หลังจากนั้น stack จะ `up`/restart ได้แม้เน็ตหลุด

```bash
cd infra/monitoring
docker compose pull                      # 5 service หลัก
docker compose --profile tunnel build    # เฉพาะตอนจะใช้ tunnel (เฟส 3) — ต้องมีเน็ตเพราะ apk add
```

## 3. เปิด / ปิด / ดู log

```bash
cd infra/monitoring
docker compose up -d
docker compose ps
docker compose logs -f prometheus        # หรือ loki / grafana / blackbox / node-exporter
docker compose stop                      # หยุดชั่วคราว
docker compose down                      # ลบ container แต่ "เก็บ volume ข้อมูลไว้"
```

> **ห้าม `docker compose down -v`** — `-v` ลบ volume `prom-data` / `loki-data` / `grafana-data` ทิ้งทั้งหมด
> และ **ห้าม `docker system prune` / `docker volume prune`** บนเครื่องนี้ เพราะมี stack `flash-sale-system` ของโปรเจกต์อื่นอยู่

## 4. เข้า Grafana

ไม่มีพอร์ตไหน publish ออกนอกเครื่องเลย ทุกพอร์ต bind `127.0.0.1` → ต้องเข้าผ่าน SSH port forward จากเครื่องตัวเอง:

```bash
ssh -L 3000:localhost:3000 <user>@<ไอพีของ VM อาจารย์>
# แล้วเปิดเบราว์เซอร์ที่ http://localhost:3000   (user: admin, password: ค่าใน .env)
```

ถ้าอยากดู Prometheus UI หรือยิง query ตรงๆ ก็ forward เพิ่มได้ `-L 9090:localhost:9090`

## 5. ตรวจหลังเปิดครั้งแรก

```bash
# ทุก container ต้อง Up และไม่มี restart วน
docker compose ps

# ทุก target ต้อง "up"  (prometheus, monitoring-host, blackbox-http)
curl -s localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job:.labels.job, health:.health, err:.lastError}'

# Loki พร้อมรับ log แล้ว (เฟส 1 ยังไม่มีใครส่งเข้ามา ถือว่าถูกต้อง)
curl -s localhost:3100/ready

# blackbox probe ผ่าน (ต้องได้ probe_success 1)
curl -s 'localhost:9090/api/v1/query?query=probe_success' | jq '.data.result'

# การใช้ RAM จริงของแต่ละ container เทียบกับ mem_limit
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}'

# ไม่มีพอร์ตไหนโผล่บน 0.0.0.0 และ stack ของ flash-sale ต้องยังครบเท่าเดิม
ss -ltnp | grep -E ':(9090|3100|3000)\b'
docker ps --format '{{.Names}}\t{{.Status}}'
```

ใน Grafana: **Connections → Data sources** ต้องเห็น Prometheus (default) กับ Loki และกด *Save & test* ขึ้น
"Data source is working" · **Dashboards** ต้องมี *Host Overview (Monitoring VM)* ที่มีกราฟจริง

ทดสอบว่า provision จาก git ได้จริง: `docker compose down && docker compose up -d` แล้ว datasource/dashboard ต้องกลับมาเอง

## 6. งบ RAM

| service | `mem_limit` |
|---|---|
| prometheus | 512 MiB |
| loki | 512 MiB |
| grafana | 384 MiB |
| blackbox | 64 MiB |
| node-exporter | 64 MiB |
| **รวมที่รันในเฟส 1** | **1536 MiB** |
| tunnel (เฟส 3) | 32 MiB |
| **รวมสูงสุด** | **1568 MiB** |

นี่คือ *เพดาน* ไม่ใช่การใช้จริง (คาดว่าจริงต่ำกว่านี้มากตอนยังไม่มีข้อมูลจาก production)
ถ้า `docker stats` ชี้ว่า Prometheus หรือ Loki ชนเพดานบ่อย **อย่าเพิ่มเอง** ให้บันทึกตัวเลขแล้วคุยกันก่อน

## 7. ดิสก์ / retention

- Prometheus: `--storage.tsdb.retention.time=10d` **และ** `--storage.tsdb.retention.size=3GB` (อันหลังคือตัวที่กันดิสก์จริง)
- Loki: `retention_period: 168h` (7 วัน) โดยมี compactor เปิด `retention_enabled: true`
- log ของ Docker เอง: จำกัด 10 MiB × 3 ไฟล์ ต่อ container (anchor `x-logging`)

## 8. ข้อจำกัดที่รู้อยู่ (อ่านก่อนตีความกราฟ)

1. **node-exporter เห็น network ของ container ไม่ใช่ของ host** — เราเลือกรันบน bridge network (ไม่ใช้
   `network_mode: host`) เพราะ host networking จะทำให้ node-exporter เปิดพอร์ต 9100 บนเครื่องและเสี่ยงชนกับ
   node-exporter ของ `flash-sale-system` ที่รันอยู่ก่อน ผลคือ **CPU / RAM / ดิสก์ เป็นของ host จริง**
   (เพราะ `pid: host` + `--path.rootfs=/host`) แต่ `node_network_*` เป็นของ namespace ใน container
   panel "Network I/O" จึงใช้ดูได้แค่ว่ามีชีวิตอยู่ · ตัวเลข network ของ **เครื่อง production** จะได้จาก
   exporter ที่ติดตั้งบน Azure ในเฟส 3 ซึ่งตั้ง host networking ได้เต็มที่
2. **`out_of_order_time_window: 1h` ยังไม่ได้ทดสอบจริง** — ตั้งไว้เพื่อให้ Alloy ส่งข้อมูลย้อนหลังเข้ามาได้
   หลัง tunnel หลุด **ต้องพิสูจน์ในเฟส 3** ด้วยการ `docker compose stop tunnel` 3 นาที แล้วเปิดใหม่
   และดูว่าช่วงที่ขาดหายเติมกลับมาครบหรือไม่
3. **blackbox probe ตอนนี้ยิงเป้าหมายภายใน** (`http://grafana:3000/api/health`) เพื่อพิสูจน์ว่าการต่อสาย
   blackbox ↔ Prometheus ถูกต้องตั้งแต่เฟส 1 · เฟส 3 ให้เปลี่ยน target เป็น `https://<โดเมน prod>/health/ready`
4. **Loki ยังไม่มี log เข้าเลยในเฟส 1** — ผู้ส่ง (Alloy บน Azure) มาในเฟส 3 ดังนั้น Explore ของ Loki ที่ว่างเปล่า
   คือพฤติกรรมที่ถูกต้อง

## 9. ทำไมเปิด remote-write receiver แล้วยังปลอดภัย

`--web.enable-remote-write-receiver` ทำให้ Prometheus รับข้อมูลที่ถูก *push* เข้ามาได้ ซึ่งปกติเป็นช่องทางที่ต้องระวัง
แต่ในสถาปัตยกรรมนี้:

- พอร์ต 9090 ถูก publish แบบ `127.0.0.1:9090:9090` → เข้าถึงได้เฉพาะจากตัวเครื่องนี้เอง ไม่ใช่จาก LAN ของมหาวิทยาลัย
- ทางเดียวที่ production จะส่งเข้ามาได้คือ **reverse SSH tunnel ที่เครื่องนี้เป็นฝ่ายเปิดออกไปเอง** (เฟส 3)
  ปลายทางฝั่ง Azure ก็ bind `127.0.0.1` และ key ของ user `tunnel` ถูกจำกัดด้วย
  `restrict,port-forwarding,permitlisten=...` ทำ shell ไม่ได้
- ไม่มีการเปิดพอร์ตขาเข้าบนเครื่องนี้แม้แต่พอร์ตเดียว และไม่ต้องแก้ firewall ของมหาวิทยาลัย

## 10. tunnel (เฟส 3) — เตรียม `secrets/`

`secrets/` ถูก git-ignore สร้างบนเครื่องนี้เท่านั้น ประกอบด้วย

| ไฟล์ | คืออะไร |
|---|---|
| `secrets/id_azure_tunnel` | private key (ไม่มี passphrase) ของ user `tunnel` บน Azure · `chmod 600` |
| `secrets/known_hosts` | host key ของ Azure ที่ **ตรวจ fingerprint ด้วยตาแล้ว** |

**ห้ามใช้ `StrictHostKeyChecking=no`** — compose ตั้ง `StrictHostKeyChecking=yes` ไว้แล้วและอ่าน known_hosts จากไฟล์นี้
วิธีสร้างแบบตรวจ fingerprint จริง:

```bash
# (1) บน Azure (ผ่าน session ที่เชื่อถือได้อยู่แล้ว) — อ่าน fingerprint ของ host key
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub

# (2) บน VM อาจารย์ — ดึง host key มาเก็บ
mkdir -p infra/monitoring/secrets && chmod 700 infra/monitoring/secrets
ssh-keyscan -t ed25519 <AZURE_HOST> > infra/monitoring/secrets/known_hosts

# (3) เทียบ fingerprint ของสิ่งที่เพิ่งดึงมา กับค่าที่อ่านได้ในข้อ (1) — ต้องตรงกันทุกตัวอักษร
ssh-keygen -lf infra/monitoring/secrets/known_hosts
```

ถ้าสองค่าไม่ตรงกัน **อย่าใช้ต่อ** ให้สงสัยว่าถูกดักกลางแล้วตรวจเส้นทางเน็ตก่อน

เปิด tunnel:

```bash
cd infra/monitoring
docker compose --profile tunnel build
docker compose --profile tunnel up -d
docker compose logs -f tunnel
```

ฝั่ง Azure ตรวจว่าปลายทางขึ้นจริง: `ss -ltnp | grep -E '127\.0\.0\.1:(9090|3100)'`
ถ้า forward ไม่ขึ้น ให้ดู `/var/log/auth.log` บน Azure ว่า `permitlisten` ตรงกับที่ขอ forward หรือไม่

## 11. กู้คืนเมื่อ session มหาวิทยาลัยหมด

อาการ: Grafana ไม่มีข้อมูลใหม่จาก production, log ของ `tunnel` ขึ้น timeout / connection closed

1. ล็อกอิน captive portal ของมหาวิทยาลัยใหม่ (พิมพ์รหัสเอง)
2. ตรวจว่าเน็ตออกได้: `curl -s -o /dev/null -w '%{http_code}\n' https://example.com`
3. ตรวจว่า IP ขาออกยังตรงกับที่ NSG อนุญาต: `curl -s ifconfig.me` — ถ้าเปลี่ยนต้องอัปเดตกฎ NSG ก่อน
4. autossh ปกติต่อกลับเอง ถ้าไม่กลับภายใน ~1 นาที: `docker compose --profile tunnel restart tunnel`
5. ยืนยันว่าข้อมูลไหลอีกครั้ง: ใน Grafana Explore ดูว่ามี sample ใหม่ภายใน 1 นาทีล่าสุด

Prometheus/Loki/Grafana **ไม่ต้องรีสตาร์ต** ตอนเน็ตหลุด — ทั้งสามตัวไม่ได้ต้องการอินเทอร์เน็ตขาออกเลย

## 12. อยู่ร่วมกับ `flash-sale-system` บนเครื่องเดียวกัน

- project name ของเราคือ `subscription-monitoring` → network / volume / container ทั้งหมดมี prefix ของตัวเอง
- ไม่มี `container_name:` ตายตัวในไฟล์นี้ จึงไม่มีทางชนชื่อกับ stack อื่น
- พอร์ตที่เราจอง: `127.0.0.1` เท่านั้น ที่ 9090 / 3100 / 3000 (ตรวจว่าว่างก่อนด้วย `ss -ltnp`)
- node-exporter ของเราไม่ publish พอร์ตเลย จึงไม่ชนกับ node-exporter ของ flash-sale ที่ใช้ 9100
