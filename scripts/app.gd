extends Control

# Mystery Escape's - offline, original assets, no external SDK required.
# Godot 4.3+ / portrait canvas 720 x 1280.
const NAVY = Color("#101b27")
const INK = Color("#152736")
const PANEL = Color("#182936")
const PAPER = Color("#ecdec3")
const GOLD = Color("#e3bb7e")
const GOLD_BRIGHT = Color("#ffdfa1")
const QUIET = Color("#adbbc4")
const GREEN = Color("#69d6b4")
const RED = Color("#eb8889")
const CHAPTERS_FR = ["LE MANOIR", "LE LABORATOIRE", "LA PRISON", "LE MUSÉE", "L'HORLOGERIE"]
const CHAPTERS_EN = ["THE MANOR", "THE LAB", "THE PRISON", "THE MUSEUM", "CLOCKWORK"]
const BG_NAMES = ["manor", "laboratory", "prison", "museum", "clocktower"]
const SYMBOLS = ["◆", "▲", "●", "✦"]
const COLORS = ["AMBRE", "AZUR", "RUBIS", "VERT"]
const COLORS_EN = ["AMBER", "BLUE", "RUBY", "GREEN"]
const TONES = [Color("#efc475"), Color("#72c8dc"), Color("#ee8490"), Color("#79cf9f")]
const SAVE_PATH = "user://mystery_escape_save_v2.json"

var levels: Array = []
var save: Dictionary = {}
var screen = "home"
var selected_level = 0
var stage_index = 0
var daily_mode = false
var daily_day = ""
var elapsed = 0.0
var mistakes = 0
var hints_used = 0
var stage_started = 0.0
var puzzle_state: Dictionary = {}
var seq_reveal_end = 0
var seq_played = false
var chapter_filter = 0
var content: Control
var page: Control
var current_bg: TextureRect
var timer_text: Label
var progress_text: Label
var notice_text: Label
var sfx: AudioStreamPlayer
var music: AudioStreamPlayer
var sound_enabled = true
var music_enabled = true
var modal_layer: Control
var theme_color = GOLD
var txt_name: LineEdit
var last_briefing_id = ""
var stage_time_limit = 0.0

func _ready() -> void:
	get_node("EditorPreview").hide()
	get_node("PreviewBackground").hide()
	var raw = FileAccess.get_file_as_string("res://data/levels.json")
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_ARRAY:
		levels = parsed
	else:
		push_error("Cannot read levels.json")
	load_game()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/sounds/ambient.wav")
	music.volume_db = -16.0
	music.finished.connect(func():
		if music_enabled:
			music.play()
	)
	add_child(music)
	if music_enabled:
		music.play()
	show_home()

func _process(delta: float) -> void:
	if screen == "game":
		elapsed += delta
		if timer_text != null and is_instance_valid(timer_text):
			if stage_time_limit > 0.0:
				timer_text.text = "⏳ " + time_display(maxi(0, int(stage_time_limit - (elapsed - stage_started))))
				if elapsed - stage_started >= stage_time_limit:
					mistakes += 1
					reset_puzzle()
					render_game()
					popup(loc("TEMPS ÉCOULÉ","TIME'S UP"),loc("Le mécanisme a été réinitialisé. Tu peux réessayer.","The mechanism has reset. You may try again."))
			else:
				timer_text.text = time_display(int(elapsed))
		if seq_reveal_end > 0 and Time.get_ticks_msec() > seq_reveal_end:
			seq_reveal_end = 0
			render_game()

func fresh_save() -> Dictionary:
	return {"name":"Détective", "coins":600, "gems":30, "xp":0, "best":{}, "runs":[], "solved":[], "completed":0, "daily_date":"", "daily_claim":"", "language":"fr", "sound":true, "music":true, "theme":0, "purchases":[], "achievements":[], "session":{}}

func load_game() -> void:
	save = fresh_save()
	if FileAccess.file_exists(SAVE_PATH):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			for key in save.keys():
				if parsed.has(key):
					save[key] = parsed[key]
	sound_enabled = bool(save.get("sound", true))
	music_enabled = bool(save.get("music", true))
	change_theme(int(save.get("theme", 0)))

func persist() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save, "  "))
		file.close()

func loc(fr: String, en: String) -> String:
	return en if str(save.get("language", "fr")) == "en" else fr

func property_text(data: Dictionary, key: String) -> String:
	var suffix = "_en" if str(save.get("language", "fr")) == "en" else "_fr"
	return str(data.get(key + suffix, data.get(key + "_fr", "")))

func change_theme(value: int) -> void:
	match value:
		1: theme_color = Color("#79d1c2")
		2: theme_color = Color("#ce9bcf")
		_: theme_color = GOLD

func play_sound(name: String) -> void:
	if not sound_enabled or sfx == null:
		return
	var path = "res://assets/sounds/" + name + ".wav"
	if ResourceLoader.exists(path):
		sfx.stream = load(path)
		sfx.volume_db = -5.0
		sfx.play()

func time_display(sec: int) -> String:
	return "%02d:%02d" % [int(sec / 60), sec % 60]

func user_level() -> int:
	return 1 + int(int(save.get("xp", 0)) / 850)

func solved_count() -> int:
	return (save.get("solved", []) as Array).size()

func unlocked(i: int) -> bool:
	return i <= solved_count()

func current_stage() -> Dictionary:
	return levels[selected_level]["stages"][stage_index]

func wipe() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	for child in modal_layer.get_children():
		modal_layer.remove_child(child)
		child.queue_free()
	page = Control.new()
	page.size = Vector2(720,1280)
	page.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(page)
	timer_text = null
	progress_text = null
	seq_reveal_end = 0 if screen != "game" else seq_reveal_end

func box(x: float, y: float, w: float, h: float, bg: Color = PANEL, radius: int = 20, edge: Color = Color("#a9845488"), parent: Control = null) -> Panel:
	var node = Panel.new()
	node.position = Vector2(x,y)
	node.size = Vector2(w,h)
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.border_color = edge
	style.set_border_width_all(2)
	style.shadow_color = Color(0,0,0,0.25)
	style.shadow_size = 8
	node.add_theme_stylebox_override("panel", style)
	(parent if parent != null else page).add_child(node)
	return node

func label(t: String, x: float,y: float,w: float,h: float, sz: int=24, col: Color=PAPER, centered: bool=false, parent: Control=null) -> Label:
	var node = Label.new()
	node.text = t
	node.position = Vector2(x,y)
	node.size = Vector2(w,h)
	node.add_theme_color_override("font_color",col)
	node.add_theme_font_size_override("font_size",sz)
	node.add_theme_color_override("font_shadow_color", Color(0,0,0,0.4))
	node.add_theme_constant_override("shadow_offset_x",1)
	node.add_theme_constant_override("shadow_offset_y",2)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else page).add_child(node)
	return node

