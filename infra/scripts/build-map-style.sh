#!/usr/bin/env bash
# Copia o estilo MapLibre GL para os assets do app.
#
# AD-07 / RNF21: o mapa vetorial (campus.pmtiles) precisa renderizar sem rede.
# Um PMTiles sem estilo é só geometria: cores, ordem de camadas e rótulos vêm
# deste Style JSON.
#
# O estilo é editado à mão em infra/map/campus-style.json — diretório versionável
# (spec §8), fonte única da verdade. Este script só o copia para mobile/assets/;
# não o gera, para não silenciar edições manuais.
#
# INTENTIONAL: o estilo referencia um endpoint `glyphs` (herdado do template
# MapLibre) que nunca é buscado em tempo de execução — vector_map_tiles /
# vector_tile_renderer renderizam rótulos com o motor de texto do próprio
# Flutter (mobile/lib/routing/campus_map.dart), não com glifos PBF. Por isso
# este script não baixa nem embarca glifos (Ruling 14 / Etapa 4, confirmado
# inerte e removido na Etapa 5, Task 20) — a referência em si permanece no
# JSON, só não tem efeito.
#
# Parametrizável por variáveis de ambiente; sem nenhuma definida, o comportamento
# é o do campus (MAP_PREFIX=campus, MAP_DATA_DIR=infra/data, CAMPUS_BBOX em
# infra/osm/bbox.env). build-test-map.sh as define para o banco de testes.
#   MAP_PREFIX     prefixo do PMTiles copiado. Padrão: campus
#   MAP_DATA_DIR   diretório de dados. Padrão: infra/data
# O estilo copiado é sempre o mesmo (campus-style.json), seja qual for o prefixo.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
MAP_PREFIX="${MAP_PREFIX:-campus}"
DATA_DIR="${MAP_DATA_DIR:-$INFRA_DIR/data}"
MAP_DIR="$INFRA_DIR/map"
REPO_DIR="$(dirname "$INFRA_DIR")"
MOBILE_ASSETS="$REPO_DIR/mobile/assets"

AUTHORED_STYLE="$MAP_DIR/campus-style.json"

if [[ ! -f "$AUTHORED_STYLE" ]]; then
  echo "ERRO: $AUTHORED_STYLE não existe — é a fonte única do estilo, versionada." >&2
  exit 1
fi

mkdir -p "$DATA_DIR"

if [[ ! -f "$DATA_DIR/$MAP_PREFIX.pmtiles" ]]; then
  echo "ERRO: $DATA_DIR/$MAP_PREFIX.pmtiles não existe. Rodar build-pmtiles.sh primeiro." >&2
  exit 1
fi

echo "==> Copiando assets para $MOBILE_ASSETS"
mkdir -p "$MOBILE_ASSETS"
cp "$DATA_DIR/$MAP_PREFIX.pmtiles" "$MOBILE_ASSETS/$MAP_PREFIX.pmtiles"
cp "$AUTHORED_STYLE" "$MOBILE_ASSETS/campus-style.json"

echo "==> Pronto. Conteúdo de $MOBILE_ASSETS:"
find "$MOBILE_ASSETS" -type f | sort
