import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import cookieParser from 'cookie-parser';
import { AllExceptionsFilter } from '@buildone/app-server-tslib';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Register global exception filter
  app.useGlobalFilters(new AllExceptionsFilter());

  app.use(cookieParser());

  await app.listen(3000);
}

bootstrap();
