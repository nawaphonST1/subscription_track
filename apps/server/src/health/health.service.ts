import * as fs from 'node:fs';
import { resolve } from 'node:path';
import {
  Injectable,
  Logger,
  Optional,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PrismaService } from '../prisma/prisma.service';

export interface HealthCheckResult {
  status: 'ok' | 'maintenance';
  message?: string;
  checks: {
    database: 'ok';
    maintenance?: boolean;
  };
}

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  async check(): Promise<HealthCheckResult> {
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      // Do not log or expose the raw driver/Prisma error: it can contain
      // connection strings, hostnames, or credentials. Mirrors the
      // sanitization discipline in HttpExceptionFilter.
      this.logger.error('Database readiness check failed');
      throw new ServiceUnavailableException('Database not ready');
    }

    let isMaintenance =
      this.configService?.get<boolean>('app.maintenanceMode') ??
      (process.env.NODE_ENV !== 'test' &&
        process.env.MAINTENANCE_MODE === 'true');

    if (!isMaintenance && process.env.NODE_ENV !== 'test') {
      try {
        const envPath = resolve(process.cwd(), '.env');
        if (fs.existsSync(envPath)) {
          const content = fs.readFileSync(envPath, 'utf8');
          const match = content.match(/^MAINTENANCE_MODE\s*=\s*(true|1)/m);
          if (match) {
            isMaintenance = true;
          }
        }
      } catch {}
    }

    if (isMaintenance) {
      return {
        status: 'maintenance',
        message:
          'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง',
        checks: {
          database: 'ok',
          maintenance: true,
        },
      };
    }

    return {
      status: 'ok',
      checks: {
        database: 'ok',
      },
    };
  }
}
