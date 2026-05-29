#!/usr/bin/env python3
"""
Generates `BrainrotLab_Verify.luau` — a post-install validation script that
the user pastes into Studio's Command Bar after running the main installer.
It walks the DataModel hierarchy that the installer should have created
and prints PASS/FAIL for each expected piece. Catches:

  * paste truncation (e.g. browser dropped the last 50 KB of the installer)
  * Studio reverted state (running the installer while playtesting)
  * missing services from a partial install retry

Run:  python3 tools/build_verifier.py
Out:  BrainrotLab_Verify.luau
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def list_files(src_dir: Path):
    out = []
    for path in sorted(src_dir.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(src_dir).as_posix()
        if rel.endswith(".server.luau"):
            cls, clean = "Script", rel[: -len(".server.luau")]
        elif rel.endswith(".client.luau"):
            cls, clean = "LocalScript", rel[: -len(".client.luau")]
        elif rel.endswith(".luau"):
            cls, clean = "ModuleScript", rel[: -len(".luau")]
        elif rel.endswith(".lua"):
            cls, clean = "ModuleScript", rel[: -len(".lua")]
        else:
            continue
        if clean.endswith("/init"):
            clean = clean[: -len("/init")]
        elif clean == "init":
            clean = ""
        out.append((clean, cls))
    return out


DOMAINS = [
    ("ReplicatedStorage", "Shared", "src/shared"),
    ("ReplicatedStorage", "Assets", "src/assets"),
    ("ServerScriptService", "Server", "src/server"),
    ("StarterPlayer.StarterPlayerScripts", "Client", "src/client"),
]


def main() -> int:
    expected = []
    for container, folder, subdir in DOMAINS:
        src = ROOT / subdir
        if not src.exists():
            continue
        for clean, cls in list_files(src):
            expected.append((container, folder, clean, cls))

    lines: list[str] = []
    add = lines.append

    add("--!strict")
    add("-- BrainrotLab post-install verifier — auto-generated.")
    add("-- Paste into Studio Command Bar AFTER running BrainrotLab_Installer.luau.")
    add("-- Prints PASS/FAIL for every expected Folder, Script, ModuleScript,")
    add("-- LocalScript. Returns the number of failures to the command bar.")
    add("")
    add("local function resolveContainer(path)")
    add("\tlocal cur = game")
    add("\tfor part in string.gmatch(path, \"[^%.]+\") do")
    add("\t\tlocal nxt = cur:FindFirstChild(part)")
    add("\t\tif not nxt and cur == game then")
    add("\t\t\tlocal ok, svc = pcall(function() return game:GetService(part) end)")
    add("\t\t\tif ok then nxt = svc end")
    add("\t\tend")
    add("\t\tif not nxt then return nil end")
    add("\t\tcur = nxt")
    add("\tend")
    add("\treturn cur")
    add("end")
    add("")
    add("local function resolveChild(root, path)")
    add("\tif path == \"\" then return root end")
    add("\tlocal cur = root")
    add("\tfor seg in string.gmatch(path, \"[^/]+\") do")
    add("\t\tcur = cur and cur:FindFirstChild(seg)")
    add("\t\tif not cur then return nil end")
    add("\tend")
    add("\treturn cur")
    add("end")
    add("")
    add("local fails = 0")
    add("local total = 0")
    add("local function check(label, ok)")
    add("\ttotal = total + 1")
    add("\tif ok then")
    add("\t\tprint(string.format(\"  PASS  %s\", label))")
    add("\telse")
    add("\t\tfails = fails + 1")
    add("\t\twarn(string.format(\"  FAIL  %s\", label))")
    add("\tend")
    add("end")
    add("")
    add("print(\"[BrainrotLab Verifier] starting…\")")

    # Domain root checks
    for container, folder, _, _ in expected[:1]:
        pass  # handled below

    seen_roots: set[tuple[str, str]] = set()
    for container, folder, clean, cls in expected:
        key = (container, folder)
        if key not in seen_roots:
            seen_roots.add(key)
            add(f"do")
            add(f"\tlocal container = resolveContainer({quote(container)})")
            add(f"\tcheck({quote(container)}, container ~= nil)")
            add(f"\tlocal root = container and container:FindFirstChild({quote(folder)})")
            add(f"\tcheck({quote(container + '/' + folder)}, root ~= nil)")
            add(f"end")

    add("")
    # Per-script checks
    for container, folder, clean, cls in expected:
        add("do")
        add(f"\tlocal container = resolveContainer({quote(container)})")
        add(f"\tlocal root = container and container:FindFirstChild({quote(folder)})")
        if clean == "":
            label = f"{container}/{folder} :: {cls}"
            add(f"\tcheck({quote(label)}, root and root.ClassName == {quote(cls)} or false)")
        else:
            label = f"{container}/{folder}/{clean} :: {cls}"
            add(f"\tlocal inst = root and resolveChild(root, {quote(clean)})")
            add(f"\tcheck({quote(label)}, inst and inst.ClassName == {quote(cls)} or false)")
        add("end")

    # Remote registry presence
    add("")
    add("do  -- Remotes folder presence")
    add("\tlocal rs = game:GetService('ReplicatedStorage')")
    add("\tcheck('ReplicatedStorage/Remotes', rs:FindFirstChild('Remotes') ~= nil)")
    add("end")

    add("")
    add("print(string.format(\"[BrainrotLab Verifier] %d / %d checks passed (%d failures)\", total - fails, total, fails))")
    add("if fails > 0 then warn(\"Re-run BrainrotLab_Installer.luau to repair.\") end")

    out_path = ROOT / "BrainrotLab_Verify.luau"
    out_text = "\n".join(lines) + "\n"
    out_path.write_text(out_text, encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)} ({len(out_text):,} bytes, {len(expected)} script checks)")
    return 0


def quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


if __name__ == "__main__":
    sys.exit(main())
