#!/usr/bin/env python3
"""
Publish BrainrotLab.rbxlx to a Roblox place using the Open Cloud API.

This is the only sandbox-friendly way to ship the game without opening
Roblox Studio. The user provides a Universe ID, Place ID, and an Open
Cloud API key (created at https://create.roblox.com/dashboard/credentials
with the "Place Publishing" scope). The script POSTs the built .rbxlx
to Roblox's Save endpoint as a NEW version.

Usage:
    python3 tools/publish_opencloud.py \\
        --universe 1234567890 \\
        --place    9876543210 \\
        --api-key  YOUR_KEY \\
        --file     BrainrotLab.rbxlx \\
        [--publish]                  # also bump the live version

Without --publish the upload becomes a SAVE (versioned but not live).
With --publish it's the new live version Roblox players see on next join.

API docs: https://create.roblox.com/docs/cloud/reference/PlaceManagementApi

Runs anywhere with Python 3.8+ and the standard library (no pip needed).
On mobile: install Termux (Android) or Pythonista (iOS) → git clone the
repo → run this script → game goes live.
"""
from __future__ import annotations

import argparse
import sys
import urllib.request
import urllib.error
from pathlib import Path

ENDPOINT = "https://apis.roblox.com/universes/v1/{universe}/places/{place}/versions"


def publish(universe_id: int, place_id: int, api_key: str, file_path: Path, live: bool) -> int:
    if not file_path.exists():
        print(f"file not found: {file_path}", file=sys.stderr)
        return 2

    body = file_path.read_bytes()
    version_type = "Published" if live else "Saved"
    url = ENDPOINT.format(universe=universe_id, place=place_id) + f"?versionType={version_type}"

    req = urllib.request.Request(
        url,
        data=body,
        method="POST",
        headers={
            "x-api-key": api_key,
            "Content-Type": "application/xml",
            "User-Agent": "BrainrotLab-Publisher/1.0",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            print(f"HTTP {resp.status}: {resp.read().decode('utf-8', 'replace')}")
            print(
                f"Uploaded {len(body):,} bytes as {version_type}. "
                + ("Game is now LIVE for new joins." if live else "Saved as a draft version.")
            )
            return 0
    except urllib.error.HTTPError as e:
        detail = ""
        try:
            detail = e.read().decode("utf-8", "replace")
        except Exception:
            pass
        print(f"HTTP {e.code}: {e.reason}\n{detail}", file=sys.stderr)
        if e.code == 401:
            print("→ API key invalid or missing 'Place Publishing' scope.", file=sys.stderr)
        elif e.code == 403:
            print("→ Key does not have permission for this universe/place. "
                  "Add the experience to the key's allow-list at create.roblox.com/dashboard/credentials.",
                  file=sys.stderr)
        elif e.code == 404:
            print("→ Universe or Place ID is wrong. Check Creator Dashboard.", file=sys.stderr)
        return e.code or 1
    except urllib.error.URLError as e:
        print(f"network error: {e.reason}", file=sys.stderr)
        return 1


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--universe", type=int, required=True, help="Universe ID from create.roblox.com")
    p.add_argument("--place", type=int, required=True, help="Place ID from create.roblox.com")
    p.add_argument("--api-key", required=True, help="Open Cloud API key (Place Publishing scope)")
    p.add_argument("--file", default="BrainrotLab.rbxlx", type=Path, help="path to .rbxlx (default: BrainrotLab.rbxlx)")
    p.add_argument("--publish", action="store_true", help="publish live (default: save as draft)")
    args = p.parse_args()
    return publish(args.universe, args.place, args.api_key, args.file, args.publish)


if __name__ == "__main__":
    sys.exit(main())
