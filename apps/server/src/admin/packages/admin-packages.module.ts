import { Module } from '@nestjs/common';
import { AdminPackagesController } from './admin-packages.controller';
import { AdminPackagesService } from './admin-packages.service';
import { PrismaModule } from '../../prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [AdminPackagesController],
  providers: [AdminPackagesService],
  exports: [AdminPackagesService],
})
export class AdminPackagesModule {}
