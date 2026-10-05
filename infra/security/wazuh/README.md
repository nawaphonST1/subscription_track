# Wazuh SIEM (DP-505)

Single-node Wazuh (manager + indexer + dashboard) บน **เครื่อง dev เท่านั้น**
เปิดเฉพาะช่วงเตรียม/ทำ demo · agent อยู่บน VM Azure (production) เชื่อมกลับมาผ่าน **Tailscale เท่านั้น**

```
VM Azure (production, public)                 เครื่อง dev (เปิดช่วง demo)
  wazuh-agent ───────── Tailscale (1514/1515) ──────▶ wazuh.manager
   - FIM: /etc/ssh, /srv, compose, ...                  │
   - /var/log/auth.log (SSH)                      wazuh.indexer (ไม่ publish)
   - docker container logs (nginx รวมอยู่)              │
                                                  wazuh.dashboard (127.0.0.1:8443)
```

> ที่มา: ดัดแปลงจาก official `wazuh-docker` single-node tag **v4.14.8**
> ส่วนที่แก้จาก upstream อยู่ในหัวคอมเมนต์ของ `docker-compose.yml` (ตัด default password,
> จำกัด port binding, ใส่ mem_limit) — ของเดิมไม่ปลอดภัยพอจะขึ้น git/รันจริง

## ไฟล์ในโฟลเดอร์นี้

| ไฟล์ | หน้าที่ |
|---|---|
| `docker-compose.yml` | manager + indexer + dashboard (project: `subscription-wazuh`) |
| `.env.example` | แม่แบบรหัสผ่าน + `WAZUH_BIND_ADDR` (Tailscale IP ของเครื่อง dev) |
| `ossec-agent.conf.example` | config ของ agent บน Azure (FIM + log sources) |
| `../../../scripts/wazuh-agent-bootstrap.sh` | ติดตั้ง+enroll agent บน Azure (idempotent) |
| `../../../scripts/wazuh-demo-attack.sh` | สร้าง event สำหรับ demo (มี guard บังคับ) |

## 1. ก่อนเริ่ม — เคลียร์ดิสก์และตั้ง kernel param

Wazuh indexer คือ OpenSearch กินแรม ~2 GiB และต้องการ `vm.max_map_count` สูง

```bash
df -h /                      # ต้องเหลือพอ (indexer + image รวม ~5-6 GB)
sudo sysctl -w vm.max_map_count=262144
# ให้ถาวร:
echo 'vm.max_map_count=262144' | sudo tee /etc/sysctl.d/99-wazuh.conf
```

> **WSL:** ค่า `vm.max_map_count` ตั้งใน distro ไม่อยู่ถ้ารีสตาร์ท ต้องใส่ใน `/etc/wsl.conf`
> (`[boot] command = sysctl -w vm.max_map_count=262144`) หรือ `%UserProfile%\.wslconfig`
> แล้ว `wsl --shutdown` ก่อน ถ้า indexer ขึ้นแล้วตายเงียบ ให้ดูค่านี้เป็นอย่างแรก

## 2. เตรียม cert + config (ครั้งเดียวต่อเครื่อง)

cert และไฟล์ config (`config/wazuh_cluster/`, `config/wazuh_indexer/`, `config/wazuh_dashboard/`)
**ไม่ได้อยู่ใน repo นี้** — เป็นของ generated และมี bcrypt hash กับรหัส API จริงอยู่ข้างใน
ทั้ง `config/` และ `upstream/` อยู่ใน `.gitignore` แล้ว **ห้าม commit**

### วิธีที่แนะนำ — ใช้สคริปต์

```bash
cd infra/security/wazuh
cp .env.example .env            # แล้วใส่ค่าจริง (ดู §3 เรื่องการสุ่มรหัส)
git clone --depth 1 -b v4.14.8 https://github.com/wazuh/wazuh-docker.git upstream

cd "$(git rev-parse --show-toplevel)"
./scripts/wazuh-server-bootstrap.sh --dry-run    # ดูก่อนว่าจะทำอะไร
./scripts/wazuh-server-bootstrap.sh
```

