import { ApiPropertyOptional } from '@nestjs/swagger';
import { BillingCycle, SubscriptionStatus, UsageStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class UpdateSubscriptionDto {
  @ApiPropertyOptional({
    example: 'payment-card-id',
    description: 'Updated payment card ID',
  })
  @IsOptional()
  @IsString()
  payment_card_id?: string;

  @ApiPropertyOptional({
    example: 'payment-card-id',
    description: 'Updated payment card ID (alias for payment_card_id)',
  })
  @IsOptional()
  @IsString()
  card_id?: string;

  @ApiPropertyOptional({
    example: 'Netflix Premium 4K',
    description: 'Updated service name',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: 'Entertainment',
    description: 'Updated category',
  })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({ example: 450, description: 'Updated price' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  price?: number;

  @ApiPropertyOptional({
    enum: BillingCycle,
    description: 'Updated billing cycle',
  })
  @IsOptional()
  @Transform(({ value }: { value: unknown }): unknown =>
    typeof value === 'string' ? value.toUpperCase() : value,
  )
  @IsEnum(BillingCycle)
  billing_cycle?: BillingCycle;

  @ApiPropertyOptional({
    example: '2026-10-15T00:00:00.000Z',
    description: 'Updated next renewal date',
  })
  @IsOptional()
  @IsDateString()
  next_renewal_date?: string;

  @ApiPropertyOptional({
    enum: UsageStatus,
    description: 'Updated usage status',
  })
  @IsOptional()
  @IsEnum(UsageStatus)
  usage_status?: UsageStatus;

  @ApiPropertyOptional({
    enum: SubscriptionStatus,
    description: 'Updated subscription status',
  })
  @IsOptional()
  @IsEnum(SubscriptionStatus)
  status?: SubscriptionStatus;

  @ApiPropertyOptional({ example: '#FF0000', description: 'Brand color' })
  @IsOptional()
  @IsString()
  brand_color?: string;

  @ApiPropertyOptional({ example: 'Updated notes', description: 'Notes' })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({ example: 'Premium', description: 'Plan tier' })
  @IsOptional()
  @IsString()
  plan_tier?: string;

  @ApiPropertyOptional({ example: 'Premium', description: 'Plan tier alias' })
  @IsOptional()
  @IsString()
  planTier?: string;

  @ApiPropertyOptional({ example: 'preset-uuid', description: 'Preset ID' })
  @IsOptional()
  @IsString()
  preset_id?: string;

  @ApiPropertyOptional({ example: 'preset-uuid', description: 'Preset ID alias' })
  @IsOptional()
  @IsString()
  presetId?: string;
}
