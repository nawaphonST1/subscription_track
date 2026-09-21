import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { JwtPayload, JwtStrategy } from './jwt.strategy';
import { PrismaService } from '../../prisma/prisma.service';

describe('JwtStrategy', () => {
  let strategy: JwtStrategy;
  let prismaService: {
    user: {
      findUnique: ReturnType<typeof vi.fn>;
    };
  };
  let configService: {
    getOrThrow: ReturnType<typeof vi.fn>;
    get: ReturnType<typeof vi.fn>;
  };

  const TEST_SECRET = 'deterministic-test-secret-at-least-32-chars-long';

  beforeEach(() => {
    prismaService = {
      user: {
        findUnique: vi.fn(),
      },
    };

    configService = {
      getOrThrow: vi.fn().mockImplementation((key: string) => {
        if (key === 'JWT_SECRET') return TEST_SECRET;
        throw new Error(`Configuration property "${key}" does not exist`);
      }),
      get: vi.fn(),
    };

    strategy = new JwtStrategy(
      prismaService as unknown as PrismaService,
      configService as unknown as ConfigService,
    );
  });

  it('fails fast during instantiation if JWT_SECRET is missing from ConfigService', () => {
    const brokenConfigService = {
      getOrThrow: vi.fn().mockImplementation((key: string) => {
        throw new Error(`Configuration property "${key}" does not exist`);
      }),
    };

    expect(() => {
      new JwtStrategy(
        prismaService as unknown as PrismaService,
        brokenConfigService as unknown as ConfigService,
      );
    }).toThrow('Configuration property "JWT_SECRET" does not exist');
    expect(brokenConfigService.getOrThrow).toHaveBeenCalledWith('JWT_SECRET');
  });

  it('resolves authenticated user identity when valid payload and user exists', async () => {
    const mockUser = {
      id: 'usr-1234-uuid',
      email: 'verified@example.com',
      name: 'Jane Doe',
    };
    prismaService.user.findUnique.mockResolvedValue(mockUser);

    const payload: JwtPayload = {
      sub: 'usr-1234-uuid',
      email: 'verified@example.com',
    };

    const result = await strategy.validate(payload);

    expect(result).toEqual({
      id: 'usr-1234-uuid',
      email: 'verified@example.com',
      name: 'Jane Doe',
    });
  });

  it('uses payload.sub as the canonical User id lookup key', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      id: 'canonical-sub-id',
      email: 'canonical@example.com',
      name: 'Canonical User',
    });

    const payload: JwtPayload = {
      sub: 'canonical-sub-id',
      email: 'canonical@example.com',
    };

    await strategy.validate(payload);

    expect(prismaService.user.findUnique).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 'canonical-sub-id' },
      }),
    );
  });

  it('throws UnauthorizedException when referenced user does not exist', async () => {
    prismaService.user.findUnique.mockResolvedValue(null);

    const payload: JwtPayload = {
      sub: 'nonexistent-user-id',
      email: 'ghost@example.com',
    };

    await expect(strategy.validate(payload)).rejects.toThrow(
      UnauthorizedException,
    );
    await expect(strategy.validate(payload)).rejects.toThrow(
      'User account not found',
    );
  });

  it('projects only minimal identity fields and never requests sensitive or unnecessary data', async () => {
    prismaService.user.findUnique.mockResolvedValue({
      id: 'usr-1',
      email: 'test@example.com',
      name: 'Test',
    });

    const payload: JwtPayload = {
      sub: 'usr-1',
      email: 'test@example.com',
    };

    await strategy.validate(payload);

    expect(prismaService.user.findUnique).toHaveBeenCalledTimes(1);
    const callArgs = prismaService.user.findUnique.mock.calls[0][0];

    // Verify exact projection
    expect(callArgs.select).toEqual({
      id: true,
      email: true,
      name: true,
    });

    // Explicitly verify sensitive fields are not selected
    expect(callArgs.select.password_hash).toBeUndefined();
    expect(callArgs.select.security_pin_hash).toBeUndefined();
    expect(callArgs.select.monthly_income).toBeUndefined();
  });
});
