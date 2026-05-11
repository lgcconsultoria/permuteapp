import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { CompanyStatus } from '@prisma/client';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PrismaService } from '../prisma/prisma.service';
import { JwtPayload } from './auth.service';

export interface AuthenticatedCompany {
  id: string;
  email: string;
  status: CompanyStatus;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: config.get<string>('JWT_ACCESS_SECRET') ?? 'change-me',
    });
  }

  async validate(payload: JwtPayload): Promise<AuthenticatedCompany> {
    const company = await this.prisma.company.findUnique({
      where: { id: payload.sub },
      select: { id: true, email: true, status: true },
    });
    if (!company || company.status === CompanyStatus.SUSPENDED) {
      throw new UnauthorizedException('sessão inválida');
    }
    return company;
  }
}
