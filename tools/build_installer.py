#!/usr/bin/env python3
"""
BrainrotLab installer generator.

Walks src/ and emits BrainrotLab_Installer.luau — a single Luau script that
the user pastes into Roblox Studio's Command Bar (View -> Command Bar).
Running the script constructs every Folder, Script, LocalScript, and
ModuleScript for the project into the correct services, fully replacing any
previous install. Idempotent and safe to re-run on each build.

Usage:  python3 tools/build_installer.py
Output: BrainrotLab_Installer.luau (single file, paste-and-run)
"""

from __future__ import annotations
import os
import sys
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

DOMAINS = [
    # (container_path, folder_under_container, src_subdir, optional)
    ("ReplicatedStorage",                       "Shared",  "src/shared", False),
    ("ReplicatedStorage",                       "Assets",  "src/assets", True ),
    ("ServerScriptService",                     "Server",  "src/server", False),
    ("StarterPlayer.StarterPlayerScripts",      "Client",  "src/client", False),
]

SUFFIX_MAP = {
    ".server.luau":  "Script",
    ".server.lua":   "Script",
    ".client.luau":  "LocalScript",
    ".client.lua":   "LocalScript",
    ".luau":         "ModuleScript",
    ".lua":          "ModuleScript",
}

def classify(rel_path: str):
    """Return (clean_path_without_extension, class_name) for a source file."""
    for suffix, cls in SUFFIX_MAP.items():
        if rel_path.endswith(suffix):
            return rel_path[: -len(suffix)], cls
    return None, None

def walk_sources(src_dir: Path):
    """Yield (relative_path, class_name, source_text) for every Luau script."""
    for path in sorted(src_dir.rglob("*")):
        if not path.is_file():
            continue
        rel = path.relative_to(src_dir).as_posix()
        clean, cls = classify(rel)
        if clean is None:
            continue
        # `init` files mount their source onto the parent folder/container.
        if clean.endswith("/init"):
            clean = clean[: -len("/init")]
        elif clean == "init":
            clean = ""
        source = path.read_text(encoding="utf-8")
        yield clean, cls, source

def safe_long_bracket(source: str) -> str:
    """Pick an `=` count for [[...]] that won't appear inside `source`."""
    n = 0
    while re.search(rf"\]{'=' * n}\]", source):
        n += 1
        if n > 99:
            raise ValueError("source has absurd long-bracket sequences")
    return "=" * n

def lua_literal(source: str) -> str:
    eq = safe_long_bracket(source)
    return f"[{eq}[\n{source}]{eq}]"

def lua_quote(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'

PREAMBLE = r"""--!strict
-- BrainrotLab installer — auto-generated. Do not edit by hand.
--
-- INSTALLATION
--   1. Open Roblox Studio. Any place (Baseplate, empty, etc.) works.
--   2. View tab -> Command Bar.
--   3. Paste this entire file and press Enter.
--   4. Wait for "[BrainrotLab Installer] Install complete." in Output.
--   5. File -> Save (or Publish to Roblox).
--
-- The installer is idempotent: re-running it overwrites any previous install
-- in this place. Safe to run while editing; do not run during Play Solo.

local function ensureFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then return existing end
	if existing then existing:Destroy() end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function resolveContainer(path)
	local cur = game
	for part in string.gmatch(path, "[^%.]+") do
		local nextInst = cur:FindFirstChild(part)
		if not nextInst then
			if cur == game then
				nextInst = game:GetService(part)
			else
				nextInst = Instance.new("Folder")
				nextInst.Name = part
				nextInst.Parent = cur
			end
		end
		cur = nextInst
	end
	return cur
end

local function ensureScript(parent, name, className, source)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		existing:Destroy()
		existing = nil
	end
	if not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = parent
	end
	existing.Source = source
	return existing
end

local function ensurePath(root, path, className, source)
	local segments = {}
	for seg in string.gmatch(path, "[^/]+") do table.insert(segments, seg) end
	local cur = root
	for i = 1, #segments - 1 do
		cur = ensureFolder(cur, segments[i])
	end
	ensureScript(cur, segments[#segments], className, source)
end

local function ensureRootScript(container, name, className, source)
	-- Mirrors Rojo's init.* convention: the named folder *is* the Script,
	-- so `require(script.X)` in init source resolves children correctly.
	local existing = container:FindFirstChild(name)
	if existing and existing.ClassName ~= className then
		-- preserve children if reinstalling with same kind of root
		local children = existing:GetChildren()
		local replacement = Instance.new(className)
		replacement.Name = name
		for _, c in ipairs(children) do c.Parent = replacement end
		existing:Destroy()
		existing = replacement
		existing.Parent = container
	elseif not existing then
		existing = Instance.new(className)
		existing.Name = name
		existing.Parent = container
	end
	existing.Source = source
	return existing
end

local function ensureBaseScene()
	-- Workspace baseplate
	local workspace = game:GetService("Workspace")
	if not workspace:FindFirstChild("Baseplate") then
		local base = Instance.new("Part")
		base.Name = "Baseplate"
		base.Anchored = true
		base.Size = Vector3.new(2048, 1, 2048)
		base.Position = Vector3.new(0, -1, 0)
		base.Color = Color3.fromRGB(50, 150, 75)
		base.Material = Enum.Material.Grass
		base.Parent = workspace
	end
	ensureFolder(workspace, "Plots")
	ensureFolder(workspace, "Brainrots")

	-- Lighting tweaks
	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	lighting.ClockTime = 14
	lighting.FogEnd = 1500

	-- HTTP for the optional WebhookService
	pcall(function() game:GetService("HttpService").HttpEnabled = true end)
end

print("[BrainrotLab Installer] Beginning install...")
ensureBaseScene()
"""

POSTAMBLE = r"""
print("[BrainrotLab Installer] Install complete. Save the place or press Play to test.")
"""

def main(out_path: Path = ROOT / "BrainrotLab_Installer.luau") -> None:
    parts: list[str] = [PREAMBLE]

    for container, folder, subdir, optional in DOMAINS:
        src_dir = ROOT / subdir
        if not src_dir.exists():
            if optional:
                continue
            print(f"missing required source dir: {src_dir}", file=sys.stderr)
            sys.exit(2)

        entries = list(walk_sources(src_dir))

        # If a domain has a root `init` script (clean_path == ""), the folder
        # itself becomes that Class (mirroring Rojo's init convention), so
        # `require(script.X)` continues to resolve siblings inside the root.
        root_init = next(((c, cls, src) for c, cls, src in entries if c == ""), None)
        siblings  = [e for e in entries if e[0] != ""]

        parts.append("")
        parts.append(f"do  -- {container}/{folder}")
        parts.append(f"\tlocal container = resolveContainer({lua_quote(container)})")
        if root_init is None:
            parts.append(f"\tlocal root = ensureFolder(container, {lua_quote(folder)})")
        else:
            _, root_cls, root_src = root_init
            parts.append(
                f"\tlocal root = ensureRootScript(container, {lua_quote(folder)}, "
                f"{lua_quote(root_cls)}, {lua_literal(root_src)})"
            )

        for clean_path, class_name, source in siblings:
            literal = lua_literal(source)
            parts.append(
                f"\tensurePath(root, {lua_quote(clean_path)}, {lua_quote(class_name)}, {literal})"
            )
        parts.append("end")

    parts.append(POSTAMBLE)
    out_text = "\n".join(parts)
    out_path.write_text(out_text, encoding="utf-8")
    print(f"Wrote {out_path.relative_to(ROOT)} ({len(out_text):,} bytes)")

if __name__ == "__main__":
    main()
