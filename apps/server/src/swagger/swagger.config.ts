import type { INestApplication } from '@nestjs/common';
import {
  DocumentBuilder,
  SwaggerModule,
  type OpenAPIObject,
} from '@nestjs/swagger';

export const SWAGGER_DOCS_PATH = 'docs';
export const SWAGGER_JSON_PATH = 'docs-json';

export function buildSwaggerConfig() {
  return new DocumentBuilder()
    .setTitle('Subscription Track API')
    .setDescription('REST API for Subscription Track')
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Enter JWT access token',
      },
      'bearer',
    )
    .build();
}

export function createSwaggerDocument(app: INestApplication): OpenAPIObject {
  return SwaggerModule.createDocument(app, buildSwaggerConfig());
}

export function setupSwagger(
  app: INestApplication,
  environment: 'development' | 'test' | 'production',
): OpenAPIObject | null {
  if (environment === 'production') {
    return null;
  }

  const document = createSwaggerDocument(app);

  SwaggerModule.setup(SWAGGER_DOCS_PATH, app, document, {
    jsonDocumentUrl: SWAGGER_JSON_PATH,
    swaggerOptions: {
      persistAuthorization: true,
    },
  });

  return document;
}
