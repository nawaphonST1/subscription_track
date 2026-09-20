import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Patch,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { UpdateIncomeDto } from './dto/update-income.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { VerifyPinDto } from './dto/verify-pin.dto';
import { ChangePinDto } from './dto/change-pin.dto';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('me')
  @ApiOperation({ summary: 'Get current user profile and metrics' })
  @ApiResponse({
    status: 200,
    description: 'User profile retrieved successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Missing or invalid token',
  })
  @ApiResponse({
    status: 404,
    description: 'User not found',
  })
  async getProfile(@CurrentUser('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Patch('me')
  @ApiOperation({ summary: 'Update user profile and/or monthly income' })
  @ApiResponse({
    status: 200,
    description: 'User profile updated successfully',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad Request - Validation error or no fields provided',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - Missing or invalid token',
  })
  @ApiResponse({
    status: 404,
    description: 'User not found',
  })
  async updateProfile(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(userId, dto);
  }

  @Patch('income')
  @ApiOperation({ summary: 'Update monthly income' })
  @ApiResponse({ status: 200, description: 'Monthly income updated' })
  async updateIncome(
    @CurrentUser('id') userId: string,
    @Body() dto: UpdateIncomeDto,
  ) {
    return this.usersService.updateIncome(userId, dto.monthly_income);
  }

  @Post('verify-pin')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify 6-digit security PIN' })
  @ApiResponse({ status: 200, description: 'PIN verification result returned' })
  async verifyPin(
    @CurrentUser('id') userId: string,
    @Body() dto: VerifyPinDto,
  ) {
    return this.usersService.verifyPin(userId, dto.pin);
  }

  @Patch('pin')
  @ApiOperation({ summary: 'Change 6-digit security PIN' })
  @ApiResponse({
    status: 200,
    description: 'Security PIN updated successfully',
  })
  @ApiResponse({
    status: 401,
    description: 'Current security PIN is incorrect',
  })
  async changePin(
    @CurrentUser('id') userId: string,
    @Body() dto: ChangePinDto,
  ) {
    return this.usersService.changePin(userId, dto.current_pin, dto.new_pin);
  }
}
