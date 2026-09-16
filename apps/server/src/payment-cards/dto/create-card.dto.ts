import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { CardType } from '@prisma/client';
import {
  IsBoolean,
  IsEnum,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Length,
  Matches,
  Min,
} from 'class-validator';

export class CreateCardDto {
  @ApiProperty({
    example: 'My Salary Card',
    description: 'User-assigned card nickname',
  })
  @IsString()
  @IsNotEmpty()
  card_nickname!: string;

  @ApiProperty({
    example: 'Visa',
    description: 'Card brand (e.g., Visa, Mastercard, JCB)',
  })
  @IsString()
  @IsNotEmpty()
  card_brand!: string;

  @ApiProperty({
    enum: CardType,
    example: CardType.DEBIT,
    description: 'Card type',
  })
  @IsEnum(CardType)
  @IsNotEmpty()
  card_type!: CardType;

  @ApiProperty({ example: '1234', description: 'Last 4 digits of card number' })
  @IsString()
  @Matches(/^\d{4}$/, { message: 'last_4_digits must be exactly 4 digits' })
  last_4_digits!: string;

  @ApiProperty({ example: 'Kasikornbank', description: 'Issuing bank name' })
  @IsString()
  @IsNotEmpty()
  bank_name!: string;

  @ApiProperty({
    example: 25000.5,
    description: 'Current available balance on card',
  })
  @IsNumber()
  @Min(0)
  balance!: number;

  @ApiPropertyOptional({
    example: 'THB',
    default: 'THB',
    description: 'Currency code',
  })
  @IsOptional()
  @IsString()
  @Length(3, 3)
  currency?: string;

  @ApiPropertyOptional({
    example: false,
    default: false,
    description: 'Set as default payment card',
  })
  @IsOptional()
  @IsBoolean()
  is_default?: boolean;
}
