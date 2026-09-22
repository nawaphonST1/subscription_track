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
import { BillingCycle, SubscriptionStatus, UsageStatus } from '@prisma/client';

import { SubscriptionsController } from '../src/subscriptions/subscriptions.controller';
import { SubscriptionsService } from '../src/subscriptions/subscriptions.service';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';

const INTEGRATION_JWT_SECRET =
  'integration-test-secret-at-least-32-characters-entropy';

describe('Nest HTTP Subscriptions component integration (Prisma test double)', () => {
  let app: INestApplication;
  let jwtService: JwtService;

  const mockPrisma = {
    user: {
      findUnique: vi.fn(),
    },
    userSubscription: {
      findMany: vi.fn(),
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

  const subUserA = {
    id: 'sub-user-a-001',
    user_id: userA.id,
    payment_card_id: 'card-1',
    name: 'Netflix Premium',
    category: 'Streaming',
    price: { toString: () => '419.00' },
    billing_cycle: BillingCycle.MONTHLY,
    start_date: new Date('2026-09-01T00:00:00.000Z'),
    next_renewal_date: new Date('2026-10-01T00:00:00.000Z'),
    usage_status: UsageStatus.FREQUENT,
    status: SubscriptionStatus.ACTIVE,
    brand_color: '#E50914',
    notes: 'User A Family Plan',
    payment_card: {
      id: 'card-1',
      card_nickname: 'Main Visa',
      card_brand: 'Visa',
      last_4_digits: '4242',
      bank_name: 'KBANK',
    },
    created_at: new Date('2026-09-01T00:00:00.000Z'),
    updated_at: new Date('2026-09-01T00:00:00.000Z'),
  };

  const subUserB = {
    id: 'sub-user-b-002',
    user_id: userB.id,
    payment_card_id: 'card-2',
    name: 'Spotify Family',
    category: 'Music',
    price: { toString: () => '209.00' },
    billing_cycle: BillingCycle.MONTHLY,
    start_date: new Date('2026-09-05T00:00:00.000Z'),
    next_renewal_date: new Date('2026-10-05T00:00:00.000Z'),
    usage_status: UsageStatus.FREQUENT,
    status: SubscriptionStatus.ACTIVE,
    brand_color: '#1DB954',
    notes: 'User B Secret Music Plan',
    payment_card: {
      id: 'card-2',
      card_nickname: 'Secret Card',
      card_brand: 'Mastercard',
      last_4_digits: '8888',
      bank_name: 'SCB',
    },
    created_at: new Date('2026-09-05T00:00:00.000Z'),
    updated_at: new Date('2026-09-05T00:00:00.000Z'),
  };

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
      controllers: [SubscriptionsController],
      providers: [
        SubscriptionsService,
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
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    vi.clearAllMocks();

    // Default mock behavior for user authentication lookup in JwtStrategy
    mockPrisma.user.findUnique.mockImplementation(
      ({ where }: { where: { id: string } }) => {
        if (where.id === userA.id) return Promise.resolve(userA);
        if (where.id === userB.id) return Promise.resolve(userB);
        return Promise.resolve(null);
      },
    );
  });

  function createToken(userId: string, email: string) {
    return jwtService.sign({ sub: userId, email });
  }

  it('CASE 1: GET /subscriptions with valid authenticated User A returns 200 with standard response envelope', async () => {
    mockPrisma.userSubscription.findMany.mockResolvedValue([subUserA]);
    const token = createToken(userA.id, userA.email);

    const response = await request(app.getHttpServer())
      .get('/subscriptions')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body).toMatchObject({
      success: true,
      statusCode: 200,
      data: [
        {
          id: 'sub-user-a-001',
          name: 'Netflix Premium',
          price: 419,
          billing_cycle: 'MONTHLY',
        },
      ],
    });
    expect(response.body.timestamp).toBeDefined();
    expect(mockPrisma.userSubscription.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { user_id: userA.id },
      }),
    );
  });

  it('CASE 2: GET /subscriptions without Authorization header returns 401 via global JwtAuthGuard', async () => {
    const response = await request(app.getHttpServer())
      .get('/subscriptions')
      .expect(401);

    expect(response.body).toMatchObject({
      success: false,
      statusCode: 401,
      error: 'UnauthorizedException',
    });
    expect(mockPrisma.userSubscription.findMany).not.toHaveBeenCalled();
  });

  it('CASE 3 (SECURITY CRITICAL): User A request never returns User B subscriptions (cross-user isolation)', async () => {
    // Mock database containing subscriptions for both users
    mockPrisma.userSubscription.findMany.mockImplementation(
      ({ where }: { where: { user_id: string } }) => {
        if (where.user_id === userA.id) return Promise.resolve([subUserA]);
        if (where.user_id === userB.id) return Promise.resolve([subUserB]);
        return Promise.resolve([]);
      },
    );

    const tokenUserA = createToken(userA.id, userA.email);

    const response = await request(app.getHttpServer())
      .get('/subscriptions')
      .set('Authorization', `Bearer ${tokenUserA}`)
      .expect(200);

    // Verify User A receives only their subscription
    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].id).toBe('sub-user-a-001');
    expect(response.body.data[0].name).toBe('Netflix Premium');

    // Assert User B subscriptions are strictly excluded
    const hasUserBData = response.body.data.some(
      (item: { id: string; name: string }) =>
        item.id === subUserB.id || item.name === subUserB.name,
    );
    expect(hasUserBData).toBe(false);

    // Assert query was scoped strictly by authenticated caller ID
    expect(mockPrisma.userSubscription.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { user_id: userA.id },
      }),
    );
  });

  it('CASE 4: Invalid enum query parameter returns 400 validation error via ValidationPipe', async () => {
    const token = createToken(userA.id, userA.email);

    const response = await request(app.getHttpServer())
      .get('/subscriptions?status=INVALID_STATUS_VALUE')
      .set('Authorization', `Bearer ${token}`)
      .expect(400);

    expect(response.body).toMatchObject({
      success: false,
      statusCode: 400,
      error: 'Bad Request',
    });
    expect(mockPrisma.userSubscription.findMany).not.toHaveBeenCalled();
  });

  it('CASE 5: User with no subscriptions returns 200 with empty array data: []', async () => {
    mockPrisma.userSubscription.findMany.mockResolvedValue([]);
    const token = createToken(userA.id, userA.email);

    const response = await request(app.getHttpServer())
      .get('/subscriptions')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body).toMatchObject({
      success: true,
      statusCode: 200,
      data: [],
    });
  });

  it('CASE 6 (NEGATIVE SECURITY TEST): Client-supplied userId query parameter cannot override authenticated identity and is rejected by ValidationPipe', async () => {
    const token = createToken(userA.id, userA.email);

    // Attacker tries to pass ?userId=victim-id to hijack query scoping
    const response = await request(app.getHttpServer())
      .get(`/subscriptions?userId=${userB.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(400);

    expect(response.body).toMatchObject({
      success: false,
      statusCode: 400,
      error: 'Bad Request',
    });
    expect(mockPrisma.userSubscription.findMany).not.toHaveBeenCalled();
  });
});
