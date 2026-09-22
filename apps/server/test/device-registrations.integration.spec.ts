import { INestApplication, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import {
  afterAll,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from 'vitest';
import { DevicePlatform, DeviceRegistrationStatus } from '@prisma/client';

import { DeviceRegistrationsController } from '../src/device-registrations/device-registrations.controller';
import { DeviceRegistrationsService } from '../src/device-registrations/device-registrations.service';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';

const INTEGRATION_JWT_SECRET =
  'integration-test-secret-device-registrations-at-least-32-chars';

describe('Nest HTTP Device Registrations component integration (Prisma test double)', () => {
  let app: INestApplication;
  let jwtService: JwtService;

  const mockTx = {
    deviceRegistration: {
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  };

  const mockPrisma = {
    $transaction: vi.fn(async (cb: any) => cb(mockTx)),
    user: {
      findUnique: vi.fn(),
    },
    deviceRegistration: {
      findFirst: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  };

  const userA = {
    id: 'user-a-uuid-1111',
    email: 'user.a@example.com',
    name: 'User A',
  };

  const userB = {
    id: 'user-b-uuid-2222',
    email: 'user.b@example.com',
    name: 'User B',
  };

  let tokenUserA: string;
  let tokenUserB: string;

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          load: [
            () => ({
              JWT_SECRET: INTEGRATION_JWT_SECRET,
            }),
          ],
        }),
        PassportModule.register({ defaultStrategy: 'jwt' }),
        JwtModule.register({
          secret: INTEGRATION_JWT_SECRET,
          signOptions: { expiresIn: '1h' },
        }),
      ],
      controllers: [DeviceRegistrationsController],
      providers: [
        DeviceRegistrationsService,
        JwtStrategy,
        {
          provide: PrismaService,
          useValue: mockPrisma,
        },
        {
          provide: APP_GUARD,
          useClass: JwtAuthGuard,
        },
        {
          provide: APP_FILTER,
          useClass: HttpExceptionFilter,
        },
        {
          provide: APP_INTERCEPTOR,
          useClass: TransformInterceptor,
        },
      ],
    }).compile();

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

    tokenUserA = jwtService.sign({ sub: userA.id, email: userA.email });
    tokenUserB = jwtService.sign({ sub: userB.id, email: userB.email });
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    vi.clearAllMocks();

    mockPrisma.user.findUnique.mockImplementation(
      ({ where }: { where: { id: string } }) => {
        if (where.id === userA.id) return Promise.resolve(userA);
        if (where.id === userB.id) return Promise.resolve(userB);
        return Promise.resolve(null);
      },
    );
  });

  it('1. valid JWT + valid payload → success (201 Created, wrapped envelope)', async () => {
    mockTx.deviceRegistration.findFirst.mockResolvedValue(null);
    mockTx.deviceRegistration.create.mockResolvedValue({
      id: 'reg-integration-1',
      user_id: userA.id,
      push_token: 'valid-fcm-push-token-1234',
      platform: DevicePlatform.IOS,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
      });

    expect(response.status).toBe(201);
    expect(response.headers.location).toBe(
      '/device-registrations/reg-integration-1',
    );
    expect(response.body.success).toBe(true);
    expect(response.body.statusCode).toBe(201);
    expect(response.body.data).toMatchObject({
      id: 'reg-integration-1',
      platform: 'IOS',
      status: 'ACTIVE',
    });
  });

  it('2. missing JWT → 401 Unauthorized', async () => {
    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
      });

    expect(response.status).toBe(401);
    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('3. invalid platform → validation failure (400 Bad Request)', async () => {
    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'WINDOWS',
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(400);
  });

  it('4. missing/empty token → validation failure (400 Bad Request)', async () => {
    const responseEmpty = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: '',
        platform: 'IOS',
      });

    expect(responseEmpty.status).toBe(400);
    expect(responseEmpty.body.success).toBe(false);

    const responseMissing = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        platform: 'IOS',
      });

    expect(responseMissing.status).toBe(400);
    expect(responseMissing.body.success).toBe(false);
  });

  it('5. whitespace-only token → validation failure without a database write', async () => {
    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: '   ',
        platform: 'ANDROID',
      });

    expect(response.status).toBe(400);
    expect(response.body.success).toBe(false);
    expect(mockTx.deviceRegistration.create).not.toHaveBeenCalled();
  });

  it('6. client-supplied userId/user_id → rejected by ValidationPipe (400 Bad Request)', async () => {
    const responseUserId = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
        userId: userB.id,
      });

    expect(responseUserId.status).toBe(400);
    expect(responseUserId.body.success).toBe(false);

    const responseSnakeUserId = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
        user_id: userB.id,
      });

    expect(responseSnakeUserId.status).toBe(400);
    expect(responseSnakeUserId.body.success).toBe(false);
  });

  it('7. authenticated User A is always used as owner', async () => {
    mockTx.deviceRegistration.findFirst.mockResolvedValue(null);
    mockTx.deviceRegistration.create.mockResolvedValue({
      id: 'reg-owner-verify',
      user_id: userA.id,
      push_token: 'valid-fcm-push-token-1234',
      platform: DevicePlatform.IOS,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
      });

    expect(response.status).toBe(201);
    expect(mockTx.deviceRegistration.create).toHaveBeenCalledWith({
      data: {
        user_id: userA.id,
        push_token: 'valid-fcm-push-token-1234',
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
      },
    });
  });

  it('8. repeated registration → successful idempotent behavior (200 OK)', async () => {
    const activeExisting = {
      id: 'reg-existing-id',
      user_id: userA.id,
      push_token: 'valid-fcm-push-token-1234',
      platform: DevicePlatform.IOS,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    };

    mockTx.deviceRegistration.findFirst.mockResolvedValueOnce(activeExisting);

    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'valid-fcm-push-token-1234',
        platform: 'IOS',
      });

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.statusCode).toBe(200);
    expect(response.body.data.id).toBe(activeExisting.id);
    expect(mockTx.deviceRegistration.create).not.toHaveBeenCalled();
  });

  it('9. response does not contain raw push token, user_id, or deactivated_at', async () => {
    mockTx.deviceRegistration.findFirst.mockResolvedValue(null);
    mockTx.deviceRegistration.create.mockResolvedValue({
      id: 'reg-minimized-1',
      user_id: userA.id,
      push_token: 'secret-raw-push-token-do-not-leak',
      platform: DevicePlatform.ANDROID,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .send({
        pushToken: 'secret-raw-push-token-do-not-leak',
        platform: 'ANDROID',
      });

    expect(response.status).toBe(201);
    expect(response.headers.location).toBe(
      '/device-registrations/reg-minimized-1',
    );
    const data = response.body.data;
    expect(data.pushToken).toBeUndefined();
    expect(data.push_token).toBeUndefined();
    expect(data.userId).toBeUndefined();
    expect(data.user_id).toBeUndefined();
    expect(data.deactivated_at).toBeUndefined();
    expect(data).toHaveProperty('id', 'reg-minimized-1');
    expect(data).toHaveProperty('platform', 'ANDROID');
    expect(data).toHaveProperty('status', 'ACTIVE');
    expect(data).toHaveProperty('createdAt');
    expect(data).toHaveProperty('updatedAt');
  });

  it('10. token transfer: User B registering token active for User A revokes User A and creates for User B', async () => {
    const userAActive = {
      id: 'reg-user-a-active',
      user_id: userA.id,
      push_token: 'shared-device-token',
      platform: DevicePlatform.IOS,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    };

    mockTx.deviceRegistration.findFirst
      .mockResolvedValueOnce(userAActive) // currently active for User A
      .mockResolvedValueOnce(null); // no inactive row for User B

    mockTx.deviceRegistration.update.mockResolvedValue({
      ...userAActive,
      status: DeviceRegistrationStatus.REVOKED,
    });

    mockTx.deviceRegistration.create.mockResolvedValue({
      id: 'reg-user-b-new',
      user_id: userB.id,
      push_token: 'shared-device-token',
      platform: DevicePlatform.IOS,
      status: DeviceRegistrationStatus.ACTIVE,
      deactivated_at: null,
      created_at: new Date('2026-09-22T00:00:00.000Z'),
      updated_at: new Date('2026-09-22T00:00:00.000Z'),
    });

    const response = await request(app.getHttpServer())
      .post('/device-registrations')
      .set('Authorization', `Bearer ${tokenUserB}`)
      .send({
        pushToken: 'shared-device-token',
        platform: 'IOS',
      });

    expect(response.status).toBe(201);
    expect(response.body.data.id).toBe('reg-user-b-new');
    expect(mockTx.deviceRegistration.update).toHaveBeenCalledWith({
      where: { id: userAActive.id },
      data: {
        status: DeviceRegistrationStatus.REVOKED,
        deactivated_at: expect.any(Date),
      },
    });
    expect(mockTx.deviceRegistration.create).toHaveBeenCalledWith({
      data: {
        user_id: userB.id,
        push_token: 'shared-device-token',
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
      },
    });
  });
});
