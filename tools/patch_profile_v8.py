from pathlib import Path
p=Path(__file__).resolve().parents[1]/'scripts/app.gd'
s=p.read_text(encoding='utf-8')
def replace(old,new):
 global s
 assert old in s, 'Missing search anchor: '+old[:120]
 s=s.replace(old,new,1)
replace('var opening_completed: bool = false','var opening_completed: bool = false\nvar avatar_preview_v8: int = -1\nconst AVATAR_COUNT_V8: int = 20\nconst PROFILE_XP_ONCE_V8: int = 25\nconst PROFILE_POINTS_ONCE_V8: int = 10')
replace('"avatar":0, "hints_stock":0', '"avatar":0, "avatar_unlocked": [0,1,2,3], "profile_customization_claimed": [], "profile_points": 0, "hints_stock":0')
old='''func change_avatar(step: int) -> void:
	save["avatar"]=(int(save.get("avatar",0))+step+2)%2
	persist()
	play_sound("paper")
	show_profile()
'''
new='''# V8: artwork unlocks progressively. Never award XP repeatedly for the same choice.
func avatar_path_v8(index: int) -> String:
	return "res://assets/ui/avatars/detective_%02d.png" % (posmod(index, AVATAR_COUNT_V8) + 1)

func avatar_unlock_level_v8(index: int) -> int:
	return 1 if index < 4 else 2 + int((index - 4) / 2)

func avatar_is_available_v8(index: int) -> bool:
	if index < 4 or user_level() >= avatar_unlock_level_v8(index):
		return true
	return (save.get("avatar_unlocked",[]) as Array).has(index)

func avatar_price_v8(index: int) -> int:
	return 150 + 50 * maxi(0,index - 4)

func change_avatar(step: int) -> void:
	if avatar_preview_v8 < 0:
		avatar_preview_v8 = clampi(int(save.get("avatar",0)),0,AVATAR_COUNT_V8-1)
	avatar_preview_v8 = posmod(avatar_preview_v8 + step, AVATAR_COUNT_V8)
	play_sound("paper")
	show_profile()

func select_avatar_v8() -> void:
	var index = clampi(avatar_preview_v8,0,AVATAR_COUNT_V8-1)
	if not avatar_is_available_v8(index):
		var price = avatar_price_v8(index)
		if int(save.get("coins",0)) < price:
			popup(loc("AVATAR VERROUILLÉ", "LOCKED AVATAR"),loc("Débloqué au niveau %d, ou pour %d pièces." % [avatar_unlock_level_v8(index),price], "Unlock at level %d, or for %d coins." % [avatar_unlock_level_v8(index),price]))
			return
		save["coins"] = int(save.get("coins",0)) - price
		var unlocked: Array = save.get("avatar_unlocked", [])
		if not unlocked.has(index):
			unlocked.append(index)
			save["avatar_unlocked"] = unlocked
	if int(save.get("avatar",0)) != index:
		save["avatar"] = index
		var rewarded: Array = save.get("profile_customization_claimed", [])
		var claim: String = "avatar_%02d" % index
		if not rewarded.has(claim):
			rewarded.append(claim)
			save["profile_customization_claimed"] = rewarded
			save["xp"] = int(save.get("xp",0)) + PROFILE_XP_ONCE_V8
			save["profile_points"] = int(save.get("profile_points",0)) + PROFILE_POINTS_ONCE_V8
	persist()
	play_sound("unlock")
	show_profile()
'''
replace(old,new)
old='''	var avatar_id=int(save.get("avatar",0))
	if avatar_id==0:
		image("res://assets/ui/agent_morgan.png",265,252,188,203,page,.95)
	else:
		image("res://assets/ui/seal.png",250,245,220,216,page,.88)
	btn("‹",171,310,62,68,func():change_avatar(-1),false,page,true)
	btn("›",494,310,62,68,func():change_avatar(1),false,page,true)
	label(loc("NOM DU DÉTECTIVE","DETECTIVE NAME"),73,462,574,37,20,QUIET,true)
	txt_name=LineEdit.new()
	txt_name.text=str(save.get("name","Détective"))
	txt_name.max_length=20
	txt_name.alignment=HORIZONTAL_ALIGNMENT_CENTER
	txt_name.position=Vector2(95,517)
	txt_name.size=Vector2(530,67)
	txt_name.add_theme_font_size_override("font_size",27)
	page.add_child(txt_name)
	btn(loc("ENREGISTRER","SAVE NAME"),207,591,306,55,store_username,true,page,true)
'''
new='''	if avatar_preview_v8 < 0:
		avatar_preview_v8 = clampi(int(save.get("avatar",0)),0,AVATAR_COUNT_V8-1)
	var avatar_id = clampi(avatar_preview_v8,0,AVATAR_COUNT_V8-1)
	image(avatar_path_v8(avatar_id),268,248,184,181,page,1.0 if avatar_is_available_v8(avatar_id) else .60)
	btn("‹",171,305,62,68,func():change_avatar(-1),false,page,true)
	btn("›",494,305,62,68,func():change_avatar(1),false,page,true)
	label("%02d / %02d  •  %d PP" % [avatar_id+1,AVATAR_COUNT_V8,int(save.get("profile_points",0))],244,426,232,34,17,GOLD_BRIGHT,true)
	var status = loc("ÉQUIPÉ", "EQUIPPED") if int(save.get("avatar",0)) == avatar_id else (loc("CHOISIR +25 XP", "EQUIP +25 XP") if avatar_is_available_v8(avatar_id) else loc("DÉBLOQUER : %d PIÈCES" % avatar_price_v8(avatar_id),"UNLOCK: %d COINS" % avatar_price_v8(avatar_id)))
	btn(status,212,457,296,45,select_avatar_v8,avatar_is_available_v8(avatar_id),page,true)
	label(loc("NOM DU DÉTECTIVE","DETECTIVE NAME"),73,504,574,32,19,QUIET,true)
	txt_name=LineEdit.new()
	txt_name.text=str(save.get("name","Détective"))
	txt_name.max_length=20
	txt_name.alignment=HORIZONTAL_ALIGNMENT_CENTER
	txt_name.position=Vector2(95,542)
	txt_name.size=Vector2(530,56)
	txt_name.add_theme_font_size_override("font_size",25)
	page.add_child(txt_name)
	btn(loc("ENREGISTRER","SAVE NAME"),207,600,306,44,store_username,true,page,true)
'''
replace(old,new)
old='''func store_username() -> void:
	var name=txt_name.text.strip_edges()
	if name.is_empty():name="Détective"
	save["name"]=name.substr(0,20)
	persist()
	popup(loc("PROFIL ENREGISTRÉ","PROFILE SAVED"),loc("Ton nouveau pseudonyme est enregistré sur cet appareil.","Your detective name is saved on this device."))
'''
new='''func store_username() -> void:
	var name = txt_name.text.strip_edges()
	if name.is_empty(): name = "Détective"
	name = name.substr(0,20)
	if name != str(save.get("name","Détective")):
		var claimed: Array = save.get("profile_customization_claimed", [])
		if not claimed.has("name_first_change"):
			claimed.append("name_first_change")
			save["profile_customization_claimed"] = claimed
			save["xp"] = int(save.get("xp",0)) + 25
			save["profile_points"] = int(save.get("profile_points",0)) + 10
	save["name"] = name
	persist()
	popup(loc("PROFIL ENREGISTRÉ","PROFILE SAVED"),loc("Pseudo enregistré sur cet appareil. Les bonus de personnalisation ne sont accordés qu'une fois par option.","Name saved on this device. Customization bonuses are awarded only once per option."))
'''
replace(old,new)
replace('image_bg.texture = load("res://assets/ui/loading_background.png")','image_bg.texture = load("res://assets/ui/loading_background_v8.png")')
replace('emblem.texture = load("res://assets/ui/seal_v5.png")','emblem.texture = load("res://assets/ui/detective_notebook_v8.png")')
replace('''		emblem.scale = Vector2(.89,.89)
		var intro = create_tween().set_parallel(true)
		intro.tween_property(emblem,"modulate:a",1.0,1.0)
		intro.tween_property(emblem,"scale",Vector2.ONE,1.3).set_trans(Tween.TRANS_SINE)''','''		emblem.scale = Vector2(.76,.89)
		emblem.rotation = -.035
		var intro = create_tween().set_parallel(true)
		intro.tween_property(emblem,"modulate:a",1.0,.95)
		intro.tween_property(emblem,"scale",Vector2.ONE,1.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		intro.tween_property(emblem,"rotation",.0,1.25).set_trans(Tween.TRANS_SINE)
		# A short notebook-opening illusion, without a fake loading percentage.''')
p.write_text(s,encoding='utf-8')
print('PROFILE V8 PATCH APPLIED')
