import {
  DevicePlatform,
  DeviceRegistrationStatus,
  PrismaClient,
} from '@prisma/client';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { DeviceRegistrationsService } from '../src/device-registrations/device-registrations.service';
import { PrismaService } from '../src/prisma/prisma.service';

const runRealDatabaseIntegration = process.env.RUN_DB_INTEGRATION === '1';
const describeRealPostgres = runRealDatabaseIntegration
  ? describe
  : describe.skip;

function assertSafeTestDatabaseUrl(databaseUrl: string): void {
  if (process.env.NODE_ENV === 'production') {
    throw new Error(
      'Refusing to run BE-401 PostgreSQL integration tests with NODE_ENV=production',
    );
  }

  let parsed: URL;
  try {
    parsed = new URL(databaseUrl);
  } catch {
    throw new Error('BE401_REAL_DATABASE_URL is not a valid PostgreSQL URL');
  }

  if (parsed.protocol !== 'postgresql:' && parsed.protocol !== 'postgres:') {
    throw new Error(
      'BE401_REAL_DATABASE_URL must use postgres:// or postgresql://',
    );
  }

  const databaseName = decodeURIComponent(parsed.pathname.replace(/^\/+/, ''));
  if (!databaseName) {
    throw new Error('BE401_REAL_DATABASE_URL must specify a database name');
  }

  if (!databaseName.endsWith('_test')) {
    throw new Error(
      'Refusing to run BE-401 PostgreSQL integration tests against a database whose name does not end with _test',
    );
  }
}

describeRealPostgres(
  'DeviceRegistrationsService against real PostgreSQL',
  () => {
    let prisma: PrismaClient;
    let service: DeviceRegistrationsService;
    const userIds: string[] = [];

    beforeAll(async () => {
      const databaseUrl = process.env.BE401_REAL_DATABASE_URL;
      if (!databaseUrl) {
        throw new Error(
          'BE401_REAL_DATABASE_URL is required when RUN_DB_INTEGRATION=1',
        );
      }
      assertSafeTestDatabaseUrl(databaseUrl);

      prisma = new PrismaClient({
        datasources: { db: { url: databaseUrl } },
      });
      await prisma.$connect();
      service = new DeviceRegistrationsService(
        prisma as unknown as PrismaService,
      );

      const users = await Promise.all([
        prisma.user.create({
          data: {
            email: `be401-real-a-${Date.now()}@example.com`,
            password_hash: 'test-password-hash',
            security_pin_hash: 'test-pin-hash',
          },
        }),
        prisma.user.create({
          data: {
            email: `be401-real-b-${Date.now()}@example.com`,
            password_hash: 'test-password-hash',
            security_pin_hash: 'test-pin-hash',
          },
        }),
      ]);
      userIds.push(...users.map((user) => user.id));
    });

    afterAll(async () => {
      if (!prisma) {
        return;
      }
      if (userIds.length > 0) {
        await prisma.user.deleteMany({ where: { id: { in: userIds } } });
      }
      await prisma.$disconnect();
    });

    it('preserves at most one ACTIVE owner for concurrent same-token registration', async () => {
      const pushToken = `be401-real-concurrent-${Date.now()}`;

      const results = await Promise.allSettled([
        service.register(userIds[0], {
          pushToken,
          platform: DevicePlatform.ANDROID,
        }),
        service.register(userIds[1], {
          pushToken,
          platform: DevicePlatform.IOS,
        }),
      ]);

      const rows = await prisma.deviceRegistration.findMany({
        where: { push_token: pushToken },
        orderBy: [{ created_at: 'asc' }, { id: 'asc' }],
      });
      const activeRows = rows.filter(
        (row) => row.status === DeviceRegistrationStatus.ACTIVE,
      );

      expect(results.some((result) => result.status === 'fulfilled')).toBe(
        true,
      );
      expect(activeRows).toHaveLength(1);
      expect(new Set(activeRows.map((row) => row.user_id)).size).toBe(1);
      expect(rows.every((row) => row.push_token === pushToken)).toBe(true);
    });

    it('reactivates the newest inactive historical row for the same user', async () => {
      const pushToken = `be401-real-history-${Date.now()}`;
      const older = new Date('2026-01-01T00:00:00.000Z');
      const newer = new Date('2026-02-01T00:00:00.000Z');

      const historicalRows = await Promise.all([
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: pushToken,
            platform: DevicePlatform.ANDROID,
            status: DeviceRegistrationStatus.REVOKED,
            deactivated_at: older,
            created_at: older,
            updated_at: older,
          },
        }),
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: pushToken,
            platform: DevicePlatform.IOS,
            status: DeviceRegistrationStatus.INVALID,
            deactivated_at: newer,
            created_at: newer,
            updated_at: newer,
          },
        }),
      ]);

      const result = await service.register(userIds[0], {
        pushToken,
        platform: DevicePlatform.ANDROID,
      });

      expect(result.registration.id).toBe(historicalRows[1].id);
      expect(
        await prisma.deviceRegistration.count({
          where: {
            push_token: pushToken,
            status: DeviceRegistrationStatus.ACTIVE,
          },
        }),
      ).toBe(1);
    });

    it('enforces device-registration row integrity in PostgreSQL', async () => {
      const baseToken = `be401-real-check-${Date.now()}`;

      await expect(
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: '   ',
            platform: DevicePlatform.ANDROID,
            status: DeviceRegistrationStatus.ACTIVE,
            deactivated_at: null,
          },
        }),
      ).rejects.toThrow();

      await expect(
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: `${baseToken}-active-deactivated`,
            platform: DevicePlatform.ANDROID,
            status: DeviceRegistrationStatus.ACTIVE,
            deactivated_at: new Date(),
          },
        }),
      ).rejects.toThrow();

      await expect(
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: `${baseToken}-revoked-active`,
            platform: DevicePlatform.ANDROID,
            status: DeviceRegistrationStatus.REVOKED,
            deactivated_at: null,
          },
        }),
      ).rejects.toThrow();

      await expect(
        prisma.deviceRegistration.create({
          data: {
            user_id: userIds[0],
            push_token: `${baseToken}-invalid-active`,
            platform: DevicePlatform.ANDROID,
            status: DeviceRegistrationStatus.INVALID,
            deactivated_at: null,
          },
        }),
      ).rejects.toThrow();

      const validActive = await prisma.deviceRegistration.create({
        data: {
          user_id: userIds[0],
          push_token: `${baseToken}-valid-active`,
          platform: DevicePlatform.ANDROID,
          status: DeviceRegistrationStatus.ACTIVE,
          deactivated_at: null,
        },
      });

      expect(validActive.status).toBe(DeviceRegistrationStatus.ACTIVE);
      await prisma.deviceRegistration.delete({
        where: { id: validActive.id },
      });
    });
  },
);
