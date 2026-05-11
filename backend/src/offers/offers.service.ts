import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { OfferStatus, Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOfferDto } from './dto/create-offer.dto';
import { ListOffersQuery } from './dto/list-offers.query';
import { UpdateOfferDto } from './dto/update-offer.dto';

@Injectable()
export class OffersService {
  constructor(private readonly prisma: PrismaService) {}

  async create(companyId: string, dto: CreateOfferDto) {
    return this.prisma.offer.create({
      data: {
        companyId,
        title: dto.title,
        description: dto.description,
        priceCents: BigInt(dto.priceCents),
        category: dto.category,
      },
    });
  }

  async list(query: ListOffersQuery) {
    const where: Prisma.OfferWhereInput = {
      status: OfferStatus.ACTIVE,
      ...(query.category ? { category: query.category } : {}),
      ...(query.q
        ? {
            OR: [
              { title: { contains: query.q, mode: 'insensitive' } },
              { description: { contains: query.q, mode: 'insensitive' } },
            ],
          }
        : {}),
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.offer.findMany({
        where,
        include: {
          company: { select: { id: true, nomeFantasia: true, razaoSocial: true } },
        },
        orderBy: { createdAt: 'desc' },
        take: query.limit,
        skip: query.offset,
      }),
      this.prisma.offer.count({ where }),
    ]);

    return { items, total, limit: query.limit, offset: query.offset };
  }

  async findOne(id: string) {
    const offer = await this.prisma.offer.findUnique({
      where: { id },
      include: {
        company: {
          select: { id: true, nomeFantasia: true, razaoSocial: true, cnpj: true },
        },
      },
    });
    if (!offer) throw new NotFoundException('oferta não encontrada');
    return offer;
  }

  async listMine(companyId: string) {
    return this.prisma.offer.findMany({
      where: { companyId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async update(companyId: string, id: string, dto: UpdateOfferDto) {
    const offer = await this.prisma.offer.findUnique({ where: { id } });
    if (!offer) throw new NotFoundException('oferta não encontrada');
    if (offer.companyId !== companyId) {
      throw new ForbiddenException('oferta não pertence à empresa');
    }

    return this.prisma.offer.update({
      where: { id },
      data: {
        title: dto.title,
        description: dto.description,
        priceCents:
          dto.priceCents !== undefined ? BigInt(dto.priceCents) : undefined,
        category: dto.category,
        status: dto.status,
      },
    });
  }

  async remove(companyId: string, id: string) {
    const offer = await this.prisma.offer.findUnique({ where: { id } });
    if (!offer) throw new NotFoundException('oferta não encontrada');
    if (offer.companyId !== companyId) {
      throw new ForbiddenException('oferta não pertence à empresa');
    }
    await this.prisma.offer.update({
      where: { id },
      data: { status: OfferStatus.ARCHIVED },
    });
  }
}
