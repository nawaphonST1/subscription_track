import { ApiProperty } from '@nestjs/swagger';

export class AdminUserResponseDto {
  @ApiProperty({ example: '3fa85f64-5717-4562-b3fc-2c963f66afa6' })
  id!: string;

  @ApiProperty({ example: 'user@example.com' })
  email!: string;

  @ApiProperty({ example: 'Somchai Prasert', nullable: true })
  name!: string | null;

  @ApiProperty({ example: 35000.0 })
  monthlyIncome!: number;

  @ApiProperty({ example: 3 })
  subscriptionsCount!: number;

  @ApiProperty({ example: 1 })
  cardsCount!: number;

  @ApiProperty({ example: '2026-10-01T12:00:00.000Z' })
  createdAt!: Date;
}
