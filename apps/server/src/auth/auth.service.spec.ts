import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as bcrypt from 'bcryptjs';
import { AuthService } from './auth.service';
import { JwtService } from '@nestjs/jwt';

describe('AuthService pin_configured responses', () => {
  let authService: AuthService;
  let mockPrisma: any;
  let mockJwtService: any;

  beforeEach(() => {
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
      } as any);

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
      } as any);

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
        token: 'mock-google-token',
      } as any);

      expect(res.user.pin_configured).toBe(false);
      expect(res.token).toBe('mock-jwt-token');
    });

    it('returns pin_configured: true when returning Google user with configured PIN', async () => {
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
        token: 'mock-google-token',
      } as any);

      expect(res.user.pin_configured).toBe(true);
      expect(res.token).toBe('mock-jwt-token');
    });
  });
});
