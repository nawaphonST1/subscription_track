import { describe, expect, it, vi } from 'vitest';
import { ExecutionContext, ServiceUnavailableException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  MaintenanceGuard,
  MAINTENANCE_MESSAGE,
} from './maintenance.guard';

function createMockContext(url: string): ExecutionContext {
  const req = { url };
  return {
    switchToHttp: () => ({
      getRequest: () => req,
    }),
  } as unknown as ExecutionContext;
}

describe('MaintenanceGuard', () => {
  it('allows all requests when maintenance mode is disabled', () => {
    const configService = {
      get: vi.fn().mockReturnValue(false),
    } as unknown as ConfigService;

    const guard = new MaintenanceGuard(configService);
    const context = createMockContext('/subscriptions');

    expect(guard.canActivate(context)).toBe(true);
  });

  it('allows probe paths even when maintenance mode is active', () => {
    const configService = {
      get: vi.fn().mockReturnValue(true),
    } as unknown as ConfigService;

    const guard = new MaintenanceGuard(configService);

    expect(guard.canActivate(createMockContext('/health'))).toBe(true);
    expect(guard.canActivate(createMockContext('/metrics'))).toBe(true);
    expect(guard.canActivate(createMockContext('/'))).toBe(true);
  });

  it('throws ServiceUnavailableException (503) for api paths when maintenance mode is active', () => {
    const configService = {
      get: vi.fn().mockReturnValue(true),
    } as unknown as ConfigService;

    const guard = new MaintenanceGuard(configService);
    const context = createMockContext('/subscriptions');

    expect(() => guard.canActivate(context)).toThrow(
      ServiceUnavailableException,
    );
    try {
      guard.canActivate(context);
    } catch (err) {
      expect((err as ServiceUnavailableException).message).toBe(
        MAINTENANCE_MESSAGE,
      );
      expect((err as ServiceUnavailableException).getStatus()).toBe(503);
    }
  });
});
