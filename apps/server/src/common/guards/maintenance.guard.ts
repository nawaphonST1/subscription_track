import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

import * as fs from 'node:fs';
import { resolve } from 'node:path';

export const MAINTENANCE_MESSAGE =
  'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';

@Injectable()
export class MaintenanceGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    let isMaintenance =
      this.configService.get<boolean>('app.maintenanceMode') ??
      process.env.MAINTENANCE_MODE === 'true';

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
      } catch {
        // Ignore .env read errors and fall back to environment variables or config service
      }
    }

    if (!isMaintenance) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const requestPath = request?.url ?? '';

    // Allow probes and root endpoint
    if (
      requestPath.startsWith('/health') ||
      requestPath.startsWith('/metrics') ||
      requestPath === '/'
    ) {
      return true;
    }

    throw new ServiceUnavailableException(MAINTENANCE_MESSAGE);
  }
}
