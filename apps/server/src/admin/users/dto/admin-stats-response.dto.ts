import { ApiProperty } from '@nestjs/swagger';

export class AdminStatsResponseDto {
  @ApiProperty({ example: 42, description: 'จำนวนผู้ใช้ทั้งหมดในระบบ' })
  totalUsers!: number;

  @ApiProperty({ example: 120, description: 'จำนวน Subscription ที่กำลังใช้งานอยู่' })
  totalSubscriptions!: number;

  @ApiProperty({ example: 55, description: 'จำนวนบัตรชำระเงินที่เปิดใช้งาน' })
  totalCards!: number;

  @ApiProperty({ example: 18, description: 'จำนวนบริการ/แพ็กเกจกลางในระบบ' })
  totalPackages!: number;
}
