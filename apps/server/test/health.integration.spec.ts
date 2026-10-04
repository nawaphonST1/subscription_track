import { INestApplication } from '@nestjs/common';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
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

import { HealthController } from '../src/health/health.controller';
import { HealthService } from '../src/health/health.service';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { PrismaService } from '../src/prisma/prisma.service';

describe('Nest HTTP Health component integration (Prisma test double)', () => {
  let app: INestApplication;

  const mockPrisma = {
    $queryRaw: vi.fn(),
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      controllers: [HealthController],
      providers: [
        HealthService,
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
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    vi.clearAllMocks();
  });

  it('1. GET /health without an Authorization header succeeds when PostgreSQL is reachable (200, wrapped envelope)', async () => {
    mockPrisma.$queryRaw.mockResolvedValue([{ '?column?': 1 }]);

    const response = await request(app.getHttpServer()).get('/health');

    expect(response.status).toBe(200);
    expect(response.body.success).toBe(true);
    expect(response.body.statusCode).toBe(200);
    expect(response.body.data.status).toBe('ok');
    expect(response.body.data.checks.database).toBe('ok');
    expect(response.body.timestamp).toEqual(expect.any(String));
  });

  it('2. GET /health returns 503 without leaking the raw database error when PostgreSQL is unreachable', async () => {
    const rawErrorMessage =
      'SYNTHETIC_RAW_DATABASE_ERROR: connection terminated unexpectedly';
    mockPrisma.$queryRaw.mockRejectedValue(new Error(rawErrorMessage));

    const response = await request(app.getHttpServer()).get('/health');

    expect(response.status).toBe(503);
    expect(response.body.success).toBe(false);
    expect(response.body.statusCode).toBe(503);
    expect(response.body.message).toBe('Database not ready');
    expect(JSON.stringify(response.body)).not.toContain(rawErrorMessage);
  });
});
