import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, Matches } from 'class-validator';

export class LinkMockCardDto {
  @ApiPropertyOptional({
    example: 'd290f1ee-6c54-4b01-90e6-d701748f0851',
    description: 'Specific MockBankCard ID to link',
  })
  @IsOptional()
  @IsString()
  mock_card_id?: string;

  @ApiPropertyOptional({
    example: 'Kasikornbank',
    description: 'Issuing bank name to match mock card',
  })
  @IsOptional()
  @IsString()
  bank_name?: string;

  @ApiPropertyOptional({
    example: '9999',
    description: 'Last 4 digits to match mock card',
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}$/, { message: 'last_4_digits must be exactly 4 digits' })
  last_4_digits?: string;
}
