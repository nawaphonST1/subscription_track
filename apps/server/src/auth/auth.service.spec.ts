import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import * as bcrypt from 'bcryptjs';
import {
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';

const mockVerifyIdToken = vi.fn();
const mockGetTokenInfo = vi.fn();

vi.mock('google-auth-library', () => {
  return {
    OAuth2Client: vi.fn().mockImplementation(function (this: any) {
      this.verifyIdToken = mockVerifyIdToken;
      this.getTokenInfo = mockGetTokenInfo;
      return this;
    }),
  };
});

describe('AuthService pin_configured responses', () => {
  let authService: AuthService;
  let mockPrisma: any;
  let mockJwtService: any;
  const originalEnv = process.env;

  beforeEach(() => {
    process.env = { ...originalEnv, GOOGLE_CLIENT_ID: 'test-google-client-id' };
    mockVerifyIdToken.mockReset();
    mockGetTokenInfo.mockReset();
    mockPrisma = {
      user: {
        findUnique: vi.fn(),
        create: vi.fn(),
      },
    };
    mockJwtService = {
      sign: vi.fn().mockReturnValue('mock-jwt-token'),
    };
    authService = new AuthService(mockPrisma, mockJwtService);
  });

  afterEach(() => {
    process.env = originalEnv;
  });

  describe('register', () => {
    it('returns pin_configured: false when user registers with default PIN', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue({
        id: 'u-1',
        email: 'new@example.com',
        name: 'New User',
        monthly_income: 0,
        created_at: new Date(),
      });

      const res = await authService.register({
        email: 'new@example.com',
        password: 'password123',
        name: 'New User',
        security_pin: '111111',
      });

      expect(res.user.pin_configured).toBe(false);
      expect(res.token).toBe('mock-jwt-token');
    });

    it('returns pin_configured: true when user registers with custom PIN', async () => {
      mockPrisma.user.findUnique.mockResolvedValue(null);
      mockPrisma.user.create.mockResolvedValue({
        id: 'u-2',
        email: 'custom@example.com',
        name: 'Custom User',
        monthly_income: 0,
        created_at: new Date(),
      });

      const res = await authService.register({
        email: 'custom@example.com',
        password: 'password123',
        name: 'Custom User',
        security_pin: '849201',
      });

      expect(res.user.pin_configured).toBe(true);
      expect(res.token).toBe('mock-jwt-token');
    });
  });

  describe('login', () => {
    it('returns pin_configured: false when logging in to account with default PIN', async () => {
      const defaultPinHash = await bcrypt.hash('111111', 10);
      const passwordHash = await bcrypt.hash('password123', 10);

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'u-default',
        email: 'default@example.com',
        password_hash: passwordHash,
        security_pin_hash: defaultPinHash,
        name: 'Default User',
        monthly_income: 0,
        created_at: new Date(),
      });

      const res = await authService.login({
        email: 'default@example.com',
        password: 'password123',
      });

      expect(res.user.pin_configured).toBe(false);
      expect(res.token).toBe('mock-jwt-token');
    });

    it('returns pin_configured: true when logging in to account with custom PIN', async () => {
      const customPinHash = await bcrypt.hash('987654', 10);
      const passwordHash = await bcrypt.hash('password123', 10);

      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'u-custom',
        email: 'custom@example.com',
        password_hash: passwordHash,
        security_pin_hash: customPinHash,
        name: 'Custom User',
        monthly_income: 0,
        created_at: new Date(),
      });

      const res = await authService.login({
        email: 'custom@example.com',
        password: 'password123',
      });

      expect(res.user.pin_configured).toBe(true);
      expect(res.token).toBe('mock-jwt-token');
    });
  });

  describe('socialLogin', () => {
    it('returns pin_configured: false when newly created via Google login', async () => {
      mockVerifyIdToken.mockResolvedValue({
        getPayload: () => ({
          email: 'google@example.com',
          email_verified: true,
          name: 'Google User',
        }),
      });
      mockPrisma.user.findUnique.mockResolvedValue(null);
      const defaultPinHash = await bcrypt.hash('111111', 10);
      mockPrisma.user.create.mockResolvedValue({
        id: 'u-google-new',
        email: 'google@example.com',
        name: 'Google User',
        monthly_income: 0,
        security_pin_hash: defaultPinHash,
        created_at: new Date(),
      });

      const res = await authService.socialLogin({
        email: 'google@example.com',
        provider: 'google',
        token: 'valid-google-token',
      } as any);

      expect(res.user.pin_configured).toBe(false);
      expect(res.token).toBe('mock-jwt-token');
    });

    it('returns pin_configured: true when returning Google user with configured PIN', async () => {
      mockVerifyIdToken.mockResolvedValue({
        getPayload: () => ({
          email: 'google-return@example.com',
          email_verified: true,
          name: 'Google User',
        }),
      });
      const customPinHash = await bcrypt.hash('654321', 10);
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'u-google-returning',
        email: 'google-return@example.com',
        name: 'Google User',
        monthly_income: 0,
        security_pin_hash: customPinHash,
        created_at: new Date(),
      });

      const res = await authService.socialLogin({
        email: 'google-return@example.com',
        provider: 'google',
        token: 'valid-google-token',
      } as any);

      expect(res.user.pin_configured).toBe(true);
      expect(res.token).toBe('mock-jwt-token');
    });

    it('fails closed with InternalServerErrorException when GOOGLE_CLIENT_ID is missing or empty', async () => {
      delete process.env.GOOGLE_CLIENT_ID;

      await expect(
        authService.socialLogin({
          email: 'victim@example.com',
          provider: 'google',
          token: 'any-token',
        } as any),
      ).rejects.toThrow(InternalServerErrorException);

      process.env.GOOGLE_CLIENT_ID = '   ';

      await expect(
        authService.socialLogin({
          email: 'victim@example.com',
          provider: 'google',
          token: 'any-token',
        } as any),
      ).rejects.toThrow(InternalServerErrorException);
    });

    it('rejects unverified Google emails from ID token with UnauthorizedException', async () => {
      mockVerifyIdToken.mockResolvedValue({
        getPayload: () => ({
          email: 'unverified@example.com',
          email_verified: false,
          name: 'Unverified User',
        }),
      });

      await expect(
        authService.socialLogin({
          email: 'unverified@example.com',
          provider: 'google',
          token: 'token-unverified-email',
        } as any),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('rejects access token when audience does not match GOOGLE_CLIENT_ID', async () => {
      mockVerifyIdToken.mockRejectedValue(
        new Error('Wrong number of segments in token'),
      );
      mockGetTokenInfo.mockResolvedValue({
        aud: 'wrong-audience-client-id',
        email: 'victim@example.com',
      });

      await expect(
        authService.socialLogin({
          email: 'victim@example.com',
          provider: 'google',
          token: 'wrong-aud-access-token',
        } as any),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('succeeds via access token fallback when audience matches and email exists', async () => {
      mockVerifyIdToken.mockRejectedValue(
        new Error('Wrong number of segments in token'),
      );
      mockGetTokenInfo.mockResolvedValue({
        aud: 'test-google-client-id',
        email: 'access-user@example.com',
      });
      mockPrisma.user.findUnique.mockResolvedValue(null);
      const defaultPinHash = await bcrypt.hash('111111', 10);
      mockPrisma.user.create.mockResolvedValue({
        id: 'u-access',
        email: 'access-user@example.com',
        name: 'Google User',
        monthly_income: 0,
        security_pin_hash: defaultPinHash,
        created_at: new Date(),
      });

      const res = await authService.socialLogin({
        email: 'spoofed@example.com',
        provider: 'google',
        token: 'valid-access-token',
      } as any);

      expect(res.user.email).toBe('access-user@example.com');
      expect(res.token).toBe('mock-jwt-token');
    });

    it('overrides spoofed request email with verified token email to prevent account hijacking', async () => {
      mockVerifyIdToken.mockResolvedValue({
        getPayload: () => ({
          email: 'real-owner@example.com',
          email_verified: true,
          name: 'Real Owner',
        }),
      });
      mockPrisma.user.findUnique.mockResolvedValue({
        id: 'u-real',
        email: 'real-owner@example.com',
        name: 'Real Owner',
        monthly_income: 0,
        security_pin_hash: 'hash',
        created_at: new Date(),
      });

      const res = await authService.socialLogin({
        email: 'hijacked-admin@example.com',
        provider: 'google',
        token: 'valid-id-token',
      } as any);

      expect(res.user.email).toBe('real-owner@example.com');
      expect(mockPrisma.user.findUnique).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { email: 'real-owner@example.com' },
        }),
      );
    });
  });
});
