import { Controller, Get, INestApplication } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_FILTER, APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { HttpExceptionFilter } from '../src/common/filters/http-exception.filter';
import { JwtAuthGuard } from '../src/common/guards/jwt-auth.guard';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor';
import { Public } from '../src/common/decorators/public.decorator';
import { MetricsModule } from '../src/metrics/metrics.module';
import { MetricsServerService } from '../src/metrics/metrics-server.service';

// Stand-ins for real controllers: the point is the shape of the route
// pattern (`/subscriptions/:id`), not the business behaviour.
@Controller('subscriptions')
class TestSubscriptionsController {
  @Public()
  @Get(':id')
  findOne(): { id: string } {
    return { id: 'stub' };
  }
}

@Controller('health')
class TestHealthController {
  @Public()
  @Get()
  check(): { status: string } {
    return { status: 'ok' };
  }
}

describe('Metrics endpoint and HTTP metrics (full Nest pipeline)', () => {
  let app: INestApplication;
  let metricsBaseUrl: string;

  const scrape = async (): Promise<string> => {
    const response = await fetch(`${metricsBaseUrl}/metrics`);
    expect(response.status).toBe(200);
    return response.text();
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        // Port 0: the OS picks a free port, so this never clashes with a
        // real metrics server. No .env file is read and no env validation
        // runs — this fake loader supplies the only value needed.
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({ app: { metricsPort: 0 } })],
        }),
        MetricsModule,
      ],
      controllers: [TestSubscriptionsController, TestHealthController],
      providers: [
        { provide: APP_GUARD, useClass: JwtAuthGuard },
        { provide: APP_FILTER, useClass: HttpExceptionFilter },
        { provide: APP_INTERCEPTOR, useClass: TransformInterceptor },
      ],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();

    const port = app.get(MetricsServerService).port;
    expect(port).toBeTypeOf('number');
    metricsBaseUrl = `http://127.0.0.1:${port}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. labels a parameterised request with its route pattern', async () => {
    const response = await request(app.getHttpServer()).get(
      '/subscriptions/0b4b9a4e-1111-2222-3333-444455556666',
    );

    expect(response.status).toBe(200);
    // The API contract is untouched: the envelope still wraps API responses.
    expect(response.body.success).toBe(true);

    const metrics = await scrape();
    expect(metrics).toContain(
      'http_requests_total{method="GET",route="/subscriptions/:id",status="200"} 1',
    );
    expect(metrics).not.toContain('0b4b9a4e');
  });

  it('2. collapses unmatched paths onto `unmatched`', async () => {
    await request(app.getHttpServer()).get('/wp-login.php?x=1').expect(404);

    const metrics = await scrape();
    expect(metrics).toContain('route="unmatched"');
    expect(metrics).not.toContain('wp-login');
  });

  it('3. does not record health probes', async () => {
    await request(app.getHttpServer()).get('/health').expect(200);

    const metrics = await scrape();
    expect(metrics).not.toContain('route="/health"');
  });

  it('4. serves metrics off the API port, unauthenticated and unwrapped', async () => {
    const response = await fetch(`${metricsBaseUrl}/metrics`);
    const body = await response.text();

    expect(response.headers.get('content-type')).toContain(
      'text/plain; version=0.0.4',
    );
    expect(body).toMatch(/^# HELP /);
    expect(body).not.toContain('"success"');

    // The same path on the API itself is not a route at all.
    await request(app.getHttpServer()).get('/metrics').expect(404);
  });

  it('5. closes the metrics server when the application shuts down', async () => {
    await app.close();

    await expect(fetch(`${metricsBaseUrl}/metrics`)).rejects.toThrow();
  });
});