func btn(t: String, x: float,y: float,w: float,h: float, pressed: Callable, primary: bool=false, parent: Control=null, small: bool=false) -> Button:
	var node = Button.new()
	node.text = t
	node.position = Vector2(x,y)
	node.size = Vector2(w,h)
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_font_size_override("font_size", 19 if small else 23)
	node.add_theme_color_override("font_color",NAVY if primary else PAPER)
	node.add_theme_color_override("font_hover_color",NAVY if primary else GOLD_BRIGHT)
	var style = StyleBoxFlat.new()
	style.bg_color = theme_color if primary else Color("#233749f5")
	style.set_corner_radius_all(15)
	style.border_color = theme_color
	style.set_border_width_all(2)
	style.shadow_color = Color(0,0,0,.35)
	style.shadow_size = 7
	node.add_theme_stylebox_override("normal",style)
	var hover = style.duplicate()
	hover.bg_color = GOLD_BRIGHT if primary else Color("#36526a")
	node.add_theme_stylebox_override("hover",hover)
	node.add_theme_stylebox_override("pressed",hover)
	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color("#26303b")
	disabled_style.border_color = Color("#4b5159")
	node.add_theme_stylebox_override("disabled",disabled_style)
	node.add_theme_color_override("font_disabled_color",Color("#818790"))
	node.pressed.connect(func():
		play_sound("tap")
		pressed.call()
	)
	(parent if parent != null else page).add_child(node)
	return node

func image(path: String, x: float, y: float, w: float, h: float, parent: Control=null, alpha: float=1.0) -> TextureRect:
	var node = TextureRect.new()
	node.position=Vector2(x,y)
	node.size=Vector2(w,h)
	node.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.texture=load(path)
	node.modulate.a=alpha
	node.mouse_filter=Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else page).add_child(node)
	return node

func backdrop(bg: String="menu", darkness: float=.48) -> void:
	current_bg = image("res://assets/backgrounds/"+bg+".png",0,0,720,1280)
	var shade = ColorRect.new()
	shade.color = Color(0.018,0.035,0.055,darkness)
	shade.position=Vector2.ZERO
	shade.size=Vector2(720,1280)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(shade)

func fade_in() -> void:
	page.modulate.a=0.0
	var tween = create_tween()
	tween.tween_property(page,"modulate:a",1.0,.24).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func small_header(subtitle: String="") -> void:
	box(15,17,690,102,Color("#0c1a27f5"),18,Color("#b28c5b88"))
	label("◈",30,35,58,61,40,theme_color,true)
	label(str(save.get("name","Détective")),85,28,280,41,25,PAPER)
	label(loc("NIVEAU ","LEVEL ")+str(user_level())+"  •  "+subtitle,86,70,330,30,16,QUIET)
	label("◈ "+str(save.get("gems",0)),445,37,111,55,22,theme_color,true)
	label("● "+str(save.get("coins",0)),559,37,125,55,22,theme_color,true)

func topbar(title_text: String, back: Callable) -> void:
	box(15,18,690,100,Color("#101e2cf5"))
	btn("‹",30,34,64,67,back, false)
	label(title_text,115,28,555,78,29,theme_color)

func navigation(active: String) -> void:
	box(9,1157,702,114,Color("#0b1622f8"),20,Color("#926f4b99"))
	var names = [loc("ACCUEIL","HOME"),loc("DOSSIERS","CASES"),loc("CLASSEMENT","RANKS"),loc("BOUTIQUE","SHOP"),loc("PROFIL","PROFILE")]
	var callbacks = [Callable(self,"show_home"),Callable(self,"show_levels"),Callable(self,"show_leaderboard"),Callable(self,"show_shop"),Callable(self,"show_profile")]
	for i in range(5):
		var b = btn(names[i],19+i*139,1178,134,74,callbacks[i], active==["home","levels","leaderboard","shop","profile"][i],page,true)
		b.add_theme_font_size_override("font_size",16)

func show_home() -> void:
	screen="home"
	wipe()
	backdrop("menu",.37)
	small_header(loc("AGENT ACTIF","ACTIVE AGENT"))
	var hero_seal=image("res://assets/ui/seal.png",270,145,180,180, page,.88)
	hero_seal.pivot_offset=hero_seal.size/2
	var pulse=create_tween().bind_node(hero_seal).set_loops()
	pulse.tween_property(hero_seal,"scale",Vector2(1.045,1.045),1.75).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(hero_seal,"scale",Vector2.ONE,1.75).set_trans(Tween.TRANS_SINE)
	label("MYSTERY",60,291,600,78,62,PAPER,true)
	label("ESCAPE'S",60,360,600,70,59,theme_color,true)
	label(loc("DÉMASQUEZ LA VÉRITÉ","UNCOVER THE TRUTH"),60,426,600,36,21,QUIET,true)
	btn("⚙",635,135,61,60,show_settings,false,page,true)
	var ongoing=save.get("session",{}) as Dictionary
	var next_id = clampi(int(ongoing.get("level",solved_count())),0,49)
	box(38,492,644,320,Color("#152536ed"),22,Color("#d5ad76cc"))
	label(loc("VOTRE PROCHAINE ENQUÊTE","YOUR NEXT INVESTIGATION"),62,510,585,45,20,theme_color,true)
	label("DOSSIER %02d" % (next_id+1),55,561,608,48,33,PAPER,true)
	label(property_text(levels[next_id],"title"),60,622,596,68,29,PAPER,true)
	label(loc("RECORD : ","BEST : ")+str((save.get("best",{}) as Dictionary).get(str(next_id+1),0))+" PTS",80,687,560,40,20,QUIET,true)
	if not ongoing.is_empty():
		btn(loc("REPRENDRE L'ENQUÊTE  ›","RESUME INVESTIGATION  ›"),71,741,577,64,Callable(self,"resume_session"),true)
	else:
		btn(loc("COMMENCER L'ENQUÊTE  ›","START INVESTIGATION  ›"),71,741,577,64,Callable(self,"start_case").bind(next_id),true)
	label(loc("◈  DÉFIS ET RÉCOMPENSES","◈  CHALLENGES & REWARDS"),37,836,650,42,24,theme_color)
	box(37,892,306,214,Color("#1b303eee"))
	box(371,892,310,214,Color("#1b303eee"))
	label(loc("DÉFI DU JOUR","DAILY CASE"),52,904,276,42,24,PAPER,true)
	label(loc("Enquête bonus", "Bonus investigation"),54,953,274,42,20,QUIET,true)
	btn(loc("JOUER","PLAY"),62,1021,255,64,show_daily,true)
	label(loc("VOTRE DOSSIER","YOUR FILE"),387,904,279,42,24,PAPER,true)
	label(loc("%d / 50 résolus" % solved_count(),"%d / 50 solved" % solved_count()),390,953,275,42,20,QUIET,true)
	btn(loc("SUCCÈS","ACHIEVEMENTS"),397,1021,260,64,show_achievements,false,page,true)
	navigation("home")
	fade_in()

