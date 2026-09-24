# Ticketz Company Exporter

Ferramenta simples para exportar, por empresa, apenas os dados necessários do Ticketz:

- `Messages`
- `Tickets`
- `Contacts`

A exportação gera um arquivo `.tar.gz` contendo os três arquivos CSV, filtrados exclusivamente pelo `companyId` informado.


## Instalação

Clone o repositório no servidor:

```bash
git clone https://github.com/leostrongGG/ticketz-company-exporter.git
cd ticketz-company-exporter
```

Dê permissão de execução ao script:

```bash
chmod +x exportar-ticketz-company.sh
```

## Execução

Execute informando o `companyId` desejado:

```bash
sudo ./exportar-ticketz-company.sh 109
```
Substitua `109` pelo ID da empresa que deseja exportar


## Pasta de destino opcional

Por padrão, o arquivo `.tar.gz` é criado na pasta atual. Para escolher outra pasta:

```bash
sudo ./exportar-ticketz-company.sh 109 ~/exportacoes-ticketz
```

## Arquivo gerado

O script gera um arquivo semelhante a:

```text
ticketz-export-109-20260924173402.tar.gz
```

O arquivo contém:

```text
ticketz-export-109-20260924173402/
├── Contacts_company_109.csv
├── Messages_company_109.csv
└── Tickets_company_109.csv
```

## Conferir o conteúdo

```bash
tar -tzf ticketz-export-109-*.tar.gz
```

Para extrair os CSVs:

```bash
tar -xzf ticketz-export-109-*.tar.gz
```

## Observações

- O script localiza automaticamente o container PostgreSQL ativo do Ticketz.
- O banco padrão utilizado é `ticketz`.
- O usuário padrão utilizado é `ticketz`.
- Cada tabela é filtrada por `"companyId" = <companyId informado>`.
- Nenhuma outra empresa é copiada.
- A exportação é somente de dados em CSV; não é um backup completo nem contém a estrutura necessária para restaurar todo o sistema.

## Licença

MIT
