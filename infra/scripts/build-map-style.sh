#!/usr/bin/env bash
# Gera o estilo MapLibre GL e o conjunto de glifos que o app usa offline.
#
# AD-07 / RNF21: o mapa vetorial (campus.pmtiles) precisa renderizar sem rede.
# Um PMTiles sem estilo é só geometria: cores, ordem de camadas e rótulos vêm
# deste Style JSON. Os rótulos, por sua vez, exigem glifos (PBF SDF) embarcados,
# senão o MapLibre tenta buscá-los online e o texto some no subsolo.
#
# O estilo é editado à mão em infra/map/campus-style.json — diretório versionável
# (spec §8), fonte única da verdade. Este script só o copia para mobile/assets/;
# não o gera, para não silenciar edições manuais. Os glifos são o único insumo
# externo, então ficam travados: release + sha256 fixados abaixo, no mesmo
# espírito de fetch-osm.sh. Rode este script numa máquina com rede antes de
# compilar o app; o resultado embarcado é versionado em mobile/assets/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$INFRA_DIR/data"
MAP_DIR="$INFRA_DIR/map"
REPO_DIR="$(dirname "$INFRA_DIR")"
MOBILE_ASSETS="$REPO_DIR/mobile/assets"

# Glifos: openmaptiles/fonts, release v2.0 (Noto Sans, derivado do Noto do Google,
# SIL OFL 1.1). O asset noto-sans.zip traz Noto Sans Regular/Bold/Italic com
# todos os ranges Unicode; usamos só o Regular 0-255 (latino-1, cobre os
# acentos do pt-BR). O bloco 0x0400 (cirílico) é dispensado: nada no campus
# da UFCG usa cirílico e cada range extra são ~125 KB embarcados à toa.
FONTS_RELEASE="v2.0"
FONTS_ASSET="noto-sans.zip"
FONTS_URL="https://github.com/openmaptiles/fonts/releases/download/${FONTS_RELEASE}/${FONTS_ASSET}"
FONTS_SHA256="d117316544b43a5dde7ee761b36e17701e9f85574e181d76a74814240fdbaf34"
FONTSTACK="Noto Sans Regular"
GLYPH_RANGES=("0-255")

AUTHORED_STYLE="$MAP_DIR/campus-style.json"
GLYPHS_DIR="$DATA_DIR/glyphs"

if [[ ! -f "$AUTHORED_STYLE" ]]; then
  echo "ERRO: $AUTHORED_STYLE não existe — é a fonte única do estilo, versionada." >&2
  exit 1
fi

mkdir -p "$DATA_DIR"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Baixando glifos ($FONTS_RELEASE / $FONTS_ASSET)"
curl -fL --retry 3 -o "$TMP_DIR/$FONTS_ASSET" "$FONTS_URL"

echo "==> Verificando integridade (sha256)"
echo "${FONTS_SHA256}  ${TMP_DIR}/${FONTS_ASSET}" | sha256sum --check -

echo "==> Extraindo $FONTSTACK (${GLYPH_RANGES[*]})"
rm -rf "$GLYPHS_DIR"
mkdir -p "$GLYPHS_DIR"
for range in "${GLYPH_RANGES[@]}"; do
  unzip -o -j "$TMP_DIR/$FONTS_ASSET" "${FONTSTACK}/${range}.pbf" -d "$GLYPHS_DIR/$FONTSTACK"
done

if [[ ! -f "$DATA_DIR/campus.pmtiles" ]]; then
  echo "ERRO: $DATA_DIR/campus.pmtiles não existe. Rodar build-pmtiles.sh primeiro." >&2
  exit 1
fi

echo "==> Copiando assets para $MOBILE_ASSETS"
mkdir -p "$MOBILE_ASSETS"
rm -rf "$MOBILE_ASSETS/glyphs"
cp "$DATA_DIR/campus.pmtiles" "$MOBILE_ASSETS/campus.pmtiles"
cp "$AUTHORED_STYLE" "$MOBILE_ASSETS/campus-style.json"
cp -r "$GLYPHS_DIR" "$MOBILE_ASSETS/glyphs"

echo "==> Pronto. Conteúdo de $MOBILE_ASSETS:"
find "$MOBILE_ASSETS" -type f | sort