func show_levels() -> void:
	screen="levels"
	wipe()
	backdrop(BG_NAMES[chapter_filter],.57)
	topbar(loc("DOSSIERS D'ENQUÊTE","INVESTIGATION FILES"),show_home)
	label(loc("50 ENQUÊTES • 5 CHAPITRES","50 CASES • 5 CHAPTERS"),35,135,650,55,25,PAPER,true)
	for i in range(5):
		btn(str(i+1),27+i*138,205,125,66,Callable(self,"set_chapter").bind(i),chapter_filter==i)
	label(CHAPTERS_EN[chapter_filter] if str(save["language"])=="en" else CHAPTERS_FR[chapter_filter],30,283,655,51,28,theme_color,true)
	# ScrollContainer with separately editable card structure created from level data.
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(34,347)
	scroll.size=Vector2(650,793)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	var list=VBoxContainer.new()
	list.add_theme_constant_override("separation",16)
	list.custom_minimum_size=Vector2(624,0)
	scroll.add_child(list)
	for k in range(10):
		var i=chapter_filter*10+k
		var holder=Control.new()
		holder.custom_minimum_size=Vector2(625,142)
		list.add_child(holder)
		var available = unlocked(i)
		box(2,2,610,135,Color("#1c2b39f2"),18,theme_color if available else Color("#666b74"),holder)
		label("%02d"%(i+1),13,22,105,87,53,theme_color if available else QUIET,true,holder)
		label(property_text(levels[i],"title"),122,16,460,51,25,PAPER if available else QUIET,false,holder)
		var prev = str((save.get("best",{}) as Dictionary).get(str(i+1),0))
		label(loc("RECORD : ","BEST : ")+prev+loc(" pts"," pts"),122,70,265,39,19,QUIET,false,holder)
		var b=btn(loc("JOUER","PLAY") if available else loc("FERMÉ","LOCKED"),410,77,188,50,Callable(self,"start_case").bind(i),available,holder,true)
		if not available:
			b.disabled=true
	navigation("levels")
	fade_in()

func set_chapter(index: int) -> void:
	chapter_filter=index
	show_levels()

func start_case(n: int, is_daily: bool=false) -> void:
	if n<0 or n>=levels.size():
		return
	if not is_daily and not unlocked(n):
		popup(loc("DOSSIER VERROUILLÉ","CASE LOCKED"),loc("Résous d'abord l'enquête précédente.","Solve the previous case first."))
		return
	selected_level=n
	stage_index=0
	mistakes=0
	hints_used=0
	elapsed=0
	daily_mode=is_daily
	last_briefing_id=""
	reset_puzzle()
	render_game()

func snapshot_session() -> void:
	if selected_level>=0 and selected_level<levels.size():
		save["session"]={"level":selected_level,"stage":stage_index,"elapsed":elapsed,"mistakes":mistakes,"hints":hints_used,"daily":daily_mode,"state":puzzle_state.duplicate(true),"started":stage_started}
		persist()

func resume_session() -> void:
	var session=save.get("session",{}) as Dictionary
	if session.is_empty():
		show_home()
		return
	selected_level=clampi(int(session.get("level",0)),0,49)
	stage_index=clampi(int(session.get("stage",0)),0,(levels[selected_level]["stages"] as Array).size()-1)
	elapsed=float(session.get("elapsed",0))
	mistakes=int(session.get("mistakes",0))
	hints_used=int(session.get("hints",0))
	daily_mode=bool(session.get("daily",false))
	puzzle_state=session.get("state",{}) as Dictionary
	stage_started=float(session.get("started",elapsed))
	seq_reveal_end=0
	stage_time_limit=95.0 if selected_level>=20 and str(current_stage()["type"]) in ["wires","time"] else 0.0
	last_briefing_id=""
	render_game()

func reset_puzzle() -> void:
	puzzle_state={"typed":"", "wheels":[], "entered":[], "choice":-1,"maze":[0,0],"guessed":[],"wrong":0,"selected":[],"hour":0,"minute":0,"gears":[0,0,0]}
	stage_started=elapsed
	stage_time_limit=95.0 if selected_level>=20 and str(current_stage()["type"]) in ["wires","time"] else 0.0
	seq_reveal_end=0
	seq_played=false
	var stage=current_stage()
	var kind=str(stage["type"])
	if kind in ["lock","cipher"]:
		var solution=str(stage.get("answer",""))
		for ch in solution:
			puzzle_state["wheels"].append(0)
	if kind in ["memory","sound"]:
		seq_reveal_end=Time.get_ticks_msec()+3700 if kind=="memory" else 0

func render_game() -> void:
	screen="game"
	wipe()
	backdrop(BG_NAMES[int(levels[selected_level]["chapter"])],.66)
	topbar(loc("ENQUÊTE ","CASE ")+"%02d"%(selected_level+1),show_levels)
	box(27,135,666,76,Color("#112536ee"))
	label(loc("ÉTAPE ","STEP ")+str(stage_index+1)+" / "+str((levels[selected_level]["stages"] as Array).size()),47,151,350,43,23,theme_color)
	timer_text=label(time_display(int(elapsed)),492,151,179,43,26,PAPER,true)
	box(28,228,664,174,Color("#13212def"))
	var portrait=image("res://assets/ui/agent_morgan.png",42,249,91,108,page,.95)
	portrait.pivot_offset=portrait.size/2
	var portrait_motion=create_tween().bind_node(portrait)
	portrait_motion.tween_property(portrait,"scale",Vector2(1.05,1.05),.4)
	portrait_motion.tween_property(portrait,"scale",Vector2.ONE,.4)
	label(loc("AGENT MORGAN  •  BRIEFING","AGENT MORGAN  •  BRIEFING"),143,247,522,34,19,theme_color)
	var briefing=label(property_text(current_stage(),"question"),142,283,521,100,22,PAPER)
	var key=str(selected_level)+":"+str(stage_index)
	if last_briefing_id!=key:
		last_briefing_id=key
		briefing.visible_characters=0
		create_tween().bind_node(briefing).tween_property(briefing,"visible_characters",briefing.get_total_character_count(),1.0)
	box(26,418,669,620,Color("#0f1e2bec"),24,Color("#c39b64cc"))
	label(type_name(str(current_stage()["type"])),51,438,620,52,29,theme_color,true)
	render_puzzle()
	snapshot_session()
	box(27,1053,667,78,Color("#102331e9"))
	var hint_name=loc("INDICE  ","HINT  ")+ (loc("STOCK ","OWNED ")+str(save.get("hints_stock",0)) if int(save.get("hints_stock",0))>0 else "● 90")
	btn(hint_name,41,1064,311,57,show_hint_options,false,page,true)
	btn(loc("RECOMMENCER","RESTART"),369,1064,311,57,func(): start_case(selected_level,daily_mode),false,page,true)
	label(loc("Vies illimitées  •  Sauvegarde automatique","Unlimited lives  •  Autosave"),31,1132,659,28,17,QUIET,true)
	fade_in()

func type_name(kind: String) -> String:
	var fr={"code":"CADENAS À CODE", "cipher":"MESSAGE CHIFFRÉ", "memory":"MÉMOIRE VISUELLE", "wires":"CIRCUIT ÉLECTRIQUE", "deduction":"DÉDUCTION", "lock":"SERRURE À MOLETTES", "hidden":"INDICES CACHÉS", "logic":"LOGIQUE", "time":"HORLOGE", "hangman":"LE MOT SECRET", "mechanism":"MÉCANISME", "maze":"LABYRINTHE", "inventory":"INVENTAIRE", "sound":"ÉCHO MUSICAL"}
	var en={"code":"KEYPAD LOCK", "cipher":"SECRET CIPHER", "memory":"VISUAL MEMORY", "wires":"ELECTRIC CIRCUIT", "deduction":"DEDUCTION", "lock":"COMBINATION DIAL", "hidden":"HIDDEN EVIDENCE", "logic":"LOGIC", "time":"CLOCK", "hangman":"SECRET WORD", "mechanism":"MECHANICAL DIALS", "maze":"MAZE", "inventory":"INVENTORY", "sound":"SOUND PATTERN"}
	return (en if str(save["language"])=="en" else fr).get(kind,kind)

