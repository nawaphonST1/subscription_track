import {
  BadRequestException,
  CanActivate,
  ExecutionContext,
  Injectable,
  SetMetadata,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SecurityPinService } from '../security/security-pin.service';

export const REQUIRE_SECURITY_PIN_KEY = 'requireSecurityPin';
export const RequireSecurityPin = () =>
  SetMetadata(REQUIRE_SECURITY_PIN_KEY, true);

interface RequestWithPin {
  user?: {
    id: string;
  };
  body?: {
    security_pin?: unknown;
  };
  headers: Record<string, string | string[] | undefined>;
}

@Injectable()
export class SecurityPinGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly securityPinService: SecurityPinService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isRequired = this.reflector.getAllAndOverride<boolean>(
      REQUIRE_SECURITY_PIN_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (!isRequired) {
      return true;
    }

    const request = context.switchToHttp().getRequest<RequestWithPin>();
    const userId = request.user?.id;
    if (!userId) {
      return false;
    }

    // Support PIN either in JSON body as security_pin or in HTTP header x-security-pin
    const bodyPin =
      typeof request.body?.security_pin === 'string'
        ? request.body.security_pin
        : undefined;
    const headerPin =
      typeof request.headers['x-security-pin'] === 'string'
        ? request.headers['x-security-pin']
        : undefined;

    const pin = bodyPin ?? headerPin;

    if (!pin) {
      throw new BadRequestException(
        'Security PIN is required (provide in JSON body "security_pin" or "x-security-pin" header)',
      );
    }

    await this.securityPinService.verifyPin(userId, pin);
    return true;
  }
}
