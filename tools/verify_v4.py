#!/usr/bin/env python3
"""Static V4 validation, suitable for macOS GitHub Actions or Windows Python.
This does not replace running Godot or testing on a physical iPhone.
"""
from pathlib import Path
from collections import Counter
import json, re, sys, zipfile, subprocess, hashlib
ROOT=Path(__file__).resolve().parents[1]
errors=[]
def check(condition, message):
    if not condition:errors.append(message)
main=json.loads((ROOT/'data/levels.json').read_text(encoding='utf-8'))
kids=json.loads((ROOT/'data/kids_levels.json').read_text(encoding='utf-8'))
check(len(main)==100,f'Expected 100 main cases, got {len(main)}')
original_hash='44651e5b3679d47ab9ead3438c631845a3d7e439dab997a0065a37028a90d7c8'
current_hash=hashlib.sha256(json.dumps(main[:50],ensure_ascii=False,sort_keys=True).encode()).hexdigest()
check(current_hash==original_hash,'One of the original V3 first 50 case definitions changed')
check(len(kids)==10,f'Expected 10 junior cases, got {len(kids)}')
check([case['id'] for case in main]==list(range(1,101)),'Main case IDs are not sequential')
check([case['id'] for case in kids]==list(range(101,111)),'Junior case IDs are not sequential')
counts=Counter()
for case in main+kids:
    check(bool(case.get('title_fr') and case.get('title_en')),'Case missing bilingual title '+str(case.get('id')))
    check(bool(case.get('stages')),'Case without stages '+str(case.get('id')))
    for n,stage in enumerate(case['stages']):
        kind=stage.get('type')
        counts[kind]+=1
        where=f"case={case['id']} step={n+1} type={kind}"
        check(all(isinstance(stage.get(x),str) and stage.get(x) for x in ['question_fr','question_en','hint_fr','hint_en']),where+' missing FR/EN texts')
        answer=stage.get('answer')
        if kind=='code': check(isinstance(answer,str) and len(answer)==4 and answer.isdigit(),where+' invalid code')
        elif kind=='lock': check(isinstance(answer,str) and len(answer) in (3,4) and answer.isdigit(),where+' invalid lock')
        elif kind=='cipher':check(isinstance(answer,str) and 2<=len(answer)<=7 and answer.isalpha() and answer.isupper(),where+' invalid cipher')
        elif kind in ('memory','sound'):check(isinstance(answer,list) and 2<=len(answer)<=9 and all(v in range(4) for v in answer),where+' invalid sequence')
        elif kind=='wires':check(isinstance(answer,list) and 1<=len(answer)<=4 and all(v in range(4) for v in answer),where+' invalid wiring')
        elif kind in ('logic','deduction'):
            opts=stage.get('options') if kind=='logic' else stage.get('options_fr')
            check(isinstance(opts,list) and isinstance(answer,int) and 0<=answer<len(opts),where+' invalid choice')
            if kind=='deduction':check(len(stage.get('options_en',[]))==len(opts),where+' missing English choices')
        elif kind=='hidden':check(isinstance(answer,int) and 0<=answer<len(stage.get('objects_fr',[])) and len(stage.get('objects_en',[]))==len(stage.get('objects_fr',[])),where+' invalid hidden object')
        elif kind=='time':check(isinstance(answer,str) and re.fullmatch(r'(0[1-9]|1[0-2]):(00|15|30|45)',answer) is not None,where+' invalid clock')
        elif kind=='hangman':check(all(isinstance(stage.get(v),str) and stage[v].isalpha() for v in ['answer_fr','answer_en']),where+' invalid word')
        elif kind=='mechanism':check(isinstance(answer,list) and len(answer)==3 and all(v in range(4) for v in answer),where+' invalid gears')
        elif kind=='maze':
            walls=stage.get('walls',[])
            if len(walls)==5 and all(isinstance(row,str) and len(row)==5 for row in walls):
                reachable={(0,0)};todo=[(0,0)]
                while todo:
                    x,y=todo.pop()
                    for nx,ny in ((x+1,y),(x-1,y),(x,y-1),(x,y+1)):
                        if 0<=nx<5 and 0<=ny<5 and walls[ny][nx]=='0' and (nx,ny) not in reachable:
                            reachable.add((nx,ny));todo.append((nx,ny))
                check((4,4) in reachable,where+' unsolvable maze')
            else:check(False,where+' malformed maze')
        elif kind=='inventory':check(isinstance(answer,list) and len(answer)==2 and all(0<=v<len(stage.get('items_fr',[])) for v in answer) and len(stage.get('items_fr',[]))==len(stage.get('items_en',[])),where+' invalid inventory')
        elif kind=='sliding':
            start=stage.get('start',[])
            check(sorted(start)==list(range(9)) and answer==[1,2,3,4,5,6,7,8,0] and start!=answer,where+' invalid sliding tiles')
            # 3x3 sliding parity test, necessary and sufficient for same blank target.
            inv=sum(start[i]>start[j] for i in range(9) for j in range(i+1,9) if start[i] and start[j])
            check(inv%2==0,where+' impossible sliding permutation')
        else:check(False,where+' unsupported puzzle type')
app=(ROOT/'scripts/app.gd').read_text(encoding='utf-8')
proj=(ROOT/'project.godot').read_text(encoding='utf-8')
export=(ROOT/'export_presets.cfg').read_text(encoding='utf-8')
check('user://mystery_escape_save_v2.json' in app,'Save path changed')
check('application/bundle_identifier="com.lixcroville.mysteryescapes"' in export,'Bundle ID changed')
check('application/targeted_device_family=0' in export,'iPhone export target changed')
check('textures/vram_compression/import_etc2_astc=true' in proj,'ETC2 ASTC iOS compression flag missing')
check('func show_tutorial_step(' in app and 'func _input(' in app,'Missing V4 tutorial/touch hooks')
check('func draw_sliding(' in app and '"sliding":draw_sliding()' in app,'Missing sliding implementation')
for i in range(1,23):check((ROOT/f'assets/music/v3/track_{i:02d}.ogg').is_file(),f'Missing musical track {i}')
for name in ('sliding','code','cipher','hidden','logic','inventory','lock','memory','wires','deduction','time','hangman','mechanism','maze','sound'):
    check((ROOT/f'assets/ui/apparatus_{name}.png').is_file(),f'Missing apparatus image {name}')
check((ROOT/'assets/ui/icons/kids.png').exists(),'Missing junior mode icon')
check((ROOT/'.github/workflows/ios-ipa.yml').is_file(),'Missing iOS workflow')
print(f'Levels: {len(main)} main + {len(kids)} junior, stages: {sum(len(v["stages"]) for v in main+kids)}')
print('Puzzle families:',dict(counts))
if errors:
    print('\nVALIDATION FAILED:')
    for e in errors:print(' -',e)
    sys.exit(1)
print('STATIC CHECKS PASSED (not a Godot runtime/iOS device test)')
