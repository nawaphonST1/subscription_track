import { ApiProperty } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsString,
  Matches,
  MaxLength,
} from 'class-validator';
import { DevicePlatform } from '@prisma/client';

export class RegisterDeviceDto {
  @ApiProperty({
    description: 'FCM mobile push registration token',
    example: 'fcm-device-registration-token-sample',
    maxLength: 4096,
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/\S/, {
    message: 'pushToken must contain at least one non-whitespace character',
  })
  @MaxLength(4096)
  pushToken!: string;

  @ApiProperty({
    description: 'Device operating system platform',
    enum: DevicePlatform,
    example: DevicePlatform.IOS,
  })
  @IsEnum(DevicePlatform)
  platform!: DevicePlatform;
}
