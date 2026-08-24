#!/usr/bin/env bash
# Baixa o extrato do OpenStreetMap e verifica a integridade contra o md5 publicado.
#
# O arquivo não é versionado (centenas de MB). O checksum registrado em
# infra/osm/ é o que trava o insumo: sem ele, "as versões estão travadas" seria
# falso para o único dado externo do projeto.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$INFRA_DIR/data"

# shellcheck source=../osm/bbox.env
source "$INFRA_DIR/osm/bbox.env"

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

echo "==> Recortando o campus com osmium"
docker run --rm -v "$DATA_DIR:/data" \
  stefda/osmium-tool@sha256:d2321d0e926f77ead7547b4b35f5cf98d9fd74043673cecc4fc2bb7cce06ff63 \
  osmium extract --bbox "$CAMPUS_BBOX" --overwrite \
  -o /data/campus.osm.pbf "/data/$OSM_SOURCE_FILE"

echo "==> Pronto: $DATA_DIR/campus.osm.pbf"
ls -lh "$DATA_DIR/campus.osm.pbf"
