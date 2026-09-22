import { Body, Controller, HttpStatus, Post, Res } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import type { Response } from 'express';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { DeviceRegistrationsService } from './device-registrations.service';
import { RegisterDeviceDto } from './dto/register-device.dto';

@ApiTags('device-registrations')
@ApiBearerAuth()
@Controller('device-registrations')
export class DeviceRegistrationsController {
  constructor(
    private readonly deviceRegistrationsService: DeviceRegistrationsService,
  ) {}

  @Post()
  @ApiOperation({ summary: 'Register mobile device push destination' })
  @ApiResponse({
    status: 200,
    description: 'Existing active registration returned',
  })
  @ApiResponse({
    status: 201,
    description: 'Registration created or transferred',
  })
  @ApiResponse({
    status: 400,
    description: 'Validation failed or malformed request payload',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - missing or invalid Bearer token',
  })
  async register(
    @CurrentUser('id') userId: string,
    @Body() dto: RegisterDeviceDto,
    @Res({ passthrough: true }) res: Response,
  ) {
    const result = await this.deviceRegistrationsService.register(userId, dto);
    if (!result.isNew) {
      res.status(HttpStatus.OK);
    } else {
      res.status(HttpStatus.CREATED);
      res.setHeader(
        'Location',
        `/device-registrations/${result.registration.id}`,
      );
    }
    return result.registration;
  }
}
