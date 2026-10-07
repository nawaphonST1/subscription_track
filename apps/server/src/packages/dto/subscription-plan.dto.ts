import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

/**
 * Shape of one entry in `SubscriptionPreset.available_plans` (a Prisma Json
 * column), used for Swagger/response typing only — presets are seed-managed,
 * not user-writable, so this DTO is never used as request input.
 */
export class SubscriptionPlanDto {
  @ApiProperty({ example: 'Premium', description: 'Plan tier name' })
  tier!: string;

  @ApiProperty({ example: 419.0, description: 'Monthly price for this tier' })
  monthlyPrice!: number;

  @ApiPropertyOptional({
    example: 4190.0,
    description: 'Yearly price for this tier, if offered',
  })
  yearlyPrice?: number | null;

  @ApiProperty({
    example: 4,
    description: 'Maximum number of shared slots/screens for this tier',
  })
  maxSlots!: number;

  @ApiProperty({
    example: ['4K UHD + HDR', '4 Screens', 'Spatial Audio'],
    description: 'Feature highlights for this tier',
    type: [String],
  })
  features!: string[];
}
