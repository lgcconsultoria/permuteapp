import { Body, Controller, Post, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentCompany } from '../auth/current-company.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedCompany } from '../auth/jwt.strategy';
import { TransferDto } from './dto/transfer.dto';
import { TransactionsService } from './transactions.service';

@ApiTags('transactions')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('transactions')
export class TransactionsController {
  constructor(private readonly transactions: TransactionsService) {}

  @Post('transfer')
  @ApiOperation({ summary: 'Transferir créditos para outra empresa (P2P)' })
  transfer(
    @CurrentCompany() company: AuthenticatedCompany,
    @Body() dto: TransferDto,
  ) {
    return this.transactions.transfer(company.id, dto);
  }
}
