import { describe, it, expect, beforeEach, vi } from 'vitest';
import { ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import * as bcrypt from 'bcryptjs';
import { PinSetupGuard } from './pin-setup.guard';
import { CacheService } from '../../cache/cache.service';
import { DEFAULT_PIN, RESET_PIN_PREFIX } from '../security/pin.util';

describe('PinSetupGuard', () => {
  let guard: PinSetupGuard;
  let reflector: Reflector;
  let mockPrisma: any;
  let cacheService: CacheService;

  beforeEach(() => {
    reflector = new Reflector();
    mockPrisma = {
      user: {
        findUnique: vi.fn(),
      },
    };
    cacheService = new CacheService();
    guard = new PinSetupGuard(reflector, mockPrisma, cacheService);
  });

  function createMockContext(
    user: any,
    isPublic = false,
    allowWithoutPin = false,
  ): ExecutionContext {
    vi.spyOn(reflector, 'getAllAndOverride').mockImplementation(
      (key: unknown) => {
        if (key === 'isPublic') return isPublic;
        if (key === 'allowWithoutPin') return allowWithoutPin;
        return undefined;
      },
    );

    const request = { user };
    return {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
      getHandler: () => ({}),
      getClass: () => ({}),
    } as unknown as ExecutionContext;
  }

  it('allows public routes unconditionally', async () => {
    const context = createMockContext(undefined, true, false);
    expect(await guard.canActivate(context)).toBe(true);
    expect(mockPrisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('allows routes decorated with @AllowWithoutPin even if user has unconfigured PIN', async () => {
    const context = createMockContext({ id: 'u-1' }, false, true);
    expect(await guard.canActivate(context)).toBe(true);
    expect(mockPrisma.user.findUnique).not.toHaveBeenCalled();
  });

  it('allows access when user has a configured custom PIN', async () => {
    const customHash = await bcrypt.hash('987654', 10);
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: customHash,
    });

    const context = createMockContext({ id: 'u-configured' }, false, false);
    expect(await guard.canActivate(context)).toBe(true);
  });

  it('throws 403 Forbidden PIN_SETUP_REQUIRED when user is on default PIN 111111', async () => {
    const defaultHash = await bcrypt.hash(DEFAULT_PIN, 10);
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: defaultHash,
    });

    const context = createMockContext({ id: 'u-default' }, false, false);

    await expect(guard.canActivate(context)).rejects.toThrow(
      ForbiddenException,
    );

    try {
      await guard.canActivate(context);
    } catch (err: any) {
      expect(err.getResponse()).toMatchObject({
        statusCode: 403,
        code: 'PIN_SETUP_REQUIRED',
      });
    }
  });

  it('throws 403 Forbidden PIN_SETUP_REQUIRED when user PIN has been rotated/reset', async () => {
    mockPrisma.user.findUnique.mockResolvedValue({
      security_pin_hash: `${RESET_PIN_PREFIX}reset-uuid-hash`,
    });

    const context = createMockContext({ id: 'u-reset' }, false, false);

    await expect(guard.canActivate(context)).rejects.toThrow(
      ForbiddenException,
    );
  });
});
