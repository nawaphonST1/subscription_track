import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  async onModuleInit() {
    try {
      await this.$connect();
    } catch (error) {
      console.warn(
        'Database connection failed during onModuleInit (degraded mode):',
        error,
      );
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
