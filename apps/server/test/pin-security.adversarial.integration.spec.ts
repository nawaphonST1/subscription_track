import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';
import { RESET_PIN_PREFIX } from '../src/common/security/pin.util';

describe('PIN Security Adversarial & Regression Integration Suite', () => {
  let app: INestApplication;
  let jwtService: JwtService;

  const JWT_SECRET =
    'pin-security-adversarial-test-jwt-secret-at-least-32-chars';
  const victimPassword = 'VictimPassword123!';
  let victimPasswordHash: string;

  const configuredPin = '482910';
  let configuredPinHash: string;

  const defaultPin = '111111';
  let defaultPinHash: string;

  const rotatedResetPinHash = `${RESET_PIN_PREFIX}$2a$10$abcdefghijklmnopqrstuvwxyz1234567890`;

  // Test users in simulated database
  const configuredUser = {
    id: 'user-configured-uuid-1',
    email: 'configured@example.com',
    name: 'Configured Victim',
    monthly_income: 50000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 1, subscriptions: 1 },
  };

  const unconfiguredUser = {
    id: 'user-unconfigured-uuid-2',
    email: 'unconfigured@example.com',
    name: 'Unconfigured User',
    monthly_income: 30000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 0, subscriptions: 0 },
  };

  const setupFlowUser = {
    id: 'user-setup-flow-uuid-5',
    email: 'setupflow@example.com',
    name: 'Setup Flow User',
    monthly_income: 35000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 0, subscriptions: 0 },
  };

  const rotatedUser = {
    id: 'user-rotated-uuid-3',
    email: 'rotated@example.com',
    name: 'Rotated User',
    monthly_income: 40000,
    security_pin_hash: rotatedResetPinHash,
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 0, subscriptions: 0 },
  };

  const rateLimitUser = {
    id: 'user-rate-limit-uuid-4',
    email: 'ratelimit@example.com',
    name: 'Rate Limit Victim',
    monthly_income: 45000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 1, subscriptions: 0 },
  };

  const notificationRotatedUser = {
    id: 'user-notif-rotated-uuid-6',
    email: 'notifrotated@example.com',
    name: 'Notif Rotated User',
    monthly_income: 42000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: { payment_cards: 0, subscriptions: 0 },
  };

  const sampleSubscription = {
    id: 'sub-test-uuid-1',
    user_id: configuredUser.id,
    payment_card_id: 'card-test-uuid-1',
    name: 'Netflix 4K',
    category: 'Streaming',
    price: 419,
    billing_cycle: 'MONTHLY',
    start_date: new Date('2026-01-01'),
    next_renewal_date: new Date('2026-11-01'),
    usage_status: 'FREQUENT',
    status: 'ACTIVE',
    brand_color: '#E50914',
    created_at: new Date('2026-01-01'),
    updated_at: new Date('2026-01-01'),
  };

  const sampleCard = {
    id: 'card-test-uuid-1',
    user_id: configuredUser.id,
    card_nickname: 'Primary Card',
    card_brand: 'Visa',
    card_type: 'CREDIT',
    last_4_digits: '4242',
    bank_name: 'KBANK',
    balance: 50000,
    currency: 'THB',
    is_default: true,
    is_active: true,
    created_at: new Date('2026-01-01'),
    updated_at: new Date('2026-01-01'),
  };

  const notificationsStore: any[] = [
    {
      id: 'notif-1',
      user_id: rotatedUser.id,
      title: 'รหัส PIN ของคุณถูกรีเซ็ตเพื่อความปลอดภัย',
      message:
        'รหัสความปลอดภัย (PIN) ของคุณถูกรีเซ็ตเนื่องจากนโยบายความปลอดภัย กรุณาตั้งค่ารหัส PIN ใหม่ของคุณผ่านแอปพลิเคชัน',
      type: NotificationType.SECURITY_ALERT,
      is_read: false,
      created_at: new Date('2026-10-06T12:00:00.000Z'),
    },
    {
      id: 'notif-2',
      user_id: notificationRotatedUser.id,
      title: 'รหัส PIN ของคุณถูกรีเซ็ตเพื่อความปลอดภัย',
      message:
        'รหัสความปลอดภัย (PIN) ของคุณถูกรีเซ็ตเนื่องจากนโยบายความปลอดภัย กรุณาตั้งค่ารหัส PIN ใหม่ของคุณผ่านแอปพลิเคชัน',
      type: NotificationType.SECURITY_ALERT,
      is_read: false,
      created_at: new Date('2026-10-06T12:00:00.000Z'),
    },
  ];

  let usersDb: Record<string, any>;

  beforeAll(async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('JWT_SECRET', JWT_SECRET);

    victimPasswordHash = await bcrypt.hash(victimPassword, 10);
    configuredPinHash = await bcrypt.hash(configuredPin, 10);
    defaultPinHash = await bcrypt.hash(defaultPin, 10);

    configuredUser.password_hash = victimPasswordHash;
    configuredUser.security_pin_hash = configuredPinHash;

    unconfiguredUser.password_hash = victimPasswordHash;
    unconfiguredUser.security_pin_hash = defaultPinHash;

    setupFlowUser.password_hash = victimPasswordHash;
    setupFlowUser.security_pin_hash = defaultPinHash;

    rotatedUser.password_hash = victimPasswordHash;

    rateLimitUser.password_hash = victimPasswordHash;
    rateLimitUser.security_pin_hash = configuredPinHash;

    notificationRotatedUser.password_hash = victimPasswordHash;
    notificationRotatedUser.security_pin_hash = configuredPinHash;

    usersDb = {
      [configuredUser.id]: { ...configuredUser },
      [unconfiguredUser.id]: { ...unconfiguredUser },
      [setupFlowUser.id]: { ...setupFlowUser },
      [rotatedUser.id]: { ...rotatedUser },
      [rateLimitUser.id]: { ...rateLimitUser },
      [notificationRotatedUser.id]: { ...notificationRotatedUser },
    };

    const mockPrisma = {
      user: {
        findUnique: async ({ where, select }: any) => {
          const user = Object.values(usersDb).find(
            (u) => u.id === where.id || u.email === where.email,
          );
          if (!user) return null;
          if (select) {
            const projected: Record<string, any> = {};
            for (const [key, val] of Object.entries(select)) {
              if (key === '_count') projected._count = user._count;
              else if (val) projected[key] = user[key] ?? null;
            }
            return projected;
          }
          return user;
        },
        update: async ({ where, data }: any) => {
          const user = usersDb[where.id];
          if (!user) throw new Error('User not found');
          Object.assign(user, data);
          return user;
        },
      },
      userSubscription: {
        findMany: async ({ where }: any) => {
          if (where?.user_id === configuredUser.id) {
            return [sampleSubscription];
          }
          return [];
        },
        findFirst: async ({ where }: any) => {
          if (
            where?.id === sampleSubscription.id &&
            where?.user_id === configuredUser.id
          ) {
            return sampleSubscription;
          }
          return null;
        },
        update: async ({ data }: any) => {
          return { ...sampleSubscription, ...data };
        },
        delete: async ({ where }: any) => {
          if (where?.id === sampleSubscription.id) {
            return sampleSubscription;
          }
          throw new Error('Not found');
        },
        updateMany: async () => ({ count: 1 }),
      },
      paymentCard: {
        findMany: async ({ where }: any) => {
          if (
            where?.user_id === configuredUser.id ||
            where?.user_id === rateLimitUser.id
          ) {
            return [sampleCard];
          }
          return [];
        },
        findFirst: async ({ where }: any) => {
          if (where?.id === sampleCard.id) {
            return sampleCard;
          }
          return null;
        },
        update: async ({ where, data }: any) => {
          if (where?.id === sampleCard.id) {
            return { ...sampleCard, ...data };
          }
          throw new Error('Not found');
        },
      },
      savingsCancellationLog: {
        create: async ({ data }: any) => ({
          id: 'log-1',
          ...data,
          cancelled_at: new Date(),
        }),
      },
      notification: {
        create: async ({ data }: any) => {
          const notif = {
            id: `notif-${Date.now()}-${Math.random()}`,
            ...data,
            is_read: false,
            created_at: new Date(),
          };
          notificationsStore.push(notif);
          return notif;
        },
        findMany: async ({ where }: any) => {
          return notificationsStore.filter((n) => n.user_id === where?.user_id);
        },
        count: async ({ where }: any) => {
          return notificationsStore.filter(
            (n) =>
              n.user_id === where?.user_id &&
              (!where?.is_read || n.is_read === where.is_read),
          ).length;
        },
      },
      cancellationLog: {
        createMany: async () => ({ count: 1 }),
      },
      $transaction: async (arg: any) => {
        if (typeof arg === 'function') {
          return arg(mockPrisma);
        }
        return Promise.all(arg);
      },
    };

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrisma)
      .compile();

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );

    jwtService = moduleRef.get(JwtService);
    await app.init();
  });

  afterAll(async () => {
    try {
      await app?.close();
    } finally {
      vi.unstubAllEnvs();
    }
  });

  function makeToken(user: { id: string; email: string }): string {
    return jwtService.sign({ sub: user.id, email: user.email });
  }

  describe('H1 — Server-Side PIN Setup Enforcement (PinSetupGuard)', () => {
    it('H1-1: Configured user with valid JWT can access protected application endpoints', async () => {
      const token = makeToken(configuredUser);
      const res = await request(app.getHttpServer())
        .get('/subscriptions')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('H1-2: Unconfigured user (default PIN 111111) is blocked by server-side guard with 403 PIN_SETUP_REQUIRED', async () => {
      const token = makeToken(unconfiguredUser);
      const res = await request(app.getHttpServer())
        .get('/subscriptions')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toBe('PIN_SETUP_REQUIRED');
    });

    it('H1-2b: Rotated user ($RESET$ marker) is blocked from normal endpoints with 403 PIN_SETUP_REQUIRED', async () => {
      const token = makeToken(rotatedUser);
      const res = await request(app.getHttpServer())
        .get('/subscriptions')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toBe('PIN_SETUP_REQUIRED');
    });

    it('H1-2c: Rotated user cannot access /notifications until PIN setup is completed', async () => {
      const token = makeToken(rotatedUser);
      const res = await request(app.getHttpServer())
        .get('/notifications')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('PIN_SETUP_REQUIRED');
    });

    it('H1-3: Direct API calls (curl/Postman simulation) cannot bypass PinSetupGuard', async () => {
      const token = makeToken(unconfiguredUser);
      const res = await request(app.getHttpServer())
        .get('/cards')
        .set('Authorization', `Bearer ${token}`)
        .set('User-Agent', 'curl/8.5.0')
        .set('X-Client-Bypass', 'true');

      expect(res.status).toBe(403);
      expect(res.body.error).toBe('PIN_SETUP_REQUIRED');
    });

    it('H1-AllowWithoutPin: Unconfigured user CAN access @AllowWithoutPin endpoints (GET /users/me)', async () => {
      const token = makeToken(unconfiguredUser);
      const res = await request(app.getHttpServer())
        .get('/users/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.pin_configured).toBe(false);
      // Hash is NEVER exposed in API response
      expect(res.body.data.security_pin_hash).toBeUndefined();
    });
  });

  describe('H1 — PIN Setup / Reset Reauthentication Protection (§18)', () => {
    it('H1-15: Stolen JWT cannot set a new PIN without primary credentials (password or social token)', async () => {
      const token = makeToken(unconfiguredUser);

      // Attacker attempts to change PIN using only stolen JWT + known default current_pin
      const res = await request(app.getHttpServer())
        .patch('/users/pin')
        .set('Authorization', `Bearer ${token}`)
        .send({
          current_pin: '111111',
          new_pin: '987654',
        });

      // Must be rejected because primary re-auth is required for unconfigured/reset accounts
      expect(res.status).toBe(401);
      expect(res.body.message).toContain('Primary authentication');
    });

    it('H1-15b: Stolen JWT with incorrect password is rejected with 401', async () => {
      const token = makeToken(unconfiguredUser);

      const res = await request(app.getHttpServer())
        .patch('/users/pin')
        .set('Authorization', `Bearer ${token}`)
        .send({
          password: 'WrongPasswordGuess!',
          new_pin: '987654',
        });

      expect(res.status).toBe(401);
      expect(res.body.message).toContain('Primary authentication');
    });

    it('H1-DefaultPin: New PIN cannot be the default PIN 111111', async () => {
      const token = makeToken(unconfiguredUser);

      const res = await request(app.getHttpServer())
        .patch('/users/pin')
        .set('Authorization', `Bearer ${token}`)
        .send({
          password: victimPassword,
          new_pin: '111111',
        });

      expect(res.status).toBe(400);
      expect(JSON.stringify(res.body.message)).toContain('111111');
    });

    it('H1-SetupSuccess: Legitimate user with valid password successfully configures custom PIN', async () => {
      const token = makeToken(setupFlowUser);

      const res = await request(app.getHttpServer())
        .patch('/users/pin')
        .set('Authorization', `Bearer ${token}`)
        .send({
          password: victimPassword,
          new_pin: '876543',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      // Verify that after setup, the user can now access protected endpoints
      const checkRes = await request(app.getHttpServer())
        .get('/subscriptions')
        .set('Authorization', `Bearer ${token}`);

      expect(checkRes.status).toBe(200);
    });
  });

  describe('H1 — Server-Side Sensitive Action Enforcement (SecurityPinGuard)', () => {
    const configuredToken = () => makeToken(configuredUser);

    it('H1-10: DELETE /subscriptions/:id without PIN is rejected', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`);

      expect([400, 403]).toContain(res.status);
      expect(res.body.message).toContain('Security PIN is required');
    });

    it('H1-10b: DELETE /subscriptions/:id with invalid PIN format is rejected', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .set('x-security-pin', 'abc');

      expect([400, 403]).toContain(res.status);
      expect(res.body.message).toContain('6 digits');
    });

    it('H1-10c: DELETE /subscriptions/:id with wrong PIN is rejected with 403', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .set('x-security-pin', '000000');

      expect(res.status).toBe(403);
      expect(res.body.message).toContain('security PIN');
    });

    it('H1-10d: DELETE /subscriptions/:id with correct PIN via x-security-pin header succeeds with 200', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .set('x-security-pin', configuredPin);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('H1-10e: DELETE /subscriptions/:id with correct PIN via JSON body succeeds with 200', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .send({ security_pin: configuredPin });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('H1-11: DELETE /cards/:id without PIN is rejected', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/cards/${sampleCard.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`);

      expect([400, 403]).toContain(res.status);
      expect(res.body.message).toContain('Security PIN is required');
    });

    it('H1-11b: DELETE /cards/:id with correct PIN succeeds with 200', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/cards/${sampleCard.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .set('x-security-pin', configuredPin);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('H1-11c: DELETE /cards/:id with wrong PIN is rejected with 403', async () => {
      const res = await request(app.getHttpServer())
        .delete(`/cards/${sampleCard.id}`)
        .set('Authorization', `Bearer ${configuredToken()}`)
        .set('x-security-pin', '000000');

      expect(res.status).toBe(403);
      expect(res.body.message).toContain('security PIN');
    });

    it('H1-12: POST /savings/batch-cancel with default PIN 111111 is rejected', async () => {
      const res = await request(app.getHttpServer())
        .post('/savings/batch-cancel')
        .set('Authorization', `Bearer ${configuredToken()}`)
        .send({
          subscription_ids: [sampleSubscription.id],
          security_pin: '111111',
        });

      expect(res.status).toBe(403);
    });

    it('H1-12b: POST /savings/batch-cancel with correct PIN succeeds', async () => {
      const res = await request(app.getHttpServer())
        .post('/savings/batch-cancel')
        .set('Authorization', `Bearer ${configuredToken()}`)
        .send({
          subscription_ids: [sampleSubscription.id],
          security_pin: configuredPin,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });
  });

  describe('H1-13 & H1-14 — PIN Rate Limiting and Reset', () => {
    it('Locks out after 5 consecutive incorrect PIN attempts and rejects 6th attempt with 429', async () => {
      const token = makeToken(rateLimitUser);

      // Attempt 1 to 5 with wrong PIN -> records 5 failures
      for (let i = 0; i < 5; i++) {
        const res = await request(app.getHttpServer())
          .delete(`/cards/${sampleCard.id}`)
          .set('Authorization', `Bearer ${token}`)
          .set('x-security-pin', '999999');

        expect(res.status).toBe(403);
      }

      // 6th attempt while locked out is rejected with 429
      const lockedRes = await request(app.getHttpServer())
        .delete(`/cards/${sampleCard.id}`)
        .set('Authorization', `Bearer ${token}`)
        .set('x-security-pin', configuredPin);

      expect(lockedRes.status).toBe(429);
    });
  });

  describe('H2 — Safe Rotation and Notification Exposure (§26 & §28)', () => {
    it('H2-1: Rotated user notifications NEVER disclose plaintext PINs', async () => {
      const legitToken = makeToken(notificationRotatedUser);

      const res = await request(app.getHttpServer())
        .get('/notifications')
        .set('Authorization', `Bearer ${legitToken}`);

      expect(res.status).toBe(200);
      const notifications = res.body.data.notifications;
      expect(notifications.length).toBeGreaterThan(0);

      for (const notif of notifications) {
        expect(notif.message).not.toMatch(/\b\d{6}\b/);
        expect(notif.title).not.toMatch(/\b\d{6}\b/);
        expect(notif.message).toContain(
          'รหัสความปลอดภัย (PIN) ของคุณถูกรีเซ็ต',
        );
      }
    });
  });

  describe('§28 — Comprehensive Adversarial Scenario: Stolen JWT Attack Chain', () => {
    it('Attacker with stolen JWT cannot obtain plaintext PIN or execute destructive actions', async () => {
      // Scenario:
      // - Victim account exists with secret configured PIN (attacker doesn't know)
      // - Attacker obtains victim's valid Bearer JWT
      // - Attacker calls API endpoints directly using HTTP client
      const stolenJwt = makeToken(configuredUser);

      // Attack Step 1: Attacker calls GET /users/me to inspect user info
      const meRes = await request(app.getHttpServer())
        .get('/users/me')
        .set('Authorization', `Bearer ${stolenJwt}`);

      expect(meRes.status).toBe(200);
      // Ensure victim's security_pin_hash or PIN is NEVER in response
      expect(meRes.body.data.security_pin_hash).toBeUndefined();
      expect(meRes.body.data.security_pin).toBeUndefined();

      // Attack Step 2: Attacker attempts to overwrite PIN with attacker's PIN using default current_pin
      const overwriteRes = await request(app.getHttpServer())
        .patch('/users/pin')
        .set('Authorization', `Bearer ${stolenJwt}`)
        .send({
          current_pin: '111111',
          new_pin: '666666',
        });

      // Rejected because victim PIN is configured and current_pin '111111' is wrong
      expect(overwriteRes.status).toBe(401);

      // Attack Step 3: Attacker attempts to delete victim's subscriptions without PIN
      const delSubRes = await request(app.getHttpServer())
        .delete(`/subscriptions/${sampleSubscription.id}`)
        .set('Authorization', `Bearer ${stolenJwt}`);

      expect([400, 403]).toContain(delSubRes.status);
      expect(delSubRes.body.message).toContain('Security PIN is required');

      // Attack Step 4: Attacker attempts to delete victim's payment cards without PIN
      const delCardRes = await request(app.getHttpServer())
        .delete(`/cards/${sampleCard.id}`)
        .set('Authorization', `Bearer ${stolenJwt}`);

      expect([400, 403]).toContain(delCardRes.status);
      expect(delCardRes.body.message).toContain('Security PIN is required');

      // Attack Step 5: Attacker attempts batch-cancellation without PIN
      const batchCancelRes = await request(app.getHttpServer())
        .post('/savings/batch-cancel')
        .set('Authorization', `Bearer ${stolenJwt}`)
        .send({
          subscription_ids: [sampleSubscription.id],
        });

      expect(batchCancelRes.status).toBe(400);

      // Adversarial conclusion: Stolen JWT alone is completely insufficient to bypass PIN protection
    });
  });
});
