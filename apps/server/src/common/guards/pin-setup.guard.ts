import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  Optional,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';
import { ALLOW_WITHOUT_PIN_KEY } from '../decorators/allow-without-pin.decorator';
import { PrismaService } from '../../prisma/prisma.service';
import { isPinConfigured } from '../security/pin.util';
import { CacheService } from '../../cache/cache.service';

interface AuthenticatedRequest {
  user?: {
    id: string;
    email?: string;
  };
}

@Injectable()
export class PinSetupGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly prisma: PrismaService,
    @Optional() private readonly cacheService?: CacheService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (isPublic) {
      return true;
    }

    const allowWithoutPin = this.reflector.getAllAndOverride<boolean>(
      ALLOW_WITHOUT_PIN_KEY,
      [context.getHandler(), context.getClass()],
    );

    if (allowWithoutPin) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const userId = request.user?.id;

    if (!userId) {
      return false;
    }

    const cacheKey = `user:${userId}:pin-configured`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<boolean>(cacheKey);
      if (cached !== null && cached !== undefined) {
        if (!cached) {
          throw new ForbiddenException({
            statusCode: 403,
            error: 'PIN_SETUP_REQUIRED',
            message:
              'Security PIN setup is required before accessing this resource',
            code: 'PIN_SETUP_REQUIRED',
          });
        }
        return true;
      }
    }

    const user: { security_pin_hash: string } | null =
      await this.prisma.user.findUnique({
        where: { id: userId },
        select: { security_pin_hash: true },
      });

    if (!user) {
      return false;
    }

    const configured = await isPinConfigured(user.security_pin_hash);

    if (this.cacheService) {
      await this.cacheService.set(cacheKey, configured, 180);
    }

    if (!configured) {
      throw new ForbiddenException({
        statusCode: 403,
        error: 'PIN_SETUP_REQUIRED',
        message:
          'Security PIN setup is required before accessing this resource',
        code: 'PIN_SETUP_REQUIRED',
      });
    }

    return true;
  }
}
