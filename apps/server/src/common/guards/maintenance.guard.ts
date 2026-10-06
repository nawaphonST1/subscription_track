import {
  CanActivate,
  ExecutionContext,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Request } from 'express';

export const MAINTENANCE_MESSAGE =
  'เซิร์ฟเวอร์กำลังปิดปรับปรุงชั่วคราว กรุณาลองใหม่อีกครั้งในภายหลัง';

@Injectable()
export class MaintenanceGuard implements CanActivate {
  constructor(private readonly configService: ConfigService) {}

  canActivate(context: ExecutionContext): boolean {
    const isMaintenance =
      this.configService.get<boolean>('app.maintenanceMode') ??
      process.env.MAINTENANCE_MODE === 'true';

    if (!isMaintenance) {
      return true;
    }

    const request = context.switchToHttp().getRequest<Request>();
    const path = request?.url ?? '';

    // Allow probes and root endpoint
    if (
      path.startsWith('/health') ||
      path.startsWith('/metrics') ||
      path === '/'
    ) {
      return true;
    }

    throw new ServiceUnavailableException(MAINTENANCE_MESSAGE);
  }
}
