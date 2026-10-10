#!/usr/bin/env python3
"""V6 static release gates. Runtime and iPhone touch/audio require a real device test."""
from pathlib import Path
from collections import Counter
import json, re, hashlib, sys, zipfile
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def assert_(cond,msg):
    if not cond: errors.append(msg)

def load(name): return json.loads((ROOT/name).read_text(encoding='utf-8'))
main=load('data/levels.json'); juniors=load('data/kids_levels.json'); hard=load('data/impossible_cases.json')
assert_(len(main)==100,'100 main investigations required')
assert_(len(juniors)==20,'20 junior investigations required')
assert_(len(hard)==3,'3 genuinely new impossible investigations required')
assert_([x['id'] for x in hard]==[121,122,123],'Impossible case IDs must not conflict with saved V5 cases')
assert_([x['id'] for x in main]==list(range(1,101)),'Main case IDs changed')
assert_([x['id'] for x in juniors]==list(range(101,121)),'Junior case IDs changed')
old_hash='44651e5b3679d47ab9ead3438c631845a3d7e439dab997a0065a37028a90d7c8'
assert_(hashlib.sha256(json.dumps(main[:50],ensure_ascii=False,sort_keys=True).encode()).hexdigest()==old_hash,'Original 50 case contents changed')
assert_(sum(len(x['stages']) for x in hard)==15,'Each new impossible case requires 5 puzzles')
for case in hard:
    assert_(case.get('chapter') in range(10),'Illegal chapter in impossible case')
    for idx,stage in enumerate(case['stages'],1):
        prefix=f"impossible case {case['id']} stage {idx}"
        for k in ('type','question_fr','question_en','hint_fr','hint_en'):
            assert_(bool(stage.get(k)),prefix+' missing '+k)
        kind=stage['type']; answer=stage.get('answer')
        if kind=='cipher':
            encoded=''.join(chr((ord(ch)-65+int(stage['shift']))%26+65) for ch in answer)
            assert_(encoded==stage.get('encoded'),prefix+' cipher mismatch')
        elif kind in ('lock','code'):
            assert_(isinstance(answer,str) and answer.isdigit() and len(answer) in (3,4),prefix+' invalid numeric answer')
        elif kind in ('logic','deduction'):
            options=stage.get('options') if kind=='logic' else stage.get('options_fr')
            assert_(isinstance(answer,int) and 0<=answer<len(options),prefix+' invalid multiple-choice answer')
            if kind=='deduction':assert_(len(options)==len(stage.get('options_en',[])),prefix+' bilingual mismatch')
        elif kind in ('memory','wires'):
            assert_(isinstance(answer,list) and all(isinstance(v,int) and 0<=v<4 for v in answer),prefix+' invalid color sequence')
        elif kind=='mechanism':
            assert_(isinstance(answer,list) and len(answer)==3 and all(0<=v<4 for v in answer),prefix+' invalid mechanism')
        elif kind=='sliding':
            start=stage.get('start',[])
            assert_(sorted(start)==list(range(9)),prefix+' missing sliding tiles')
            inv=sum(1 for i in range(9) for j in range(i+1,9) if start[i] and start[j] and start[i]>start[j])
            assert_(inv%2==0,prefix+' unsolvable sliding puzzle')
        else:assert_(False,prefix+' unsupported puzzle type '+kind)
app=(ROOT/'scripts/app.gd').read_text(encoding='utf-8')
project=(ROOT/'project.godot').read_text(encoding='utf-8')
preset=(ROOT/'export_presets.cfg').read_text(encoding='utf-8')
workflow=(ROOT/'.github/workflows/ios-ipa.yml').read_text(encoding='utf-8')
checks={
    'legacy save name': 'user://mystery_escape_save_v2.json' in app,
    'new impossible mode visible': '["impossible",loc(' in app,
    '15 minute challenge': 'impossible_seconds_left = 900.0' in app,
    'overtime score penalty': 'float(score) * 0.55' in app,
    'advanced cases appended after juniors':'res://data/impossible_cases.json' in app,
    'scroll gesture handler':'func move_scroll_gesture(dy: float)' in app,
    'inertia physics':'kinetic_velocity *= pow(' in app,
    'avoid taps after swiping':'scroll_block_click_until' in app,
    'mode scroll':'configure_touch_scroll(scroll)' in app,
    'settings scroll':'configure_touch_scroll(scroller)' in app,
    'save timer when resuming':'"impossible_time":impossible_seconds_left' in app,
    'bug report offline':'func copy_bug_report() -> void:' in app,
    'no heavy home logo':'var hero_seal=image(' not in app,
    'ios bundle':'application/bundle_identifier="com.lixcroville.mysteryescapes"' in preset,
    'ios iphone family':'application/targeted_device_family=0' in preset,
    'iOS Metal texture compression':'textures/vram_compression/import_etc2_astc=true' in project,
    'Xcode compatible':'Xcode_26.3.app' in workflow,
    'Godot smoke test':'Smoke test Godot' in workflow,
    'V6 export artifact':'MysteryEscapes-V6-IPA-non-signe' in workflow,
}
for name,condition in checks.items():assert_(condition,name+' check failed')
for name in ('settings_gear_v6.png','coin_v6.png','gem_v6.png','profile_badge.png','impossible.png'):
    assert_((ROOT/'assets/ui/icons'/name).is_file(),'missing '+name)
assert_((ROOT/'scenes/main_menu.tscn').read_text().count('[node name="LogoSeal"')==0,'Editor preview still shows old logo')
for i in range(1,23):assert_((ROOT/f'assets/music/v3/track_{i:02d}.ogg').is_file(),'missing track '+str(i))
fn=re.findall(r'^func\s+(\w+)\s*\(',app,re.M)
assert_(len(fn)==len(set(fn)),'duplicate GDScript functions')
assert_(app.count('configure_touch_scroll(scroll)')==4,'Not all 4 list scrollers configured')
assert_(app.count('configure_touch_scroll(scroller)')==1,'Settings scroll must support swipe')
assert_(not re.search(r'\bset_theme\(which: int\)',app),'Godot base override conflict set_theme()')
print('Main:',len(main),'Junior:',len(juniors),'Advanced impossible:',len(hard))
print('Stages:',sum(len(c['stages']) for c in main+juniors+hard))
print('Distinct puzzle families:',sorted(set(s['type'] for c in main+juniors+hard for s in c['stages'])))
print('GDScript functions:',len(fn),'Touch-aware scroll containers:',5)
print('Static checks:',len(checks)+10)
if errors:
    for err in errors: print('ERROR:',err)
    sys.exit(1)
print('V6 STATIC CHECKS PASSED — runtime/iPhone testing still required')
