#!/usr/bin/env bash
# Gate de cobertura (Actividad 3, PR-01). Falla si la cobertura de líneas de
# coverage/lcov.info baja del mínimo.
#
#   flutter test --coverage && bash tool/coverage_gate.sh 55
#
# El mínimo sube por hito (55 -> 60 -> 70).
set -euo pipefail

MIN="${1:-${COVERAGE_MIN:-55}}"
LCOV="${2:-coverage/lcov.info}"

if [ ! -s "$LCOV" ]; then
  echo "::error::No existe $LCOV. Corre flutter test --coverage antes del gate."
  exit 1
fi

read -r HIT FOUND < <(awk -F: '/^LH:/{h+=$2} /^LF:/{f+=$2} END{print h+0, f+0}' "$LCOV")
if [ "$FOUND" -eq 0 ]; then
  echo "::error::$LCOV no tiene líneas medidas."
  exit 1
fi

PCT=$(awk -v h="$HIT" -v f="$FOUND" 'BEGIN{printf "%.2f", 100*h/f}')
LINEA="Cobertura de líneas: ${PCT} % (${HIT}/${FOUND}). Mínimo: ${MIN} %."
echo "$LINEA"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  echo "### $LINEA" >> "$GITHUB_STEP_SUMMARY"
fi

if awk -v p="$PCT" -v m="$MIN" 'BEGIN{exit !(p+0 < m+0)}'; then
  echo "::error::La cobertura (${PCT} %) bajó del mínimo (${MIN} %)."
  exit 1
fi
