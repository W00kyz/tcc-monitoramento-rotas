#!/usr/bin/env bash
# Baixa o extrato do OpenStreetMap e verifica a integridade contra o md5 publicado.
#
# O arquivo não é versionado (centenas de MB). O checksum registrado em
# infra/osm/ é o que trava o insumo: sem ele, "as versões estão travadas" seria
# falso para o único dado externo do projeto.
#
# Parametrizável por variáveis de ambiente; sem nenhuma definida, o comportamento
# é o do campus (MAP_PREFIX=campus, MAP_DATA_DIR=infra/data, CAMPUS_BBOX em
# infra/osm/bbox.env). build-test-map.sh as define para o banco de testes.
#   MAP_PREFIX     prefixo do recorte gerado (<prefixo>.osm.pbf). Padrão: campus
#   MAP_DATA_DIR   diretório de dados. Padrão: infra/data
#   MAP_BBOX_FILE  arquivo .env com o retângulo. Padrão: infra/osm/bbox.env
#   MAP_BBOX_VAR   variável do retângulo nesse arquivo. Padrão: CAMPUS_BBOX
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
MAP_PREFIX="${MAP_PREFIX:-campus}"
DATA_DIR="${MAP_DATA_DIR:-$INFRA_DIR/data}"
MAP_BBOX_FILE="${MAP_BBOX_FILE:-$INFRA_DIR/osm/bbox.env}"
MAP_BBOX_VAR="${MAP_BBOX_VAR:-CAMPUS_BBOX}"

# O extrato de origem (OSM_SOURCE_*) vive sempre em bbox.env.
# shellcheck source=../osm/bbox.env
source "$INFRA_DIR/osm/bbox.env"
# shellcheck disable=SC1090
source "$MAP_BBOX_FILE"
BBOX="${!MAP_BBOX_VAR}"

mkdir -p "$DATA_DIR"
cd "$DATA_DIR"

echo "==> Baixando $OSM_SOURCE_FILE"
curl -fL --retry 3 --continue-at - -o "$OSM_SOURCE_FILE" "$OSM_SOURCE_URL"

echo "==> Baixando o checksum publicado"
curl -fL --retry 3 -o "${OSM_SOURCE_FILE}.md5" "${OSM_SOURCE_URL}.md5"

echo "==> Verificando integridade"
md5sum --check "${OSM_SOURCE_FILE}.md5"

RECORDED="$INFRA_DIR/osm/${OSM_SOURCE_FILE}.md5"
if [[ -f "$RECORDED" ]]; then
  if ! diff -q "$RECORDED" "${OSM_SOURCE_FILE}.md5" >/dev/null; then
    echo "AVISO: o extrato publicado mudou desde o checksum registrado." >&2
    echo "  registrado: $(cut -d' ' -f1 "$RECORDED")" >&2
    echo "  baixado:    $(cut -d' ' -f1 "${OSM_SOURCE_FILE}.md5")" >&2
    echo "  Regenerar OSRM e PMTiles, e atualizar o registro deliberadamente." >&2
  fi
else
  echo "==> Registrando o checksum como referência"
  cp "${OSM_SOURCE_FILE}.md5" "$RECORDED"
fi

echo "==> Recortando $MAP_PREFIX com osmium"
docker run --rm -v "$DATA_DIR:/data" \
  stefda/osmium-tool@sha256:d2321d0e926f77ead7547b4b35f5cf98d9fd74043673cecc4fc2bb7cce06ff63 \
  osmium extract --bbox "$BBOX" --overwrite \
  -o "/data/$MAP_PREFIX.osm.pbf" "/data/$OSM_SOURCE_FILE"

echo "==> Pronto: $DATA_DIR/$MAP_PREFIX.osm.pbf"
ls -lh "$DATA_DIR/$MAP_PREFIX.osm.pbf"
