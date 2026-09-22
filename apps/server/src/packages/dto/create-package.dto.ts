import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { BillingCycle } from '@prisma/client';
import {
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class CreatePackageDto {
  @ApiProperty({
    example: 'Netflix Standard',
    description: 'Name of the preset package',
  })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({
    example: 'Entertainment',
    description: 'Category of the package',
  })
  @IsString()
  @IsNotEmpty()
  category!: string;

  @ApiProperty({
    example: 349.0,
    description: 'Default price of the package',
  })
  @IsNumber()
  @Min(0)
  default_price!: number;

  @ApiPropertyOptional({
    enum: BillingCycle,
    default: BillingCycle.MONTHLY,
    description: 'Default billing cycle for the package',
  })
  @IsOptional()
  @IsEnum(BillingCycle)
  billing_cycle?: BillingCycle = BillingCycle.MONTHLY;

  @ApiProperty({
    example: '#E50914',
    description: 'Brand color hex code',
  })
  @IsString()
  @IsNotEmpty()
  brand_color!: string;

  @ApiPropertyOptional({
    example: 'https://example.com/icons/netflix.png',
    description: 'Icon URL or asset identifier',
  })
  @IsOptional()
  @IsString()
  icon_url?: string;

  @ApiPropertyOptional({
    example: 'Full HD streaming, 2 devices simultaneously',
    description: 'Package description or plan features',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
