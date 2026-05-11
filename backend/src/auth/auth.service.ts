import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { CompanyStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { randomBytes, createHash } from 'crypto';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

export interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}

export interface JwtPayload {
  sub: string;
  email: string;
}

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto): Promise<AuthTokens> {
    const cnpj = dto.cnpj.replace(/\D/g, '');
    const existing = await this.prisma.company.findFirst({
      where: { OR: [{ email: dto.email }, { cnpj }] },
    });
    if (existing) {
      throw new ConflictException('email ou cnpj já cadastrado');
    }

    const rounds = Number(this.config.get('BCRYPT_ROUNDS') ?? 10);
    const passwordHash = await bcrypt.hash(dto.password, rounds);

    const company = await this.prisma.company.create({
      data: {
        cnpj,
        razaoSocial: dto.razaoSocial,
        nomeFantasia: dto.nomeFantasia,
        email: dto.email,
        phone: dto.phone,
        passwordHash,
        status: CompanyStatus.PENDING,
        wallet: { create: {} },
      },
    });

    return this.issueTokens(company.id, company.email);
  }

  async login(dto: LoginDto): Promise<AuthTokens> {
    const company = await this.prisma.company.findUnique({
      where: { email: dto.email },
    });
    if (!company) throw new UnauthorizedException('credenciais inválidas');

    const ok = await bcrypt.compare(dto.password, company.passwordHash);
    if (!ok) throw new UnauthorizedException('credenciais inválidas');

    if (company.status === CompanyStatus.SUSPENDED) {
      throw new UnauthorizedException('conta suspensa');
    }

    return this.issueTokens(company.id, company.email);
  }

  async refresh(refreshToken: string): Promise<AuthTokens> {
    const tokenHash = this.hashToken(refreshToken);
    const record = await this.prisma.refreshToken.findUnique({
      where: { tokenHash },
      include: { company: true },
    });
    if (!record || record.revokedAt || record.expiresAt < new Date()) {
      throw new UnauthorizedException('refresh token inválido');
    }

    await this.prisma.refreshToken.update({
      where: { id: record.id },
      data: { revokedAt: new Date() },
    });

    return this.issueTokens(record.company.id, record.company.email);
  }

  async logout(refreshToken: string): Promise<void> {
    const tokenHash = this.hashToken(refreshToken);
    await this.prisma.refreshToken.updateMany({
      where: { tokenHash, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }

  private async issueTokens(
    companyId: string,
    email: string,
  ): Promise<AuthTokens> {
    const payload: JwtPayload = { sub: companyId, email };

    const accessToken = await this.jwt.signAsync(payload, {
      secret: this.config.get('JWT_ACCESS_SECRET'),
      expiresIn: this.config.get('JWT_ACCESS_EXPIRES_IN') ?? '15m',
    });

    const refreshToken = randomBytes(48).toString('base64url');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);
    await this.prisma.refreshToken.create({
      data: {
        companyId,
        tokenHash: this.hashToken(refreshToken),
        expiresAt,
      },
    });

    return { accessToken, refreshToken };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }
}
