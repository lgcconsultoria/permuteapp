import { ApiProperty } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import {
  IsInt,
  IsOptional,
  IsString,
  Length,
  Min,
} from 'class-validator';

export class CreateOfferDto {
  @ApiProperty({ example: 'Hospedagem hotel 1 diária' })
  @IsString()
  @Length(2, 200)
  title!: string;

  @ApiProperty({ example: 'Diária em quarto duplo, café incluso' })
  @IsString()
  @Length(2, 2000)
  description!: string;

  @ApiProperty({ example: 25000, description: 'preço em centavos (1 crédito = R$ 1,00)' })
  @Transform(({ value }) => Number(value))
  @IsInt()
  @Min(1)
  priceCents!: number;

  @ApiProperty({ example: 'hospedagem', required: false })
  @IsOptional()
  @IsString()
  @Length(2, 50)
  category?: string;
}
