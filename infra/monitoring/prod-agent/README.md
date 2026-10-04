# prod-agent — ชุด agent ฝั่ง production (DP-5 เฟส 3a)

รันบน **VM Azure (production)** เท่านั้น ข้างๆ app stack (`docker-compose-prosuction.yml` ที่ root)
ไม่ใช่ monitoring stack — ตัวนั้นอยู่ที่ [`../docker-compose.yml`](../docker-compose.yml) และรันบน VM อาจารย์

```
app stack (api, worker, postgres, redis, nginx)
   │  /metrics 127.0.0.1:9464 / :9465        (compose override ในโฟลเดอร์นี้)
   │  stdout/stderr ของทุก container          (docker.sock :ro)
   ▼
node_exporter · cAdvisor · postgres_exporter · redis_exporter   ← ทุกตัว bind 127.0.0.1
   ▼  scrape ผ่าน loopback
Grafana Alloy (network_mode: host)
   ├── remote_write → http://127.0.0.1:9090/api/v1/write   ─┐ ปลาย reverse SSH tunnel
   └── loki.write   → http://127.0.0.1:3100/loki/api/v1/push ┘ (เปิดจากฝั่ง VM อาจารย์)
```

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | หน้าที่ |
|---|---|
| `docker-compose.yml` | exporters + Alloy (project name: `subscription-prod-agent`) |
| `config.alloy` | scrape → remote_write, อ่าน log ของ container → Loki, parse nginx access log |
| `docker-compose.app-metrics.override.yml` | **override ของ app stack** publish `127.0.0.1:9464/9465` ให้ Alloy scrape ได้ |
| `.env.example` | แม่แบบของ `.env` (ชื่อ network ของ app + connection string ของ exporter) |
| `tests/log-pipeline/` | เทสต์จริงของ pipeline nginx — ดู §6 |

## 1. ทำไม Alloy ต้อง `network_mode: host`

ปลายทางของ reverse tunnel คือ **loopback ของ host** (`127.0.0.1:9090`, `127.0.0.1:3100`)
container ที่อยู่บน bridge network มี loopback ของตัวเอง จึงยิงไปไม่ถึง และเราจะไม่แก้ด้วยการให้ tunnel
bind ที่ IP ที่ route ได้ (นั่นคือการเปิดพอร์ต monitoring ออกสู่เน็ตเวิร์ก — ผิด §3 ของแผน)

ผลข้างเคียงที่ยอมรับและปิดความเสี่ยงแล้ว:

- HTTP server ของ Alloy เองจะอยู่บน host network → บังคับ `--server.http.listen-addr=127.0.0.1:12345`
- Alloy resolve ชื่อ compose (`api`, `worker`, `postgres`) ไม่ได้ → จึงต้องมี compose override publish พอร์ต
  metrics ที่ loopback และ exporter สองตัวที่ต้องคุยกับ postgres/redis ถูกต่อเข้า network ของ app แทน
  (ดู `networks.app` ใน `docker-compose.yml`)
- image ของ Alloy รันเป็น root อยู่แล้ว (ค่า default ของ upstream) จึงอ่าน `docker.sock` ได้โดยไม่ต้อง
  เพิ่ม group — และ socket ถูก mount แบบ `:ro`

exporter ตัวอื่น **ไม่** ใช้ host network: publish ที่ `127.0.0.1:<port>` เพื่อไม่ให้ชนพอร์ตบนเครื่อง
และไม่โผล่ออกสู่สาธารณะ

## 2. งบหน่วยความจำ (เพดานรวม 512 MiB บน B2als v2 — 2 vCPU / 4 GiB)

| service | `mem_limit` | เหตุผล |
|---|---|---|
| node_exporter | 32 MiB | ตัวเล็ก ไม่มี state |
| redis_exporter | 48 MiB | |
| postgres_exporter | 64 MiB | query หลายชุดต่อ scrape |
| cAdvisor | 224 MiB | ตัวกินแรมที่สุด จึงหั่น metric/housekeeping ลง (ดูคอมเมนต์ใน compose) |
| Alloy | 128 MiB | WAL + queue ของ remote_write |
| **รวม** | **496 MiB** | เหลือ headroom 16 MiB จากเพดาน |

## 3. WAL และพฤติกรรมตอน tunnel ขาด

`prometheus.remote_write` เก็บ sample ที่ยังส่งไม่สำเร็จไว้ใน WAL ใต้ `--storage.path=/var/lib/alloy/data`
ซึ่งผูกกับ **named volume `alloy-data`** (ไม่ใช่ที่ว่างใน container) ถ้าไม่ทำแบบนี้ ทุกครั้งที่ restart
Alloy จะเริ่มจาก WAL ว่าง และข้อมูลที่ยังไม่ถูก push จะหายเงียบๆ — ตรงกับเคส S3 ที่เฟส 1.5 วัดได้

| เหตุการณ์ | ผล |
|---|---|
| tunnel ขาด (session ม. หมด) Alloy ยังรัน | sample ค้างใน WAL แล้ว replay เมื่อ tunnel กลับมา — เฟส 1.5 S1/S2 คืนครบ 100% |
| tunnel ขาด **และ** Alloy restart ในช่วงเดียวกัน | ข้อมูลช่วงนั้นหายได้บางส่วน (เฟส 1.5 S3 คืน 66.7%) — **KNOWN-LIMITATION** |
| volume `alloy-data` ถูกลบ | เหมือนเริ่มใหม่ ข้อมูลที่ยังไม่ push หายทั้งหมด |

