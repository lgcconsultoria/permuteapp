import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ServeStaticModule } from '@nestjs/serve-static';
import { join } from 'path';
import { AuthModule } from './auth/auth.module';
import { CompaniesModule } from './companies/companies.module';
import { OffersModule } from './offers/offers.module';
import { PrismaModule } from './prisma/prisma.module';
import { TransactionsModule } from './transactions/transactions.module';
import { WalletModule } from './wallet/wallet.module';

// In production the Flutter web build is copied into ./web (relative to the
// compiled dist/ folder). In dev it's optional; absence is harmless.
const WEB_ROOT = join(__dirname, '..', 'web');

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ServeStaticModule.forRoot({
      rootPath: WEB_ROOT,
      exclude: ['/api*', '/docs*'],
      serveStaticOptions: { fallthrough: true },
    }),
    PrismaModule,
    AuthModule,
    CompaniesModule,
    OffersModule,
    WalletModule,
    TransactionsModule,
  ],
})
export class AppModule {}
