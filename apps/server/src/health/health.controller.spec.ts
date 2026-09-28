import { describe, expect, it, vi, beforeEach } from 'vitest';
import { HealthController } from './health.controller';
import { HealthService } from './health.service';

describe('HealthController', () => {
  let controller: HealthController;
  let serviceMock: HealthService;

  beforeEach(() => {
    serviceMock = {
      check: vi.fn().mockResolvedValue({
        status: 'ok',
        checks: { database: 'ok' },
      }),
    } as unknown as HealthService;

    controller = new HealthController(serviceMock);
  });

  it('delegates check to HealthService', async () => {
    const result = await controller.check();
    expect(result).toEqual({
      status: 'ok',
      checks: { database: 'ok' },
    });
    expect(serviceMock.check).toHaveBeenCalledTimes(1);
  });

  it('returns pong message on ping', () => {
    const result = controller.ping();
    expect(result).toEqual({ message: 'pong' });
  });
});
