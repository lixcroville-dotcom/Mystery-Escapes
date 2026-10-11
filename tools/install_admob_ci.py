#!/usr/bin/env python3
"""Install official Poing Studios Godot AdMob 5.1.0 resources from GitHub.
This runs on the macOS runner with network access, NEVER uses placeholder native libs.
Exit nonzero rather than build a misleading IPA without native ad dependencies.
"""
from pathlib import Path
import io, os, json, urllib.request, zipfile, shutil
ROOT=Path(__file__).resolve().parents[1]
BASE='https://api.github.com/repos/poingstudios/godot-admob-plugin/releases/tags/v5.1.0'
headers={'User-Agent':'MysteryEscapes-CI','Accept':'application/vnd.github+json'}
def get(url):
    with urllib.request.urlopen(urllib.request.Request(url,headers=headers), timeout=90) as resp: return resp.read()
data=json.loads(get(BASE)); assets=data.get('assets',[])
print('AdMob release assets:',*[a['name'] for a in assets],sep='\n - ')
plugin=[a for a in assets if a['name'].startswith('poing-godot-admob-v') and a['name'].endswith('.zip')]
assert plugin, 'Missing official Poing AdMob v5 project plugin zip'
raw=get(plugin[0]['browser_download_url'])
with zipfile.ZipFile(io.BytesIO(raw)) as z:
    assert z.testzip() is None
    z.extractall(ROOT)
assert (ROOT/'addons/admob/plugin.cfg').exists(), 'Godot AdMob editor addon missing'
# Native SDK is installed by official editor plugin / platform template installer.
# Verify it was actually provided before producing an IPA.
# Download matching Godot 4.7.2 iOS prebuilt template from official release.
chosen=[item for item in assets if item['name'].startswith('ios-template-v4.7.2') and item['name'].endswith('.zip')]
assert chosen, 'No official iOS template for Godot 4.7.2 found in this release'
native=get(chosen[0]['browser_download_url'])
with zipfile.ZipFile(io.BytesIO(native)) as z:
    assert z.testzip() is None
    members=z.namelist()
    print('Native template sample:', members[:20])
    # Zip may be rooted in addons/ or contain the plugin-relative ios/bin tree.
    if any(m.startswith('addons/') for m in members):
        z.extractall(ROOT)
    else:
        target=ROOT/'addons/admob/ios/bin'
        target.mkdir(parents=True,exist_ok=True)
        z.extractall(target)
print('Official AdMob 5.1.0 plugin and iOS 4.7.2 native package staged')
