#!/usr/bin/env bash
# check-spec.sh — mechanical wiring checks for a hedera-harness spec.
#
# Line-oriented only (grep/rg). No YAML/JSON parser. False positives/negatives
# are possible on unusually formatted files; treat findings as leads, not law.
#
# Usage: bash check-spec.sh <root> <slug>
#   Clone / run:  <root> = harness clone; expects specs/<slug>.yaml
#   Extend:       <root> = project root; expects .harness/spec.yaml with name: <slug>
# Exit 0 = clean. Non-zero = one finding printed per line on stderr/stdout.

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: check-spec.sh <root> <slug>" >&2
  exit 2
fi

ROOT="${1%/}"
SLUG="$2"
FINDINGS=0
LAYOUT=""

fail() {
  echo "FAIL: $*"
  FINDINGS=$((FINDINGS + 1))
}

warn_missing() {
  echo "FAIL: $*"
  FINDINGS=$((FINDINGS + 1))
}

SPEC_FILE=""
PRD=""
STATIC=""
COMMANDS=""
CONTRACT=""
PLAYWRIGHT=""

if [[ -f "$ROOT/specs/${SLUG}.yaml" ]]; then
  LAYOUT="run"
  SPEC_FILE="$ROOT/specs/${SLUG}.yaml"
elif [[ -f "$ROOT/.harness/spec.yaml" ]]; then
  LAYOUT="extend"
  SPEC_FILE="$ROOT/.harness/spec.yaml"
else
  fail "spec file missing: expected $ROOT/specs/${SLUG}.yaml or $ROOT/.harness/spec.yaml"
  exit 1
fi

# --- helpers -----------------------------------------------------------------

# First non-comment match for a YAML key's scalar value (best-effort).
yaml_scalar() {
  local file="$1" key="$2"
  # shellcheck disable=SC2016
  grep -E "^[[:space:]]*${key}:[[:space:]]*" "$file" 2>/dev/null \
    | grep -v '^[[:space:]]*#' \
    | head -1 \
    | sed -E "s/^[[:space:]]*${key}:[[:space:]]*//; s/[\"']//g; s/[[:space:]]+#.*//; s/[[:space:]]*$//"
}

# True if an uncommented line matching pattern exists.
has_active() {
  local file="$1" pattern="$2"
  grep -E "$pattern" "$file" 2>/dev/null | grep -v '^[[:space:]]*#' | grep -q .
}

# --- resolve paths from spec file -------------------------------------------

PRD_REL="$(yaml_scalar "$SPEC_FILE" "prd" || true)"
if [[ -n "$PRD_REL" ]]; then
  PRD="$ROOT/$PRD_REL"
fi

