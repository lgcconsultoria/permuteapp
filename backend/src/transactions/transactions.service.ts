import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  CompanyStatus,
  LedgerEntryKind,
  Prisma,
  TransactionType,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { TransferDto } from './dto/transfer.dto';

@Injectable()
export class TransactionsService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Atomic P2P credit transfer.
   *
   * Uses SERIALIZABLE isolation so concurrent transfers from the same wallet
   * cannot oversubscribe the balance. Creates one Transaction with two
   * LedgerEntries (DEBIT on sender, CREDIT on receiver) and updates both
   * wallet balances in a single DB transaction.
   */
  async transfer(fromCompanyId: string, dto: TransferDto) {
    if (dto.toCompanyId === fromCompanyId) {
      throw new BadRequestException('não é possível transferir para si mesmo');
    }
    const amount = BigInt(dto.amountCents);

    return this.prisma.$transaction(
      async (tx) => {
        const fromWallet = await tx.wallet.findUnique({
          where: { companyId: fromCompanyId },
        });
        const toWallet = await tx.wallet.findUnique({
          where: { companyId: dto.toCompanyId },
          include: { company: { select: { status: true } } },
        });
        if (!fromWallet) throw new NotFoundException('carteira de origem não encontrada');
        if (!toWallet) throw new NotFoundException('carteira de destino não encontrada');
        if (toWallet.company.status === CompanyStatus.SUSPENDED) {
          throw new ConflictException('empresa destinatária suspensa');
        }
        if (fromWallet.balanceCents < amount) {
          throw new ConflictException('saldo insuficiente');
        }

        const fromBalanceAfter = fromWallet.balanceCents - amount;
        const toBalanceAfter = toWallet.balanceCents + amount;

        await tx.wallet.update({
          where: { id: fromWallet.id },
          data: { balanceCents: fromBalanceAfter },
        });
        await tx.wallet.update({
          where: { id: toWallet.id },
          data: { balanceCents: toBalanceAfter },
        });

        const transaction = await tx.transaction.create({
          data: {
            type: TransactionType.TRANSFER,
            amountCents: amount,
            description: dto.description,
            entries: {
              create: [
                {
                  walletId: fromWallet.id,
                  kind: LedgerEntryKind.DEBIT,
                  amountCents: amount,
                  balanceAfter: fromBalanceAfter,
                },
                {
                  walletId: toWallet.id,
                  kind: LedgerEntryKind.CREDIT,
                  amountCents: amount,
                  balanceAfter: toBalanceAfter,
                },
              ],
            },
          },
          include: { entries: true },
        });

        return {
          id: transaction.id,
          type: transaction.type,
          amountCents: Number(transaction.amountCents),
          description: transaction.description,
          createdAt: transaction.createdAt,
          fromBalanceAfter: Number(fromBalanceAfter),
        };
      },
      { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
    );
  }
}
