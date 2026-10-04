import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class SocialLoginDto {
  @ApiProperty({
    example: 'google',
    description: 'Social authentication provider',
    enum: ['google', 'apple'],
  })
  @IsIn(['google', 'apple'])
  @IsNotEmpty()
  provider!: 'google' | 'apple';

  @ApiProperty({
    example: 'user@example.com',
    description: 'User email address received from social provider',
  })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({
    example: 'oauth-token-xyz',
    description: 'OAuth Identity Token or Access Token from provider',
  })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiPropertyOptional({
    example: 'John Doe',
    description: 'User display name',
  })
  @IsOptional()
  @IsString()
  name?: string;
}
