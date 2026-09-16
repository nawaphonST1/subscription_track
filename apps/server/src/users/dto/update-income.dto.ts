import { ApiProperty } from '@nestjs/swagger';
import { IsNotEmpty, IsNumber, Min } from 'class-validator';

export class UpdateIncomeDto {
  @ApiProperty({
    example: 50000,
    description: 'Monthly income in user currency',
  })
  @IsNumber()
  @Min(0)
  @IsNotEmpty()
  monthly_income!: number;
}
