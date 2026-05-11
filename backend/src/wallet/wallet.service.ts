import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WalletService {
  constructor(private readonly prisma: PrismaService) {}

  async getBalance(companyId: string) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { companyId },
      select: { id: true, balanceCents: true, updatedAt: true },
    });
    if (!wallet) throw new NotFoundException('carteira não encontrada');
    return {
      walletId: wallet.id,
      balanceCents: Number(wallet.balanceCents),
      updatedAt: wallet.updatedAt,
    };
  }

  async getStatement(companyId: string, limit = 50, offset = 0) {
    const wallet = await this.prisma.wallet.findUnique({
      where: { companyId },
      select: { id: true },
    });
    if (!wallet) throw new NotFoundException('carteira não encontrada');

    const [items, total] = await this.prisma.$transaction([
      this.prisma.ledgerEntry.findMany({
        where: { walletId: wallet.id },
        include: {
          transaction: {
            select: {
              id: true,
              type: true,
              amountCents: true,
              description: true,
              createdAt: true,
              entries: {
                where: { NOT: { walletId: wallet.id } },
                include: {
                  wallet: {
                    include: {
                      company: {
                        select: {
                          id: true,
                          nomeFantasia: true,
                          razaoSocial: true,
                          cnpj: true,
                        },
                      },
                    },
                  },
                },
              },
            },
          },
        },
        orderBy: { createdAt: 'desc' },
        take: limit,
        skip: offset,
      }),
      this.prisma.ledgerEntry.count({ where: { walletId: wallet.id } }),
    ]);

    return {
      items: items.map((entry) => {
        const counterparty =
          entry.transaction.entries[0]?.wallet?.company ?? null;
        return {
          id: entry.id,
          transactionId: entry.transactionId,
          kind: entry.kind,
          amountCents: Number(entry.amountCents),
          balanceAfter: Number(entry.balanceAfter),
          type: entry.transaction.type,
          description: entry.transaction.description,
          counterparty,
          createdAt: entry.createdAt,
        };
      }),
      total,
      limit,
      offset,
    };
  }
}
