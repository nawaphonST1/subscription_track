import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayNotEmpty,
  IsArray,
  IsNotEmpty,
  IsString,
  Matches,
} from 'class-validator';

export class BatchCancelDto {
  @ApiProperty({
    example: [
      'd290f1ee-6c54-4b01-90e6-d701748f0851',
      'b471c2ee-7d21-4a12-81e5-d701748f0852',
    ],
    description: 'Array of subscription IDs to cancel',
  })
  @IsArray()
  @ArrayNotEmpty()
  @IsString({ each: true })
  subscription_ids!: string[];

  @ApiProperty({
    example: '111111',
    description: 'User 6-digit security PIN for authorization',
  })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, { message: 'security_pin must be exactly 6 digits' })
  security_pin!: string;
}
