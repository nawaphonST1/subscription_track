import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class VerifyPinDto {
  @ApiProperty({ example: '482910', description: '6-digit security PIN' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, { message: 'PIN must be exactly 6 digits' })
  pin!: string;
}
