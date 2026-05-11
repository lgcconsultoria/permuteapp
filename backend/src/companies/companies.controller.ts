import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentCompany } from '../auth/current-company.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedCompany } from '../auth/jwt.strategy';
import { CompaniesService } from './companies.service';

@ApiTags('companies')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('companies')
export class CompaniesController {
  constructor(private readonly companies: CompaniesService) {}

  @Get('me')
  @ApiOperation({ summary: 'Perfil da empresa autenticada' })
  me(@CurrentCompany() company: AuthenticatedCompany) {
    return this.companies.getProfile(company.id);
  }

  @Get('by-cnpj/:cnpj')
  @ApiOperation({ summary: 'Buscar empresa por CNPJ (para transferências)' })
  byCnpj(@Param('cnpj') cnpj: string) {
    return this.companies.findByCnpj(cnpj);
  }
}
