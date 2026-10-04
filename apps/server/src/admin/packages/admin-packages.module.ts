import { Module } from '@nestjs/common';
import { AdminPackagesController } from './admin-packages.controller';
import { AdminPackagesService } from './admin-packages.service';
import { PrismaModule } from '../../prisma/prisma.module';
import { PackagesModule } from '../../packages/packages.module';

@Module({
  imports: [PrismaModule, PackagesModule],
  controllers: [AdminPackagesController],
  providers: [AdminPackagesService],
  exports: [AdminPackagesService],
})
export class AdminPackagesModule {}
