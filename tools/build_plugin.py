#!/usr/bin/env python3
"""
Generates `BrainrotLab_Plugin.rbxmx` — a Roblox Studio Plugin model file.

The plugin contains a single Script whose source is the entire
BrainrotLab_Installer.luau wrapped in a CreateToolbar / CreateButton
shell. The user drops the .rbxmx into their Studio plugins folder
(Windows: %LOCALAPPDATA%/Roblox/Plugins/, Mac:
~/Documents/Roblox/Plugins/), restarts Studio, and a "Brainrot Lab"
button appears in the toolbar. One click installs / updates the game
in the currently-open place.

Run after build_installer.py so the latest source is embedded:
    python3 tools/build_installer.py
    python3 tools/build_plugin.py
"""
from __future__ import annotations
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
INSTALLER = ROOT / "BrainrotLab_Installer.luau"
OUTPUT = ROOT / "BrainrotLab_Plugin.rbxmx"


def main() -> int:
    if not INSTALLER.exists():
        print(f"missing {INSTALLER} — run tools/build_installer.py first", file=sys.stderr)
        return 2

    installer_src = INSTALLER.read_text(encoding="utf-8")

    # Strip the installer's preamble comment block; we'll prepend our own.
    # Anything that wraps the existing installer in a plugin toolbar button.
    plugin_src = '''--!strict
-- BrainrotLab Studio Plugin
-- Click the toolbar button to install or update the game in this place.

local toolbar = plugin:CreateToolbar("Brainrot Lab")
local button = toolbar:CreateButton(
    "Install / Update",
    "Install or update Brainrot Lab into this place",
    "rbxasset://textures/AnimationEditor/icon_export.png"
)

local function install()
    button:SetActive(true)
    local ok, err = pcall(function()
__INSTALLER_BODY__
    end)
    button:SetActive(false)
    if not ok then
        warn("[BrainrotLab Plugin] install failed: " .. tostring(err))
    else
        print("[BrainrotLab Plugin] install / update complete. Save the place.")
    end
end

button.Click:Connect(install)
print("[BrainrotLab Plugin] loaded. Click the Brainrot Lab toolbar button to install.")
'''.replace("__INSTALLER_BODY__", installer_src)

    # Defensively split any `]]>` sequence so it can't terminate the CDATA
    # block. Currently zero occurrences in the source, but a future edit
    # could introduce one.
    if "]]>" in plugin_src:
        plugin_src = plugin_src.replace("]]>", "]]]]><![CDATA[>")

    # Wrap in a Roblox XML model file. The single child is a Script whose
    # Source property holds the plugin code. Studio loads any Script at the
    # root of a plugin .rbxmx as a plugin on startup.
    xml = f"""<roblox version="4">
\t<Item class="Script" referent="0">
\t\t<Properties>
\t\t\t<bool name="Disabled">false</bool>
\t\t\t<Content name="LinkedSource"><null></null></Content>
\t\t\t<string name="Name">BrainrotLab_Plugin</string>
\t\t\t<ProtectedString name="Source"><![CDATA[{plugin_src}]]></ProtectedString>
\t\t</Properties>
\t</Item>
</roblox>
"""

    OUTPUT.write_bytes(xml.encode("utf-8"))
    print(f"Wrote {OUTPUT.relative_to(ROOT)} ({len(xml):,} bytes)")
    print("Install path:")
    print("  Windows: %LOCALAPPDATA%\\Roblox\\Plugins\\BrainrotLab_Plugin.rbxmx")
    print("  Mac:     ~/Documents/Roblox/Plugins/BrainrotLab_Plugin.rbxmx")
    return 0


if __name__ == "__main__":
    sys.exit(main())
