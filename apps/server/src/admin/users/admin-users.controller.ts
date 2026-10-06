import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiParam,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { AdminGuard } from '../../common/guards/admin.guard';
import { AdminUsersService } from './admin-users.service';
import { AdminUserResponseDto } from './dto/admin-user-response.dto';
import { AdminStatsResponseDto } from './dto/admin-stats-response.dto';
import { UpdateAdminUserDto } from './dto/update-admin-user.dto';
import { UpdateSubscriptionDto } from '../../subscriptions/dto/update-subscription.dto';

@ApiTags('admin-users')
@ApiBearerAuth()
@UseGuards(AdminGuard)
@Controller('admin')
export class AdminUsersController {
  constructor(private readonly adminUsersService: AdminUsersService) {}

  @Get('stats')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get system-wide overview statistics for admin dashboard',
    description: 'Returns total users, active subscriptions, cards, and packages in the system.',
  })
  @ApiResponse({
    status: 200,
    description: 'System statistics summary',
    type: AdminStatsResponseDto,
  })
  async getStats(): Promise<AdminStatsResponseDto> {
    return this.adminUsersService.getStats();
  }

  @Get('users')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get all users in the system',
    description: 'Returns all registered users with subscription and payment card counts.',
  })
  @ApiResponse({
    status: 200,
    description: 'List of all registered users',
    type: [AdminUserResponseDto],
  })
  async getUsers(): Promise<AdminUserResponseDto[]> {
    return this.adminUsersService.getUsers();
  }

  @Get('users/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Get user detail by ID including their subscriptions and cards',
    description: 'Returns a user with their full subscriptions and cards list.',
  })
  async getUserDetail(@Param('id') id: string) {
    return this.adminUsersService.getUserDetail(id);
  }

  @Patch('users/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update user profile by ID (Admin action)',
    description: 'Allows administrator to update user name, role, or monthly income.',
  })
  async updateUser(
    @Param('id') id: string,
    @Body() dto: UpdateAdminUserDto,
  ) {
    return this.adminUsersService.updateUser(id, dto);
  }

  @Patch('subscriptions/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Update user subscription by ID (Admin action)',
    description: 'Allows administrator to edit any user subscription details (name, price, status, billing cycle, renewal date, etc.)',
  })
  async updateSubscription(
    @Param('id') id: string,
    @Body() dto: UpdateSubscriptionDto,
  ) {
    return this.adminUsersService.updateSubscription(id, dto);
  }

  @Delete('subscriptions/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete user subscription by ID (Admin action)',
    description: 'Allows administrator to remove a subscription item.',
  })
  async deleteSubscription(@Param('id') id: string) {
    return this.adminUsersService.deleteSubscription(id);
  }

  @Delete('users/:id')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'Delete user by ID',
    description: 'Deletes a user and their associated subscriptions/cards from the system.',
  })
  @ApiParam({
    name: 'id',
    description: 'Unique UUID of the user to delete',
    example: '3fa85f64-5717-4562-b3fc-2c963f66afa6',
  })
  @ApiResponse({
    status: 200,
    description: 'User successfully deleted',
  })
  @ApiResponse({ status: 404, description: 'User not found' })
  async deleteUser(
    @Param('id') id: string,
  ): Promise<{ message: string; id: string }> {
    return this.adminUsersService.deleteUser(id);
  }
}
