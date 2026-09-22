import { Module } from '@nestjs/common';
import { DeviceRegistrationsController } from './device-registrations.controller';
import { DeviceRegistrationsService } from './device-registrations.service';

@Module({
  controllers: [DeviceRegistrationsController],
  providers: [DeviceRegistrationsService],
  exports: [DeviceRegistrationsService],
})
export class DeviceRegistrationsModule {}
