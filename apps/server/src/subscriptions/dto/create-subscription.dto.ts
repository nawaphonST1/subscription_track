import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BillingCycle, UsageStatus } from '@prisma/client';
import { Transform } from 'class-transformer';
import {
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreateSubscriptionDto {
  @ApiPropertyOptional({
    example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    description: 'Associated payment card ID',
  })
  @IsOptional()
  @IsString()
  payment_card_id?: string;

  @ApiPropertyOptional({
    example: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
    description: 'Associated payment card ID (alias for payment_card_id)',
  })
  @IsOptional()
  @IsString()
  card_id?: string;

  @ApiPropertyOptional({
    example: 'preset-uuid',
    description: 'Optional preset catalog ID',
  })
  @IsOptional()
  @IsString()
  preset_id?: string;

  @ApiProperty({
    example: 'Netflix Premium',
    description: 'Service or subscription name',
  })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: 'Streaming', description: 'Subscription category' })
  @IsString()
  @IsNotEmpty()
  category!: string;

  @ApiProperty({ example: 419.0, description: 'Recurring cost' })
  @IsNumber()
  @Min(0)
  price!: number;

  @ApiProperty({
    enum: BillingCycle,
    example: BillingCycle.MONTHLY,
    description: 'Billing frequency',
  })
  @Transform(({ value }: { value: unknown }): unknown =>
    typeof value === 'string' ? value.toUpperCase() : value,
  )
  @IsEnum(BillingCycle)
  billing_cycle!: BillingCycle;

  @ApiPropertyOptional({
    example: '2026-09-01T00:00:00.000Z',
    description: 'Subscription start date',
  })
  @IsOptional()
  @IsDateString()
  start_date?: string;

  @ApiPropertyOptional({
    example: '2026-10-01',
    description: 'First bill date (alias for start_date)',
  })
  @IsOptional()
  @IsDateString()
  first_bill_date?: string;

  @ApiPropertyOptional({
    example: '2026-10-01T00:00:00.000Z',
    description: 'Next scheduled billing date',
  })
  @IsOptional()
  @IsDateString()
  next_renewal_date?: string;

  @ApiPropertyOptional({
    enum: UsageStatus,
    example: UsageStatus.FREQUENT,
    description: 'Usage perception level',
  })
  @IsOptional()
  @IsEnum(UsageStatus)
  usage_status?: UsageStatus;

  @ApiPropertyOptional({
    example: '#E50914',
    description: 'Brand primary color hex',
  })
  @IsOptional()
  @IsString()
  brand_color?: string;

  @ApiPropertyOptional({
    example: 'Shared with family members',
    description: 'Custom notes',
  })
  @IsOptional()
  @IsString()
  notes?: string;

  @ApiPropertyOptional({
    example: 'Premium',
    description:
      "Plan tier chosen from the preset catalog's available_plans (requires preset_id)",
  })
  @IsOptional()
  @IsString()
  plan_tier?: string;

  @ApiPropertyOptional({
    example: 2,
    default: 1,
    description: 'Number of people sharing/splitting this subscription',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  shared_members?: number = 1;
}
