#!/usr/bin/env python3
"""Install official Poing Studios AdMob 5.1.0 with layout-aware extraction.

Fail closed: if either the editor or native iOS plugin is missing, stop the
build rather than generating an IPA that pretends to support ads.
"""
from pathlib import Path
import io
import json
import shutil
import urllib.request
import zipfile

ROOT = Path(__file__).resolve().parents[1]
RELEASE = "https://api.github.com/repos/poingstudios/godot-admob-plugin/releases/tags/v5.1.0"
HEADERS = {"User-Agent": "MysteryEscapes-CI", "Accept": "application/vnd.github+json"}


def download(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers=HEADERS), timeout=120) as response:
        return response.read()


def matching_asset(assets, prefix):
    options = [a for a in assets if a["name"].startswith(prefix) and a["name"].endswith(".zip")]
    if len(options) != 1:
        raise RuntimeError(f"Expected exactly one {prefix} zip, found {[x['name'] for x in options]}")
    return options[0]


def unzip_checked(blob, label):
    archive = zipfile.ZipFile(io.BytesIO(blob))
    if archive.testzip() is not None:
        raise RuntimeError(f"Corrupted {label} download")
    return archive


def install_editor(asset):
    archive = unzip_checked(download(asset["browser_download_url"]), "editor")
    filenames = [n for n in archive.namelist() if n.endswith("/plugin.cfg")]
    print("Plugin.cfg candidates:", filenames)
    # Supports release zips with or without a wrapper directory.
    base_candidates = [n[: -len("plugin.cfg")] for n in filenames if n.endswith("addons/admob/plugin.cfg")]
    if len(base_candidates) != 1:
        print("First release entries:", archive.namelist()[:60])
        raise RuntimeError("Official archive does not contain unique addons/admob/plugin.cfg")
    prefix = base_candidates[0]
    # Find root prefix preceding addons/admob/ and normalize to project root.
    wrapper = prefix[: -len("addons/admob/")]
    count = 0
    for entry in archive.infolist():
        if entry.is_dir() or not entry.filename.startswith(wrapper + "addons/admob/"):
            continue
        rel = entry.filename[len(wrapper):]
        dest = ROOT / rel
        if not dest.resolve().is_relative_to(ROOT.resolve()):
            raise RuntimeError("Unsafe ZIP entry")
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(archive.read(entry))
        count += 1
    plugin = ROOT / "addons/admob/plugin.cfg"
    if not plugin.is_file():
        raise RuntimeError("Editor plugin missing after extraction")
    print(f"Installed editor: {plugin} ({count} files)")


def install_native(asset):
    archive = unzip_checked(download(asset["browser_download_url"]), "iOS native")
    names = archive.namelist()
    print("Native template entries:", names[:35])
    candidates = [n for n in names if "addons/admob/ios/" in n]
    if candidates:
        prefix = candidates[0].split("addons/admob/ios/")[0]
        for entry in archive.infolist():
            if entry.is_dir() or not entry.filename.startswith(prefix + "addons/admob/ios/"):
                continue
            rel = entry.filename[len(prefix):]
            dest = ROOT / rel
            if not dest.resolve().is_relative_to(ROOT.resolve()):
                raise RuntimeError("Unsafe native ZIP entry")
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(archive.read(entry))
    else:
        # Native iOS template normally contains plugin-relative files.
        target = ROOT / "addons/admob/ios/bin"
        target.mkdir(parents=True, exist_ok=True)
        for entry in archive.infolist():
            if entry.is_dir():
                continue
            rel = Path(entry.filename)
            if ".." in rel.parts:
                raise RuntimeError("Unsafe native ZIP entry")
            dest = target / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(archive.read(entry))

    native_root = ROOT / "addons/admob/ios"
    artifacts = [p for p in native_root.rglob("*") if p.is_file() and p.suffix.lower() in (".gdextension", ".gdip", ".a", ".dylib")]
    artifacts += [p for p in native_root.rglob("*.xcframework") if p.is_dir()]
    if not artifacts:
        print("iOS tree:", [str(p.relative_to(native_root)) for p in native_root.rglob("*")][:70])
        raise RuntimeError("Official native iOS plugin missing; refusing misleading IPA")
    print("Native artifacts:", [str(x.relative_to(ROOT)) for x in artifacts[:15]])


def main():
    payload = json.loads(download(RELEASE))
    assets = payload.get("assets", [])
    print("Release assets:", [a["name"] for a in assets])
    install_editor(matching_asset(assets, "poing-godot-admob-v"))
    install_native(matching_asset(assets, "ios-template-v4.7.2"))
    print("Official AdMob plugin setup complete")


if __name__ == "__main__":
    main()
