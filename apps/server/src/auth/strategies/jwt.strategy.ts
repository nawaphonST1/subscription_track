import { Injectable, Optional, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { ActiveUsersTracker } from '../../metrics/active-users.tracker';
import { CacheService } from '../../cache/cache.service';

export interface JwtPayload {
  sub: string;
  email: string;
  role?: string;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly prisma: PrismaService,
    configService: ConfigService,
    @Optional() private readonly activeUsers?: ActiveUsersTracker,
    @Optional() private readonly cacheService?: CacheService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.getOrThrow<string>('JWT_SECRET'),
    });
  }

  async validate(payload: JwtPayload) {
    const cacheKey = `auth:user:${payload.sub}`;
    if (this.cacheService) {
      const cached = await this.cacheService.get<{
        id: string;
        email: string;
        name: string;
        role: string;
      }>(cacheKey);
      if (cached) {
        this.activeUsers?.record(cached.id);
        return cached;
      }
    }

    const user = await this.prisma.user.findUnique({
      where: { id: payload.sub },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
      },
    });

    if (!user) {
      throw new UnauthorizedException('User account not found');
    }

    if (this.cacheService) {
      // 180 seconds (3 minutes) TTL as agreed
      await this.cacheService.set(cacheKey, user, 180);
    }

    // O(1) Map write. The id stays in process memory and is never exported
    // as a label or written to a log.
    this.activeUsers?.record(user.id);

    return user;
  }
}
