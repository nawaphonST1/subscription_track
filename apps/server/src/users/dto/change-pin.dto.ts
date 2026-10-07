import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  NotEquals,
} from 'class-validator';

export class ChangePinDto {
  @ApiPropertyOptional({
    example: '482910',
    description:
      'Current 6-digit PIN (required if account is already PIN-configured)',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'current_pin must be exactly 6 digits' })
  current_pin?: string;

  @ApiProperty({ example: '739201', description: 'New 6-digit PIN' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, { message: 'new_pin must be exactly 6 digits' })
  @NotEquals('111111', { message: 'Cannot use weak default PIN 111111' })
  new_pin!: string;

  @ApiPropertyOptional({
    example: 'myStrongPassword123',
    description:
      'Account password for primary authentication (required when setting PIN on unconfigured or reset accounts)',
  })
  @IsOptional()
  @IsString()
  password?: string;

  @ApiPropertyOptional({
    description:
      'Social OAuth token for primary authentication (for Google/Apple accounts)',
  })
  @IsOptional()
  @IsString()
  social_token?: string;
}
