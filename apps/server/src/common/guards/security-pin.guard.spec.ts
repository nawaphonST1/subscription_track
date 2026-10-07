import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  BadRequestException,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SecurityPinGuard } from './security-pin.guard';

describe('SecurityPinGuard', () => {
  let guard: SecurityPinGuard;
  let reflector: Reflector;
  let mockSecurityPinService: any;

  beforeEach(() => {
    reflector = new Reflector();
    mockSecurityPinService = {
      verifyPin: vi.fn(),
    };
    guard = new SecurityPinGuard(reflector, mockSecurityPinService);
  });

  function createMockContext(
    req: { user?: any; body?: any; headers?: any },
    requiresPin = true,
  ): ExecutionContext {
    vi.spyOn(reflector, 'getAllAndOverride').mockReturnValue(requiresPin);

    return {
      switchToHttp: () => ({
        getRequest: () => req,
      }),
      getHandler: () => ({}),
      getClass: () => ({}),
    } as unknown as ExecutionContext;
  }

  it('allows request through when route is not decorated with @RequireSecurityPin', async () => {
    const context = createMockContext({}, false);
    expect(await guard.canActivate(context)).toBe(true);
    expect(mockSecurityPinService.verifyPin).not.toHaveBeenCalled();
  });

  it('throws 400 BadRequestException when PIN is missing from both body and header', async () => {
    const context = createMockContext({
      user: { id: 'user-1' },
      body: {},
      headers: {},
    });

    await expect(guard.canActivate(context)).rejects.toThrow(
      BadRequestException,
    );
  });

  it('verifies PIN passed in body as security_pin', async () => {
    mockSecurityPinService.verifyPin.mockResolvedValue(true);

    const context = createMockContext({
      user: { id: 'user-1' },
      body: { security_pin: '847291' },
      headers: {},
    });

    expect(await guard.canActivate(context)).toBe(true);
    expect(mockSecurityPinService.verifyPin).toHaveBeenCalledWith(
      'user-1',
      '847291',
    );
  });

  it('verifies PIN passed in x-security-pin header', async () => {
    mockSecurityPinService.verifyPin.mockResolvedValue(true);

    const context = createMockContext({
      user: { id: 'user-1' },
      body: {},
      headers: { 'x-security-pin': '847291' },
    });

    expect(await guard.canActivate(context)).toBe(true);
    expect(mockSecurityPinService.verifyPin).toHaveBeenCalledWith(
      'user-1',
      '847291',
    );
  });

  it('propagates ForbiddenException when securityPinService rejects invalid PIN', async () => {
    mockSecurityPinService.verifyPin.mockRejectedValue(
      new ForbiddenException('Invalid 6-digit security PIN'),
    );

    const context = createMockContext({
      user: { id: 'user-1' },
      body: { security_pin: '000000' },
      headers: {},
    });

    await expect(guard.canActivate(context)).rejects.toThrow(
      ForbiddenException,
    );
  });
});
