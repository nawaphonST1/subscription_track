import { Global, Module } from '@nestjs/common';
import { PinRateLimiter } from './pin-rate-limiter.service';
import { SecurityPinService } from './security-pin.service';

@Global()
@Module({
  providers: [PinRateLimiter, SecurityPinService],
  exports: [PinRateLimiter, SecurityPinService],
})
export class SecurityModule {}
