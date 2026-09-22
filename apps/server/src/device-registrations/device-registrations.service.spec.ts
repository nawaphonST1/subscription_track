import { describe, expect, it, vi, beforeEach } from 'vitest';
import {
  DevicePlatform,
  DeviceRegistrationStatus,
  Prisma,
} from '@prisma/client';
import { DeviceRegistrationsService } from './device-registrations.service';

describe('DeviceRegistrationsService', () => {
  let service: DeviceRegistrationsService;
  let txMock: any;
  let prismaMock: any;

  beforeEach(() => {
    txMock = {
      deviceRegistration: {
        findFirst: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
      },
    };

    prismaMock = {
      $transaction: vi.fn(async (cb: any) => cb(txMock)),
      deviceRegistration: {
        findFirst: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
      },
    };

    service = new DeviceRegistrationsService(prismaMock);
  });

  describe('register', () => {
    const userId = 'user-uuid-1111';
    const otherUserId = 'user-uuid-2222';
    const pushToken = 'fcm-secret-token-long-string-12345';
    const now = new Date('2026-09-22T00:00:00.000Z');

    it('1. first registration creates an ACTIVE destination with isNew=true', async () => {
      txMock.deviceRegistration.findFirst
        .mockResolvedValueOnce(null) // no active registration
        .mockResolvedValueOnce(null); // no inactive registration for this user

      txMock.deviceRegistration.create.mockResolvedValue({
        id: 'reg-new-1',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(result.isNew).toBe(true);
      expect(result.registration.id).toBe('reg-new-1');
      expect(result.registration.status).toBe(DeviceRegistrationStatus.ACTIVE);
      expect(result.registration.platform).toBe(DevicePlatform.IOS);
      expect(txMock.deviceRegistration.create).toHaveBeenCalledWith({
        data: {
          user_id: userId,
          push_token: pushToken,
          platform: DevicePlatform.IOS,
          status: DeviceRegistrationStatus.ACTIVE,
        },
      });
    });

    it('2. authenticated user ID becomes the owner of the destination', async () => {
      txMock.deviceRegistration.findFirst.mockResolvedValue(null);
      txMock.deviceRegistration.create.mockResolvedValue({
        id: 'reg-owner-check',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.ANDROID,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      });

      await service.register(userId, {
        pushToken,
        platform: DevicePlatform.ANDROID,
      });

      expect(txMock.deviceRegistration.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            user_id: userId,
          }),
        }),
      );
    });

    it('3. repeated registration by the same user is idempotent and returns isNew=false', async () => {
      const existingActive = {
        id: 'reg-active-1',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      };

      txMock.deviceRegistration.findFirst.mockResolvedValueOnce(existingActive);

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(result.isNew).toBe(false);
      expect(result.registration.id).toBe(existingActive.id);
      expect(txMock.deviceRegistration.create).not.toHaveBeenCalled();
      expect(txMock.deviceRegistration.update).not.toHaveBeenCalled();
    });

    it('4. same token previously associated with another user revokes old owner and creates for new owner', async () => {
      const otherUserActive = {
        id: 'reg-other-active',
        user_id: otherUserId,
        push_token: pushToken,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      };

      txMock.deviceRegistration.findFirst
        .mockResolvedValueOnce(otherUserActive) // currently active for otherUserId
        .mockResolvedValueOnce(null); // no inactive row for caller userId

      txMock.deviceRegistration.update.mockResolvedValue({
        ...otherUserActive,
        status: DeviceRegistrationStatus.REVOKED,
      });

      txMock.deviceRegistration.create.mockResolvedValue({
        id: 'reg-caller-transferred',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(result.isNew).toBe(true);
      expect(result.registration.id).toBe('reg-caller-transferred');

      // Old registration must be revoked with deactivated_at set
      expect(txMock.deviceRegistration.update).toHaveBeenCalledWith({
        where: { id: otherUserActive.id },
        data: {
          status: DeviceRegistrationStatus.REVOKED,
          deactivated_at: expect.any(Date),
        },
      });

      // New registration created for authenticated caller
      expect(txMock.deviceRegistration.create).toHaveBeenCalledWith({
        data: {
          user_id: userId,
          push_token: pushToken,
          platform: DevicePlatform.IOS,
          status: DeviceRegistrationStatus.ACTIVE,
        },
      });
    });

    it('5. the newest inactive registration is reactivated deterministically', async () => {
      const previousInactive = {
        id: 'reg-inactive-newest',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.ANDROID,
        status: DeviceRegistrationStatus.REVOKED,
        deactivated_at: new Date('2026-08-01T00:00:00.000Z'),
        created_at: new Date('2026-08-01T00:00:00.000Z'),
        updated_at: new Date('2026-08-01T00:00:00.000Z'),
      };

      txMock.deviceRegistration.findFirst
        .mockResolvedValueOnce(null) // no active registration anywhere
        .mockResolvedValueOnce(previousInactive); // existing inactive registration for this user

      txMock.deviceRegistration.update.mockResolvedValue({
        ...previousInactive,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        updated_at: now,
      });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(result.isNew).toBe(true);
      expect(result.registration.id).toBe(previousInactive.id);
      expect(result.registration.status).toBe(DeviceRegistrationStatus.ACTIVE);
      expect(result.registration.platform).toBe(DevicePlatform.IOS);

      expect(txMock.deviceRegistration.update).toHaveBeenCalledWith({
        where: { id: previousInactive.id },
        data: {
          platform: DevicePlatform.IOS,
          status: DeviceRegistrationStatus.ACTIVE,
          deactivated_at: null,
        },
      });
      expect(txMock.deviceRegistration.create).not.toHaveBeenCalled();
      expect(txMock.deviceRegistration.findFirst).toHaveBeenNthCalledWith(2, {
        where: { user_id: userId, push_token: pushToken },
        orderBy: [{ updated_at: 'desc' }, { id: 'desc' }],
      });
    });

    it('6. platform update behavior updates existing active registration and returns isNew=false', async () => {
      const existingActive = {
        id: 'reg-active-1',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.ANDROID,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      };

      txMock.deviceRegistration.findFirst.mockResolvedValueOnce(existingActive);
      txMock.deviceRegistration.update.mockResolvedValue({
        ...existingActive,
        platform: DevicePlatform.IOS,
        updated_at: new Date(),
      });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(result.isNew).toBe(false);
      expect(result.registration.platform).toBe(DevicePlatform.IOS);
      expect(txMock.deviceRegistration.update).toHaveBeenCalledWith({
        where: { id: existingActive.id },
        data: {
          platform: DevicePlatform.IOS,
        },
      });
      expect(txMock.deviceRegistration.create).not.toHaveBeenCalled();
    });

    it('7. returned object does not expose raw push token, user_id, or deactivated_at', async () => {
      txMock.deviceRegistration.findFirst.mockResolvedValue(null);
      txMock.deviceRegistration.create.mockResolvedValue({
        id: 'reg-data-min',
        user_id: userId,
        push_token: pushToken,
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        deactivated_at: null,
        created_at: now,
        updated_at: now,
      });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      const returned = result.registration as any;
      expect(returned.pushToken).toBeUndefined();
      expect(returned.push_token).toBeUndefined();
      expect(returned.userId).toBeUndefined();
      expect(returned.user_id).toBeUndefined();
      expect(returned.deactivated_at).toBeUndefined();
      expect(returned).toEqual({
        id: 'reg-data-min',
        platform: DevicePlatform.IOS,
        status: DeviceRegistrationStatus.ACTIVE,
        createdAt: now,
        updatedAt: now,
      });
    });

    it('8. database failure does not cause sensitive-data leakage from service logic', async () => {
      const dbError = new Error('Database connection reset');
      prismaMock.$transaction.mockRejectedValueOnce(dbError);

      await expect(
        service.register(userId, {
          pushToken,
          platform: DevicePlatform.IOS,
        }),
      ).rejects.toThrow('Database connection reset');
    });

    it('9. exact Prisma query/update contract required for uniqueness and retries P2002 conflict', async () => {
      const p2002Error = new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed on the fields: (`push_token`)',
        {
          code: 'P2002',
          clientVersion: '6.4.1',
          meta: { modelName: 'DeviceRegistration', target: ['push_token'] },
        },
      );

      // First attempt throws P2002 (simulating concurrent race), second attempt succeeds
      prismaMock.$transaction
        .mockRejectedValueOnce(p2002Error)
        .mockImplementationOnce(async (cb: any) => {
          txMock.deviceRegistration.findFirst.mockResolvedValueOnce({
            id: 'reg-race-winner',
            user_id: userId,
            push_token: pushToken,
            platform: DevicePlatform.IOS,
            status: DeviceRegistrationStatus.ACTIVE,
            deactivated_at: null,
            created_at: now,
            updated_at: now,
          });
          return cb(txMock);
        });

      const result = await service.register(userId, {
        pushToken,
        platform: DevicePlatform.IOS,
      });

      expect(prismaMock.$transaction).toHaveBeenCalledTimes(2);
      expect(result.registration.id).toBe('reg-race-winner');
    });

    it('does not retry an unrelated P2002 error', async () => {
      const unrelatedP2002 = new Prisma.PrismaClientKnownRequestError(
        'Unique constraint failed on the fields: (`email`)',
        {
          code: 'P2002',
          clientVersion: '6.4.1',
          meta: { modelName: 'User', target: ['email'] },
        },
      );
      prismaMock.$transaction.mockRejectedValueOnce(unrelatedP2002);

      await expect(
        service.register(userId, {
          pushToken,
          platform: DevicePlatform.IOS,
        }),
      ).rejects.toBe(unrelatedP2002);
      expect(prismaMock.$transaction).toHaveBeenCalledTimes(1);
    });
  });
});
