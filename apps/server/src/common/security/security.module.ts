import { Global, Module } from '@nestjs/common';
import { PinRateLimiter } from './pin-rate-limiter.service';

@Global()
@Module({
  providers: [PinRateLimiter],
  exports: [PinRateLimiter],
})
export class SecurityModule {}
