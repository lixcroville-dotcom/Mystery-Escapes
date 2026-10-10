#!/usr/bin/env python3
import json,collections, pathlib, subprocess,sys
R=pathlib.Path(__file__).resolve().parents[1]
sets={f:json.loads((R/'data'/f).read_text()) for f in ['levels.json','kids_levels.json','impossible_cases.json']}
problems=[]; checks=0
for f,levels in sets.items():
 for c in levels:
  for j,s in enumerate(c['stages']):
   checks+=1;t=s['type'];a=s.get('answer')
   if t in ('memory','sound','wires','mechanism','inventory'):
    if not isinstance(a,list) or not a:problems.append((c['id'],j,'invalid sequence'))
    if t in ('memory','sound') and (len(a)<3 or any(not isinstance(v,int) or not 0<=v<4 for v in a)):problems.append((c['id'],j,'invalid memory notes'))
   if t=='sliding':
    start=s['start'];goal=s['answer']
    if sorted(start)!=list(range(9)) or sorted(goal)!=list(range(9)):problems.append((c['id'],j,'invalid sliding tiles'))
    def inv(seq):
     q=[v for v in seq if v];return sum(q[i]>q[k] for i in range(len(q)) for k in range(i+1,len(q)))
    if inv(start)%2!=inv(goal)%2:problems.append((c['id'],j,'unsolvable sliding puzzle'))
   if t=='maze':
    walls=s.get('walls',[])
    if len(walls)!=5 or any(len(row)!=5 for row in walls):problems.append((c['id'],j,'maze dimension'));continue
    queue=[(0,0)];seen={(0,0)}
    while queue:
     x,y=queue.pop(0)
     for xx,yy in [(x+1,y),(x-1,y),(x,y+1),(x,y-1)]:
      if 0<=xx<5 and 0<=yy<5 and walls[yy][xx]=='0' and (xx,yy) not in seen:seen.add((xx,yy));queue.append((xx,yy))
    if (4,4) not in seen:problems.append((c['id'],j,'maze cannot be solved'))
   if t in ('code','lock') and (not isinstance(a,str) or not a.isdigit()):problems.append((c['id'],j,'invalid numeric solution'))
   if t=='hidden' and not 0<=a<len(s.get('objects_fr',[])):problems.append((c['id'],j,'hidden object not present'))
   if t=='deduction' and not 0<=a<len(s.get('options_fr',[])):problems.append((c['id'],j,'invalid suspect'))
   if t=='hangman' and (not s.get('answer_fr') or not s.get('answer_en')):problems.append((c['id'],j,'missing word'))
   for field in ['question_fr','question_en','hint_fr','hint_en']:
    if not s.get(field,'').strip():problems.append((c['id'],j,'empty '+field))
for field in ('question_fr','question_en'):
 allq=[(s['type'],s[field].strip().casefold()) for levels in sets.values() for c in levels for s in c['stages']]
 if len(allq)!=len(set(allq)):problems.append(('all','all','repeated '+field))
report={'stages_checked':checks,'errors':problems,'limitations':['No Godot runtime in this environment','No physical iPhone interaction or pixel-overflow test','Semantic similarity remains possible','This test checks data invariants and solvability for supported mechanisms, not full human gameplay']}
(R/'V8_DEEP_VERIFICATION.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print(json.dumps({'stages_checked':checks,'error_count':len(problems),'examples':problems[:15]},ensure_ascii=False))
sys.exit(bool(problems))
