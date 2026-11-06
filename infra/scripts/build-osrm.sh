#!/usr/bin/env bash
# Processa o recorte do campus no grafo de roteirização do OSRM.
#
# Perfil `foot`: o profissional de campo se desloca a pé entre pontos do campus.
# Trocar por `car` invalidaria os tempos estimados de RF12 e RF14.
#
# Parametrizável por variáveis de ambiente; sem nenhuma definida, o comportamento
# é o do campus (MAP_PREFIX=campus, MAP_DATA_DIR=infra/data, CAMPUS_BBOX em
# infra/osm/bbox.env). build-test-map.sh as define para o banco de testes.
#   MAP_PREFIX     prefixo dos arquivos. Padrão: campus
#   MAP_DATA_DIR   diretório de dados. Padrão: infra/data
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP_PREFIX="${MAP_PREFIX:-campus}"
DATA_DIR="${MAP_DATA_DIR:-$(dirname "$SCRIPT_DIR")/data}"

OSRM_IMAGE="ghcr.io/project-osrm/osrm-backend@sha256:729461bcc9ae9e6aafa92c0f93db9b060a32e85d5e72092c01ae4a4a9f1eb564"

if [[ ! -f "$DATA_DIR/$MAP_PREFIX.osm.pbf" ]]; then
  echo "ERRO: $DATA_DIR/$MAP_PREFIX.osm.pbf não existe. Rodar fetch-osm.sh primeiro." >&2
  exit 1
fi

run_osrm() {
  docker run --rm -v "$DATA_DIR:/data" "$OSRM_IMAGE" "$@"
}

echo "==> osrm-extract (perfil foot)"
run_osrm osrm-extract -p /opt/foot.lua "/data/$MAP_PREFIX.osm.pbf"

echo "==> osrm-partition"
run_osrm osrm-partition "/data/$MAP_PREFIX.osrm"

echo "==> osrm-customize"
run_osrm osrm-customize "/data/$MAP_PREFIX.osrm"

echo "==> Pronto. Arquivos gerados:"
ls -lh "$DATA_DIR/$MAP_PREFIX".osrm*
