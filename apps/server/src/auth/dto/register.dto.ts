import {
  IsEmail,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Min,
  MinLength,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class RegisterDto {
  @ApiProperty({
    example: 'user@example.com',
    description: 'User email address',
  })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({
    example: 'Password123!',
    description: 'Minimum 6 character password',
  })
  @IsString()
  @MinLength(6)
  password!: string;

  @ApiPropertyOptional({ example: 'John Doe', description: 'Display name' })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: 45000,
    description: 'Monthly income in user currency',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  monthly_income?: number;

  @ApiPropertyOptional({
    example: '111111',
    description: '6-digit security PIN (defaults to 111111)',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{6}$/, { message: 'security_pin must be exactly 6 digits' })
  security_pin?: string;
}
