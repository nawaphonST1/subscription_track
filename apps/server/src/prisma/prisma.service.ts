import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);

  async onModuleInit() {
    try {
      await this.$connect();
    } catch (error: any) {
      const msg = error?.message || String(error);
      this.logger.warn(`Database connection deferred (offline during startup): ${msg}`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
