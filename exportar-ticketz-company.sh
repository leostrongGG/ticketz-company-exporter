#!/usr/bin/env bash
set -euo pipefail

COMPANY_ID="${1:-}"
DEST_DIR="${2:-.}"
TIMESTAMP="$(date +%Y%m%d%H%M%S)"
EXPORT_NAME="ticketz-export-${COMPANY_ID}-${TIMESTAMP}"
EXPORT_DIR="${DEST_DIR}/${EXPORT_NAME}"
ARCHIVE_FILE="${DEST_DIR}/${EXPORT_NAME}.tar.gz"

if [[ -z "$COMPANY_ID" || ! "$COMPANY_ID" =~ ^[0-9]+$ ]]; then
    echo "Uso:"
    echo "  sudo ./exportar-ticketz-company.sh COMPANY_ID [PASTA_DESTINO]"
    echo
    echo "Exemplos:"
    echo "  sudo ./exportar-ticketz-company.sh 109"
    echo "  sudo ./exportar-ticketz-company.sh 109 /home/ubuntu/exportacoes"
    exit 1
fi

if [[ ! -d "$DEST_DIR" ]]; then
    echo "ERRO: pasta de destino não existe: $DEST_DIR"
    exit 1
fi

# Localiza o container PostgreSQL ativo
PG_CONTAINER="$(
    docker ps --format '{{.Names}}' |
    grep -E 'postgres|ticketz.*db' |
    head -n 1 || true
)"

if [[ -z "$PG_CONTAINER" ]]; then
    echo "ERRO: container PostgreSQL não encontrado."
    echo
    echo "Containers ativos:"
    docker ps --format 'table {{.Names}}\t{{.Image}}'
    exit 1
fi

DB_NAME="${DB_NAME:-ticketz}"
DB_USER="${DB_USER:-ticketz}"

mkdir -p "$EXPORT_DIR"

echo "Container PostgreSQL: $PG_CONTAINER"
echo "Banco: $DB_NAME"
echo "Usuário: $DB_USER"
echo "Company ID: $COMPANY_ID"
echo "Pasta temporária: $EXPORT_DIR"
echo

# Verifica se a empresa existe
COMPANY_EXISTS="$(
    docker exec -i "$PG_CONTAINER" \
        psql -U "$DB_USER" -d "$DB_NAME" -tA \
        -c "SELECT COUNT(*) FROM public.\"Companies\" WHERE id = $COMPANY_ID;"
)"

if [[ "$COMPANY_EXISTS" != "1" ]]; then
    echo "ERRO: companyId $COMPANY_ID não existe na tabela Companies."
    rm -rf "$EXPORT_DIR"
    exit 1
fi

for TABLE in Messages Tickets Contacts; do
    OUTPUT_FILE="$EXPORT_DIR/${TABLE}_company_${COMPANY_ID}.csv"

    echo "Exportando $TABLE..."

    docker exec -i "$PG_CONTAINER" \
        psql -U "$DB_USER" -d "$DB_NAME" -v ON_ERROR_STOP=1 \
        -c "COPY (
                SELECT *
                FROM public.\"$TABLE\"
                WHERE \"companyId\" = $COMPANY_ID
             )
             TO STDOUT
             WITH (FORMAT CSV, HEADER TRUE, FORCE_QUOTE *);" \
        > "$OUTPUT_FILE"

    ROW_COUNT=$(( $(wc -l < "$OUTPUT_FILE") - 1 ))

    echo "  Arquivo: $OUTPUT_FILE"
    echo "  Registros: $ROW_COUNT"
done

echo
echo "Compactando arquivos..."

tar -czf "$ARCHIVE_FILE" \
    -C "$DEST_DIR" \
    "$EXPORT_NAME"

# Remove a pasta temporária
rm -rf "$EXPORT_DIR"

echo
echo "Exportação concluída com sucesso."
echo "Arquivo gerado:"
ls -lh "$ARCHIVE_FILE"
