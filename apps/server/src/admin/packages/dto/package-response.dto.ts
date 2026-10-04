import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class AdminPackageResponseDto {
  @ApiProperty({ example: 'f10e2dbc-7668-4b6c-ad02-1b83314bb2ac' })
  id!: string;

  @ApiProperty({ example: 'Netflix Standard' })
  name!: string;

  @ApiProperty({ example: 'Entertainment' })
  category!: string;

  @ApiProperty({ example: 349.0 })
  defaultPrice!: number;

  @ApiProperty({ example: 'MONTHLY' })
  billingCycle!: string;

  @ApiProperty({ example: '#E50914' })
  brandColor!: string;

  @ApiPropertyOptional({ example: 'https://example.com/icons/netflix.png' })
  iconUrl?: string | null;

  @ApiPropertyOptional({ example: '1080p Full HD video streaming' })
  description?: string | null;

  @ApiProperty({ example: true })
  isActive!: boolean;

  @ApiPropertyOptional({
    example: '2026-09-22T00:00:00.000Z',
    nullable: true,
  })
  deletedAt?: Date | null;

  @ApiProperty({ example: '2026-09-22T00:00:00.000Z' })
  createdAt!: Date;

  @ApiProperty({ example: '2026-09-22T00:00:00.000Z' })
  updatedAt!: Date;
}