สคริปต์ idempotent รันซ้ำได้ ไม่แตะของที่ถูกต้องอยู่แล้ว และทำให้ครบทั้ง 4 อย่างที่เคยพลาด
ตอนทำมือ: generate cert ลงที่ถูก, ตรวจว่าได้ 12 ไฟล์จริง, หมุน bcrypt hash ของ `admin` +
`kibanaserver` ให้ตรง `.env`, แทนรหัส API default ของ upstream ใน `wazuh_dashboard/wazuh.yml`
และตั้ง Vulnerability Detection (ดู §7)

### ถ้าอยากทำมือ

```bash
cd infra/security/wazuh
git clone --depth 1 -b v4.14.8 https://github.com/wazuh/wazuh-docker.git upstream
cp -r upstream/single-node/config ./config          # config ที่ compose mount เข้าไป
# --project-directory . สำคัญ: ถ้าไม่ใส่ compose จะคิด path ./config/ เทียบกับโฟลเดอร์ของ
# ไฟล์ -f (upstream/single-node/) แล้ว cert จะไปตกที่ upstream/single-node/config/ แทน
# พอ up ขึ้นมา docker จะสร้าง ./config/wazuh_indexer_ssl_certs/*.pem เป็น "โฟลเดอร์เปล่า" ให้แทน
docker compose -f upstream/single-node/generate-indexer-certs.yml --project-directory . run --rm generator
# cert จะไปอยู่ ./config/wazuh_indexer_ssl_certs/ (git-ignored แล้ว)
ls -l config/wazuh_indexer_ssl_certs/   # ต้องเห็น 12 ไฟล์ .pem/.key ไม่ใช่โฟลเดอร์
```

แล้วต้องทำต่อเองอีก 3 อย่าง ไม่งั้น stack จะขึ้นแต่ auth ไม่ผ่าน (401 ทุกทาง):

1. `config/wazuh_indexer/internal_users.yml` — หมุน `hash:` ของ `admin` และ `kibanaserver`
   ให้เป็น bcrypt ของรหัสใน `.env` (ใช้ `hash.sh` ใน image ของ indexer)
2. `config/wazuh_dashboard/wazuh.yml` — แทน `password:` ที่ยังเป็น default ของ upstream
   ด้วย `WAZUH_API_PASSWORD`
3. `config/wazuh_cluster/wazuh_manager.conf` — ตั้ง `<vulnerability-detection>` ตามดิสก์ที่มี (§7)

> ถ้า indexer เคย `up` ไปแล้วด้วยรหัสเก่า การแก้ `internal_users.yml` เฉย ๆ จะไม่มีผล เพราะ
> indexer อ่านไฟล์นี้แค่ตอนสร้าง `.opendistro_security` ครั้งแรก ต้องดันเข้าไปด้วย
> `./scripts/wazuh-server-bootstrap.sh --rotate --apply-security`

## 3. เปิด stack

```bash
cd infra/security/wazuh
cp .env.example .env
tailscale ip -4                       # เอา IP ไปใส่ WAZUH_BIND_ADDR ใน .env
for v in INDEXER API DASHBOARD; do openssl rand -base64 24; done   # ใส่รหัสใน .env
docker compose up -d
docker compose ps
# เปิด dashboard: https://127.0.0.1:8443  (user: admin / WAZUH_INDEXER_PASSWORD)
```

ports ที่เปิด (ยืนยันด้วย `docker compose port` / `ss -ltn`):
- `1514`, `1515` → **Tailscale IP เท่านั้น** (`WAZUH_BIND_ADDR`)
- `8443` (dashboard), `55000` (manager API) → `127.0.0.1` เท่านั้น
- `9200` (indexer) → ไม่ publish
- `514/udp` → **ตัดทิ้ง** (ของ upstream เปิดไว้ เราไม่ใช้ syslog)

