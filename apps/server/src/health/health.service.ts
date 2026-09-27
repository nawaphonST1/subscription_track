import {
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

export interface HealthCheckResult {
  status: 'ok';
  checks: {
    database: 'ok';
  };
}

@Injectable()
export class HealthService {
  private readonly logger = new Logger(HealthService.name);

  constructor(private readonly prisma: PrismaService) {}

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

    return {
      status: 'ok',
      checks: {
        database: 'ok',
      },
    };
  }
}
