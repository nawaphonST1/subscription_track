import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BillingCycle, SubscriptionStatus, UsageStatus } from '@prisma/client';
import { IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class AdminCreateSubscriptionDto {
  @ApiProperty({ example: 'Netflix Premium' })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiPropertyOptional({ example: 'Entertainment' })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ example: 419.0 })
  @IsOptional()
  price?: number | string;

  @ApiPropertyOptional({ example: 'MONTHLY', enum: BillingCycle })
  @IsOptional()
  billing_cycle?: BillingCycle;

  @IsOptional()
  billingCycle?: BillingCycle;

  @ApiPropertyOptional({ example: '2026-09-01T00:00:00.000Z' })
  @IsOptional()
  start_date?: string | Date;

  @IsOptional()
  startDate?: string | Date;

  @ApiPropertyOptional({ example: '2026-10-01T00:00:00.000Z' })
  @IsOptional()
  next_renewal_date?: string | Date;

  @IsOptional()
  nextRenewalDate?: string | Date;

  @ApiPropertyOptional({ example: 'ACTIVE', enum: SubscriptionStatus })
  @IsOptional()
  status?: SubscriptionStatus;

  @ApiPropertyOptional({ example: 'FREQUENT', enum: UsageStatus })
  @IsOptional()
  usage_status?: UsageStatus;

  @IsOptional()
  usageStatus?: UsageStatus;

  @ApiPropertyOptional({ example: '#E50914' })
  @IsOptional()
  @IsString()
  brand_color?: string;

  @IsOptional()
  @IsString()
  brandColor?: string;

  @ApiPropertyOptional({ example: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string | null;

  @ApiPropertyOptional({ example: 'card-uuid' })
  @IsOptional()
  @IsString()
  payment_card_id?: string;

  @IsOptional()
  @IsString()
  paymentCardId?: string;

  @IsOptional()
  @IsString()
  card_id?: string;

  @ApiPropertyOptional({ example: 'Premium' })
  @IsOptional()
  @IsString()
  plan_tier?: string;

  @IsOptional()
  @IsString()
  planTier?: string;

  @ApiPropertyOptional({ example: 'preset-uuid' })
  @IsOptional()
  @IsString()
  preset_id?: string;

  @IsOptional()
  @IsString()
  presetId?: string;
}
