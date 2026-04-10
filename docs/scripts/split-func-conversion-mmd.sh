#!/usr/bin/env bash
# Generate sync-only and async-only .mmd files from the full conversion rules diagram.
# Usage: split-func-conversion-mmd.sh <full.mmd> <output-dir>
set -euo pipefail

FULL="$1"
OUTDIR="$2"

mkdir -p "$OUTDIR"

# Extract the Sync subgraph title from the source
SYNC_TITLE=$(sed -n 's/^        subgraph Sync\["\(.*\)"\]/\1/p' "$FULL")

# --- Sync-only ---
cat > "$OUTDIR/func-conversion-sync.mmd" <<HEADER
%%{init: {"flowchart": {"defaultRenderer": "elk"}} }%%
flowchart BT
    subgraph Isolation["${SYNC_TITLE}"]
        direction BT

HEADER

# Extract Sync subgraph inner content (strip the subgraph/end wrapper)
sed -n '/^        subgraph Sync\[/,/^        end$/p' "$FULL" \
  | sed '1d;$d' >> "$OUTDIR/func-conversion-sync.mmd"

# Extract sync edges
sed -n '/^        %% @isolated(any) deprecated/,/^$/p' "$FULL" \
  >> "$OUTDIR/func-conversion-sync.mmd"
sed -n '/^        %% Core sync relationships/,/^$/p' "$FULL" \
  >> "$OUTDIR/func-conversion-sync.mmd"
sed -n '/^        %% isolated LocalActor branch/,/^$/p' "$FULL" \
  >> "$OUTDIR/func-conversion-sync.mmd"

cat >> "$OUTDIR/func-conversion-sync.mmd" <<'FOOTER'
    end

    style SendableSync stroke-dasharray: 5 5
FOOTER

# Extract the Async subgraph title from the source
ASYNC_TITLE=$(sed -n 's/^        subgraph Async\["\(.*\)"\]/\1/p' "$FULL")

# --- Async-only ---
cat > "$OUTDIR/func-conversion-async.mmd" <<HEADER
%%{init: {"flowchart": {"defaultRenderer": "elk"}} }%%
flowchart BT
    subgraph Isolation["${ASYNC_TITLE}"]
        direction BT

HEADER

# Extract Async subgraph inner content (strip the subgraph/end wrapper)
sed -n '/^        subgraph Async\[/,/^        end$/p' "$FULL" \
  | sed '1d;$d' >> "$OUTDIR/func-conversion-async.mmd"

# Extract async edges
# Stop before sync/async group-level section markers.
awk '
  /^        %% Non-Sendable async$/ { in_async = 1; print; next }
  /^        %% Cross:/ && in_async { in_async = 0; exit }
  /^        %% Group-level sync-to-async conversion$/ && in_async { in_async = 0; exit }
  in_async { print }
' "$FULL" >> "$OUTDIR/func-conversion-async.mmd"

cat >> "$OUTDIR/func-conversion-async.mmd" <<'FOOTER'
    end

    %% Async bidirectional edges color (N2↔C2, C2↔IA2, S2↔M2/CS2/IAS2)
    linkStyle 0,1,2,3,4 stroke:red,stroke-width:3px;

    style NonSendableAsync stroke-dasharray: 5 5
    style SendableAsync stroke-dasharray: 5 5
FOOTER