STATIC_REL="$(yaml_scalar "$SPEC_FILE" "static" || true)"
# validators.static is nested; also try after validators: block
if [[ -z "$STATIC_REL" ]] || { [[ "$STATIC_REL" != validators/* ]] && [[ "$STATIC_REL" != .harness/* ]]; }; then
  STATIC_REL="$(grep -E '^[[:space:]]*static:[[:space:]]*' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | head -1 | sed -E 's/^[[:space:]]*static:[[:space:]]*//; s/[\"'\'']//g; s/[[:space:]]*$//' || true)"
fi
if [[ -n "$STATIC_REL" ]]; then
  STATIC="$ROOT/$STATIC_REL"
fi

COMMANDS_REL="$(grep -E '^[[:space:]]*commands:[[:space:]]*(validators/|\.harness/)' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | head -1 | sed -E 's/^[[:space:]]*commands:[[:space:]]*//; s/[\"'\'']//g; s/[[:space:]]*$//' || true)"
if [[ -n "$COMMANDS_REL" ]]; then
  COMMANDS="$ROOT/$COMMANDS_REL"
fi

CONTRACT_REL="$(yaml_scalar "$SPEC_FILE" "contract" || true)"
if [[ -n "$CONTRACT_REL" ]] && { [[ "$CONTRACT_REL" == contracts/* ]] || [[ "$CONTRACT_REL" == .harness/* ]]; }; then
  CONTRACT="$ROOT/$CONTRACT_REL"
fi

PLAY_REL="$(grep -E '^[[:space:]]*playwright:[[:space:]]*' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | head -1 | sed -E 's/^[[:space:]]*playwright:[[:space:]]*//; s/[\"'\'']//g; s/[[:space:]]*$//' || true)"
if [[ -n "$PLAY_REL" ]]; then
  PLAYWRIGHT="$ROOT/$PLAY_REL"
fi

# --- slug agreement ----------------------------------------------------------

SPEC_NAME="$(yaml_scalar "$SPEC_FILE" "name" || true)"
if [[ "$SPEC_NAME" != "$SLUG" ]]; then
  fail "spec file name='$SPEC_NAME' does not match slug='$SLUG'"
fi

TM_NAME="$(grep -A5 '^templateMetadata:' "$SPEC_FILE" | grep -E '^[[:space:]]*name:' | head -1 | sed -E 's/^[[:space:]]*name:[[:space:]]*//; s/[\"'\'']//g; s/[[:space:]]*$//' || true)"

if [[ "$LAYOUT" == "run" ]]; then
  if [[ -n "$TM_NAME" ]] && [[ "$TM_NAME" != "$SLUG" ]]; then
    fail "templateMetadata.name='$TM_NAME' does not match slug='$SLUG'"
  fi

  if [[ -n "$PRD_REL" ]] && [[ "$PRD_REL" != *"$SLUG"* ]]; then
    fail "prd path '$PRD_REL' does not contain slug='$SLUG'"
  fi

  if [[ -n "$STATIC" ]] && [[ -f "$STATIC" ]]; then
    if ! grep -E "\"equals\"[[:space:]]*:[[:space:]]*\"${SLUG}\"" "$STATIC" >/dev/null; then
      fail "static validator missing template.json name equals '$SLUG'"
    fi
  elif [[ -n "$STATIC_REL" ]]; then
    warn_missing "static validator missing: $STATIC"
  fi

  if [[ -n "$CONTRACT" ]] && [[ -f "$CONTRACT" ]]; then
    if ! grep -E "\"template\"[[:space:]]*:[[:space:]]*\"${SLUG}\"" "$CONTRACT" >/dev/null; then
      fail "oracle template field does not equal slug='$SLUG'"
    fi
  fi
else
  # Extend: templateMetadata.name is host identity; may differ from extension slug.
  # Static / oracle often omit template.json name equals — skip those checks.
  if [[ -n "$STATIC_REL" ]] && [[ ! -f "$STATIC" ]]; then
    warn_missing "static validator missing: $STATIC"
  fi
  if [[ -n "$CONTRACT_REL" ]] && [[ ! -f "$CONTRACT" ]]; then
    warn_missing "oracle missing: $CONTRACT"
  fi
fi

# --- REPLACE_ME --------------------------------------------------------------

FILES_TO_SCAN=("$SPEC_FILE")
[[ -n "$PRD" && -f "$PRD" ]] && FILES_TO_SCAN+=("$PRD")
[[ -n "$STATIC" && -f "$STATIC" ]] && FILES_TO_SCAN+=("$STATIC")
[[ -n "$COMMANDS" && -f "$COMMANDS" ]] && FILES_TO_SCAN+=("$COMMANDS")
[[ -n "$CONTRACT" && -f "$CONTRACT" ]] && FILES_TO_SCAN+=("$CONTRACT")
[[ -n "$PLAYWRIGHT" && -f "$PLAYWRIGHT" ]] && FILES_TO_SCAN+=("$PLAYWRIGHT")

if grep -R --line-number "REPLACE_ME" "${FILES_TO_SCAN[@]}" >/dev/null 2>&1; then
  while IFS= read -r line; do
    fail "REPLACE_ME leftover: $line"
  done < <(grep -R --line-number "REPLACE_ME" "${FILES_TO_SCAN[@]}" 2>/dev/null || true)
fi

# --- install command name ----------------------------------------------------

if [[ -n "$COMMANDS" ]] && [[ -f "$COMMANDS" ]]; then
  if ! grep -E '"name"[[:space:]]*:[[:space:]]*"install"' "$COMMANDS" >/dev/null; then
    fail "command validator missing a command literally named \"install\""
  fi
elif [[ -n "$COMMANDS_REL" ]]; then
  warn_missing "command validator missing: $COMMANDS"
else
  fail "could not resolve validators.commands path from spec file"
fi

# --- extend.baseline (extend layout only) ------------------------------------

if [[ "$LAYOUT" == "extend" ]]; then
  if ! has_active "$SPEC_FILE" '^[[:space:]]*extend:'; then
    fail "extend layout requires an extend: block"
  elif ! grep -A20 -E '^[[:space:]]*extend:' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | grep -E '^[[:space:]]*baseline:' >/dev/null; then
    fail "extend layout requires extend.baseline"
  elif ! grep -A40 -E '^[[:space:]]*baseline:' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | grep -E '^[[:space:]]*-?[[:space:]]*name:[[:space:]]*install[[:space:]]*$' >/dev/null; then
    fail "extend.baseline missing a command literally named \"install\""
  fi
fi

# --- Tier 3 pairing: contract + validator.enabled ----------------------------

HAS_CONTRACT=false
HAS_VALIDATOR_ENABLED=false

if has_active "$SPEC_FILE" '^[[:space:]]*contract:[[:space:]]*'; then
  HAS_CONTRACT=true
fi

# Look for enabled: true under a validator: block (best-effort: any active enabled: true
# near validator — also accept top-level under validator stanza).
if grep -E '^[[:space:]]*validator:[[:space:]]*$' "$SPEC_FILE" | grep -v '^[[:space:]]*#' | grep -q .; then
  # Grab a window after the first active validator: key
  if awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*validator:[[:space:]]*$/ { in_v=1; next }
    in_v && /^[^[:space:]#]/ { exit }
    in_v && /^[[:space:]]*enabled:[[:space:]]*true/ { found=1; exit }
    END { exit found ? 0 : 1 }
  ' "$SPEC_FILE"; then
    HAS_VALIDATOR_ENABLED=true
  fi
fi

if $HAS_CONTRACT && ! $HAS_VALIDATOR_ENABLED; then
  fail "gate 3 incomplete: contract present but validator.enabled is not true"
fi
if $HAS_VALIDATOR_ENABLED && ! $HAS_CONTRACT; then
  fail "gate 3 incomplete: validator.enabled true but contract missing"
fi

# --- chainValidation.network -------------------------------------------------

if has_active "$SPEC_FILE" '^[[:space:]]*chainValidation:'; then
  NETWORK="$(awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*chainValidation:/ { in_c=1; next }
    in_c && /^[^[:space:]#]/ { exit }
    in_c && /^[[:space:]]*network:/ {
      sub(/^[[:space:]]*network:[[:space:]]*/, "")
      gsub(/["'\'']/, "")
      print
      exit
    }
  ' "$SPEC_FILE" || true)"
  if [[ -n "$NETWORK" ]] && [[ "$NETWORK" != "testnet" ]]; then
    fail "chainValidation.network='$NETWORK' (must be testnet)"
  fi
  if [[ -z "$NETWORK" ]]; then
    fail "chainValidation present but network field not found"
  fi
fi

# --- executableWithTestSigner requires chainValidation -----------------------

HAS_EXEC=false
if [[ -n "$CONTRACT" ]] && [[ -f "$CONTRACT" ]]; then
  if grep -E '"executableWithTestSigner"[[:space:]]*:[[:space:]]*true' "$CONTRACT" >/dev/null; then
    HAS_EXEC=true
  fi
fi

HAS_CHAIN=false
if has_active "$SPEC_FILE" '^[[:space:]]*chainValidation:'; then
  if awk '
    /^[[:space:]]*#/ { next }
    /^[[:space:]]*chainValidation:/ { in_c=1; next }
    in_c && /^[^[:space:]#]/ { exit }
    in_c && /^[[:space:]]*enabled:[[:space:]]*true/ { found=1; exit }
    END { exit found ? 0 : 1 }
  ' "$SPEC_FILE"; then
    HAS_CHAIN=true
  fi
fi

if $HAS_EXEC && ! $HAS_CHAIN; then
  fail "executableWithTestSigner=true in oracle but chainValidation.enabled is not true"
fi

# --- blind check on PRD ------------------------------------------------------

if [[ -n "$PRD" ]] && [[ -f "$PRD" ]]; then
  if grep -E '\bC[0-9]+\b' "$PRD" >/dev/null; then
    fail "blind: PRD contains assertion id (C1, C2, …)"
  fi
  if grep -E 'howToVerify' "$PRD" >/dev/null; then
    fail "blind: PRD contains howToVerify"
  fi
  if grep -Ei 'severity[[:space:]]*:[[:space:]]*(critical|major|minor)' "$PRD" >/dev/null; then
    fail "blind: PRD contains severity label"
  fi
elif [[ -n "$PRD_REL" ]]; then
  warn_missing "prd missing on disk: $PRD"
fi

# --- summary -----------------------------------------------------------------

if [[ "$FINDINGS" -gt 0 ]]; then
  echo "check-spec: $FINDINGS finding(s) (layout=$LAYOUT)"
  exit 1
fi

echo "check-spec: OK (layout=$LAYOUT)"
exit 0
