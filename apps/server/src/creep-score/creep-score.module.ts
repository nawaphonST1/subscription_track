import { Module } from '@nestjs/common';
import { CreepScoreController } from './creep-score.controller';
import { CreepScoreService } from './creep-score.service';

@Module({
  controllers: [CreepScoreController],
  providers: [CreepScoreService],
  exports: [CreepScoreService],
})
export class CreepScoreModule {}
