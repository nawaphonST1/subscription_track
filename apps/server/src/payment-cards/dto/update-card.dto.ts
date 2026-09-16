import { ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsBoolean,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from 'class-validator';

export class UpdateCardDto {
  @ApiPropertyOptional({
    example: 'Savings Card',
    description: 'Updated card nickname',
  })
  @IsOptional()
  @IsString()
  card_nickname?: string;

  @ApiPropertyOptional({ example: 30000, description: 'Updated balance' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  balance?: number;

  @ApiPropertyOptional({ example: true, description: 'Set as default card' })
  @IsOptional()
  @IsBoolean()
  is_default?: boolean;
}
