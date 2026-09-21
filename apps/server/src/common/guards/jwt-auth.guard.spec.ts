import { ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { JwtAuthGuard } from './jwt-auth.guard';
import { IS_PUBLIC_KEY, Public } from '../decorators/public.decorator';

class TestProtectedController {
  @Public()
  publicHandler() {}

  protectedHandler() {}
}

@Public()
class TestPublicController {
  @Public()
  publicHandler() {}

  unannotatedHandler() {}
}

describe('JwtAuthGuard', () => {
  let guard: JwtAuthGuard;
  let reflector: Reflector;

  beforeEach(() => {
    reflector = new Reflector();
    guard = new JwtAuthGuard(reflector);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function createMockContext(
    handler: (...args: unknown[]) => unknown,
    targetClass: new (...args: unknown[]) => unknown,
  ): ExecutionContext {
    return {
      getHandler: () => handler,
      getClass: () => targetClass,
      switchToHttp: () => ({
        getRequest: () => ({}),
        getResponse: () => ({}),
        getNext: () => ({}),
      }),
    } as unknown as ExecutionContext;
  }

  it('allows access when handler is marked with @Public() without invoking Passport', () => {
    const controller = new TestProtectedController();
    const context = createMockContext(
      controller.publicHandler,
      TestProtectedController,
    );

    const superCanActivateSpy = vi
      .spyOn(AuthGuard('jwt').prototype, 'canActivate')
      .mockReturnValue(false);

    const result = guard.canActivate(context);

    expect(result).toBe(true);
    expect(superCanActivateSpy).not.toHaveBeenCalled();
  });

  it('allows access when controller class is marked with @Public() without invoking Passport', () => {
    const controller = new TestPublicController();
    const context = createMockContext(
      controller.unannotatedHandler,
      TestPublicController,
    );

    const superCanActivateSpy = vi
      .spyOn(AuthGuard('jwt').prototype, 'canActivate')
      .mockReturnValue(false);

    const result = guard.canActivate(context);

    expect(result).toBe(true);
    expect(superCanActivateSpy).not.toHaveBeenCalled();
  });

  it('delegates to Passport AuthGuard canActivate() when route is protected', async () => {
    const controller = new TestProtectedController();
    const context = createMockContext(
      controller.protectedHandler,
      TestProtectedController,
    );

    const superCanActivateSpy = vi
      .spyOn(AuthGuard('jwt').prototype, 'canActivate')
      .mockReturnValue(true);

    const result = await guard.canActivate(context);

    expect(superCanActivateSpy).toHaveBeenCalledTimes(1);
    expect(superCanActivateSpy).toHaveBeenCalledWith(context);
    expect(result).toBe(true);
  });

  it('respects Reflector handler metadata precedence over class metadata', async () => {
    const overrideSpy = vi.spyOn(reflector, 'getAllAndOverride');
    const controller = new TestProtectedController();
    const context = createMockContext(
      controller.publicHandler,
      TestProtectedController,
    );

    await guard.canActivate(context);

    expect(overrideSpy).toHaveBeenCalledWith(IS_PUBLIC_KEY, [
      controller.publicHandler,
      TestProtectedController,
    ]);
  });

  it('enforces default-deny when no @Public() metadata is present and Passport rejects', async () => {
    const controller = new TestProtectedController();
    const context = createMockContext(
      controller.protectedHandler,
      TestProtectedController,
    );

    vi.spyOn(AuthGuard('jwt').prototype, 'canActivate').mockReturnValue(false);

    const result = await guard.canActivate(context);

    expect(result).toBe(false);
  });
});
