import { describe, it, expect, vi, beforeEach } from 'vitest';
import * as bcrypt from 'bcryptjs';
import {
  rotateDefaultPins,
  generateRandomPin,
  DEFAULT_PIN,
} from './rotate-default-pins';

describe('rotate-default-pins', () => {
  describe('generateRandomPin', () => {
    it('generates a 6-digit numeric string not equal to the default PIN', () => {
      for (let i = 0; i < 50; i++) {
        const pin = generateRandomPin();
        expect(pin).toHaveLength(6);
        expect(/^\d{6}$/.test(pin)).toBe(true);
        expect(pin).not.toBe(DEFAULT_PIN);
      }
    });
  });

  describe('rotateDefaultPins logic with mocked Prisma client', () => {
    let mockPrisma: {
      user: {
        findMany: ReturnType<typeof vi.fn>;
        update: ReturnType<typeof vi.fn>;
      };
    };
    let mockLogger: {
      log: ReturnType<typeof vi.fn>;
      warn: ReturnType<typeof vi.fn>;
      error: ReturnType<typeof vi.fn>;
    };

    beforeEach(() => {
      mockPrisma = {
        user: {
          findMany: vi.fn(),
          update: vi.fn(),
        },
      };
      mockLogger = {
        log: vi.fn(),
        warn: vi.fn(),
        error: vi.fn(),
      };
    });

    it('identifies only default-PIN accounts and updates them with newly hashed random PINs', async () => {
      const defaultHash = await bcrypt.hash('111111', 10);
      const customHash = await bcrypt.hash('987654', 10);

      const mockUsers = [
        { id: 'user-default-1', security_pin_hash: defaultHash },
        { id: 'user-custom-2', security_pin_hash: customHash },
        { id: 'user-default-3', security_pin_hash: defaultHash },
      ];

      mockPrisma.user.findMany.mockResolvedValueOnce(mockUsers);
      mockPrisma.user.update.mockResolvedValue({});

      const report = await rotateDefaultPins({
        prisma: mockPrisma as any,
        logger: mockLogger,
        batchSize: 10,
        dryRun: false,
      });

      // Assert report summary
      expect(report.scannedCount).toBe(3);
      expect(report.defaultPinCount).toBe(2);
      expect(report.rotatedCount).toBe(2);
      expect(report.dryRun).toBe(false);

      // Assert prisma updates were called ONLY for users with the default PIN
      expect(mockPrisma.user.update).toHaveBeenCalledTimes(2);
      expect(mockPrisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'user-default-1' },
          data: { security_pin_hash: expect.any(String) },
        }),
      );
      expect(mockPrisma.user.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'user-default-3' },
          data: { security_pin_hash: expect.any(String) },
        }),
      );
      expect(mockPrisma.user.update).not.toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: 'user-custom-2' },
        }),
      );

      // Assert that updated hashes are valid and not the default PIN
      const call1Hash =
        mockPrisma.user.update.mock.calls[0][0].data.security_pin_hash;
      const call2Hash =
        mockPrisma.user.update.mock.calls[1][0].data.security_pin_hash;

      expect(await bcrypt.compare('111111', call1Hash)).toBe(false);
      expect(await bcrypt.compare('111111', call2Hash)).toBe(false);
      expect(call1Hash).not.toBe(call2Hash);
    });

    it('does not perform database updates in dryRun mode', async () => {
      const defaultHash = await bcrypt.hash('111111', 10);

      const mockUsers = [
        { id: 'user-default-1', security_pin_hash: defaultHash },
      ];

      mockPrisma.user.findMany.mockResolvedValueOnce(mockUsers);

      const report = await rotateDefaultPins({
        prisma: mockPrisma as any,
        logger: mockLogger,
        batchSize: 10,
        dryRun: true,
      });

      expect(report.scannedCount).toBe(1);
      expect(report.defaultPinCount).toBe(1);
      expect(report.rotatedCount).toBe(0);
      expect(report.dryRun).toBe(true);

      expect(mockPrisma.user.update).not.toHaveBeenCalled();
    });

    it('never logs plaintext PINs or sensitive secrets', async () => {
      const defaultHash = await bcrypt.hash('111111', 10);
      const mockUsers = [{ id: 'user-1', security_pin_hash: defaultHash }];

      mockPrisma.user.findMany.mockResolvedValueOnce(mockUsers);
      mockPrisma.user.update.mockResolvedValue({});

      const testGeneratedPin = '482910';

      await rotateDefaultPins({
        prisma: mockPrisma as any,
        logger: mockLogger,
        dryRun: false,
        generatePin: () => testGeneratedPin,
      });

      const capturedLogOutput = [
        ...mockLogger.log.mock.calls.map((c) => c[0]),
        ...(mockLogger.warn?.mock.calls.map((c) => c[0]) ?? []),
        ...(mockLogger.error?.mock.calls.map((c) => c[0]) ?? []),
      ];

      // Format-agnostic check against actual generated PIN value appearing anywhere
      expect(capturedLogOutput.join('\n')).not.toContain(testGeneratedPin);

      for (const msg of capturedLogOutput) {
        // Must never print a plaintext PIN or mention secrets
        expect(msg).not.toMatch(/pin=\d{6}/i);
        expect(msg).not.toMatch(/secret/i);
        expect(msg).not.toMatch(/plaintext/i);
      }
    });

    it('supports batch pagination via cursor when scanning large user tables', async () => {
      const defaultHash = await bcrypt.hash('111111', 10);

      const batch1 = [
        { id: 'user-1', security_pin_hash: defaultHash },
        { id: 'user-2', security_pin_hash: defaultHash },
      ];
      const batch2 = [{ id: 'user-3', security_pin_hash: defaultHash }];

      mockPrisma.user.findMany
        .mockResolvedValueOnce(batch1)
        .mockResolvedValueOnce(batch2);
      mockPrisma.user.update.mockResolvedValue({});

      const report = await rotateDefaultPins({
        prisma: mockPrisma as any,
        logger: mockLogger,
        batchSize: 2,
        dryRun: false,
      });

      expect(mockPrisma.user.findMany).toHaveBeenCalledTimes(2);
      expect(report.scannedCount).toBe(3);
      expect(report.defaultPinCount).toBe(3);
      expect(report.rotatedCount).toBe(3);
      expect(mockPrisma.user.update).toHaveBeenCalledTimes(3);
    });
  });
});
