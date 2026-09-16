import { Controller, Get } from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { CreepScoreService } from './creep-score.service';
import { CurrentUser } from '../common/decorators/current-user.decorator';

@ApiTags('creep-score')
@ApiBearerAuth()
@Controller('creep-score')
export class CreepScoreController {
  constructor(private readonly creepScoreService: CreepScoreService) {}

  @Get()
  @ApiOperation({
    summary: 'Calculate Creep Score and financial risk analytics',
  })
  @ApiResponse({
    status: 200,
    description: 'Creep score metrics and risk status',
  })
  async getCreepScore(@CurrentUser('id') userId: string) {
    return this.creepScoreService.getCreepScore(userId);
  }
}
