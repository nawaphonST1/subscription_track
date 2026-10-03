import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { Test, TestingModule } from '@nestjs/testing';
import * as bcrypt from 'bcryptjs';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it, vi } from 'vitest';

import { AuthController } from '../src/auth/auth.controller';
import { AuthService } from '../src/auth/auth.service';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { MetricsModule } from '../src/metrics/metrics.module';
import { MetricsServerService } from '../src/metrics/metrics-server.service';
import { PrismaService } from '../src/prisma/prisma.service';

const INTEGRATION_JWT_SECRET =
  'deterministic-integration-jwt-secret-32-chars-min';
const PASSWORD = 'CorrectHorseBattery1!';
const USER_ID = '7f1c0f6a-aaaa-bbbb-cccc-0123456789ab';

describe('Business metrics through the real module graph', () => {
  let app: INestApplication;
  let metricsBaseUrl: string;

  const mockPrisma = {
    user: {
      findUnique: vi.fn(),
    },
  };

  const scrape = async (): Promise<string> => {
    const response = await fetch(`${metricsBaseUrl}/metrics`);
    expect(response.status).toBe(200);
    return response.text();
  };

  beforeAll(async () => {
    const passwordHash = await bcrypt.hash(PASSWORD, 4);

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [
            () => ({
              app: { metricsPort: 0, activeUsersWindowSeconds: 900 },
              JWT_SECRET: INTEGRATION_JWT_SECRET,
            }),
          ],
        }),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: INTEGRATION_JWT_SECRET,
          signOptions: { expiresIn: '1h' },
        }),
        MetricsModule,
      ],
      controllers: [AuthController],
      providers: [
        AuthService,
        JwtStrategy,
        { provide: PrismaService, useValue: mockPrisma },
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_FILTER, useClass: HttpExceptionFilter },
        { provide: APP_INTERCEPTOR, useClass: TransformInterceptor },
      ],
    }).compile();

    mockPrisma.user.findUnique.mockImplementation(
      ({ where }: { where: { email?: string; id?: string } }) => {
        if (where.email === 'known@example.com' || where.id === USER_ID) {
          return Promise.resolve({
            id: USER_ID,
            email: 'known@example.com',
            name: 'Known User',
            password_hash: passwordHash,
            monthly_income: 0,
            created_at: new Date('2026-01-01T00:00:00.000Z'),
          });
        }
        return Promise.resolve(null);
      },
    );

    app = moduleRef.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({
        transform: true,
        whitelist: true,
        forbidNonWhitelisted: true,
      }),
    );
    await app.init();

    metricsBaseUrl = `http://127.0.0.1:${app.get(MetricsServerService).port}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. counts a successful login without changing the response contract', async () => {
    const response = await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'known@example.com', password: PASSWORD });

    // POST /auth/login is @HttpCode(HttpStatus.OK) — unchanged by 2b.
    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.data.token).toEqual(expect.any(String));

    expect(await scrape()).toContain(
      'auth_login_total{result="success",method="password"} 1',
    );
  });

  it('2. counts a wrong password and an unknown email as failures, with the same 401 as before', async () => {
    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'known@example.com', password: 'WrongPassword1!' })
      .expect(401);

    await request(app.getHttpServer())
      .post('/auth/login')
      .send({ email: 'unknown@example.com', password: PASSWORD })
      .expect(401);

    expect(await scrape()).toContain(
      'auth_login_total{result="failure",method="password"} 2',
    );
  });

  it('3. counts an authenticated user once in the active-users gauge', async () => {
    const strategy = app.get(JwtStrategy);

    await strategy.validate({ sub: USER_ID, email: 'known@example.com' });
    await strategy.validate({ sub: USER_ID, email: 'known@example.com' });

    expect(await scrape()).toContain('active_users{window="900s"} 1');
  });

  it('4. never leaks an identifier or a credential into the exposition output', async () => {
    const exposition = await scrape();

    expect(exposition).not.toContain(USER_ID);
    expect(exposition).not.toContain('known@example.com');
    expect(exposition).not.toContain(PASSWORD);
  });
});
