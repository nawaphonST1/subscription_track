import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString } from 'class-validator';

export class UpdatePackageStatusDto {
  @ApiProperty({
    description: 'Whether the package is active and selectable by users',
    example: false,
  })
  @IsBoolean()
  isActive!: boolean;

  @ApiPropertyOptional({
    description: 'Optional reason for disabling or changing the package status',
    example: 'Service discontinued or temporarily unavailable',
  })
  @IsOptional()
  @IsString()
  reason?: string;
}
