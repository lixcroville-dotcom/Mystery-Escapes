const test = require('node:test');
const assert = require('node:assert/strict');
const { periodKey, boardsFor, serverScore, answersEqual, expectedStageAnswer } = require('../scoring');
test('weekly rolls over Monday 00:00 UTC', () => {
 const sun = Date.UTC(2026,9,11,23,59,59);
 const mon = Date.UTC(2026,9,12,0,0,0);
 assert.notEqual(periodKey('weekly',sun),periodKey('weekly',mon));
});
test('monthly rollover UTC',()=>assert.notEqual(periodKey('monthly',Date.UTC(2026,9,31,23,59)),periodKey('monthly',Date.UTC(2026,10,1,0,0))));
test('score is server-computed, bounded',()=>{
 assert.equal(serverScore({chapter:0,durationSeconds:60,mistakes:0,hints:0}),2260);
 assert.equal(serverScore({chapter:0,durationSeconds:60,mistakes:1,hints:1}),1865);
 assert.throws(()=>serverScore({durationSeconds:-1}));
});
test('all board keys known and free of user strings',()=>{
 const boards=boardsFor({mode:'expert',levelId:9,country:'FR'});
 assert(boards.includes('global'));
 assert(boards.includes('expert'));
 assert(boards.includes('country_FR'));
 assert(boards.includes('case_009'));
 assert(boards.some(v=>v.startsWith('weekly_')));
 assert(!boards.includes('country_FR/../secret'));
});
test('stage proof checks array order, unicode and locale',()=>{
 assert(answersEqual('écho','ÉCHO'));
 assert(answersEqual([1,2,3],[1,2,3]));
 assert(!answersEqual([1,2,3],[3,2,1]));
 assert.equal(expectedStageAnswer({type:'hangman',answer_fr:'CHAT',answer_en:'CAT'},'en'),'CAT');
});
