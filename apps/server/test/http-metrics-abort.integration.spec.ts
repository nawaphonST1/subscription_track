import { Controller, Get, INestApplication } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';

import { MetricsModule } from '../src/metrics/metrics.module';
import { MetricsServerService } from '../src/metrics/metrics-server.service';

/**
 * The abort path can only be exercised against a real socket: supertest and
 * the fake-EventEmitter unit tests cannot reproduce a client that disappears
 * mid-response. This boots the real Nest HTTP pipeline on an OS-assigned port
 * and hangs up on a deliberately slow handler.
 */
@Controller()
class SlowController {
  @Get('slow')
  async slow(): Promise<{ ok: true }> {
    await new Promise((resolve) => setTimeout(resolve, 1000));
    return { ok: true };
  }

  @Get('fast')
  fast(): { ok: true } {
    return { ok: true };
  }
}

describe('HTTP metrics: aborted requests against a real server', () => {
  let app: INestApplication;
  let apiPort: number;
  let metricsBaseUrl: string;

  const scrape = async (): Promise<string> => {
    const response = await fetch(`${metricsBaseUrl}/metrics`);
    expect(response.status).toBe(200);
    return response.text();
  };

  const countFor = (body: string, route: string, status: string): number => {
    const pattern = new RegExp(
      `^http_requests_total\\{method="GET",route="${route.replace(
        /[/\\^$*+?.()|[\]{}]/g,
        '\\$&',
      )}",status="${status}"\\} (\\d+)`,
      'm',
    );
    const match = pattern.exec(body);
    return match === null ? 0 : Number(match[1]);
  };

  beforeAll(async () => {
    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({ app: { metricsPort: 0 } })],
        }),
        MetricsModule,
      ],
      controllers: [SlowController],
    }).compile();

    app = moduleRef.createNestApplication();
    await app.init();
    await app.listen(0, '127.0.0.1');
    apiPort = (app.getHttpServer().address() as { port: number }).port;
    metricsBaseUrl = `http://127.0.0.1:${app.get(MetricsServerService).port}`;
  });

  afterAll(async () => {
    await app.close();
  });

  it('1. counts a completed request once, with its real status', async () => {
    const before = countFor(await scrape(), '/fast', '200');

    const response = await fetch(`http://127.0.0.1:${apiPort}/fast`);
    expect(response.status).toBe(200);
    await response.text();

    const body = await scrape();
    expect(countFor(body, '/fast', '200')).toBe(before + 1);
    expect(countFor(body, '/fast', 'aborted')).toBe(0);
  });

  it('2. counts a client abort once, as status="aborted"', async () => {
    const before = await scrape();

    const controller = new AbortController();
    const pending = fetch(`http://127.0.0.1:${apiPort}/slow`, {
      signal: controller.signal,
    }).catch((error: Error) => error.name);
    await new Promise((resolve) => setTimeout(resolve, 150));
    controller.abort();
    expect(await pending).toBe('AbortError');

    // Let the handler run to completion, so a late `finish` would have had
    // every chance to double count.
    await new Promise((resolve) => setTimeout(resolve, 1200));

    const after = await scrape();
    expect(countFor(after, '/slow', 'aborted')).toBe(
      countFor(before, '/slow', 'aborted') + 1,
    );
    expect(countFor(after, '/slow', '200')).toBe(0);
  }, 15000);

  it('3. leaves the 5xx-style numeric status queries free of aborts', async () => {
    const body = await scrape();
    const abortedAsNumeric = /status="aborted"/.test(body);
    expect(abortedAsNumeric).toBe(true);
    // `aborted` is not a number, so `status=~"5.."` can never match it.
    expect(/status="[0-9]{3}"/.test(body)).toBe(true);
    expect(/status="aborted[0-9]/.test(body)).toBe(false);
  });
});
