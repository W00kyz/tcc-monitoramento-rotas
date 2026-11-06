#!/usr/bin/env bash
# Sobe o banco de testes manual: a mesma infra do dev-up.sh, mas num projeto do
# compose separado (route-monitor-test, com volumes próprios), com o mapa e o OSRM
# do Tambor (Rua Raimundo da Silva Ribeiro, Campina Grande), cinco edificações
# reais do OSM e o expediente aberto 24 h, todos os dias — dá para testar o app
# em qualquer horário, na rua do endereço. A stack real e os dados dela não são
# tocados.
#
# Uso: ./infra/scripts/dev-up-test.sh [--reset]
#   --reset  apaga o banco de testes (down -v do projeto de teste) antes de subir.
#
# Fica em primeiro plano, mostrando os logs. Ctrl+C derruba os containers e a
# rede de teste, mas mantém o volume: o banco de testes sobrevive até o próximo
# --reset.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$INFRA_DIR/docker-compose.yml"
COMPOSE_TEST_FILE="$INFRA_DIR/docker-compose.test.yml"
REAL_PROJECT="route-monitor"
TEST_PROJECT="route-monitor-test"

RESET=false
for arg in "$@"; do
  case "$arg" in
    --reset) RESET=true ;;
    *)
      echo "Uso: $0 [--reset]" >&2
      exit 2
      ;;
  esac
done

cd "$INFRA_DIR"

real_compose() { docker compose -p "$REAL_PROJECT" -f "$COMPOSE_FILE" "$@"; }
test_compose() {
  docker compose -p "$TEST_PROJECT" -f "$COMPOSE_FILE" -f "$COMPOSE_TEST_FILE" "$@"
}

# As duas stacks publicam as mesmas portas do host (5432, 8000, 5173, 5000...) e
# nunca devem rodar juntas. Recusa antes de mexer em qualquer coisa.
if [[ -n "$(real_compose ps -q)" ]]; then
  echo "ERRO: a stack real (projeto ${REAL_PROJECT}) está rodando." >&2
  echo "      O banco de testes usa as mesmas portas do host e não sobe junto com ela." >&2
  echo "      Encerrar o dev-up.sh (Ctrl+C) ou rodar 'docker compose -p ${REAL_PROJECT} down'" >&2
  echo "      (sem -v: os dados reais ficam) e tentar de novo." >&2
  exit 1
fi

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

# O mapa e o OSRM do Tambor vêm de infra/data-test/ (nunca versionado). Só o
# primeiro uso é lento: baixa o recorte do OSM e processa o OSRM.
if [[ ! -f data-test/tambor.osrm.mldgr || ! -f data-test/tambor.pmtiles ]]; then
  echo "==> Dados do Tambor não encontrados em infra/data-test/ — gerando (lento só na primeira vez)"
  "$SCRIPT_DIR/build-test-map.sh"
fi

# Ao contrário do dev-up.sh, o osrm sempre sobe: os dados de teste acabaram de
# ser garantidos acima e o seed de teste depende do roteamento.
SERVICES=(postgres minio mailpit osrm backend dashboard)

cleanup() {
  echo
  echo "==> Encerrando: docker compose down (projeto ${TEST_PROJECT}; o banco de testes fica)"
  test_compose down
}
# Só EXIT: o bash já dispara o trap de EXIT depois de qualquer saída por sinal
# (Ctrl+C incluído) — trapar INT/TERM também rodaria a limpeza duas vezes.
trap cleanup EXIT

if [[ "$RESET" == true ]]; then
  echo "==> --reset: apagando o banco de testes (down -v do projeto ${TEST_PROJECT})"
  test_compose down -v
fi

# --no-deps: sobe exatamente a lista acima, sem o depends_on puxar mais nada.
test_compose up --build --detach --wait --no-deps "${SERVICES[@]}"

echo "==> Seed de teste (idempotente: só reimprime os logins se o banco já tiver os dados)"
SEED_OUTPUT="$(test_compose exec -T backend uv run python -m app.seed_test)"
echo "$SEED_OUTPUT"

# IP da máquina na rede local, para o app num celular físico. Melhor esforço:
# se não der para descobrir, a linha do seed fica com o <ip-da-máquina> literal.
LAN_IP="$(ip route get 1.1.1.1 2>/dev/null | awk '{for (i = 1; i < NF; i++) if ($i == "src") {print $(i + 1); exit}}' || true)"
FLUTTER_LINE="$(grep '^flutter run ' <<<"$SEED_OUTPUT" || true)"
if [[ -n "$LAN_IP" && -n "$FLUTTER_LINE" ]]; then
  FLUTTER_LINE="${FLUTTER_LINE//<ip-da-máquina>/$LAN_IP}"
fi

cat <<'EOF'

==> Banco de testes pronto (projeto route-monitor-test).
    Local    Rua Raimundo da Silva Ribeiro, Tambor, Campina Grande
    Horário  expediente 24 h, todos os dias: dá para iniciar rota a qualquer hora
    Painel   http://localhost:5173   (admin@pu.ufcg.edu.br / trocar-esta-senha)
    API      http://localhost:8000/docs
    E-mails  http://localhost:8025   (Mailpit: convites e recuperação de senha)
    MinIO    http://localhost:9001
    Operador joao@empresa.com / trocar-esta-senha (use no app)
EOF
if [[ -n "$FLUTTER_LINE" ]]; then
  echo
  echo "    App (a partir de mobile/; em emulador Android use http://10.0.2.2:8000 como API_BASE_URL):"
  echo "    $FLUTTER_LINE"
fi
cat <<'EOF'

    Logs abaixo. Ctrl+C derruba os containers de teste e mantém o banco;
    use --reset para recriá-lo do zero.
EOF

test_compose logs --follow --tail 20 "${SERVICES[@]}"
