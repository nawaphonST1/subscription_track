import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsString, Matches } from 'class-validator';

export class ChangePinDto {
  @ApiProperty({ example: '111111', description: 'Current 6-digit PIN' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, { message: 'current_pin must be exactly 6 digits' })
  current_pin!: string;

  @ApiProperty({ example: '654321', description: 'New 6-digit PIN' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^\d{6}$/, { message: 'new_pin must be exactly 6 digits' })
  new_pin!: string;
}
