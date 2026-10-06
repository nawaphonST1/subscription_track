import { ApiPropertyOptional } from '@nestjs/swagger';
import { UserRole } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateAdminUserDto {
  @ApiPropertyOptional({
    example: 'Somchai Prasert',
    description: 'User full name',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    enum: UserRole,
    description: 'Role of the user (USER or ADMIN)',
  })
  @IsOptional()
  @IsEnum(UserRole)
  role?: UserRole;

  @ApiPropertyOptional({ example: 45000, description: 'Monthly income in THB' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  monthlyIncome?: number;
}
