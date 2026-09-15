import { Test, TestingModule } from '@nestjs/testing';
import { beforeAll, describe, expect, it } from 'vitest';

describe('AppModule', () => {
  let moduleRef: TestingModule;

  beforeAll(async () => {
    Object.assign(process.env, {
      NODE_ENV: 'test',
      APP_HOST: '127.0.0.1',
      PORT: '3000',
      DB_HOST: 'localhost',
      DB_PORT: '5432',
      DB_NAME: 'subscription_track_test',
      DB_USER: 'subscription_track',
      DB_PASSWORD: 'test-password',
    });

    const { AppModule } = await import('./app.module');

    moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
  });

  it('should compile the root AppModule successfully', () => {
    expect(moduleRef).toBeDefined();
  });
});
