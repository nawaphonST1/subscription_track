import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { AppModule } from '../src/app.module';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Application-level HTTP authentication flow (isolated Prisma test double)', () => {
  let app: INestApplication;
  let jwtService: JwtService;

  const E2E_JWT_SECRET =
    'deterministic-e2e-jwt-secret-entropy-32-chars-minimum';
  const testUserPassword = 'TestPassword123!';
  let testUserPasswordHash: string;

  const seededUser = {
    id: 'e2e-user-uuid-101',
    email: 'e2e.user@example.com',
    name: 'E2E User',
    monthly_income: 45000,
    security_pin_hash: 'mock-pin-hash',
    created_at: new Date('2026-01-01T00:00:00.000Z'),
    updated_at: new Date('2026-01-01T00:00:00.000Z'),
    _count: {
      payment_cards: 1,
      subscriptions: 2,
    },
  };

  beforeAll(async () => {
    vi.stubEnv('NODE_ENV', 'test');
    vi.stubEnv('APP_HOST', '127.0.0.1');
    vi.stubEnv('PORT', '3001');
    vi.stubEnv('DB_HOST', 'localhost');
    vi.stubEnv('DB_PORT', '5432');
    vi.stubEnv('DB_NAME', 'subtracker_e2e_test');
    vi.stubEnv('DB_USER', 'test_user');
    vi.stubEnv('DB_PASSWORD', 'test_password');
    vi.stubEnv(
      'DATABASE_URL',
      'postgresql://test_user:test_password@localhost:5432/subtracker_e2e_test?schema=public',
    );
    vi.stubEnv('JWT_SECRET', E2E_JWT_SECRET);

    testUserPasswordHash = await bcrypt.hash(testUserPassword, 10);

    // This exercises the Nest HTTP stack with a Prisma test double; it does not
    // validate PostgreSQL, Prisma connectivity, or physical database failures.
    const mockPrisma = {
      user: {
        findUnique: async ({
          where,
          select,
        }: {
          where: { email?: string; id?: string };
          select?: Record<string, boolean | object>;
        }) => {
          if (where.email && where.email.toLowerCase() === seededUser.email) {
            return {
              ...seededUser,
              password_hash: testUserPasswordHash,
            };
          }

          if (where.id === seededUser.id) {
            if (select) {
              const projected: Record<string, unknown> = {};
              for (const [key, value] of Object.entries(select)) {
                if (key === '_count') {
                  projected._count = seededUser._count;
                } else if (value) {
                  projected[key] =
                    seededUser[key as keyof typeof seededUser] ?? null;
                }
              }
              return projected;
            }
            return seededUser;
          }

          return null;
        },
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
      await app.close();
    } finally {
      vi.unstubAllEnvs();
    }
  });

  it('6. GET / (public root endpoint) without Authorization header -> 200 OK', async () => {
    const response = await request(app.getHttpServer()).get('/').expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data).toBe('Hello World!');
  });

  it('3. GET /users/me without Authorization header -> 401 Unauthorized', async () => {
    const response = await request(app.getHttpServer())
      .get('/users/me')
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('4. GET /users/me with invalid / malformed token -> 401 Unauthorized', async () => {
    const response = await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', 'Bearer not-a-valid-jwt-token')
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('5. GET /users/me with expired token -> 401 Unauthorized', async () => {
    const expiredToken = jwtService.sign(
      { sub: seededUser.id, email: seededUser.email },
      { expiresIn: '-10s' },
    );

    const response = await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('1. POST /auth/login with valid credentials -> returns 200 and a valid JWT token', async () => {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: seededUser.email,
        password: testUserPassword,
      })
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.token).toBeDefined();
    expect(typeof response.body.data.token).toBe('string');
    expect(response.body.data.user.id).toBe(seededUser.id);
    expect(response.body.data.user.email).toBe(seededUser.email);
  });

  it('2. GET /users/me with valid Bearer JWT obtained from login -> 200 OK with profile', async () => {
    // 1. Obtain valid JWT via login endpoint
    const loginResponse = await request(app.getHttpServer())
      .post('/auth/login')
      .send({
        email: seededUser.email,
        password: testUserPassword,
      })
      .expect(200);

    const token = loginResponse.body.data.token;

    // 2. Access protected endpoint with Bearer token
    const profileResponse = await request(app.getHttpServer())
      .get('/users/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(profileResponse.body.success).toBe(true);
    expect(profileResponse.body.data.id).toBe(seededUser.id);
    expect(profileResponse.body.data.email).toBe(seededUser.email);
    expect(profileResponse.body.data.name).toBe(seededUser.name);
    expect(profileResponse.body.data.active_cards_count).toBe(1);
    expect(profileResponse.body.data.active_subscriptions_count).toBe(2);
  });
});
