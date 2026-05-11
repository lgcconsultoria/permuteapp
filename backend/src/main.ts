import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from './app.module';

// Money is stored in cents as BigInt. JSON.stringify cannot serialize BigInt
// natively; the values we hold (cents) always fit Number.MAX_SAFE_INTEGER, so
// emit them as plain numbers.
(BigInt.prototype as unknown as { toJSON: () => number }).toJSON = function () {
  return Number(this as unknown as bigint);
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule, { cors: true });

  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const config = new DocumentBuilder()
    .setTitle('PermuteApp API')
    .setDescription('Plataforma de permuta multilateral')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document);

  const port = Number(process.env.PORT ?? 3000);
  await app.listen(port);
}

bootstrap();
