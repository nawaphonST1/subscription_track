import type { INestApplication } from '@nestjs/common';
import { SwaggerModule, type OpenAPIObject } from '@nestjs/swagger';
import { describe, expect, it, vi } from 'vitest';
import {
  buildSwaggerConfig,
  setupSwagger,
  SWAGGER_DOCS_PATH,
  SWAGGER_JSON_PATH,
} from './swagger.config';

describe('Swagger Configuration', () => {
  const mockApp = {} as INestApplication;
  const mockDocument: OpenAPIObject = {
    openapi: '3.0.0',
    info: {
      title: 'Subscription Track API',
      description: 'REST API for Subscription Track',
      version: '1.0.0',
    },
    paths: {},
  };

  it('builds the OpenAPI config with approved metadata and bearer security scheme', () => {
    const config = buildSwaggerConfig();

    expect(config.info.title).toBe('Subscription Track API');
    expect(config.info.description).toBe('REST API for Subscription Track');
    expect(config.info.version).toBe('1.0.0');

    expect(config.components?.securitySchemes).toBeDefined();
    const bearerScheme = config.components?.securitySchemes?.['bearer'];
    expect(bearerScheme).toEqual({
      type: 'http',
      scheme: 'bearer',
      bearerFormat: 'JWT',
      description: 'Enter JWT access token',
    });
  });

  it('configures Swagger UI and OpenAPI JSON in non-production environments', () => {
    const createDocSpy = vi
      .spyOn(SwaggerModule, 'createDocument')
      .mockReturnValue(mockDocument);
    const setupSpy = vi
      .spyOn(SwaggerModule, 'setup')
      .mockImplementation(() => {});

    const document = setupSwagger(mockApp, 'development');

    expect(document).toBe(mockDocument);
    expect(createDocSpy).toHaveBeenCalledWith(mockApp, expect.any(Object));
    expect(setupSpy).toHaveBeenCalledTimes(1);

    const firstCall = setupSpy.mock.calls[0];
    expect(firstCall?.[0]).toBe(SWAGGER_DOCS_PATH);
    expect(firstCall?.[1]).toBe(mockApp);
    expect(firstCall?.[2]).toBe(mockDocument);

    const customOptions = firstCall?.[3];
    expect(customOptions?.jsonDocumentUrl).toBe(SWAGGER_JSON_PATH);
    expect(customOptions?.swaggerOptions?.persistAuthorization).toBe(true);

    createDocSpy.mockRestore();
    setupSpy.mockRestore();
  });

  it('does not mount Swagger in production environment', () => {
    const createDocSpy = vi.spyOn(SwaggerModule, 'createDocument');
    const setupSpy = vi.spyOn(SwaggerModule, 'setup');

    const document = setupSwagger(mockApp, 'production');

    expect(document).toBeNull();
    expect(createDocSpy).not.toHaveBeenCalled();
    expect(setupSpy).not.toHaveBeenCalled();

    createDocSpy.mockRestore();
    setupSpy.mockRestore();
  });
});
