import { INestApplication, ValidationPipe } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import { NotificationType } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('E2E: PIN Change Flow HTTP API (PATCH /users/me/pin & POST /users/verify-pin)', () => {
  let app: INestApplication;
  let jwtService: JwtService;

  const JWT_SECRET = 'deterministic-e2e-jwt-secret-entropy-32-chars-minimum';
  const userPassword = 'TestPassword123!';
  let userPasswordHash: string;

  const initialPin = '123456';
  let initialPinHash: string;

  const statefulUser = {
    id: 'e2e-pin-user-uuid-999',
    email: 'pin.tester@example.com',
    name: 'PIN Tester',
    monthly_income: 60000,
    security_pin_hash: '',
    password_hash: '',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: {
      payment_cards: 1,
      subscriptions: 2,
    },
  };

  let validToken: string;

  beforeAll(async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('APP_HOST', '127.0.0.1');
    vi.stubEnv('PORT', '3002');
    vi.stubEnv('DB_HOST', 'localhost');
    vi.stubEnv('DB_PORT', '5432');
    vi.stubEnv('DB_NAME', 'subtracker_pin_e2e_test');
    vi.stubEnv('DB_USER', 'test_user');
    vi.stubEnv('DB_PASSWORD', 'test_password');
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://test_user:test_password@localhost:5432/subtracker_pin_e2e_test?schema=public',
    );
    vi.stubEnv('JWT_SECRET', JWT_SECRET);

    userPasswordHash = await bcrypt.hash(userPassword, 10);
    initialPinHash = await bcrypt.hash(initialPin, 10);
    statefulUser.password_hash = userPasswordHash;
    statefulUser.security_pin_hash = initialPinHash;

    const mockPrisma = {
      user: {
        findUnique: async ({
          where,
          select,
        }: {
          where: { email?: string; id?: string };
          select?: Record<string, boolean | object>;
        }) => {
          if (
            (where.id && where.id === statefulUser.id) ||
            (where.email && where.email.toLowerCase() === statefulUser.email)
          ) {
            if (select) {
              const projected: Record<string, unknown> = {};
              for (const [key, value] of Object.entries(select)) {
                if (key === '_count') {
                  projected._count = statefulUser._count;
                } else if (value) {
                  projected[key] =
                    statefulUser[key as keyof typeof statefulUser] ?? null;
                }
              }
              return projected;
            }
            return statefulUser;
          }
          return null;
        },
        update: async ({
          where,
          data,
        }: {
          where: { id: string };
          data: { security_pin_hash?: string };
        }) => {
          if (where.id === statefulUser.id) {
            if (data.security_pin_hash) {
              statefulUser.security_pin_hash = data.security_pin_hash;
            }
            return statefulUser;
          }
          throw new Error('User not found');
        },
      },
      notification: {
        create: async ({
          data,
        }: {
          data: {
            user_id: string;
            title: string;
            message: string;
            type: NotificationType;
          };
        }) => {
          return { id: 'notif-1', ...data, created_at: new Date() };
        },
      },
      $transaction: async (queries: Array<Promise<unknown>>) => {
        return Promise.all(queries);
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

    validToken = jwtService.sign({
      sub: statefulUser.id,
      email: statefulUser.email,
    });
  });

  afterAll(async () => {
    try {
      await app.close();
    } finally {
      vi.unstubAllEnvs();
    }
  });

  it('1. PATCH /users/me/pin without Authorization -> 401 Unauthorized', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .send({ current_pin: '123456', new_pin: '654321' })
      .expect(401);

    expect(res.body.success).toBe(false);
  });

  it('2. PATCH /users/me/pin with malformed PIN formats -> 400 Bad Request', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: 'abc', new_pin: '12345' })
      .expect(400);

    expect(res.body.success).toBe(false);
  });

  it('3. PATCH /users/me/pin with weak default PIN (111111) -> 400 Bad Request', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: '123456', new_pin: '111111' })
      .expect(400);

    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Cannot use weak default PIN 111111');
  });

  it('4. PATCH /users/me/pin with identical current and new PIN -> 400 Bad Request', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: '123456', new_pin: '123456' })
      .expect(400);

    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('New PIN must be different');
  });

  it('5. PATCH /users/me/pin with wrong current PIN -> 401 Unauthorized', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: '999999', new_pin: '654321' })
      .expect(401);

    expect(res.body.success).toBe(false);
    expect(res.body.message).toContain('Current security PIN is incorrect');
  });

  it('6. PATCH /users/me/pin with correct current PIN and strong new PIN -> 200 OK', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/me/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: '123456', new_pin: '852963' })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.message).toBe('Security PIN changed successfully');
  });

  it('7. POST /users/verify-pin verifies that old PIN fails and new PIN succeeds', async () => {
    // Old PIN fails
    const oldPinRes = await request(app.getHttpServer())
      .post('/users/verify-pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ pin: '123456' })
      .expect(200);

    expect(oldPinRes.body.success).toBe(true);
    expect(oldPinRes.body.data.valid).toBe(false);

    // New PIN succeeds
    const newPinRes = await request(app.getHttpServer())
      .post('/users/verify-pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ pin: '852963' })
      .expect(200);

    expect(newPinRes.body.success).toBe(true);
    expect(newPinRes.body.data.valid).toBe(true);
  });

  it('8. PATCH /users/pin (alias route) successfully changes PIN again', async () => {
    const res = await request(app.getHttpServer())
      .patch('/users/pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ current_pin: '852963', new_pin: '741258' })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.message).toBe('Security PIN changed successfully');

    // Confirm new PIN
    const verifyRes = await request(app.getHttpServer())
      .post('/users/verify-pin')
      .set('Authorization', `Bearer ${validToken}`)
      .send({ pin: '741258' })
      .expect(200);

    expect(verifyRes.body.data.valid).toBe(true);
  });
});
