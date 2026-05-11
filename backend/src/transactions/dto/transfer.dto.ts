import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  IsUUID,
  Length,
  Min,
} from 'class-validator';

export class TransferDto {
  @ApiProperty({ description: 'ID da empresa destinatária' })
  @IsUUID()
  toCompanyId!: string;

  @ApiProperty({ example: 10000, description: 'valor em centavos' })
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  amountCents!: number;

  @ApiProperty({ required: false, example: 'Pagamento referente à NF 123' })
  @IsOptional()
  @IsString()
  @Length(1, 200)
  description?: string;
}
