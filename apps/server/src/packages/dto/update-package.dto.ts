import { ApiPropertyOptional } from '@nestjs/swagger';
import { BillingCycle } from '@prisma/client';
import { IsEnum, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdatePackageDto {
  @ApiPropertyOptional({
    example: 'Netflix Premium',
    description: 'Updated name of the package',
  })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({
    example: 'Entertainment',
    description: 'Updated category of the package',
  })
  @IsOptional()
  @IsString()
  category?: string;

  @ApiPropertyOptional({
    example: 419.0,
    description: 'Updated default price of the package',
  })
  @IsOptional()
  @IsNumber()
  @Min(0)
  default_price?: number;

  @ApiPropertyOptional({
    enum: BillingCycle,
    description: 'Updated billing cycle',
  })
  @IsOptional()
  @IsEnum(BillingCycle)
  billing_cycle?: BillingCycle;

  @ApiPropertyOptional({
    example: '#E50914',
    description: 'Updated brand color hex code',
  })
  @IsOptional()
  @IsString()
  brand_color?: string;

  @ApiPropertyOptional({
    example: 'https://example.com/icons/netflix-4k.png',
    description: 'Updated icon URL',
  })
  @IsOptional()
  @IsString()
  icon_url?: string;

  @ApiPropertyOptional({
    example: '4K Ultra HD, 4 devices simultaneously',
    description: 'Updated description',
  })
  @IsOptional()
  @IsString()
  description?: string;
}
