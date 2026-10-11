import json, pathlib, plistlib
root=pathlib.Path(__file__).resolve().parents[1]
cfg=json.loads((root/'config/online_services.json').read_text(encoding='utf-8'))
pl=plistlib.loads((root/'firebase/GoogleService-Info.plist').read_bytes())
assert cfg['firebase']['project_id']==pl['PROJECT_ID']=='mystery-escapes'
assert pl['BUNDLE_ID']=='com.lixcroville.mysteryescapes'
assert cfg['firebase']['api_key']==pl['API_KEY']
assert cfg['ads']['test_mode'] is True
assert cfg['ads']['enabled'] is True
assert 'admob_native_adapter.gd' in str((root/'scripts/online/admob_native_adapter.gd').name)
assert cfg['ads']['test_mode'] is True
assert cfg['purchases']['real_money_enabled'] is False
assert cfg['lives']['unlimited'] is True
assert cfg['ads']['coins_per_rewarded_ad']==100
assert cfg['ads']['ios_rewarded_coins_unit_id'].startswith('ca-app-pub-')
assert cfg['ads']['ios_rewarded_hint_unit_id'].startswith('ca-app-pub-')
assert cfg['ads']['ios_interstitial_unit_id'].startswith('ca-app-pub-')
s=(root/'scripts/online/online_service.gd').read_text(encoding='utf-8')
assert all(x in s for x in ['login_anonymous','login_email','register_email','is_authenticated','fetch_public_ranking'])
a=(root/'scripts/app.gd').read_text(encoding='utf-8')
assert all(x in a for x in ['show_online_account','show_online_leaderboard','online_guest_login','online_email_action'])
assert 'user://mystery_escape_save_v2.json' in a
print('V8 ONLINE: configuration verified (NOT a live Firebase or AdMob test).')