func popup(title_text: String, body: String, confirm: Callable=Callable(), action_text: String="") -> void:
	for c in modal_layer.get_children():
		c.queue_free()
	var shade=ColorRect.new()
	shade.color=Color(0,0,0,.77)
	shade.size=Vector2(720,1280)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)
	var card=box(47,403,625,410,Color("#1a2b39"),28,theme_color,modal_layer)
	label("◈",299,424,126,69,46,theme_color,true,modal_layer)
	label(title_text,74,501,568,69,32,theme_color,true,modal_layer)
	label(body,80,582,559,104,22,PAPER,true,modal_layer)
	btn(action_text if action_text!="" else loc("CONTINUER","CONTINUE"),98,713,525,70,Callable(self,"close_popup").bind(confirm),true,modal_layer)
	card.pivot_offset=card.size/2
	card.scale=Vector2(.9,.9)
	var tween=create_tween()
	tween.tween_property(card,"scale",Vector2.ONE,.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func mistake(msg: String="") -> void:
	mistakes+=1
	play_sound("error")
	popup(loc("MAUVAISE PISTE","WRONG LEAD"),msg if msg!="" else loc("Examine les indices et réessaie.","Study the evidence and try again."))

func stage_complete() -> void:
	play_sound("open")
	if stage_index+1 < (levels[selected_level]["stages"] as Array).size():
		popup(loc("ÉNIGME RÉSOLUE","PUZZLE SOLVED"),loc("Le mécanisme est déverrouillé. La prochaine pièce du dossier t'attend.","The mechanism is unlocked. Another clue awaits."),Callable(self,"complete_next_stage"),loc("PROCHAINE ÉTAPE  ›","NEXT STEP  ›"))
	else:
		case_complete()

func case_complete() -> void:
	play_sound("success")
	var seconds=int(elapsed)
	var score=max(250, 2500 + int(levels[selected_level]["chapter"])*350 - seconds*4 - mistakes*95 - hints_used*300)
	var key=str(selected_level+1)
	var best=save.get("best",{}) as Dictionary
	var previous=int(best.get(key,0))
	var first=previous==0
	if score>previous:
		best[key]=score
	var earned=100+max(0,int(score/30)) if first else 20
	if daily_mode and str(save.get("daily_claim",""))!=str(Time.get_date_string_from_system()):
		earned+=180
		save["daily_claim"]=Time.get_date_string_from_system()
	save["coins"]=int(save.get("coins",0))+earned
	save["xp"]=int(save.get("xp",0))+200
	var solved=save.get("solved",[]) as Array
	if not solved.has(selected_level+1):solved.append(selected_level+1)
	save["runs"].append({"level":selected_level+1,"score":score,"time":seconds,"date":Time.get_date_string_from_system(),"name":str(save.get("name","Détective"))})
	var runs=save.get("runs",[]) as Array
	if runs.size()>200:
		save["runs"]=runs.slice(runs.size()-200,runs.size())
	add_achievements(seconds)
	save["session"]={}
	persist()
	screen="result"
	wipe()
	backdrop(BG_NAMES[int(levels[selected_level]["chapter"])],.62)
	image("res://assets/ui/seal.png",230,140,260,260,page,.91)
	label(loc("ENQUÊTE RÉSOLUE","CASE SOLVED"),48,442,624,82,46,theme_color,true)
	label(property_text(levels[selected_level],"title"),45,533,630,78,29,PAPER,true)
	box(46,660,626,303,Color("#142634ef"),25,theme_color)
	label(loc("VOTRE SCORE","YOUR SCORE"),83,678,557,51,23,QUIET,true)
	label(str(score)+" PTS",75,735,566,87,56,theme_color,true)
	for particle_i in range(12):
		var star=label("✦",50+particle_i*53,265+(particle_i%4)*72,39,52,26,theme_color,true)
		var anim=create_tween().bind_node(star).set_loops()
		anim.tween_property(star,"position:y",star.position.y+34,2.2+float(particle_i%3)*.2).set_trans(Tween.TRANS_SINE)
		anim.tween_property(star,"position:y",star.position.y,2.2+float(particle_i%3)*.2).set_trans(Tween.TRANS_SINE)
	label(loc("Temps : ","Time: ")+time_display(seconds)+loc("   •   Erreurs : ","   •   Errors: ")+str(mistakes),60,846,601,51,22,PAPER,true)
	label("+"+str(earned)+loc(" PIÈCES"," COINS")+(loc("  •  NOUVEAU RECORD","  •  NEW RECORD") if score>previous else ""),56,907,606,45,19,GREEN,true)
	btn(loc("DOSSIER SUIVANT  ›","NEXT CASE  ›"),59,1004,606,76,func(): start_case(mini(selected_level+1,49)),true if false else false)
	btn(loc("RETOUR AU MENU","BACK TO HOME"),60,1090,602,74,show_home,true)
	fade_in()

func add_achievements(seconds: int) -> void:
	var achievements=save.get("achievements",[]) as Array
	var count=solved_count()
	for item in ["FIRST" if count>=1 else "", "TEN" if count>=10 else "", "HALF" if count>=25 else "", "ALL" if count>=50 else "", "FAST" if seconds<50 else "", "PERFECT" if mistakes==0 and hints_used==0 else ""]:
		if item!="" and not achievements.has(item):achievements.append(item)

func show_hint_options() -> void:
	var message=loc("Utilise un indice de ton stock.","Use a hint from your inventory.") if int(save.get("hints_stock",0))>0 else loc("Un indice coûte 90 pièces. Il réduit ton score final.","A hint costs 90 coins and reduces your score.")
	popup(loc("UN INDICE ?","NEED A HINT?"),message,Callable(self,"buy_hint"),loc("OBTENIR L'INDICE","GET HINT"))

func buy_hint() -> void:
	if int(save.get("hints_stock",0))>0:
		save["hints_stock"]=int(save["hints_stock"])-1
	else:
		if int(save["coins"])<90:
			popup(loc("PIÈCES INSUFFISANTES","NOT ENOUGH COINS"),loc("Termine des enquêtes pour gagner des pièces.","Complete cases to earn coins."))
			return
		save["coins"]=int(save["coins"])-90
	hints_used+=1
	persist()
	play_sound("hint")
	popup(loc("INDICE DÉBLOQUÉ","HINT UNLOCKED"),property_text(current_stage(),"hint"))

func show_daily() -> void:
	var today=str(Time.get_date_string_from_system())
	var n=abs(today.hash())%50
	popup(loc("DÉFI QUOTIDIEN","DAILY CHALLENGE"),loc("Une enquête spéciale du jour ! Termine-la pour gagner 180 pièces supplémentaires (une fois par jour).","Today's special case! Solve it for 180 extra coins (once a day)."),func():start_case(n,true),loc("COMMENCER","START"))

# -------------------------------------------------------------
# Fourteen interactive puzzle mechanisms. Every case uses 2–4
# authored, deterministic stages stored in data/levels.json.
# -------------------------------------------------------------
func render_puzzle() -> void:
	var kind=str(current_stage()["type"])
	image("res://assets/ui/apparatus_"+kind+".png",49,509,623,367,page,.25)
	match kind:
		"code":draw_code()
		"lock":draw_wheels(false)
		"cipher":draw_wheels(true)
		"memory":draw_memory()
		"wires":draw_wires()
		"deduction":draw_choices(true)
		"hidden":draw_hidden()
		"logic":draw_choices(false)
		"time":draw_time()
		"hangman":draw_hangman()
		"mechanism":draw_gears()
		"maze":draw_maze()
		"inventory":draw_inventory()
		"sound":draw_sound()
		_:label("Puzzle",80,600,560,60,32,PAPER,true)

func puzzle_tip(text_fr: String,text_en: String) -> void:
	label(loc(text_fr,text_en),75,928,568,69,19,QUIET,true)

func draw_code() -> void:
	var typed=str(puzzle_state.get("typed",""))
	box(100,520,520,108,Color("#0d151d"),18,theme_color)
	label((typed+" _ _ _ _").substr(0,7).replace(" ","  "),120,534,480,78,43,GOLD_BRIGHT,true)
	for n in range(9):
		btn(str(n+1),125+(n%3)*162,651+int(n/3)*88,143,74,Callable(self,"add_digit").bind(n+1),false)
	btn(loc("EFFACER","CLEAR"),125,913,144,76,clear_code,false,page,true)
	btn("0",286,913,145,76,func():add_digit(0),false)
	btn("✓",447,913,146,76,submit_code,true)

func add_digit(n: int) -> void:
	var entered=str(puzzle_state.get("typed",""))
	if entered.length()>=4:return
	puzzle_state["typed"]=entered+str(n)
	if str(puzzle_state["typed"]).length()>=4:
		if str(puzzle_state["typed"])==str(current_stage()["answer"]):
			stage_complete()
		else:
			mistake()
			puzzle_state["typed"]=""
	else:render_game()

func clear_code() -> void:
	puzzle_state["typed"]=""
	render_game()

func submit_code() -> void:
	if str(puzzle_state.get("typed",""))==str(current_stage()["answer"]):stage_complete()
	else:mistake()

func draw_wheels(as_letters: bool) -> void:
	var solution=str(current_stage()["answer"])
	var alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ" if as_letters else "0123456789"
	var wheels=puzzle_state["wheels"] as Array
	var count=wheels.size()
	var wid=minf(132.0,530.0/maxi(1,count)-7)
	var total=count*(wid+10)
	var start=(720-total)/2
	if as_letters:
		box(110,522,500,84,Color("#222f39"))
		label(str(current_stage().get("encoded","")),132,535,456,57,37,theme_color,true)
	else:
		image("res://assets/ui/seal.png",275,495,170,170,page,.55)
	for i in range(count):
		var x=start+i*(wid+10)
		btn("▲",x,670,wid,65,Callable(self,"turn_wheel").bind(i,1,alphabet.length()))
		box(x,743,wid,109,Color("#080f18"),12,theme_color)
		label(alphabet.substr(int(wheels[i]),1),x+4,760,wid-8,76,43,theme_color,true)
		btn("▼",x,862,wid,65,Callable(self,"turn_wheel").bind(i,-1,alphabet.length()))
	btn(loc("VALIDER","CONFIRM"),180,947,360,72,func():validate_wheels(alphabet),true)

func turn_wheel(i: int, step: int, base: int) -> void:
	var wheels=puzzle_state["wheels"] as Array
	wheels[i]=(int(wheels[i])+step+base)%base
	render_game()

func validate_wheels(alphabet: String) -> void:
	var result=""
	for v in puzzle_state["wheels"]:result+=alphabet.substr(int(v),1)
	if result==str(current_stage()["answer"]):stage_complete()
	else:mistake()

func draw_memory() -> void:
	var answer=current_stage()["answer"] as Array
	var showing=seq_reveal_end>0
	box(65,521,590,172,Color("#081520"),18,theme_color)
	if showing:
		var text_line=""
		for x in answer:text_line+=SYMBOLS[int(x)]+"  "
		label(text_line,77,564,565,79,42,GOLD_BRIGHT,true)
	else:
		label(loc("À TOI DE JOUER","YOUR TURN"),83,549,553,53,29,theme_color,true)
		label(sequence_visual(),80,617,559,48,28,PAPER,true)
	for i in range(4):
		var b=btn(SYMBOLS[i],92+(i%2)*275,742+int(i/2)*87,255,75,Callable(self,"choose_sequence").bind(i),false)
		b.add_theme_font_size_override("font_size",37)
	btn(loc("REVOIR","REPLAY"),205,936,310,68,func():replay_memory(),true)
	puzzle_tip("Mémorise les signes puis touche-les dans l'ordre.","Memorize the signs, then tap them in order.")

func sequence_visual() -> String:
	var s=""
	for x in puzzle_state.get("entered",[]):s+=SYMBOLS[int(x)]+" "
	return s

func replay_memory() -> void:
	puzzle_state["entered"]=[]
	seq_reveal_end=Time.get_ticks_msec()+2800
	render_game()

func choose_sequence(i: int) -> void:
	if seq_reveal_end>0:return
	var entered=puzzle_state["entered"] as Array
	var solution=current_stage()["answer"] as Array
	entered.append(i)
	if i!=int(solution[entered.size()-1]):
		puzzle_state["entered"]=[]
		mistake()
	elif entered.size()==solution.size():stage_complete()
	else:render_game()

func draw_wires() -> void:
	label(loc("BRANCHEMENT DES FILS","CONNECT THE WIRES"),110,525,500,66,25,PAPER,true)
	var entered=puzzle_state["entered"] as Array
	for i in range(4):
		var col=TONES[i]
		var b=btn("●",106+(i%2)*264,622+int(i/2)*132,243,115,Callable(self,"choose_sequence").bind(i),false)
		b.add_theme_color_override("font_color",col)
		b.add_theme_font_size_override("font_size",45)
		box(119+(i%2)*264,714+int(i/2)*132,218,6,col,2,Color.TRANSPARENT)
	label(loc("CONNEXIONS : ","CONNECTED : ")+str(entered.size())+" / "+str((current_stage()["answer"] as Array).size()),75,919,571,64,24,theme_color,true)
	# Wire puzzle reuses the visual sequence validation method, without reveal phase.

func draw_choices(as_suspects: bool) -> void:
	var stage=current_stage()
	var options: Array=[]
	if as_suspects:
		options=stage["options_en"] if str(save["language"])=="en" else stage["options_fr"]
	else:
		options=stage["options"]
	for i in range(options.size()):
		var y=548+i*130
		box(60,y,600,107,Color("#182d3c"),18,theme_color)
		label(str(i+1)+".",83,y+24,55,55,32,theme_color,true)
		btn(str(options[i]),151,y+17,487,73,Callable(self,"choose_option").bind(i),false)
	puzzle_tip("Une seule réponse est correcte.","Only one answer is correct.")

func choose_option(i: int) -> void:
	if i==int(current_stage()["answer"]):stage_complete()
	else:mistake()

func draw_hidden() -> void:
	var stage=current_stage()
	var objects: Array=stage["objects_en"] if str(save["language"])=="en" else stage["objects_fr"]
	for i in range(objects.size()):
		var x=68+(i%3)*206
		var y=535+int(i/3)*112
		box(x,y,188,100,Color("#28384a"),12,Color("#a18259"))
		btn(str(objects[i]),x+7,y+9,174,81,Callable(self,"choose_option").bind(i),false,page,true)
	pass # evidence labels explain the goal

func draw_time() -> void:
	box(153,545,414,244,Color("#101a27"),120,theme_color)
	var h=int(puzzle_state.get("hour",0));var m=int(puzzle_state.get("minute",0))
	label("%02d:%02d"%[h,m],165,623,390,78,59,theme_color,true)
	btn("H  ▲",114,810,234,69,func():adjust_clock(true,1))
	btn("MIN ▲",368,810,234,69,func():adjust_clock(false,1))
	btn("H  ▼",114,895,234,69,func():adjust_clock(true,-1))
	btn("MIN ▼",368,895,234,69,func():adjust_clock(false,-1))
	btn(loc("VÉRIFIER","CHECK"),183,976,354,56,validate_clock,true)

func adjust_clock(hour: bool, amount: int) -> void:
	if hour:puzzle_state["hour"]=(int(puzzle_state["hour"])+amount+12)%12
	else:puzzle_state["minute"]=(int(puzzle_state["minute"])+amount*15+60)%60
	render_game()

func validate_clock() -> void:
	var h=int(puzzle_state["hour"])
	if h==0:h=12
	if "%02d:%02d"%[h,int(puzzle_state["minute"])]==str(current_stage()["answer"]):stage_complete()
	else:mistake()

func draw_hangman() -> void:
	var word=str(current_stage().get("answer_en","")) if str(save["language"])=="en" else str(current_stage().get("answer_fr",""))
	var guessed=puzzle_state["guessed"] as Array
	var masked=""
	for l in word:
		masked+=l+"  " if guessed.has(l) else "_  "
	label(masked,67,516,586,100,38,theme_color,true)
	label(loc("LETTRES ESSAYÉES : ","GUESSES : ")+str(guessed.size()),70,624,578,43,21,QUIET,true)
	var alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for n in range(26):
		var l=alphabet.substr(n,1)
		var x=70+(n%7)*83
		var y=701+int(n/7)*71
		var b=btn(l,x,y,74,63,Callable(self,"guess_letter").bind(l),false,page,true)
		b.disabled=guessed.has(l)
	pass # Keyboard labels explain the goal

func guess_letter(ch: String) -> void:
	var g=puzzle_state["guessed"] as Array
	if g.has(ch):return
	g.append(ch)
	var word=str(current_stage().get("answer_en","")) if str(save["language"])=="en" else str(current_stage().get("answer_fr",""))
	if not word.contains(ch):
		mistakes+=1
		play_sound("error")
	var complete=true
	for l in word:
		if not g.has(l):complete=false
	if complete:stage_complete()
	else:render_game()

func draw_gears() -> void:
	var gears=puzzle_state["gears"] as Array
	var dirs=[loc("NORD","NORTH"),loc("EST","EAST"),loc("SUD","SOUTH"),loc("OUEST","WEST")]
	for i in range(3):
		var x=70+i*206
		box(x,570,180,201,Color("#0f1d2b"),75,theme_color)
		label("⚙",x+35,589,112,92,67,theme_color,true)
		label(dirs[int(gears[i])],x+8,676,164,45,21,PAPER,true)
		btn(loc("TOURNER","TURN"),x+9,817,162,70,Callable(self,"rotate_gear").bind(i),false,page,true)
	btn(loc("DÉCLENCHER","ACTIVATE"),176,935,365,75,validate_gears,true)

func rotate_gear(i: int) -> void:
	var gears=puzzle_state["gears"] as Array
	gears[i]=(int(gears[i])+1)%4
	render_game()

func validate_gears() -> void:
	var gears=puzzle_state["gears"] as Array
	var target=current_stage()["answer"] as Array
	if gears==target:stage_complete()
	else:mistake()

func draw_maze() -> void:
	var maze=puzzle_state["maze"] as Array
	var walls=current_stage()["walls"] as Array
	var tile=79
	for y in range(5):
		for x in range(5):
			var blocked=str(walls[y]).substr(x,1)=="1"
			var where=Vector2(156+x*tile,524+y*tile)
			var target=(x==4 and y==4)
			var pos=(int(maze[0])==x and int(maze[1])==y)
			box(where.x,where.y,72,72,Color("#39434d") if blocked else Color("#203c4b"),11,Color("#63778a"))
			if target:label("★",where.x,where.y,72,72,30,GREEN,true)
			if pos:label("●",where.x,where.y,72,72,39,theme_color,true)
	btn("▲",294,936,130,57,func():move_maze(0,-1))
	btn("‹",150,1001,130,51,func():move_maze(-1,0))
	btn("▼",294,1001,130,51,func():move_maze(0,1))
	btn("›",438,1001,130,51,func():move_maze(1,0))

func move_maze(dx: int,dy: int) -> void:
	var maze=puzzle_state["maze"] as Array
	var x=int(maze[0])+dx
	var y=int(maze[1])+dy
	if x<0 or y<0 or x>=5 or y>=5:return
	var walls=current_stage()["walls"] as Array
	if str(walls[y]).substr(x,1)=="1":
		play_sound("error")
		return
	puzzle_state["maze"]=[x,y]
	if x==4 and y==4:stage_complete()
	else:render_game()

func draw_inventory() -> void:
	var stage=current_stage()
	var items: Array=stage["items_en"] if str(save["language"])=="en" else stage["items_fr"]
	var selected=puzzle_state["selected"] as Array
	label(loc("CONTENU DU SAC","BAG CONTENTS"),70,542,580,63,25,theme_color,true)
	for i in range(4):
		var x=86+(i%2)*285
		var y=630+int(i/2)*139
		btn(str(items[i]),x,y,263,111,Callable(self,"pick_item").bind(i),false)
	label(loc("SÉLECTION : ","SELECTED : ")+str(selected.size())+" / 2",107,916,503,46,25,QUIET,true)
	btn(loc("VIDER LE SAC","RESET BAG"),185,968,350,59,Callable(self,"clear_inventory"),false)

func pick_item(k: int) -> void:
	var selected=puzzle_state["selected"] as Array
	var target=current_stage()["answer"] as Array
	selected.append(k)
	if k!=int(target[selected.size()-1]):
		puzzle_state["selected"]=[]
		mistake()
	elif selected.size()==target.size():stage_complete()
	else:render_game()

func draw_sound() -> void:
	label(loc("ÉCOUTE LES NOTES, PUIS REPRODUIS-LES","LISTEN, THEN REPEAT THE NOTES"),69,513,587,72,23,PAPER,true)
	var entered=puzzle_state["entered"] as Array
	label(str(entered.size())+" / "+str((current_stage()["answer"] as Array).size()),90,593,540,66,32,theme_color,true)
	for i in range(4):
		var b=btn(["DO","MI","SOL","DO+"][i],88+(i%2)*277,682+int(i/2)*104,260,91,Callable(self,"tap_tone").bind(i),false)
		b.add_theme_color_override("font_color",TONES[i])
	btn(loc("ÉCOUTER LA SÉQUENCE","PLAY SEQUENCE"),128,927,466,73,play_tone_sequence,true)

func tap_tone(i: int) -> void:
	play_sound("tone"+str(i))
	var entered=puzzle_state["entered"] as Array
	var solution=current_stage()["answer"] as Array
	entered.append(i)
	if i!=int(solution[entered.size()-1]):
		entered.clear()
		mistake()
	elif entered.size()>=solution.size():stage_complete()
	else:render_game()

func play_tone_sequence() -> void:
	var series=(current_stage()["answer"] as Array).duplicate()
	var original_level=selected_level
	var original_stage=stage_index
	for i in range(series.size()):
		get_tree().create_timer(.13+float(i)*.45).timeout.connect(Callable(self,"play_tone_if_current").bind(int(series[i]),original_level,original_stage))

# -------------------------------------------------------------
# Meta systems: profile, local records, collectibles, hints,
# shop (virtual currency only), journal, settings, achievements.
# -------------------------------------------------------------
func show_profile() -> void:
	screen="profile"
	wipe()
	backdrop("menu",.59)
	small_header(loc("IDENTITÉ","IDENTITY"))
	label(loc("MON DOSSIER","MY DETECTIVE FILE"),40,143,643,65,43,theme_color,true)
	box(39,236,641,398,Color("#182c3bef"))
	image("res://assets/ui/seal.png",250,244,220,220,page,.85)
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
	var statistics=[loc("NIVEAU JOUEUR","PLAYER LEVEL"),str(user_level()),loc("DOSSIERS RÉSOLUS","CASES SOLVED"),str(solved_count())+" / 50",loc("EXPÉRIENCE","EXPERIENCE"),str(save.get("xp",0))+" XP",loc("RECORD CUMULÉ","TOTAL BEST SCORE"),str(total_score())+" PTS"]
	for i in range(4):
		var x=42+(i%2)*331; var y=664+int(i/2)*154
		box(x,y,306,133,Color("#182b3bec"))
		label(str(statistics[i*2]),x+13,y+11,280,43,19,QUIET,true)
		label(str(statistics[i*2+1]),x+13,y+54,280,62,32,theme_color,true)
	btn(loc("SUCCÈS","ACHIEVEMENTS"),52,998,297,74,show_achievements,false)
	btn(loc("JOURNAL","JOURNAL"),371,998,297,74,show_journal,false)
	btn(loc("PARAMÈTRES","SETTINGS"),177,1082,365,58,show_settings,false,page,true)
	navigation("profile")
	fade_in()

func store_username() -> void:
	var name=txt_name.text.strip_edges()
	if name.is_empty():name="Détective"
	save["name"]=name.substr(0,20)
	persist()
	popup(loc("PROFIL ENREGISTRÉ","PROFILE SAVED"),loc("Ton nouveau pseudonyme est enregistré sur cet appareil.","Your detective name is saved on this device."))

func total_score() -> int:
	var sum=0
	for v in (save.get("best",{}) as Dictionary).values():sum+=int(v)
	return sum

func show_leaderboard() -> void:
	screen="leaderboard"
	wipe()
	backdrop("museum",.66)
	topbar(loc("CLASSEMENT LOCAL","LOCAL LEADERBOARD"),show_home)
	label(loc("VOS MEILLEURES PERFORMANCES","YOUR BEST PERFORMANCES"),38,142,647,69,28,theme_color,true)
	box(36,227,648,149,Color("#152c3b"))
	label(str(total_score()),75,238,565,77,51,theme_color,true)
	label(loc("POINTS CUMULÉS SUR 50 DOSSIERS","TOTAL BEST SCORE ACROSS 50 CASES"),78,319,556,35,18,QUIET,true)
	var records=[]
	for run in (save.get("runs",[]) as Array):records.append(run)
	records.sort_custom(func(a,b):return int(a.get("score",0))>int(b.get("score",0)))
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(40,398)
	scroll.size=Vector2(640,719)
	page.add_child(scroll)
	var list=VBoxContainer.new()
	list.custom_minimum_size=Vector2(612,0)
	list.add_theme_constant_override("separation",12)
	scroll.add_child(list)
	if records.size()==0:
		var l=Label.new()
		l.text=loc("Termine une enquête pour apparaître ici.","Solve a case to appear here.")
		l.custom_minimum_size=Vector2(585,100)
		l.add_theme_font_size_override("font_size",22)
		list.add_child(l)
	for i in range(mini(records.size(),30)):
		var rec=records[i] as Dictionary
		var holder=Control.new()
		holder.custom_minimum_size=Vector2(610,96)
		list.add_child(holder)
		box(0,1,597,92,Color("#1d3040f4"),13,theme_color,holder)
		label("#%02d"%(i+1),8,17,81,53,29,theme_color,true,holder)
		label(loc("Dossier ","Case ")+str(rec.get("level",1))+" • "+str(rec.get("name","")),100,8,338,43,20,PAPER,false,holder)
		label(str(rec.get("date","")),100,50,340,29,15,QUIET,false,holder)
		label(str(rec.get("score",0)),430,16,157,56,29,GREEN,true,holder)
	label(loc("HORS LIGNE • CE CLASSEMENT NE COMPARE PAS LES AUTRES JOUEURS","OFFLINE • THIS RANKING DOES NOT INCLUDE OTHER PLAYERS"),33,1126,650,28,15,QUIET,true)
	navigation("leaderboard")
	fade_in()

func show_shop() -> void:
	screen="shop"
	wipe()
	backdrop("manor",.65)
	topbar(loc("BOUTIQUE DU DÉTECTIVE","DETECTIVE SHOP"),show_home)
	label(loc("GAGNEZ ET UTILISEZ VOS RESSOURCES","EARN AND USE YOUR RESOURCES"),35,148,649,52,22,theme_color,true)
	box(44,220,633,188,Color("#132838ec"))
	label(loc("PIÈCES","COINS")+"  ● "+str(save.get("coins",0)),66,247,585,64,30,PAPER,true)
	label(loc("GEMMES","GEMS")+"  ◈ "+str(save.get("gems",0)),66,327,585,56,27,theme_color,true)
	var shop_items=[
		[loc("PAQUET D'INDICES","HINT PACK"),loc("3 indices • 220 pièces","3 hints • 220 coins"),"220", "hints"],
		[loc("DOSSIER COLORÉ","COLORED FILE"),loc("Thème turquoise • 400 pièces","Turquoise theme • 400 coins"),"400", "turquoise"],
		[loc("ENCRE VIOLETTE","VIOLET INK"),loc("Thème violet • 600 pièces","Purple theme • 600 coins"),"600", "purple"]]
	for i in range(3):
		var y=446+i*172
		box(42,y,636,148,Color("#182c3bef"))
		label(str(shop_items[i][0]),64,y+12,540,43,26,theme_color)
		label(str(shop_items[i][1]),65,y+58,460,43,19,QUIET)
		btn(str(shop_items[i][2])+" ●",496,y+78,156,56,Callable(self,"buy_virtual").bind(i),true,page,true)
	box(42,975,636,143,Color("#16202df2"))
	label(loc("PUBLICITÉS ET ACHATS","ADS & PURCHASES"),54,984,611,42,25,theme_color,true)
	label(loc("Désactivés dans ce prototype hors ligne. Aucun paiement ni pub réelle.","Disabled in this offline prototype. No real payments or ads."),65,1031,579,69,19,QUIET,true)
	navigation("shop")
	fade_in()

func buy_virtual(which: int) -> void:
	var costs=[220,400,600]
	if int(save["coins"])<costs[which]:
		popup(loc("PAS ASSEZ DE PIÈCES","NOT ENOUGH COINS"),loc("Résous de nouveaux dossiers pour gagner des pièces.","Solve new cases to earn coins."))
		return
	var purchased=save.get("purchases",[]) as Array
	if which>0 and purchased.has(which):
		popup(loc("DÉJÀ OBTENU","ALREADY OWNED"),loc("Cet objet fait déjà partie de ta collection.","You already own this item."))
		return
	save["coins"]=int(save["coins"])-costs[which]
	if which==0:
		save["hints_stock"]=int(save.get("hints_stock",0))+3
	else:purchased.append(which)
	persist()
	play_sound("success")
	popup(loc("ACHAT EFFECTUÉ","PURCHASE COMPLETE"),loc("Objet ajouté au profil. Aucun paiement réel.","Item added to your profile. No real payment."),show_shop)

func show_achievements() -> void:
	screen="achievements"
	wipe()
	backdrop("museum",.66)
	topbar(loc("SUCCÈS ET TROPHÉES","ACHIEVEMENTS"),show_profile)
	var data=[
		["FIRST",loc("PREMIÈRE PISTE","FIRST CLUE"),loc("Terminer 1 enquête","Finish 1 case")],
		["TEN",loc("ENQUÊTEUR","INVESTIGATOR"),loc("Terminer 10 enquêtes","Finish 10 cases")],
		["HALF",loc("MAÎTRE DES SECRETS","SECRET MASTER"),loc("Terminer 25 enquêtes","Finish 25 cases")],
		["ALL",loc("LÉGENDE","LEGEND"),loc("Terminer 50 enquêtes","Finish 50 cases")],
		["FAST",loc("ÉCLAIR DE GÉNIE","QUICK THINKER"),loc("Finir un dossier en moins de 50 s","Solve a case in under 50 s")],
		["PERFECT",loc("SANS FAUTE","FLAWLESS"),loc("Réussir sans erreur ni indice","No mistakes or hints")]]
	for i in range(data.size()):
		var y=167+i*152
		var gained=(save.get("achievements",[]) as Array).has(data[i][0])
		box(40,y,639,137,Color("#1a2c3aef"))
		label("★" if gained else "◇",59,y+25,87,81,51,theme_color if gained else QUIET,true)
		label(str(data[i][1]),161,y+21,477,45,25,PAPER)
		label(str(data[i][2]),161,y+67,474,44,20,GREEN if gained else QUIET)
	navigation("profile")
	fade_in()

func show_journal() -> void:
	screen="journal"
	wipe()
	backdrop("manor",.56)
	topbar(loc("JOURNAL D'ENQUÊTE","CASE JOURNAL"),show_profile)
	label(loc("PIÈCES À CONVICTION","EVIDENCE LOG"),39,141,644,59,27,theme_color,true)
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(38,218)
	scroll.size=Vector2(646,914)
	page.add_child(scroll)
	var list=VBoxContainer.new()
	list.custom_minimum_size=Vector2(613,0)
	list.add_theme_constant_override("separation",14)
	scroll.add_child(list)
	for i in range(50):
		var holder=Control.new()
		holder.custom_minimum_size=Vector2(610,119)
		list.add_child(holder)
		box(0,1,609,116,Color("#203343ed"),12,theme_color if (save.get("solved",[]) as Array).has(i+1) else QUIET,holder)
		label("%02d"%(i+1),11,20,85,65,37,theme_color,true,holder)
		label(property_text(levels[i],"title"),103,13,477,42,23,PAPER,false,holder)
		label(loc("RÉSOLU • DOSSIER CLASSÉ","SOLVED • CASE CLOSED") if (save.get("solved",[]) as Array).has(i+1) else loc("NON RÉSOLU","UNSOLVED"),104,63,466,37,17,GREEN if (save.get("solved",[]) as Array).has(i+1) else QUIET,false,holder)
	navigation("profile")
	fade_in()

func show_settings() -> void:
	screen="settings"
	wipe()
	backdrop("menu",.65)
	topbar(loc("PARAMÈTRES","SETTINGS"),show_home)
	label(loc("PRÉFÉRENCES","PREFERENCES"),37,149,643,66,35,theme_color,true)
	box(43,239,633,601,Color("#192c3bee"))
	label(loc("LANGUE DU JEU","GAME LANGUAGE"),60,271,595,50,25,PAPER,true)
	btn("FRANÇAIS",68,330,274,76,func():set_language("fr"),str(save["language"])=="fr")
	btn("ENGLISH",375,330,271,76,func():set_language("en"),str(save["language"])=="en")
	label(loc("SON & AMBIANCE","SOUND & AMBIENCE"),68,432,569,51,26,PAPER,true)
	btn(loc("SONS : ","SOUNDS: ")+("ON" if sound_enabled else "OFF"),78,507,560,76,toggle_sound,sound_enabled)
	btn(loc("MUSIQUE : ","MUSIC: ")+("ON" if music_enabled else "OFF"),78,602,560,76,toggle_music,music_enabled)
	label(loc("DIRECTION ARTISTIQUE","VISUAL THEME"),68,696,564,51,26,PAPER,true)
	for i in range(3):
		var name=[loc("OR","GOLD"),loc("AZUR","AZURE"),loc("VIOLET","VIOLET")][i]
		var choice=btn(name,78+i*189,759,177,63,Callable(self,"select_visual_theme").bind(i),int(save.get("theme",0))==i,page,true)
		if i>0 and not (save.get("purchases",[]) as Array).has(i):
			choice.disabled=true
	box(42,864,633,216,Color("#152332eb"))
	label(loc("STOCKAGE LOCAL","LOCAL STORAGE"),60,881,587,48,26,theme_color,true)
	label(loc("La progression est enregistrée automatiquement sur cet appareil. Classement et profil hors ligne.","Progress is automatically saved on this device. Leaderboard and profile are offline."),72,939,574,111,21,QUIET,true)
	btn(loc("RETOUR AU MENU","BACK TO HOME"),91,1105,542,67,show_home,true)
	fade_in()

func set_language(code: String) -> void:
	save["language"]=code
	persist()
	show_settings()

func toggle_sound() -> void:
	sound_enabled=not sound_enabled
	save["sound"]=sound_enabled
	persist()
	show_settings()

func toggle_music() -> void:
	music_enabled=not music_enabled
	save["music"]=music_enabled
	if music_enabled:music.play()
	else:music.stop()
	persist()
	show_settings()

func select_visual_theme(which: int) -> void:
	save["theme"]=which
	change_theme(which)
	persist()
	show_settings()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if screen=="game":
			popup(loc("QUITTER L'ENQUÊTE ?","EXIT THIS CASE?"),loc("Tu pourras recommencer plus tard.","You can start the case again later."),show_levels,loc("QUITTER","EXIT"))
		else:show_home()

func play_tone_if_current(note: int, original_level: int, original_stage: int) -> void:
	if screen=="game" and selected_level==original_level and stage_index==original_stage:
		play_sound("tone"+str(note))

func close_popup(confirm: Callable) -> void:
	for c in modal_layer.get_children():
		c.queue_free()
	if confirm.is_valid():
		confirm.call()

func complete_next_stage() -> void:
	stage_index+=1
	last_briefing_id=""
	reset_puzzle()
	render_game()

func clear_inventory() -> void:
	puzzle_state["selected"]=[]
	render_game()
