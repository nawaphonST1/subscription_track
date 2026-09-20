import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, Length, Min } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({
    example: 'Somchai Jaidee',
    description: 'User display name',
  })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  name?: string;

  @ApiPropertyOptional({
    example: 45000,
    description: 'Monthly income in user currency',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  monthly_income?: number;
}
