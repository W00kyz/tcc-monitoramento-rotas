#!/usr/bin/env bash
# Sobe toda a infra local num único comando — Postgres/PostGIS, MinIO, Mailpit,
# OSRM (se os dados existirem), backend e dashboard — já com migrações aplicadas
# (o container do backend roda `alembic upgrade head` ao subir) e com os dados
# de exemplo do seed. O app mobile fica de fora de propósito: ele roda à parte
# (flutter run), não em container.
#
# Fica em primeiro plano, mostrando os logs. Ctrl+C derruba tudo (containers e
# rede) antes de sair — não deixa nada pendurado para a próxima subida.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$INFRA_DIR/docker-compose.yml"

cd "$INFRA_DIR"

if [[ ! -f .env ]]; then
  echo "==> .env não existe, copiando de .env.sample"
  cp .env.sample .env
fi

# Os placeholders do .env.sample não servem para rodar: a chave do QR precisa
# ser hex de 32 bytes (Ed25519) e o segredo do JWT não pode ser público.
# Gera valores aleatórios só onde ainda há placeholder — nunca sobrescreve.
replace_placeholder() {
  local key="$1" placeholder="$2" value="$3"
  if grep -q "^${key}=${placeholder}\$" .env; then
    sed -i.bak "s|^${key}=${placeholder}\$|${key}=${value}|" .env && rm -f .env.bak
    echo "==> ${key} gerado no .env"
  fi
}
replace_placeholder QR_SIGNING_PRIVATE_KEY_HEX change_me_generate_with_scripts "$(openssl rand -hex 32)"
replace_placeholder JWT_SECRET_KEY change_me_in_local_env "$(openssl rand -hex 32)"

SERVICES=(postgres minio mailpit backend dashboard)

# osrm depende de infra/data/, gerado por fetch-osm.sh + build-osrm.sh e nunca
# versionado — só entra na subida se já tiver sido processado.
if [[ -f data/campus.osrm.mldgr ]]; then
  SERVICES+=(osrm)
else
  echo "==> infra/data/campus.osrm.* não encontrado — subindo sem o serviço osrm."
  echo "    Rodar infra/scripts/fetch-osm.sh e depois build-osrm.sh para habilitá-lo."
  echo "    Sem ele as rotas são salvas sem ordem otimizada (RF12 degradado)."
fi

cleanup() {
  echo
  echo "==> Encerrando: docker compose down"
  docker compose -f "$COMPOSE_FILE" down
}
# Só EXIT: o bash já dispara o trap de EXIT depois de qualquer saída por sinal
# (Ctrl+C incluído) — trapar INT/TERM também rodaria a limpeza duas vezes.
trap cleanup EXIT

# --no-deps: sem ele, o depends_on do backend puxaria o osrm mesmo quando ele
# ficou de fora acima por falta de dados.
docker compose -f "$COMPOSE_FILE" up --build --detach --wait --no-deps "${SERVICES[@]}"

echo "==> Seed (idempotente: não faz nada se o banco já tiver os dados de exemplo)"
docker compose -f "$COMPOSE_FILE" exec -T backend uv run python -m app.seed

cat <<'EOF'

==> Pronto.
    Painel   http://localhost:5173   (admin@pu.ufcg.edu.br / trocar-esta-senha)
    API      http://localhost:8000/docs
    E-mails  http://localhost:8025   (Mailpit: convites e recuperação de senha)
    MinIO    http://localhost:9001

    Logs abaixo. Ctrl+C derruba tudo.
EOF

docker compose -f "$COMPOSE_FILE" logs --follow --tail 20 "${SERVICES[@]}"
