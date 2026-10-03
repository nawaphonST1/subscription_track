import {
  Inject,
  Injectable,
  Logger,
  OnApplicationBootstrap,
  OnApplicationShutdown,
  Optional,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createServer, Server } from 'node:http';
import { Registry } from '@prometheus-io/client';

import type { AppConfiguration } from '../config/app.config';
import { METRICS_REGISTRY } from './metrics.registry';

export const DEFAULT_METRICS_PORT = 9464;

/**
 * Bound inside the container only. The metrics server must be reachable from
 * a sibling container (the Grafana Alloy agent, phase 3), which rules out
 * 127.0.0.1, and it is never published to the host: the production Compose
 * files give `api` no `ports:` mapping, and nginx proxies nothing to this
 * port. Prometheus data therefore never leaves the Docker network.
 */
export const METRICS_HOST = '0.0.0.0';

const METRICS_PATH = '/metrics';

/**
 * Serves the Prometheus registry on its own HTTP server, deliberately not on
 * the API's port: that keeps `/metrics` away from the global JwtAuthGuard and
 * the global TransformInterceptor (which would wrap the exposition format in
 * the JSON envelope), and off nginx's `location /`, which proxies the whole
 * API to the public internet.
 *
 * The same service is reused by the worker process in sub-step 2c.
 */
@Injectable()
export class MetricsServerService
  implements OnApplicationBootstrap, OnApplicationShutdown
{
  private readonly logger = new Logger(MetricsServerService.name);
  private server?: Server;

  constructor(
    @Inject(METRICS_REGISTRY) private readonly registry: Registry,
    @Optional() private readonly configService?: ConfigService,
  ) {}

  async onApplicationBootstrap(): Promise<void> {
    await this.listen();
  }

  async onApplicationShutdown(): Promise<void> {
    await this.close();
  }

  /** Actual bound port, or undefined when the server is not listening. */
  get port(): number | undefined {
    const address = this.server?.address();
    return address !== null && typeof address === 'object'
      ? address.port
      : undefined;
  }

  private resolvePort(): number {
    const app = this.configService?.get<AppConfiguration>('app');
    return app?.metricsPort ?? DEFAULT_METRICS_PORT;
  }

  private async listen(): Promise<void> {
    const port = this.resolvePort();
    const server = createServer((request, response) => {
      const path = (request.url ?? '').split('?')[0];

      if (request.method !== 'GET' || path !== METRICS_PATH) {
        response.writeHead(404, { 'Content-Type': 'text/plain' });
        response.end('Not found\n');
        return;
      }

      this.registry
        .metrics()
        .then((body) => {
          response.writeHead(200, {
            'Content-Type': this.registry.contentType,
          });
          response.end(body);
        })
        .catch(() => {
          // Never echo the underlying error: it can carry internal detail.
          response.writeHead(500, { 'Content-Type': 'text/plain' });
          response.end('Failed to collect metrics\n');
        });
    });

    try {
      await new Promise<void>((resolve, reject) => {
        server.once('error', reject);
        server.listen(port, METRICS_HOST, () => {
          server.removeListener('error', reject);
          resolve();
        });
      });
    } catch {
      // Metrics are auxiliary: a busy port must not stop the API from
      // serving traffic. The message carries no address detail beyond the
      // port that was attempted.
      this.logger.error(`Metrics server could not bind port ${port}`);
      return;
    }

    this.server = server;
    this.logger.log(`Metrics server listening on ${METRICS_HOST}:${this.port}`);
  }

  private async close(): Promise<void> {
    const server = this.server;
    if (server === undefined) {
      return;
    }

    this.server = undefined;

    // Drop keep-alive sockets too, otherwise the port stays held until every
    // idle client disconnects and a restart hits EADDRINUSE.
    server.closeAllConnections();
    await new Promise<void>((resolve) => server.close(() => resolve()));
  }
}
