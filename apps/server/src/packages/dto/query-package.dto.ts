import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class QueryPackageDto {
  @ApiPropertyOptional({
    example: 'Entertainment',
    description: 'Filter packages by category',
  })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({
    example: 'Netflix',
    description: 'Search packages by name',
  })
  @IsOptional()
  @IsString()
  search?: string;
}
