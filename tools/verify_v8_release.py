"""Offline release checks. These checks do NOT replace a Godot/Xcode or iPhone run."""
import hashlib, json, pathlib, re, struct
root=pathlib.Path(__file__).resolve().parents[1]
errors=[]
def check(cond,msg):
 if not cond: errors.append(msg)
def png_size(p):
 b=p.read_bytes() if p.exists() else b''
 if len(b)<24 or b[:8]!=b'\x89PNG\r\n\x1a\n': return (0,0)
 return struct.unpack('>II',b[16:24])
icon=root/'assets/ui/ios_app_icon.png'
check(png_size(icon)==(1024,1024),'icon 1024px required')
check(png_size(root/'assets/ui/detective_notebook_v8.png')==(1024,1024),'new notebook missing')
check(png_size(root/'assets/ui/loading_background_v8.png')==(720,1280),'cinematic splash missing')
avatars=[root/f'assets/ui/avatars/detective_{i:02d}.png' for i in range(1,21)]
check(len(avatars)==20,'exactly 20 portraits required')
check(all(png_size(p)==(256,256) for p in avatars),'all avatars must be 256x256')
check(len(set(hashlib.sha256(p.read_bytes()).hexdigest() for p in avatars if p.exists()))==20,'portraits must be unique')
s=(root/'scripts/app.gd').read_text(encoding='utf-8')
check('AVATAR_COUNT_V8: int = 20' in s,'avatar count mismatch')
check('"profile_customization_claimed"' in s and '"profile_points"' in s,'new save defaults absent')
check('if not rewarded.has(claim)' in s,'avatar XP has to be granted once')
check('"name_first_change"' in s,'nickname XP must have claim guard')
check('assets/ui/detective_notebook_v8.png' in s and 'assets/ui/loading_background_v8.png' in s,'new splash not wired up')
check('SAVE_PATH = "user://mystery_escape_save_v2.json"' in s,'save location changed')
check('show_online_leaderboard' in s and '"weekly", "monthly"' in s,'leaderboard UI missing')
fb=json.loads((root/'config/online_services.json').read_text(encoding='utf-8'))
check(fb['ads']['test_mode'] is True and fb['ads']['production_approved'] is False,'production advertising enabled unexpectedly')
check(fb['leaderboards']['server_validation_deployed'] is False,'ranking server erroneously declared live')
check(fb['firebase']['project_id']=='mystery-escapes','wrong Firebase project')
check('"mystery-escapes"' in (root/'.firebaserc').read_text(encoding='utf-8'),'project binding lost')
levels=json.loads((root/'data/levels.json').read_text(encoding='utf-8'))
children=json.loads((root/'data/kids_levels.json').read_text(encoding='utf-8'))
check(len(levels)==100 and len(children)==50,'case counts changed')
expected=levels+json.loads((root/'data/impossible_cases.json').read_text(encoding='utf-8'))
ranked=json.loads((root/'backend/functions/levels_ranked.json').read_text(encoding='utf-8'))
check(ranked==expected,'server solutions not synchronized')
check('allow create, update, delete: if false' in (root/'backend/firestore.rules').read_text(encoding='utf-8'),'client scoreboard writes not denied')
print(json.dumps({'passed':not errors,'errors':errors,'avatars':len(avatars),'levels':len(levels),'junior_levels':len(children),'ranked_server_stages':sum(len(x['stages']) for x in ranked),'production_ads':'disabled'},ensure_ascii=False,indent=2))
raise SystemExit(0 if not errors else 1)
