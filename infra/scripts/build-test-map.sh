#!/usr/bin/env bash
# Gera o mapa e o grafo de roteirização do banco de testes manual (Tambor).
#
# O app desenha o mapa de um PMTiles embarcado e o "Iniciar rota" consulta o
# OSRM; o endereço de teste fica ~3,5 km ao sul do recorte do campus, então a
# pilha de teste precisa dos próprios dados. Reaproveita os scripts do campus
# com MAP_PREFIX=tambor e MAP_DATA_DIR=infra/data-test.
#
# Não baixa o extrato de novo: recorta direto de infra/data/nordeste-latest.osm.pbf
# (rodar fetch-osm.sh antes se ele não existir). As fontes auxiliares do
# planetiler (infra/data/sources) são montadas em vez de baixadas outra vez.
#
# Saída: infra/data-test/tambor.osm.pbf, tambor.osrm.* e tambor.pmtiles, e a
# cópia de tambor.pmtiles em mobile/assets/ (o commit é do repositório mobile).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
REPO_DIR="$(dirname "$INFRA_DIR")"
SOURCE_DIR="$INFRA_DIR/data"
TEST_DATA_DIR="$INFRA_DIR/data-test"
MOBILE_ASSETS="$REPO_DIR/mobile/assets"

# shellcheck source=../osm/bbox.env
source "$INFRA_DIR/osm/bbox.env"
# shellcheck source=../osm/test-bbox.env
source "$INFRA_DIR/osm/test-bbox.env"

# Mesma imagem (digest) usada em fetch-osm.sh.
OSMIUM_IMAGE="stefda/osmium-tool@sha256:d2321d0e926f77ead7547b4b35f5cf98d9fd74043673cecc4fc2bb7cce06ff63"

if [[ ! -f "$SOURCE_DIR/$OSM_SOURCE_FILE" ]]; then
  echo "ERRO: $SOURCE_DIR/$OSM_SOURCE_FILE não existe. Rodar fetch-osm.sh primeiro." >&2
  exit 1
fi

mkdir -p "$TEST_DATA_DIR"

echo "==> Recortando o endereço de teste com osmium ($TEST_BBOX)"
docker run --rm \
  -v "$SOURCE_DIR/$OSM_SOURCE_FILE:/source/$OSM_SOURCE_FILE:ro" \
  -v "$TEST_DATA_DIR:/data" \
  "$OSMIUM_IMAGE" \
  osmium extract --bbox "$TEST_BBOX" --overwrite \
  -o /data/tambor.osm.pbf "/source/$OSM_SOURCE_FILE"

export MAP_PREFIX=tambor
export MAP_DATA_DIR="$TEST_DATA_DIR"

bash "$SCRIPT_DIR/build-osrm.sh"

MAP_BBOX_FILE="$INFRA_DIR/osm/test-bbox.env" MAP_BBOX_VAR=TEST_BBOX \
  MAP_SOURCES_DIR="$SOURCE_DIR/sources" \
  bash "$SCRIPT_DIR/build-pmtiles.sh"

echo "==> Copiando tambor.pmtiles para $MOBILE_ASSETS"
mkdir -p "$MOBILE_ASSETS"
cp "$TEST_DATA_DIR/tambor.pmtiles" "$MOBILE_ASSETS/tambor.pmtiles"

echo "==> Pronto: $TEST_DATA_DIR"
ls -lh "$TEST_DATA_DIR"/tambor.osm.pbf "$TEST_DATA_DIR"/tambor.pmtiles
