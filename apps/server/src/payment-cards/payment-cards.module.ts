import { Module } from '@nestjs/common';
import { PaymentCardsController } from './payment-cards.controller';
import { PaymentCardsService } from './payment-cards.service';

@Module({
  controllers: [PaymentCardsController],
  providers: [PaymentCardsService],
  exports: [PaymentCardsService],
})
export class PaymentCardsModule {}
