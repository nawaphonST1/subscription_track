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
    } catch (error) {
      this.logger.warn(`Database connection deferred (offline during startup): ${error?.message || error}`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
