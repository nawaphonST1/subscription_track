import { ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsBoolean, IsOptional } from 'class-validator';

export class DeletePackageQueryDto {
  @ApiPropertyOptional({
    description:
      'Whether to permanently purge the package. If false or omitted, performs soft-delete/disable.',
    default: false,
  })
  @IsOptional()
  @Transform(({ value }) => value === 'true' || value === true)
  @IsBoolean()
  permanent?: boolean = false;
}
