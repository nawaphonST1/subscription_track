import * as crypto from 'node:crypto';
import * as bcrypt from 'bcryptjs';
import { PrismaClient } from '@prisma/client';

export const DEFAULT_PIN = '111111';

export interface RotateDefaultPinsOptions {
  prisma?: Pick<PrismaClient, 'user'> | PrismaClient;
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
 * Generates a cryptographically secure random 6-digit PIN.
 * Ensures the PIN is strictly 6 digits and not equal to the default PIN ('111111').
 */
export function generateRandomPin(): string {
  let pin: string;
  do {
    // crypto.randomInt(min, max): min inclusive, max exclusive -> [100000, 999999]
    pin = crypto.randomInt(100000, 1000000).toString();
  } while (pin === DEFAULT_PIN);
  return pin;
}

/**
 * Scans users with a security_pin_hash, identifies default-PIN accounts ('111111'),
 * generates per-user random PINs, hashes them with bcrypt, and updates the database.
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

      // Generate secure random PIN and hash it
      const newPin = generateRandomPin();
      const newHash = await bcrypt.hash(newPin, 10);

      if (!dryRun) {
        await (prisma as any).user.update({
          where: { id: user.id },
          data: { security_pin_hash: newHash },
        });
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
