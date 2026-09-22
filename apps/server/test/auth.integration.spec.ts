import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  Req,
  INestApplication,
} from '@nestjs/common';
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
import type { Request } from 'express';

import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { JwtStrategy } from '../src/auth/strategies/jwt.strategy';
import { Public } from '../src/common/decorators/public.decorator';
import {
  CurrentUser,
  AuthenticatedUser,
} from '../src/common/decorators/current-user.decorator';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';

const INTEGRATION_JWT_SECRET =
  'integration-test-secret-at-least-32-characters-entropy';
const WRONG_JWT_SECRET =
  'wrong-secret-key-different-signature-minimum-32-chars';

let protectedControllerExecutionCount = 0;
let protectedControllerRequestUser: unknown;

@Controller('test-auth')
class TestAuthController {
  @Get('protected')
  getProtected(
    @Req() request: Request,
    @CurrentUser() user: AuthenticatedUser,
    @CurrentUser('id') userId: string,
  ) {
    protectedControllerExecutionCount += 1;
    protectedControllerRequestUser = (request as { user?: unknown }).user;
    return { user, userId };
  }

  @Public()
  @Get('public')
  getPublic(@Req() req: Request) {
    return {
      message: 'public route accessed',
      hasUser: Boolean((req as { user?: unknown }).user),
    };
  }

  @Post('action')
  performAction(
    @CurrentUser('id') authUserId: string,
    @Body() body: { userId?: string },
    @Query('userId') queryUserId?: string,
  ) {
    return {
      authenticatedCallerId: authUserId,
      submittedBodyUserId: body.userId ?? null,
      submittedQueryUserId: queryUserId ?? null,
    };
  }
}

describe('Nest HTTP authentication component integration (Prisma test double)', () => {
  let app: INestApplication;
  let jwtService: JwtService;
  let mockPrisma: {
    user: {
      findUnique: ReturnType<typeof vi.fn>;
    };
  };

  const validTestUser = {
    id: 'user-valid-uuid-001',
    email: 'valid.user@example.com',
    name: 'Valid User',
  };

  beforeAll(async () => {
    mockPrisma = {
      user: {
        findUnique: vi.fn(),
      },
    };

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
      controllers: [TestAuthController],
      providers: [
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
    jwtService = moduleRef.get(JwtService);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    vi.clearAllMocks();
    protectedControllerExecutionCount = 0;
    protectedControllerRequestUser = undefined;
  });

  function createValidToken(payload: { sub: string; email: string }) {
    return jwtService.sign(payload);
  }

  it('1. Valid JWT -> protected route succeeds (200) and request.user contains { id, email, name }', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(validTestUser);
    const token = createValidToken({
      sub: validTestUser.id,
      email: validTestUser.email,
    });

    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.user).toEqual(validTestUser);
    expect(response.body.data.userId).toBe(validTestUser.id);
    expect(protectedControllerExecutionCount).toBe(1);
    expect(protectedControllerRequestUser).toEqual(validTestUser);
  });

  it('2. Missing Authorization header -> 401 Unauthorized', async () => {
    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('3. Malformed JWT -> 401 Unauthorized', async () => {
    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', 'Bearer invalid-not-a-real-jwt-token')
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('4. Expired JWT -> 401 Unauthorized', async () => {
    const expiredToken = jwtService.sign(
      { sub: validTestUser.id, email: validTestUser.email },
      { expiresIn: '-5s' },
    );

    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('5. JWT signed using wrong secret -> 401 Unauthorized', async () => {
    const foreignJwtService = new JwtService({ secret: WRONG_JWT_SECRET });
    const forgedToken = foreignJwtService.sign({
      sub: validTestUser.id,
      email: validTestUser.email,
    });

    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', `Bearer ${forgedToken}`)
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
  });

  it('6. Valid JWT referencing nonexistent or deleted user -> 401 Unauthorized', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(null);
    const token = createValidToken({
      sub: 'deleted-user-uuid',
      email: 'deleted@example.com',
    });

    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', `Bearer ${token}`)
      .expect(401);

    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(401);
    expect(response.body.message).toContain('User account not found');
  });

  it('7. @Public() endpoint without token -> 200 without creating authenticated user', async () => {
    const response = await request(app.getHttpServer())
      .get('/test-auth/public')
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.message).toBe('public route accessed');
    expect(response.body.data.hasUser).toBe(false);
  });

  it('8. @Public() endpoint with invalid token -> 200 without creating authenticated identity', async () => {
    const response = await request(app.getHttpServer())
      .get('/test-auth/public')
      .set('Authorization', 'Bearer corrupt-invalid-token')
      .expect(200);

    expect(response.body.success).toBe(true);
    expect(response.body.data.message).toBe('public route accessed');
    expect(response.body.data.hasUser).toBe(false);
  });

  it('9. Spoofed client identity in headers (x-user-id) must NOT override verified JWT user identity', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(validTestUser);
    const token = createValidToken({
      sub: validTestUser.id,
      email: validTestUser.email,
    });

    const response = await request(app.getHttpServer())
      .get('/test-auth/protected')
      .set('Authorization', `Bearer ${token}`)
      .set('x-user-id', 'attacker-controlled-victim-id')
      .expect(200);

    expect(response.body.data.userId).toBe(validTestUser.id);
    expect(response.body.data.userId).not.toBe('attacker-controlled-victim-id');
  });

  it('10. Client-provided body or query userId must NOT establish authenticated identity', async () => {
    mockPrisma.user.findUnique.mockResolvedValue(validTestUser);
    const token = createValidToken({
      sub: validTestUser.id,
      email: validTestUser.email,
    });

    const response = await request(app.getHttpServer())
      .post('/test-auth/action?userId=spoofed-query-user-id')
      .set('Authorization', `Bearer ${token}`)
      .send({ userId: 'spoofed-body-user-id' })
      .expect(201);

    expect(response.body.data.authenticatedCallerId).toBe(validTestUser.id);
    expect(response.body.data.authenticatedCallerId).not.toBe(
      'spoofed-body-user-id',
    );
    expect(response.body.data.authenticatedCallerId).not.toBe(
      'spoofed-query-user-id',
    );
  });

  describe('A02/A10:2025 — synthetic Prisma failure during authentication', () => {
    it('fails closed without disclosing internal exception details', async () => {
      const dbErrorMessage =
        'FATAL: database connection terminated unexpectedly';
      mockPrisma.user.findUnique.mockRejectedValue(new Error(dbErrorMessage));

      const token = createValidToken({
        sub: validTestUser.id,
        email: validTestUser.email,
      });

      const response = await request(app.getHttpServer())
        .get('/test-auth/protected')
        .set('Authorization', `Bearer ${token}`);

      expect(response.status).toBe(500);
      expect(response.body.success).toBe(false);
      expect(response.body.statusCode).toBe(500);
      expect(response.body.error).toBe('InternalServerError');
      expect(response.body.message).toBe('Internal server error');
      expect(JSON.stringify(response.body)).not.toContain(dbErrorMessage);
      expect(protectedControllerExecutionCount).toBe(0);
      expect(protectedControllerRequestUser).toBeUndefined();
    });
  });
});
