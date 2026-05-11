import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CurrentCompany } from '../auth/current-company.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AuthenticatedCompany } from '../auth/jwt.strategy';
import { CreateOfferDto } from './dto/create-offer.dto';
import { ListOffersQuery } from './dto/list-offers.query';
import { UpdateOfferDto } from './dto/update-offer.dto';
import { OffersService } from './offers.service';

@ApiTags('offers')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('offers')
export class OffersController {
  constructor(private readonly offers: OffersService) {}

  @Get()
  @ApiOperation({ summary: 'Listar ofertas do marketplace' })
  list(@Query() query: ListOffersQuery) {
    return this.offers.list(query);
  }

  @Get('mine')
  @ApiOperation({ summary: 'Listar ofertas da empresa autenticada' })
  mine(@CurrentCompany() company: AuthenticatedCompany) {
    return this.offers.listMine(company.id);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Detalhar oferta' })
  detail(@Param('id') id: string) {
    return this.offers.findOne(id);
  }

  @Post()
  @ApiOperation({ summary: 'Criar nova oferta' })
  create(
    @CurrentCompany() company: AuthenticatedCompany,
    @Body() dto: CreateOfferDto,
  ) {
    return this.offers.create(company.id, dto);
  }

  @Patch(':id')
  @ApiOperation({ summary: 'Atualizar oferta' })
  update(
    @CurrentCompany() company: AuthenticatedCompany,
    @Param('id') id: string,
    @Body() dto: UpdateOfferDto,
  ) {
    return this.offers.update(company.id, id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Arquivar oferta' })
  async remove(
    @CurrentCompany() company: AuthenticatedCompany,
    @Param('id') id: string,
  ): Promise<void> {
    await this.offers.remove(company.id, id);
  }
}