## 4. ตั้งรหัส enrollment (authd) บน manager

agent enroll ด้วยรหัส ตั้งให้ตรงกับ `WAZUH_REGISTRATION_PASSWORD` ใน `.env`:

```bash
docker compose exec wazuh.manager bash -c '
  echo "'"$WAZUH_REGISTRATION_PASSWORD"'" > /var/ossec/etc/authd.pass &&
  /var/ossec/bin/wazuh-control restart'
```

## 5. ติดตั้ง agent บน Azure

บน VM Azure (เครื่องเราเอง) ต้องมี Tailscale ขึ้นแล้ว:

```bash
sudo WAZUH_MANAGER=<TAILSCALE_IP_ของเครื่อง_dev> \
     WAZUH_REGISTRATION_PASSWORD='<ค่าเดียวกับใน .env>' \
     ./scripts/wazuh-agent-bootstrap.sh
```

สคริปต์ idempotent: รันซ้ำได้ ไม่ enroll ซ้ำ ไม่ import key ซ้ำ และ **ปฏิเสธถ้า manager
ไม่ใช่ Tailscale IP** (กันรหัส enrollment หลุดออกเน็ต) ตรวจจาก manager:

```bash
docker compose exec wazuh.manager /var/ossec/bin/agent_control -l
# agent ต้องขึ้น Active
```

## 6. Demo: ยิง event ใส่ระบบตัวเอง

`scripts/wazuh-demo-attack.sh` สร้าง 2 แพทเทิร์น **ใส่ VM Azure ของเราเองเท่านั้น**:
failed SSH login (→ auth.log) และ request path ที่ไม่มีจริง (→ nginx 404)

เป็นแค่ traffic generator ไม่ใช่ exploit: login ถูกออกแบบให้ล้มเหลว (user ปลอม ไม่ส่งรหัส)
และ path ทั้งหมดได้ 404 — แบบเดียวกับที่ scanner ยิงใส่ public IP อยู่แล้วทุกวัน

```bash
./scripts/wazuh-demo-attack.sh --target <AZURE_VM_PUBLIC_IP> --i-own-this-target
# ลองก่อนด้วย --dry-run เพื่อดูว่าจะทำอะไรโดยไม่แตะเน็ตเวิร์ก
```

guard ที่บังคับไว้ (ทดสอบแล้ว): ต้องมี `--i-own-this-target`, ปฏิเสธ IP private/loopback/
link-local และ **ช่วง Tailscale/CGNAT 100.64/10** (กันยิงโดนเครื่องใน mesh หรือ VM อาจารย์)
และปฏิเสธ host ใน `DENY_HOSTS`

ดูผลที่ dashboard: Security events → กรอง agent เป็น VM Azure → เห็น alert sshd + web/404
ภายใน ~1 นาที · 404 burst ชุดเดียวกันจะขึ้นที่ Grafana "Logs Explorer" เป็น spike ของ route="other"

## 7. ข้อจำกัดที่รู้อยู่

- Wazuh server กินทรัพยากรมาก (ประมาณ 4 GiB ตาม mem_limit) **รันบนเครื่อง dev เท่านั้น**
  ไม่ใช่บน Azure 4 GiB และไม่ใช่ VM อาจารย์
- manager เห็น agent เฉพาะตอนเครื่อง dev เปิดและ Tailscale ขึ้น — agent จะ buffer event
  (`client_buffer` ใน ossec-agent.conf) แล้วส่งตามเมื่อกลับมาเชื่อมได้
- active response ปิดไว้ตั้งใจ: ไม่อยากให้ auto-block ตัดเว็บตอน demo (ดูคอมเมนต์ใน
  `ossec-agent.conf.example`)
- ถ้าเวลาไม่พอ: ทำแค่ agent + log ส่งเข้า Loki ก็ได้ แล้วอธิบายว่า server เต็มรูปเป็นงานต่อยอด
