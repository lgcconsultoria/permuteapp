import { OfferStatus, PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

interface SeedCompany {
  cnpj: string;
  razaoSocial: string;
  nomeFantasia: string;
  email: string;
  phone: string;
  balanceReais: number;
  offers: Array<{
    title: string;
    description: string;
    priceReais: number;
    category: string;
  }>;
}

const companies: SeedCompany[] = [
  {
    cnpj: '11111111000111',
    razaoSocial: 'Empresa A LTDA',
    nomeFantasia: 'Hotel Aurora',
    email: 'a@a.com',
    phone: '+5511911111111',
    balanceReais: 1000,
    offers: [
      {
        title: 'Diária dupla com café',
        description: 'Quarto duplo com vista, café da manhã incluso e Wi-Fi.',
        priceReais: 250,
        category: 'hospedagem',
      },
      {
        title: 'Pacote 3 diárias + jantar',
        description: 'Estadia de fim de semana com jantar para duas pessoas.',
        priceReais: 850,
        category: 'hospedagem',
      },
    ],
  },
  {
    cnpj: '22222222000122',
    razaoSocial: 'Empresa B LTDA',
    nomeFantasia: 'BetaLog Transportes',
    email: 'b@b.com',
    phone: '+5511922222222',
    balanceReais: 500,
    offers: [
      {
        title: 'Frete fracionado capital SP',
        description: 'Coleta e entrega no mesmo dia em São Paulo capital, até 500 kg.',
        priceReais: 320,
        category: 'logistica',
      },
    ],
  },
  {
    cnpj: '33333333000133',
    razaoSocial: 'Empresa C LTDA',
    nomeFantasia: 'Gamma Marketing',
    email: 'c@c.com',
    phone: '+5511933333333',
    balanceReais: 2000,
    offers: [
      {
        title: 'Campanha digital 30 dias',
        description: 'Gestão de Google Ads + Meta Ads, criativos e relatório semanal.',
        priceReais: 1800,
        category: 'marketing',
      },
      {
        title: 'Consultoria de branding (4h)',
        description: 'Workshop presencial de posicionamento e identidade visual.',
        priceReais: 600,
        category: 'consultoria',
      },
    ],
  },
];

async function main(): Promise<void> {
  const passwordHash = await bcrypt.hash('senha-1234', 10);

  for (const c of companies) {
    const company = await prisma.company.upsert({
      where: { email: c.email },
      update: {},
      create: {
        cnpj: c.cnpj,
        razaoSocial: c.razaoSocial,
        nomeFantasia: c.nomeFantasia,
        email: c.email,
        phone: c.phone,
        passwordHash,
        status: 'ACTIVE',
        wallet: { create: { balanceCents: BigInt(c.balanceReais * 100) } },
      },
    });

    // Reset balance to the configured value on each run so the seed is
    // deterministic even if the company already existed.
    await prisma.wallet.update({
      where: { companyId: company.id },
      data: { balanceCents: BigInt(c.balanceReais * 100) },
    });

    for (const offer of c.offers) {
      const existing = await prisma.offer.findFirst({
        where: { companyId: company.id, title: offer.title },
      });
      if (!existing) {
        await prisma.offer.create({
          data: {
            companyId: company.id,
            title: offer.title,
            description: offer.description,
            priceCents: BigInt(offer.priceReais * 100),
            category: offer.category,
            status: OfferStatus.ACTIVE,
          },
        });
      }
    }

    console.log(`✓ ${c.email} (${c.nomeFantasia}) — saldo R$ ${c.balanceReais}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
