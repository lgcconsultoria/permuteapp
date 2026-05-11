import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { IsInt, IsOptional, Max, Min } from 'class-validator';
import { CurrentCompany } from '../auth/current-company.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedCompany } from '../auth/jwt.strategy';
import { WalletService } from './wallet.service';

class StatementQuery {
  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  @Max(200)
  limit?: number = 50;

  @IsOptional()
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(0)
  offset?: number = 0;
}

@ApiTags('wallet')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('wallet')
export class WalletController {
  constructor(private readonly wallet: WalletService) {}

  @Get('balance')
  @ApiOperation({ summary: 'Saldo da carteira da empresa autenticada' })
  balance(@CurrentCompany() company: AuthenticatedCompany) {
    return this.wallet.getBalance(company.id);
  }

  @Get('statement')
  @ApiOperation({ summary: 'Extrato de movimentações da carteira' })
  statement(
    @CurrentCompany() company: AuthenticatedCompany,
    @Query() query: StatementQuery,
  ) {
    return this.wallet.getStatement(company.id, query.limit, query.offset);
  }
}
