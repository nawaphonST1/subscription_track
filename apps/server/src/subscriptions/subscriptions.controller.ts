import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiHeader,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { RequireSecurityPin } from '../common/guards/security-pin.guard';
import { CreateSubscriptionDto } from './dto/create-subscription.dto';
import { UpdateSubscriptionDto } from './dto/update-subscription.dto';
import { QuerySubscriptionDto } from './dto/query-subscription.dto';

@ApiTags('subscriptions')
@ApiBearerAuth()
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get()
  @ApiOperation({ summary: 'List and filter user subscriptions' })
  @ApiResponse({ status: 200, description: 'Filtered list of subscriptions' })
  async findAll(
    @CurrentUser('id') userId: string,
    @Query() query: QuerySubscriptionDto,
  ) {
    return this.subscriptionsService.findAll(userId, query);
  }

  @Get('upcoming')
  @ApiOperation({
    summary: 'Get upcoming subscription renewals ordered by next renewal date',
  })
  @ApiResponse({ status: 200, description: 'Upcoming renewals list' })
  async findUpcoming(
    @CurrentUser('id') userId: string,
    @Query('limit') limit?: number,
  ) {
    return this.subscriptionsService.findUpcoming(
      userId,
      limit ? Number(limit) : 10,
    );
  }

  @Get('presets')
  @ApiOperation({ summary: 'List popular subscription presets catalog' })
  @ApiResponse({ status: 200, description: 'List of presets' })
  async listPresets() {
    return this.subscriptionsService.listPresets();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get single subscription detail' })
  @ApiResponse({ status: 200, description: 'Subscription details' })
  @ApiResponse({ status: 404, description: 'Subscription not found' })
  async findOne(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.subscriptionsService.findOne(userId, id);
  }

  @Post()
  @ApiOperation({ summary: 'Add a new subscription attached to a card' })
  @ApiResponse({ status: 201, description: 'Subscription created' })
  async create(
    @CurrentUser('id') userId: string,
    @Body() dto: CreateSubscriptionDto,
  ) {
    return this.subscriptionsService.create(userId, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Update subscription details' })
  @ApiResponse({ status: 200, description: 'Subscription updated' })
  @ApiResponse({
    status: 400,
    description: 'Bad request or invalid payment card',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({ status: 404, description: 'Subscription not found' })
  async update(
    @CurrentUser('id') userId: string,
    @Param('id') id: string,
    @Body() dto: UpdateSubscriptionDto,
  ) {
    return this.subscriptionsService.update(userId, id, dto);
  }

  @Delete(':id')
  @RequireSecurityPin()
  @ApiOperation({ summary: 'Delete a subscription (requires security PIN)' })
  @ApiHeader({
    name: 'x-security-pin',
    required: false,
    description:
      '6-digit security PIN (can alternatively be sent in JSON body as security_pin)',
  })
  @ApiResponse({ status: 200, description: 'Subscription deleted' })
  @ApiResponse({
    status: 400,
    description: 'Security PIN is required or invalid',
  })
  @ApiResponse({ status: 401, description: 'Unauthorized' })
  @ApiResponse({
    status: 403,
    description: 'Invalid security PIN or PIN setup required',
  })
  @ApiResponse({ status: 404, description: 'Subscription not found' })
  async remove(@CurrentUser('id') userId: string, @Param('id') id: string) {
    return this.subscriptionsService.remove(userId, id);
  }
}
