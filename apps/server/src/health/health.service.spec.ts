import { describe, expect, it, vi, beforeEach } from 'vitest';
import { ServiceUnavailableException } from '@nestjs/common';
import { HealthService } from './health.service';

describe('HealthService', () => {
  let service: HealthService;
  let prismaMock: any;

  beforeEach(() => {
    prismaMock = {
      $queryRaw: vi.fn(),
    };

    service = new HealthService(prismaMock);
  });

  it('reports ready when PostgreSQL is reachable', async () => {
    prismaMock.$queryRaw.mockResolvedValue([{ '?column?': 1 }]);

    await expect(service.check()).resolves.toEqual({
      status: 'ok',
      checks: {
        database: 'ok',
      },
    });
  });

  it('throws a sanitized ServiceUnavailableException when PostgreSQL is unreachable', async () => {
    const rawErrorMessage =
      'SYNTHETIC_RAW_DATABASE_ERROR: connection terminated unexpectedly';
    prismaMock.$queryRaw.mockRejectedValue(new Error(rawErrorMessage));

    await expect(service.check()).rejects.toBeInstanceOf(
      ServiceUnavailableException,
    );

    try {
      await service.check();
      throw new Error('expected service.check() to reject');
    } catch (error) {
      expect(error).toBeInstanceOf(ServiceUnavailableException);
      const exception = error as ServiceUnavailableException;
      expect(exception.getStatus()).toBe(503);
      expect(exception.message).toBe('Database not ready');
      expect(JSON.stringify(exception.getResponse())).not.toContain(
        rawErrorMessage,
      );
    }
  });
});
