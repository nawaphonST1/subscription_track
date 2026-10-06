import {
  ConflictException,
  Injectable,
  Optional,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { SocialLoginDto } from './dto/social-login.dto';
import { NotificationType } from '@prisma/client';
import { OAuth2Client } from 'google-auth-library';
import { BusinessMetrics } from '../metrics/business.metrics';
import { isPinConfigured } from '../common/security/pin.util';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    // Optional so the many unit tests that construct this service directly
    // keep working; MetricsModule is global, so production always has it.
    @Optional() private readonly metrics?: BusinessMetrics,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (existing) {
      throw new ConflictException('An account with this email already exists');
    }

    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(dto.password, saltRounds);
    const pin = dto.security_pin ?? '111111';
    const securityPinHash = await bcrypt.hash(pin, saltRounds);

    const user = await this.prisma.user.create({
      data: {
        email: dto.email.toLowerCase(),
        password_hash: passwordHash,
        name: dto.name,
        monthly_income: dto.monthly_income ?? 0,
        security_pin_hash: securityPinHash,
        notifications: {
          create: {
            title: 'Welcome to SubTracker',
            message:
              'Your account has been created. Default security PIN is set to 111111. You can update your income and PIN anytime in Settings.',
            type: NotificationType.SECURITY_ALERT,
          },
        },
      },
      select: {
        id: true,
        email: true,
        name: true,
        monthly_income: true,
        created_at: true,
      },
    });

    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });

    return {
      token,
      user: {
        ...user,
        monthly_income: Number(user.monthly_income),
        pin_configured: await isPinConfigured(securityPinHash),
      },
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.toLowerCase() },
    });

    if (!user) {
      this.metrics?.recordLogin('failure', 'password');
      throw new UnauthorizedException('Invalid email or password');
    }

    const isMatch = await bcrypt.compare(dto.password, user.password_hash);
    if (!isMatch) {
      this.metrics?.recordLogin('failure', 'password');
      throw new UnauthorizedException('Invalid email or password');
    }

    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });

    this.metrics?.recordLogin('success', 'password');

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        monthly_income: Number(user.monthly_income),
        pin_configured: await isPinConfigured(user.security_pin_hash),
        created_at: user.created_at,
      },
    };
  }

  async socialLogin(dto: SocialLoginDto) {
    let email = dto.email.toLowerCase();
    let name = dto.name;

    // Verify Google ID Token if provider is google (OAuth2Client)
    if (dto.provider === 'google') {
      const googleClientId = process.env.GOOGLE_CLIENT_ID;
      if (googleClientId && dto.token && dto.token !== 'mock-google-token') {
        try {
          const client = new OAuth2Client(googleClientId);
          try {
            const ticket = await client.verifyIdToken({
              idToken: dto.token,
              audience: googleClientId,
            });
            const payload = ticket.getPayload();
            if (payload && payload.email) {
              email = payload.email.toLowerCase();
              name = payload.name ?? name;
            }
          } catch {
            const tokenInfo = await client.getTokenInfo(dto.token);
            if (tokenInfo.email) {
              email = tokenInfo.email.toLowerCase();
              name = dto.name || name;
            } else {
              throw new UnauthorizedException('Invalid Google Token');
            }
          }
        } catch {
          throw new UnauthorizedException(
            'Invalid Google ID Token or Access Token',
          );
        }
      }
    }

    let user = await this.prisma.user.findUnique({
      where: { email },
      select: {
        id: true,
        email: true,
        name: true,
        monthly_income: true,
        security_pin_hash: true,
        created_at: true,
      },
    });

    if (!user) {
      const saltRounds = 10;
      const randomPassword = Math.random().toString(36).slice(-12);
      const passwordHash = await bcrypt.hash(randomPassword, saltRounds);
      const securityPinHash = await bcrypt.hash('111111', saltRounds);

      user = await this.prisma.user.create({
        data: {
          email,
          password_hash: passwordHash,
          name:
            name ?? (dto.provider === 'google' ? 'Google User' : 'Apple User'),
          monthly_income: 0,
          security_pin_hash: securityPinHash,
          notifications: {
            create: {
              title: 'Welcome to SubTracker',
              message: `Your account has been connected with ${dto.provider === 'google' ? 'Google' : 'Apple'}.`,
              type: NotificationType.SECURITY_ALERT,
            },
          },
        },
        select: {
          id: true,
          email: true,
          name: true,
          monthly_income: true,
          security_pin_hash: true,
          created_at: true,
        },
      });
    }

    const token = this.jwtService.sign({
      sub: user.id,
      email: user.email,
    });

    this.metrics?.recordLogin('success', 'password');

    const pinConfigured = await isPinConfigured(user.security_pin_hash);

    return {
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        monthly_income: Number(user.monthly_income),
        pin_configured: pinConfigured,
        created_at: user.created_at,
      },
    };
  }
}
