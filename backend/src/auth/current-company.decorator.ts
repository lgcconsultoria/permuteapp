import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { AuthenticatedCompany } from './jwt.strategy';

export const CurrentCompany = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): AuthenticatedCompany => {
    const req = ctx.switchToHttp().getRequest();
    return req.user as AuthenticatedCompany;
  },
);
