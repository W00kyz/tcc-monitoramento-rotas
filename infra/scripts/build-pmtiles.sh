#!/usr/bin/env bash
# Gera o mapa vetorial offline do campus em PMTiles.
#
# AD-07: RNF21 exige o app funcionando em subsolos sem rede, e tile server online
# não sobrevive a isso. Um arquivo único, embarcado no app, sobrevive.
#
# Parametrizável por variáveis de ambiente; sem nenhuma definida, o comportamento
# é o do campus (MAP_PREFIX=campus, MAP_DATA_DIR=infra/data, CAMPUS_BBOX em
# infra/osm/bbox.env). build-test-map.sh as define para o banco de testes.
#   MAP_PREFIX       prefixo dos arquivos. Padrão: campus
#   MAP_DATA_DIR     diretório de dados. Padrão: infra/data
#   MAP_BBOX_FILE    arquivo .env com o retângulo. Padrão: infra/osm/bbox.env
#   MAP_BBOX_VAR     variável do retângulo nesse arquivo. Padrão: CAMPUS_BBOX
#   MAP_SOURCES_DIR  (opcional) diretório com as fontes auxiliares do planetiler
#                    já baixadas, montado em /data/sources para não baixar de novo
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
MAP_PREFIX="${MAP_PREFIX:-campus}"
DATA_DIR="${MAP_DATA_DIR:-$INFRA_DIR/data}"
MAP_BBOX_FILE="${MAP_BBOX_FILE:-$INFRA_DIR/osm/bbox.env}"
MAP_BBOX_VAR="${MAP_BBOX_VAR:-CAMPUS_BBOX}"

# shellcheck disable=SC1090
source "$MAP_BBOX_FILE"
BBOX="${!MAP_BBOX_VAR}"

PLANETILER_IMAGE="ghcr.io/onthegomap/planetiler@sha256:937244c33c543c3347c55cc3d088acc8ee14a0c5e76e1d0cf1502d4c84ddeb55"

if [[ ! -f "$DATA_DIR/$MAP_PREFIX.osm.pbf" ]]; then
  echo "ERRO: $DATA_DIR/$MAP_PREFIX.osm.pbf não existe. Rodar fetch-osm.sh primeiro." >&2
  exit 1
fi

MOUNTS=(-v "$DATA_DIR:/data")
if [[ -n "${MAP_SOURCES_DIR:-}" ]]; then
  MOUNTS+=(-v "$MAP_SOURCES_DIR:/data/sources")
fi

echo "==> Gerando $MAP_PREFIX.pmtiles"
docker run --rm "${MOUNTS[@]}" "$PLANETILER_IMAGE" \
  --osm-path="/data/$MAP_PREFIX.osm.pbf" \
  --output="/data/$MAP_PREFIX.pmtiles" \
  --bounds="$BBOX" \
  --minzoom=12 \
  --maxzoom=15 \
  --download-osm-tile-weights=false \
  --download \
  --force

echo "==> Pronto:"
ls -lh "$DATA_DIR/$MAP_PREFIX.pmtiles"
