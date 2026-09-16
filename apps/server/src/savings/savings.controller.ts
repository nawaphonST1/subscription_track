import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { SavingsService } from './savings.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';
import { BatchCancelDto } from './dto/batch-cancel.dto';

@ApiTags('savings')
@ApiBearerAuth()
@Controller('savings')
export class SavingsController {
  constructor(private readonly savingsService: SavingsService) {}

  @Get('optimizer')
  @ApiOperation({
    summary:
      'Detect unused subscriptions and calculate yearly savings projection',
  })
  @ApiResponse({
    status: 200,
    description: 'Potential savings and unused subscriptions list',
  })
  async getPotentialSavings(@CurrentUser('id') userId: string) {
    return this.savingsService.getPotentialSavings(userId);
  }

  @Post('batch-cancel')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({
    summary: 'PIN-protected batch cancellation of unused subscriptions',
  })
  @ApiResponse({
    status: 200,
    description: 'Subscriptions cancelled and savings unlocked',
  })
  @ApiResponse({ status: 403, description: 'Invalid 6-digit security PIN' })
  async batchCancel(
    @CurrentUser('id') userId: string,
    @Body() dto: BatchCancelDto,
  ) {
    return this.savingsService.batchCancel(userId, dto);
  }

  @Get('logs')
  @ApiOperation({ summary: 'List audit logs of past cancelled subscriptions' })
  @ApiResponse({ status: 200, description: 'List of cancellation logs' })
  async getCancellationLogs(@CurrentUser('id') userId: string) {
    return this.savingsService.getCancellationLogs(userId);
  }
}
