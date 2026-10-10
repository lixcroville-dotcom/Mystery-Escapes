#!/usr/bin/env python3
from pathlib import Path
import json, collections, re, datetime, sys
R=Path(__file__).resolve().parents[1]
main=json.loads((R/'data/levels.json').read_text());kids=json.loads((R/'data/kids_levels.json').read_text());hard=json.loads((R/'data/impossible_cases.json').read_text());daily=json.loads((R/'data/daily_schedule.json').read_text())
issues=[]
def check(ok,msg):
 if not ok:issues.append(msg)
check(len(main)==100,'main level count');check(len(kids)==50,'junior level count');check(len(hard)==3,'impossible case count')
check([x['id'] for x in main]==list(range(1,101)),'main IDs changed')
check([x['id'] for x in kids[:20]]==list(range(101,121)),'original junior IDs changed')
check(len(set(x['id'] for x in main+kids+hard))==len(main+kids+hard),'duplicate case IDs')
check(len(daily)==365 and [d['day_of_year'] for d in daily]==list(range(1,366)),'daily schedule invalid')
check(all(1<=d['case_id']<=100 for d in daily),'daily references missing cases')
check(len(set(d['case_id'] for d in daily))==100,'daily schedule lacks variety')
app=(R/'scripts/app.gd').read_text()
check('var child_level_count: int = 50' in app,'junior count incorrectly set')
check('daily_schedule[index]' in app,'calendar schedule not wired to gameplay')
check('"daily_day":daily_day' in app and 'save["daily_claim"]=daily_day' in app,'daily reward not anchored to started date')
check('child_level_offset + child_level_count + 2' in app,'impossible chain points to junior levels')
check('"50 enquêtes simples' in app,'junior UI shows wrong level count')
check('user://mystery_escape_save_v2.json' in (R/'scripts/app.gd').read_text(),'save path changed')
check('application/bundle_identifier="com.lixcroville.mysteryescapes"' in (R/'export_presets.cfg').read_text(),'bundle identifier changed')
check(not json.loads((R/'data/future_services.json').read_text())['enabled'],'future services accidentally enabled')
seen=collections.defaultdict(list);families=collections.Counter();invalid=[]
for case in main+kids+hard:
 check(bool(case.get('stages')),'empty case '+str(case['id']))
 for idx,stage in enumerate(case['stages']):
  for field in ('type','question_fr','question_en','hint_fr','hint_en'):
   check(field in stage and stage[field] is not None,f"missing {field} in {case['id']}:{idx}")
  check('answer' in stage or (stage.get('type')=='hangman' and 'answer_fr' in stage and 'answer_en' in stage),f"missing solution in {case['id']}:{idx}")
  families[stage.get('type','?')]+=1
  key=(stage.get('type'),str(stage.get('question_fr','')).strip().lower())
  seen[key].append((case['id'],idx+1))
  if stage.get('type') in ('code','lock'):
   a=stage.get('answer');check(isinstance(a,str) and a.isdigit(),f"invalid numeric answer {case['id']}:{idx}")
  if stage.get('type')=='logic':
   opts=stage.get('options_fr',stage.get('options',[])); a=stage.get('answer');check(isinstance(a,int) and 0<=a<len(opts),f"invalid logic answer {case['id']}:{idx}")
duplicates={str(k):v for k,v in seen.items() if len(v)>1}
check(not duplicates, f'{len(duplicates)} exact repeated puzzle prompts')
for lang in ('question_fr','question_en'):
 counts=collections.Counter((st.get('type'),st.get(lang,'')) for ca in main+kids+hard for st in ca['stages'])
 check(not any(n>1 for n in counts.values()),f'duplicate {lang} prompts')
report={'static_checks_passed':not issues,'errors':issues,'cases':{'main':len(main),'junior':len(kids),'impossible':len(hard)},'stage_count':sum(families.values()),'families':families,'exact_duplicate_prompts':duplicates,'limitations':['Static checks cannot prove every answer is logically correct','Godot editor/runtime and iPhone touch tests not performed by this script','365 scheduled daily selections reuse the 100 authored main cases','Remote leaderboards, IAP and ads are disabled stubs','Some existing cases may be conceptually repetitive without exact wording'] }
(R/'V8_AUDIT_STATIC.json').write_text(json.dumps(report,ensure_ascii=False,indent=2,default=dict)+'\n')
print(json.dumps({'passed':not issues,'errors':issues,'cases':report['cases'],'stages':report['stage_count'],'exact_duplicate_prompts':len(duplicates)},ensure_ascii=False))
sys.exit(1 if issues else 0)
