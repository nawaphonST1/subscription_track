# Administrative Scripts & Operations Runbook

This directory contains standalone administrative and operational maintenance scripts for the Subscription Track backend server.

---

## 1. Security PIN Rotation (`rotate-default-pins.ts`)

### Purpose
Scans the database for legacy accounts configured with the insecure default PIN (`111111`) and marks them with an unguessable reset hash (`$RESET$...`). This forces affected users to re-enroll a fresh security PIN via authenticated primary credentials (account password or social authentication).

### Usage
```bash
# Dry run (safe audit mode - does not mutate DB or send notifications)
pnpm ts-node scripts/rotate-default-pins.ts --dry-run

# Execute batch rotation
pnpm ts-node scripts/rotate-default-pins.ts
```

---

## 2. Operational Invalidation Runbook: Out-of-Band PIN Modifications

### Background & Cache Architecture
`PinSetupGuard` (`src/common/guards/pin-setup.guard.ts`) optimizes PIN setup verification by caching whether a user has configured a security PIN in Redis:
- **Cache Key:** `user:<user_id>:pin-configured`
- **Value:** `true` (PIN is configured and non-default) | `false` (PIN setup required)
- **TTL:** 180 seconds (3 minutes)

### Standard In-App Flow vs. Out-of-Band Modifications
In standard application API operations (`UsersService.changePin` in `src/users/users.service.ts`), the application automatically and synchronously purges this cache key upon any modification:
```typescript
if (this.cacheService) {
  await this.cacheService.del(`auth:user:${userId}`);
  await this.cacheService.del(`user:${userId}:pin-configured`);
}
```

### Problem with Direct Database / Standalone Script Updates
If an administrator or maintenance script updates `security_pin_hash` directly via:
1. Direct SQL commands (e.g., `UPDATE "users" SET security_pin_hash = ... WHERE id = '...';`), or
2. Standalone scripts without Redis integration (e.g., `rotate-default-pins.ts`),

`PinSetupGuard` may continue serving the cached boolean status for up to **180 seconds**. During this window, an unconfigured or reset user might still be granted access or a freshly configured user might receive 403 `PIN_SETUP_REQUIRED`.

### Mandatory Runbook Actions After Out-of-Band PIN Changes

Whenever performing direct database updates to user PINs or running standalone rotation scripts:

#### Option A: Invalidate Single User Cache
```bash
redis-cli -u "$REDIS_URL" DEL "user:<user_id>:pin-configured"
```

#### Option B: Invalidate All User PIN Status Caches (Post-Batch Rotation)
```bash
# Delete all pin-configured cache keys across the Redis cluster/instance
redis-cli -u "$REDIS_URL" --scan --pattern "user:*:pin-configured" | xargs -r redis-cli -u "$REDIS_URL" DEL
```

#### Option C: Invalidate Auth Profile Cache (Optional but Recommended)
If user authentication claims are affected:
```bash
redis-cli -u "$REDIS_URL" DEL "auth:user:<user_id>"
```
