/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access */
import * as crypto from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaClient, NotificationType } from '@prisma/client';
import { RESET_PIN_PREFIX } from '../src/common/security/pin.util';

export const DEFAULT_PIN = '111111';

export interface RotateDefaultPinsOptions {
  prisma?: Pick<PrismaClient, 'user' | 'notification'> | PrismaClient;
  batchSize?: number;
  dryRun?: boolean;
  logger?: {
    log: (message: string) => void;
    warn?: (message: string) => void;
    error?: (message: string) => void;
  };
}

export interface RotationReport {
  scannedCount: number;
  defaultPinCount: number;
  rotatedCount: number;
  dryRun: boolean;
}

/**
 * Scans users with a security_pin_hash, identifies default-PIN accounts ('111111'),
 * and invalidates them with unguessable reset hashes ($RESET$).
 *
 * Never logs plaintext PINs.
 * Only intended for manual standalone invocation; never run during automated startup.
 */
export async function rotateDefaultPins(
  options: RotateDefaultPinsOptions = {},
): Promise<RotationReport> {
  const prisma = options.prisma ?? new PrismaClient();
  const batchSize = options.batchSize ?? 100;
  const dryRun = options.dryRun ?? false;
  const logger = options.logger ?? console;

  logger.log(
    `[rotate-default-pins] Starting PIN rotation scan (batchSize: ${batchSize}, dryRun: ${dryRun})...`,
  );

  let scannedCount = 0;
  let defaultPinCount = 0;
  let rotatedCount = 0;
  let cursor: string | undefined;

  while (true) {
    const users: { id: string; security_pin_hash: string }[] = await (
      prisma as any
    ).user.findMany({
      take: batchSize,
      ...(cursor ? { skip: 1, cursor: { id: cursor } } : {}),
      orderBy: { id: 'asc' },
      select: {
        id: true,
        security_pin_hash: true,
      },
    });

    if (!users || users.length === 0) {
      break;
    }

    scannedCount += users.length;
    cursor = users[users.length - 1].id;

    for (const user of users) {
      if (!user.security_pin_hash) {
        continue;
      }

      const isDefault = await bcrypt.compare(
        DEFAULT_PIN,
        user.security_pin_hash,
      );
      if (!isDefault) {
        continue;
      }

      defaultPinCount++;

      // Invalidate the default PIN with a cryptographically unguessable reset hash
      // so 111111 can no longer be used, and user must set a new PIN via supported primary auth.
      const newHash = `${RESET_PIN_PREFIX}${await bcrypt.hash(crypto.randomUUID(), 10)}`;

      if (!dryRun) {
        const updateOp = (prisma as any).user.update({
          where: { id: user.id },
          data: { security_pin_hash: newHash },
        });

        const notifOp = (prisma as any).notification.create({
          data: {
            user_id: user.id,
            title: 'รหัส PIN ของคุณถูกรีเซ็ตเพื่อความปลอดภัย',
            message:
              'รหัสความปลอดภัย (PIN) ของคุณถูกรีเซ็ตเนื่องจากนโยบายความปลอดภัย กรุณาตั้งค่ารหัส PIN ใหม่ของคุณผ่านแอปพลิเคชัน',
            type: NotificationType.SECURITY_ALERT,
          },
        });

        if (typeof (prisma as any).$transaction === 'function') {
          await (prisma as any).$transaction([updateOp, notifOp]);
        } else {
          await updateOp;
          await notifOp;
        }
      }

      rotatedCount++;
      // Explicitly log progress without leaking plaintext PIN or sensitive user credentials
      logger.log(
        `[rotate-default-pins] ${dryRun ? '[DRY-RUN] Would rotate' : 'Rotated'} default PIN for user id=${user.id}`,
      );
    }

    if (users.length < batchSize) {
      break;
    }
  }

  const report: RotationReport = {
    scannedCount,
    defaultPinCount,
    rotatedCount: dryRun ? 0 : rotatedCount,
    dryRun,
  };

  logger.log(
    `[rotate-default-pins] Scan finished: scanned=${report.scannedCount}, defaultPinsFound=${report.defaultPinCount}, rotated=${report.rotatedCount}, dryRun=${report.dryRun}`,
  );

  return report;
}

// Standalone execution entrypoint (only if run directly via node/ts-node, not when imported)
/* istanbul ignore next */
if (process.env.NODE_ENV !== 'test' && require.main === module) {
  const isDryRun = process.argv.includes('--dry-run');
  const prisma = new PrismaClient();
  rotateDefaultPins({ prisma, dryRun: isDryRun })
    .then((report) => {
      console.log('Result:', JSON.stringify(report, null, 2));
      process.exit(0);
    })
    .catch((err) => {
      console.error('[rotate-default-pins] Fatal error:', err);
      process.exit(1);
    })
    .finally(async () => {
      await prisma.$disconnect();
    });
}
