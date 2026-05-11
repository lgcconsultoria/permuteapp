import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class CompaniesService {
  constructor(private readonly prisma: PrismaService) {}

  async getProfile(companyId: string) {
    const company = await this.prisma.company.findUnique({
      where: { id: companyId },
      select: {
        id: true,
        cnpj: true,
        razaoSocial: true,
        nomeFantasia: true,
        email: true,
        phone: true,
        status: true,
        createdAt: true,
      },
    });
    if (!company) throw new NotFoundException('empresa não encontrada');
    return company;
  }

  async findByCnpj(cnpj: string) {
    const cleaned = cnpj.replace(/\D/g, '');
    const company = await this.prisma.company.findUnique({
      where: { cnpj: cleaned },
      select: {
        id: true,
        cnpj: true,
        razaoSocial: true,
        nomeFantasia: true,
        status: true,
      },
    });
    if (!company) throw new NotFoundException('empresa não encontrada');
    return company;
  }
}
