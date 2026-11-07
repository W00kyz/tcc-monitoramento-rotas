#!/usr/bin/env bash
# Processa o recorte do campus no grafo de roteirização do OSRM.
#
# Perfil `foot`: o profissional de campo se desloca a pé entre pontos do campus.
# Trocar por `car` invalidaria os tempos estimados de RF12 e RF14.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="$(dirname "$SCRIPT_DIR")/data"

OSRM_IMAGE="ghcr.io/project-osrm/osrm-backend@sha256:729461bcc9ae9e6aafa92c0f93db9b060a32e85d5e72092c01ae4a4a9f1eb564"

if [[ ! -f "$DATA_DIR/campus.osm.pbf" ]]; then
  echo "ERRO: $DATA_DIR/campus.osm.pbf não existe. Rodar fetch-osm.sh primeiro." >&2
  exit 1
fi

run_osrm() {
  docker run --rm -v "$DATA_DIR:/data" "$OSRM_IMAGE" "$@"
}

echo "==> osrm-extract (perfil foot)"
run_osrm osrm-extract -p /opt/foot.lua /data/campus.osm.pbf

echo "==> osrm-partition"
run_osrm osrm-partition /data/campus.osrm

echo "==> osrm-customize"
run_osrm osrm-customize /data/campus.osrm

echo "==> Pronto. Arquivos gerados:"
ls -lh "$DATA_DIR"/campus.osrm*
