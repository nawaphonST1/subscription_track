import { Controller, Get, HttpException, HttpStatus } from '@nestjs/common';
import { AppService } from './app.service';

import { Public } from './common/decorators/public.decorator';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Public()
  @Get()
  getHello(): string {
    return this.appService.getHello();
  }

  @Public()
  @Get('health')
  getHealth(): { status: string } {
    if (process.env.NODE_ENV === 'production') {
      throw new HttpException(
        'Simulated deployment smoke test failure for automated rollback demo',
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
    return { status: 'ok' };
  }
}

