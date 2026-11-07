#!/usr/bin/env bash
# Gera o mapa vetorial offline do campus em PMTiles.
#
# AD-07: RNF21 exige o app funcionando em subsolos sem rede, e tile server online
# não sobrevive a isso. Um arquivo único, embarcado no app, sobrevive.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$INFRA_DIR/data"

# shellcheck source=../osm/bbox.env
source "$INFRA_DIR/osm/bbox.env"

PLANETILER_IMAGE="ghcr.io/onthegomap/planetiler@sha256:937244c33c543c3347c55cc3d088acc8ee14a0c5e76e1d0cf1502d4c84ddeb55"

if [[ ! -f "$DATA_DIR/campus.osm.pbf" ]]; then
  echo "ERRO: $DATA_DIR/campus.osm.pbf não existe. Rodar fetch-osm.sh primeiro." >&2
  exit 1
fi

echo "==> Gerando campus.pmtiles"
docker run --rm -v "$DATA_DIR:/data" "$PLANETILER_IMAGE" \
  --osm-path=/data/campus.osm.pbf \
  --output=/data/campus.pmtiles \
  --bounds="$CAMPUS_BBOX" \
  --minzoom=12 \
  --maxzoom=15 \
  --download-osm-tile-weights=false \
  --download \
  --force

echo "==> Pronto:"
ls -lh "$DATA_DIR/campus.pmtiles"
