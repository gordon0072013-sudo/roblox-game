#!/usr/bin/env bash
# Audit script — run after every change.
#
# Verifies the four invariants we maintain:
#   1. Every service with .Init() is in init.server.luau's bootOrder.
#   2. Every used Remotes.Names.X is declared in src/shared/Remotes.luau.
#   3. No `local X = require(...)` is dead (only the declaration site uses X).
#   4. Every .luau file parses cleanly via luau-analyze (0 SyntaxErrors).
#
# Plus the build pipeline: Rojo build + installer regen + installer luac -p.
#
# Exits non-zero on any failure so CI / pre-push hooks can gate on it.

set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

LUAU_ANALYZE="${LUAU_ANALYZE:-/tmp/luau-analyze}"
ROJO="${ROJO:-$HOME/.cargo/bin/rojo}"

ok=1

# ---- (1)-(3) Service / Remote / Unused-require audits (Python). ----
python3 - <<'PY'
import re, os, sys, glob
remotes_path = 'src/shared/Remotes.luau'
remotes_text = open(remotes_path).read()
declared = set(re.findall(r'^\t([A-Za-z]\w*)\s*=\s*"', remotes_text, re.M))
used = set()
import subprocess
for tok in subprocess.check_output(['grep','-rohE',r'Remotes\.Names\.\w+','src/']).decode().split():
    used.add(tok.split('.')[-1])

server_files = sorted(glob.glob('src/server/*.luau'))
all_with_init = set(os.path.basename(f).replace('.luau','')
                    for f in server_files
                    if re.search(r'function\s+\w+\.Init\(', open(f).read()))
boot_text = open('src/server/init.server.luau').read()
booted = set(re.findall(r'\{ "\w+",\s*(\w+)\.Init', boot_text))

unused_requires = 0
for f in server_files + sorted(glob.glob('src/shared/*.luau')):
    text = open(f).read()
    for m in re.finditer(r'^local ([A-Za-z_][A-Za-z0-9_]*) *= *require', text, re.M):
        name = m.group(1)
        if len(re.findall(r'\b'+re.escape(name)+r'\b', text)) == 1:
            unused_requires += 1

orphans = sorted(all_with_init - booted)
missing = sorted(used - declared)

print(f'services: {len(all_with_init)} declared, {len(booted)} booted, orphans={orphans}')
print(f'remotes:  {len(used)} used, {len(declared)} declared, missing={missing}')
print(f'unused_requires: {unused_requires}')

bad = bool(orphans) or bool(missing) or unused_requires > 0
sys.exit(1 if bad else 0)
PY
[ $? -eq 0 ] || ok=0

# ---- (4) luau-analyze SyntaxError sweep. ----
if [ -x "$LUAU_ANALYZE" ]; then
    syn=0
    while IFS= read -r f; do
        n=$("$LUAU_ANALYZE" --no-strict-mode "$f" 2>&1 | grep -c "SyntaxError:" || true)
        if [ "$n" != "0" ]; then
            echo "  $f: $n SyntaxErrors"
            syn=$((syn + n))
        fi
    done < <(find src -name '*.luau')
    echo "luau-analyze: $syn SyntaxErrors across all .luau"
    [ "$syn" = "0" ] || ok=0
else
    echo "luau-analyze: skipped ($LUAU_ANALYZE not present — install from luau-lang/luau releases)"
fi

# ---- Build pipeline (Rojo + installer + verifier + plugin). ----
"$ROJO" build default.project.json --output BrainrotLab.rbxlx >/dev/null 2>&1 || { echo "rojo build failed"; ok=0; }
python3 tools/build_installer.py >/dev/null
python3 tools/build_verifier.py >/dev/null
python3 tools/build_plugin.py >/dev/null
luac -p BrainrotLab_Installer.luau || ok=0
luac -p BrainrotLab_Verify.luau || ok=0
echo "build: rbxlx + installer + verifier + plugin generated, luac -p valid"

if [ "$ok" = "1" ]; then
    echo "AUDIT OK"
else
    echo "AUDIT FAILED" >&2
    exit 1
fi
