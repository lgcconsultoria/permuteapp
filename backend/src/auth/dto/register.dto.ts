import { ApiProperty } from '@nestjs/swagger';
import {
  IsEmail,
  IsOptional,
  IsString,
  Length,
  Matches,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: '12.345.678/0001-90' })
  @IsString()
  @Matches(/^\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}$/, {
    message: 'cnpj inválido',
  })
  cnpj!: string;

  @ApiProperty({ example: 'Empresa Exemplo LTDA' })
  @IsString()
  @Length(2, 200)
  razaoSocial!: string;

  @ApiProperty({ example: 'Empresa Exemplo', required: false })
  @IsOptional()
  @IsString()
  @Length(2, 200)
  nomeFantasia?: string;

  @ApiProperty({ example: 'contato@empresa.com.br' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: '+5511999999999', required: false })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiProperty({ example: 'senha-forte-123', minLength: 8 })
  @IsString()
  @MinLength(8)
  password!: string;
}
