import { ApiPropertyOptional } from '@nestjs/swagger';
import { SubscriptionStatus, UsageStatus } from '@prisma/client';
import { IsEnum, IsOptional, IsString } from 'class-validator';

export class QuerySubscriptionDto {
  @ApiPropertyOptional({
    example: 'Streaming',
    description: 'Filter by category',
  })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({
    example: 'Netflix',
    description: 'Search term for subscription name',
  })
  @IsOptional()
  @IsString()
  search?: string;

  @ApiPropertyOptional({
    enum: SubscriptionStatus,
    description: 'Filter by status (ACTIVE, CANCELLED, PAUSED)',
  })
  @IsOptional()
  @IsEnum(SubscriptionStatus)
  status?: SubscriptionStatus;

  @ApiPropertyOptional({
    enum: UsageStatus,
    description: 'Filter by usage status',
  })
  @IsOptional()
  @IsEnum(UsageStatus)
  usage_status?: UsageStatus;
}