กู้คืน/ตรวจสอบ:

```bash
docker compose ps alloy                       # ต้อง Up
docker volume inspect subscription-prod-agent_alloy-data
docker compose logs --tail=50 alloy | grep -i 'remote_write\|wal'
curl -s http://127.0.0.1:12345/metrics | grep prometheus_remote_storage_samples_pending
```

> **ห้าม `docker compose down -v`** — `-v` ลบ `alloy-data` ทิ้ง ทำให้ข้อมูลที่ยังค้างหาย

## 4. nginx access log

`infra/nginx/nginx.conf` เป็นไฟล์ของเพื่อนร่วมทีม **เราไม่แก้** nginx จึงใช้ `combined` format ตามค่า default
ซึ่ง **ไม่มี `$request_time`** `config.alloy` ทำ regex ให้ field นี้เป็น optional: จะมีค่าก็ต่อเมื่อทีมรับข้อเสนอ
ข้างล่างนี้เข้าไป ถ้าไม่รับ ทุกอย่างที่เหลือยังทำงานปกติ (ได้ `remote_addr`, `method`, `route`, `status`)

**ข้อเสนอถึงเจ้าของไฟล์ (ยังไม่ได้แก้ให้):** เพิ่มใน block `http { ... }`

```nginx
log_format  combined_rt  '$remote_addr - $remote_user [$time_local] '
                         '"$request" $status $body_bytes_sent '
                         '"$http_referer" "$http_user_agent" $request_time';
access_log  /dev/stdout  combined_rt;
```

เป็น superset ของ `combined` (ต่อท้ายฟิลด์เดียว) ดังนั้นเครื่องมืออื่นที่อ่าน combined อยู่ไม่พัง
และ regex ใน `config.alloy` รองรับทั้งสองแบบอยู่แล้ว

**label ที่ pipeline สร้าง** — `service`, `container`, `compose_project`, `site` (ทุก container) และเฉพาะ nginx:
`method`, `route`, `status`
`remote_addr` กับ `request_time` ไป **structured metadata** ไม่ใช่ label เพราะเป็นค่าต่อ request
(ถ้าเป็น label จะระเบิด index ตาม §5.3) ค้นใน Grafana ด้วย

```logql
{service="nginx", status=~"4..|5.."} | remote_addr = "203.0.113.10"
```

`route` ถูกบีบเป็น route template เหมือนฝั่ง metric: ตัวเลขและ UUID → `:id` และ path ที่ไม่อยู่ใน route table
ของแอป (สแกนเนอร์, `/wp-admin`, `/.env`) ยุบเป็น `other` ค่าเดียว

## 5. ติดตั้ง

```bash
# บน VM Azure, ใน repo ที่ clone ไว้
cd infra/monitoring/prod-agent
cp .env.example .env && $EDITOR .env      # .env ถูก git-ignore
docker network ls --filter name=_default  # เอาชื่อ network ของ app stack ไปใส่ APP_NETWORK

# สร้าง role สำหรับ postgres_exporter (รันครั้งเดียว)
#   CREATE USER exporter WITH PASSWORD '<random>';
#   GRANT pg_monitor TO exporter;

docker compose pull
docker compose up -d
docker compose ps
```

publish พอร์ต metrics ของแอป (ทำที่ root ของ repo):

```bash
cd /path/to/subscription_track
docker compose \
  -f docker-compose-prosuction.yml \
  -f infra/monitoring/prod-agent/docker-compose.app-metrics.override.yml \
  up -d api worker
```

ตรวจว่าเห็นข้อมูลจริง:

```bash
curl -s http://127.0.0.1:9464/metrics | head -5     # api
curl -s http://127.0.0.1:9465/metrics | grep worker_queue_jobs | head -3
for p in 9100 8081 9187 9121; do
  echo -n "$p: "; curl -s -o /dev/null -w '%{http_code}\n' "http://127.0.0.1:$p/metrics"
done
curl -s http://127.0.0.1:12345/metrics | grep -E 'prometheus_remote_storage_(samples_total|samples_failed_total)'
```

ทุกพอร์ตข้างบนต้องตอบจาก **loopback เท่านั้น** ยืนยันว่าไม่หลุดออกสู่สาธารณะ:

```bash
ss -ltnp | grep -E ':(9464|9465|9100|8081|9187|9121|12345)\b'   # ต้องขึ้น 127.0.0.1 ทุกบรรทัด
```

## 6. เทสต์ pipeline ของ nginx

`alloy validate` พิสูจน์แค่ว่า config ถูก syntax — ไม่ได้รัน regex/template จริง ซึ่งเป็นที่อยู่ของ
การันตีเรื่อง cardinality ทั้งหมด เทสต์นี้ดึง block `loki.process "pipeline"` จาก `config.alloy`
มาตรงๆ (จึง drift ไม่ได้) ป้อน log ตัวอย่างเข้าไป แล้ว assert label ที่ออกมา

```bash
./tests/log-pipeline/run.sh      # ต้องจบด้วย RESULT: PASS
```

ไม่ต้องมี stack อะไรรันอยู่ ใช้แค่ docker และไม่ทิ้ง container ค้าง
