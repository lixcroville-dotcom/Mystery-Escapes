from pathlib import Path
import json
root=Path(__file__).resolve().parents[1]
p=root/'scripts/online/online_service.gd'; s=p.read_text(encoding='utf-8')
anchor='''	if not board_id in ["global", "weekly", "monthly", "expert", "impossible", "daily", "marathon"]:
		ranking_failed.emit("Classement inconnu")
		return
	var fb: Dictionary = config.get("firebase", {})'''
replacement='''	var resolved_board: String = board_id
	if board_id == "weekly":
		# ISO-style Monday 00:00 UTC: identical to backend/functions/scoring.js.
		resolved_board = "weekly_%d" % int(floor((Time.get_unix_time_from_system() + 259200.0) / 604800.0))
	elif board_id == "monthly":
		var utc = Time.get_datetime_dict_from_system(true)
		resolved_board = "monthly_%04d-%02d" % [int(utc["year"]), int(utc["month"])]
	var static_boards = ["global", "expert", "impossible", "daily", "marathon"]
	var ok_board = resolved_board in static_boards or resolved_board.begins_with("weekly_") or resolved_board.begins_with("monthly_") or resolved_board.begins_with("country_") or resolved_board.begins_with("case_")
	if not ok_board:
		ranking_failed.emit("Classement inconnu")
		return
	var fb: Dictionary = config.get("firebase", {})'''
assert anchor in s
s=s.replace(anchor,replacement,1)
s=s.replace('collection.uri_encode(),board_id.uri_encode()]','collection.uri_encode(),resolved_board.uri_encode()]',1)
p.write_text(s,encoding='utf-8')
p=root/'scripts/app.gd';s=p.read_text(encoding='utf-8')
s=s.replace('image("res://assets/ui/seal.png",230,140,260,260,page,.91)','image("res://assets/ui/detective_notebook_v8.png",230,140,260,260,page,.91)',1)
s=s.replace('image("res://assets/ui/seal.png",275,495,170,170,page,.55)','image("res://assets/ui/detective_notebook_v8.png",275,495,170,170,page,.55)',1)
s=s.replace('''	var tabs = ["global", "weekly", "monthly", "expert", "impossible", "daily", "marathon"]
	var tab_names = [loc("MONDE","WORLD"),loc("SEMAINE","WEEK"),loc("MOIS","MONTH"),"EXPERT",loc("IMPOSSIBLE","IMPOSSIBLE"),loc("QUOTIDIEN","DAILY"),"MARATHON"]
	for i in range(tabs.size()):
		var col = i % 2
		var row = int(i / 2)
		btn(tab_names[i],45+col*328,280+row*79,302,63,Callable(self,"online_select_board").bind(tabs[i]),online_board_name==tabs[i],page,true)
	box(38,612,645,482,Color("#152736ef"),18,theme_color)''','''	var tabs = ["global", "weekly", "monthly", "country", "friends", "expert", "impossible", "daily", "marathon", "records"]
	var tab_names = [loc("MONDE","WORLD"),loc("SEMAINE","WEEK"),loc("MOIS","MONTH"),loc("PAYS","COUNTRY"),loc("AMIS","FRIENDS"),"EXPERT",loc("IMPOSSIBLE","IMPOSSIBLE"),loc("QUOTIDIEN","DAILY"),"MARATHON",loc("RECORDS","RECORDS")]
	for i in range(tabs.size()):
		var col = i % 2
		var row = int(i / 2)
		btn(tab_names[i],45+col*328,260+row*67,302,55,Callable(self,"online_select_board").bind(tabs[i]),online_board_name==tabs[i],page,true)
	box(38,612,645,482,Color("#152736ef"),18,theme_color)''',1)
anchor='''	OnlineService.fetch_public_ranking(board)
	show_online_leaderboard()'''
replacement='''	if board == "friends":
		online_response_message = loc("Classement entre amis : nécessite le service de classement vérifié et les codes amis. Aucun faux score ne sera affiché.", "Friends: requires the verified ranking server and friend codes. No simulated scores.")
	elif board == "country":
		var country = str(save.get("profile_country", ""))
		if country.length() != 2:
			online_response_message = loc("Choisis ton pays dans le profil lorsque le service sécurisé sera déployé.", "Choose your country in your profile after the secure service is deployed.")
		else:
			OnlineService.fetch_public_ranking("country_" + country.to_upper())
	elif board == "records":
		var solved: Array = save.get("solved", [])
		var case_id = int(solved.back()) if not solved.is_empty() else 1
		OnlineService.fetch_public_ranking("case_%03d" % clampi(case_id,1,100))
	else:
		OnlineService.fetch_public_ranking(board)
	show_online_leaderboard()'''
assert anchor in s
s=s.replace(anchor,replacement,1)
p.write_text(s,encoding='utf-8')
p=root/'config/online_services.json';cfg=json.loads(p.read_text(encoding='utf-8'))
cfg['leaderboards']['server_validation_deployed']=False
cfg['leaderboards']['require_app_check_before_public_launch']=True
cfg['ads'].update({'production_approved':False,'consent_ready':False,'store_listing_linked':False,'publisher_payment_profile_complete':False})
p.write_text(json.dumps(cfg,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=root/'scripts/online/admob_native_adapter.gd';s=p.read_text(encoding='utf-8')
anchor='''func _reward_unit(kind: String) -> String:
	if bool(ads.get("test_mode", true)):'''
rep='''func _production_ready() -> bool:
	return bool(ads.get("production_approved", false)) and bool(ads.get("consent_ready", false)) and bool(ads.get("store_listing_linked", false)) and bool(ads.get("publisher_payment_profile_complete", false))

func _reward_unit(kind: String) -> String:
	if bool(ads.get("test_mode", true)):'''
assert anchor in s;s=s.replace(anchor,rep,1)
anchor='''func show_rewarded(kind: String) -> void:
	if busy or kind not in ["coins", "hint", "double"]:
		return'''
rep='''func show_rewarded(kind: String) -> void:
	if busy or kind not in ["coins", "hint", "double"]:
		return
	if not bool(ads.get("test_mode", true)) and not _production_ready():
		ad_failed.emit("Publicités commerciales désactivées : validation AdMob et consentement requis")
		return'''
assert anchor in s;s=s.replace(anchor,rep,1)
anchor='''func show_interstitial() -> void:
	if busy:
		return'''
rep='''func show_interstitial() -> void:
	if busy:
		return
	if not bool(ads.get("test_mode", true)) and not _production_ready():
		return'''
assert anchor in s;s=s.replace(anchor,rep,1)
p.write_text(s,encoding='utf-8')
print('V8 ONLINE UI + ADS SAFETY PATCH DONE')
