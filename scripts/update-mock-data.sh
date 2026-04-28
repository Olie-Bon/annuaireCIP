#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOURCES_DIR="$SCRIPT_DIR/../AnnuaireCIP/Resources"

BASE_URL="https://api.data.inclusion.beta.gouv.fr/api/v1"
DEPT="13"
SIZE="50"

if [ -z "${DI_API_TOKEN:-}" ]; then
  echo "Erreur : variable DI_API_TOKEN non définie." >&2
  exit 1
fi

echo "[1/4] Téléchargement des structures (département $DEPT, size=$SIZE)…"
curl -sf --progress-bar \
  -H "Authorization: Bearer $DI_API_TOKEN" \
  "$BASE_URL/structures?departement=$DEPT&size=$SIZE" \
  -o "$RESOURCES_DIR/structures-marseille-dev.json"

echo "[2/4] Comptage des structures…"
STRUCT_COUNT=$(python3 -c "import json,sys; d=json.load(open('$RESOURCES_DIR/structures-marseille-dev.json')); print(len(d.get('items', d)))")
echo "  ✓ $STRUCT_COUNT structures sauvegardées dans structures-marseille-dev.json"

echo "[3/4] Téléchargement des services (département $DEPT, size=$SIZE)…"
curl -sf --progress-bar \
  -H "Authorization: Bearer $DI_API_TOKEN" \
  "$BASE_URL/services?departement=$DEPT&size=$SIZE" \
  -o "$RESOURCES_DIR/services-marseille-dev.json"

echo "[4/4] Comptage des services…"
SVC_COUNT=$(python3 -c "import json,sys; d=json.load(open('$RESOURCES_DIR/services-marseille-dev.json')); print(len(d.get('items', d)))")
echo "  ✓ $SVC_COUNT services sauvegardés dans services-marseille-dev.json"

echo ""
echo "Mise à jour terminée : $STRUCT_COUNT structures, $SVC_COUNT services."
echo "Done"
