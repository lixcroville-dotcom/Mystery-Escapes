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
const CHAPTERS_FR = ["LE MANOIR", "LE LABORATOIRE", "LA PRISON", "LE MUSÉE", "L'HORLOGERIE", "LE SILENCE", "LA CITÉ DE VERRE", "LES DISPARUS", "LES TÉMOINS", "L'ARCHIVE FINALE"]
const CHAPTERS_EN = ["THE MANOR", "THE LAB", "THE PRISON", "THE MUSEUM", "CLOCKWORK", "SILENCE", "THE GLASS CITY", "THE MISSING", "THE WITNESSES", "THE FINAL ARCHIVE"]
const BG_NAMES = ["manor", "laboratory", "prison", "museum", "clocktower", "corridors", "glasscity", "missing", "witnesses", "finalarchive"]
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
# V2: layered original audio; values migrate into the existing v2 save path.
var music_b: AudioStreamPlayer
var ambience: AudioStreamPlayer
var tension_player: AudioStreamPlayer
var sfx_pool: Array = []
var sfx_cursor: int = 0
var active_music_name: String = ""
var music_on_a: bool = false
var active_ambience_name: String = ""
var music_fade: Tween
var ambience_fade: Tween
var tension_active: bool = false
var last_tick_second: int = -1
var inspector_portrait: TextureRect
var briefing_label: Label
var last_typing_sound_ms: int = 0
var note_editor: TextEdit
var ui_scale: float = 1.0
var motion_reduced: bool = false
var atmosphere_effect: Control
var stage_transitioning: bool = false
var hint_focus: int = -1
# V3: existing user://mystery_escape_save_v2.json continues to be used.
var active_mode: String = "classic"
var mode_chain: Array = []
var mode_chain_pos: int = 0
var mode_total_score: int = 0
var soundtrack: Dictionary = {}
var soundtrack_scene: String = ""
var soundtrack_cursor: int = 0
var current_music_player: AudioStreamPlayer
var transitions_enabled: bool = true
var haptics_enabled: bool = false
var sound_debug: bool = false
var settings_scroll: ScrollContainer
var music_cycle: Array = []
var music_recent_track: int = -1
var main_level_count: int = 100
var child_level_offset: int = 100
var child_level_count: int = 20
var opening_layer: Control
var opening_completed: bool = false
# V6: drag-scrolling tracks input before child buttons can consume it.
var touch_scrolls: Array = []
var dragged_scroll: ScrollContainer
var scroll_drag_total: float = 0.0
var scroll_last_velocity: float = 0.0
var kinetic_scroll: ScrollContainer
var kinetic_velocity: float = 0.0
var scroll_block_click_until: int = 0
var touch_event_ms: int = -10000
var scroll_using_touch: bool = false
# V6: a global 15-minute Impossible Challenge, with overtime penalty.
var impossible_seconds_left: float = 900.0
var impossible_overtime: bool = false
var impossible_save_checkpoint: int = -1




func _ready() -> void:
	get_node("EditorPreview").hide()
	get_node("PreviewBackground").hide()
	var raw = FileAccess.get_file_as_string("res://data/levels.json")
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) == TYPE_ARRAY:
		levels = parsed
	else:
		push_error("Cannot read levels.json")
	# Junior investigations are separate from the 100 main cases and never change old IDs.
	var juniors = JSON.parse_string(FileAccess.get_file_as_string("res://data/kids_levels.json"))
	if typeof(juniors) == TYPE_ARRAY:
		for junior in juniors:
			levels.append(junior)
	# Three authored final challenges, beyond the IDs of all saved cases.
	var impossible_cases = JSON.parse_string(FileAccess.get_file_as_string("res://data/impossible_cases.json"))
	if typeof(impossible_cases) == TYPE_ARRAY:
		for challenge in impossible_cases:
			levels.append(challenge)
	load_game()
	content = Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	modal_layer = Control.new()
	modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	setup_audio()
	show_home()
	show_opening()

func _process(delta: float) -> void:
	# Flick inertia after releasing a finger (works across iPhone and Android).
	if kinetic_scroll != null and is_instance_valid(kinetic_scroll) and absf(kinetic_velocity) > 12.0:
		kinetic_scroll.scroll_vertical += int(round(kinetic_velocity * delta))
		kinetic_velocity *= pow(0.035, delta)
	else:
		kinetic_scroll = null
		kinetic_velocity = 0.0
	if screen == "game":
		elapsed += delta
		if active_mode == "impossible" and (modal_layer == null or modal_layer.get_child_count() == 0):
			impossible_seconds_left -= delta
			if impossible_seconds_left <= 0.0 and not impossible_overtime:
				impossible_overtime = true
				play_sound("alarm")
				popup(loc("TEMPS ÉCOULÉ", "TIME EXPIRED"), loc("Tu peux continuer, mais ton score sera réduit de 45 %.", "You may continue, but your score will be reduced by 45 %."))
			var checkpoint = int(elapsed / 15.0)
			if checkpoint != impossible_save_checkpoint:
				impossible_save_checkpoint = checkpoint
				snapshot_session()
		if briefing_label != null and is_instance_valid(briefing_label):
			var remain = briefing_label.get_total_character_count() - briefing_label.visible_characters
			if briefing_label.visible_characters >= 0 and remain > 0:
				var now = Time.get_ticks_msec()
				if now - last_typing_sound_ms > 160:
					play_sound("typing")
					last_typing_sound_ms = now
				if inspector_portrait != null and is_instance_valid(inspector_portrait) and not motion_reduced:
					inspector_portrait.rotation = sin(float(now) * 0.012) * 0.019
			else:
				if inspector_portrait != null and is_instance_valid(inspector_portrait):
					inspector_portrait.rotation = 0.0
		if timer_text != null and is_instance_valid(timer_text):
			if active_mode == "impossible":
				var left = maxi(0, ceili(impossible_seconds_left))
				timer_text.text = time_display(left) if not impossible_overtime else loc("HORS DÉLAI", "OVERTIME")
				timer_text.add_theme_color_override("font_color", RED if left <= 90 else GOLD_BRIGHT)
				set_tension(left <= 90)
				if not motion_reduced and left <= 30:
					timer_text.pivot_offset = timer_text.size / 2.0
					timer_text.scale = Vector2.ONE * (1.0 + 0.045 * (1.0 + sin(elapsed * 7.0)))
				else:
					timer_text.scale = Vector2.ONE
			elif stage_time_limit > 0.0:
				var seconds_left = maxi(0, ceili(stage_time_limit - (elapsed - stage_started)))
				timer_text.text = "⏳ " + time_display(seconds_left)
				if seconds_left <= 22:
					timer_text.add_theme_color_override("font_color", RED)
					if not motion_reduced:
						timer_text.pivot_offset = timer_text.size / 2.0
						timer_text.scale = Vector2.ONE * (1.0 + .055 * (1.0 + sin(elapsed * 7.5)))
					if seconds_left != last_tick_second and seconds_left > 0:
						last_tick_second = seconds_left
						if seconds_left <= 15:
							play_sound("tick")
				else:
					timer_text.add_theme_color_override("font_color", PAPER)
					timer_text.scale = Vector2.ONE
				set_tension(seconds_left <= 22)
				if elapsed - stage_started >= stage_time_limit:
					mistakes += 1
					play_sound("alarm")
					reset_puzzle()
					render_game()
					popup(loc("TEMPS ÉCOULÉ","TIME'S UP"),loc("Le mécanisme a été réinitialisé. Tu peux réessayer.","The mechanism has reset. You may try again."))
			else:
				timer_text.text = time_display(int(elapsed))
				set_tension(false)
		if seq_reveal_end > 0 and Time.get_ticks_msec() > seq_reveal_end:
			seq_reveal_end = 0
			render_game()

func fresh_save() -> Dictionary:
	return {"name":"Détective", "coins":600, "gems":30, "xp":0, "best":{}, "runs":[], "solved":[], "completed":0, "daily_date":"", "daily_claim":"", "language":"fr", "sound":true, "music":true, "theme":0, "purchases":[], "achievements":[], "session":{}, "music_volume":25, "sfx_volume":55, "v3_audio_migrated":false, "haptics":false, "mode_records":{}, "mode_session":{}, "daily_streak":0, "last_login":"", "notebook":{}, "tutorial_seen":false, "text_scale":100, "reduced_motion":false, "avatar":0, "hints_stock":0, "impossible_clears":0, "impossible_tutorial_seen":false}

func load_game() -> void:
	save = fresh_save()
	var parsed = null
	if FileAccess.file_exists(SAVE_PATH):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(parsed) != TYPE_DICTIONARY and FileAccess.file_exists(SAVE_PATH + ".bak"):
		parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH + ".bak"))
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in parsed.keys():
			save[key] = parsed[key]
	# A previously-installed V2 uses the same save path and iOS bundle ID.
	# Preserve every record; migrate only the requested default SFX loudness.
	if not bool(save.get("v3_audio_migrated", false)):
		if int(save.get("sfx_volume",70)) == 70:
			save["sfx_volume"] = 55
		save["v3_audio_migrated"] = true
		persist()
	sound_enabled = bool(save.get("sound", true))
	music_enabled = bool(save.get("music", true))
	ui_scale = float(save.get("text_scale",100)) / 100.0
	motion_reduced = bool(save.get("reduced_motion",false))
	change_theme(int(save.get("theme", 0)))
	haptics_enabled = bool(save.get("haptics", false))
	# Old v2 keys and save location are untouched; only missing v3 keys are added.
	var today = str(Time.get_date_string_from_system())
	if str(save.get("last_login", "")) != today:
		# Daily rewards are available without needing a server or an advertisement.
		save["last_login"] = today
		persist()

func persist() -> void:
	var tmp = SAVE_PATH + ".tmp"
	var file = FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("Save temp file could not be opened")
		return
	file.store_string(JSON.stringify(save, "  "))
	file.flush()
	file.close()
	var original = ProjectSettings.globalize_path(SAVE_PATH)
	var temporary = ProjectSettings.globalize_path(tmp)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(original, ProjectSettings.globalize_path(SAVE_PATH + ".bak"))
	if DirAccess.rename_absolute(temporary, original) != OK:
		# Some platforms don't replace existing files with rename.
		if DirAccess.copy_absolute(temporary, original) == OK:
			DirAccess.remove_absolute(temporary)
		else:
			push_warning("Save could not be committed")

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

func volume_db_from_percent(percent: float, offset: float=0.0) -> float:
	if percent <= 0.5:
		return -65.0
	return linear_to_db(percent / 100.0) + offset

func setup_audio() -> void:
	# Neither AudioStreamPlayer nor this soundtrack requires a network connection.
	# Ogg Vorbis stereo files imported by Godot 4 for iOS/Android/Windows.
	music = AudioStreamPlayer.new()
	music.name = "Soundtrack_A"
	add_child(music)
	music_b = AudioStreamPlayer.new()
	music_b.name = "Soundtrack_B"
	add_child(music_b)
	for player in [music, music_b]:
		player.volume_db = -80.0
		player.finished.connect(Callable(self,"on_music_finished").bind(player))
	ambience = AudioStreamPlayer.new()
	ambience.name = "Ambience"
	ambience.volume_db = -80.0
	ambience.finished.connect(Callable(self,"on_ambience_finished"))
	add_child(ambience)
	tension_player = AudioStreamPlayer.new()
	tension_player.name = "Soft_Tension"
	tension_player.stream = load("res://assets/music/tension_v3.ogg")
	tension_player.volume_db = -80.0
	tension_player.finished.connect(Callable(self,"on_tension_finished"))
	add_child(tension_player)
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.name = "SFX_%d" % i
		add_child(player)
		sfx_pool.append(player)
	sfx = sfx_pool[0]
	# Twenty-two original instrumental tracks x 72 seconds = 26m24s.
	# Home, profile, ranking, shop, level map and settings share this playlist.
	soundtrack = {
		"menu": range(22),
		"manor": [0, 3, 6, 9, 12, 15, 18, 21],
		"laboratory": [1, 4, 7, 10, 13, 16, 19],
		"prison": [2, 5, 8, 11, 14, 17, 20],
		"museum": [3, 7, 9, 1, 12, 16, 20],
		"clocktower": [4, 8, 10, 0, 13, 17, 21],
		"corridors": [12, 0, 15, 3, 18, 6],
		"glasscity": [13, 1, 16, 4, 19, 7],
		"missing": [14, 2, 17, 5, 20, 8],
		"witnesses": [15, 3, 18, 9, 21],
		"finalarchive": [16, 4, 19, 10, 0, 21]
	}
	apply_audio_settings()

func on_music_finished(player: AudioStreamPlayer) -> void:
	if player == current_music_player and music_enabled:
		play_next_music(true)

func on_ambience_finished() -> void:
	if music_enabled and ambience.stream != null:
		ambience.play()

func on_tension_finished() -> void:
	if music_enabled and tension_active:
		tension_player.play()

func volume_db_from_percent_v3(percent: float, offset: float=0.0) -> float:
	if percent <= 0.5:
		return -80.0
	# Linear UI scale -> perceptual gain, with headroom for iPhone speakers.
	return linear_to_db(maxf(0.001, percent / 100.0)) + offset

func music_gain() -> float:
	return volume_db_from_percent_v3(float(save.get("music_volume",25)), -3.0)

func sfx_gain() -> float:
	return volume_db_from_percent_v3(float(save.get("sfx_volume",55)), -10.0)

func play_sound(name: String) -> void:
	if not sound_enabled or sfx_pool.is_empty() or int(save.get("sfx_volume",55)) <= 0:
		return
	var path = "res://assets/sounds/v3/" + name + ".wav"
	if not ResourceLoader.exists(path):
		# Preserve tone puzzles and previous resources if a V3 sound is unavailable.
		path = "res://assets/sounds/" + name + ".wav"
	if not ResourceLoader.exists(path):
		return
	var player: AudioStreamPlayer = sfx_pool[sfx_cursor % sfx_pool.size()]
	sfx_cursor += 1
	player.stop()
	player.stream = load(path)
	player.volume_db = sfx_gain() + (-6.0 if name == "typing" else -5.0 if name in ["tick","tap"] else 0.0)
	player.play()

func play_next_music(force: bool=false) -> void:
	if not music_enabled or int(save.get("music_volume",25)) <= 0:
		return
	var playlist = soundtrack.get(soundtrack_scene, soundtrack["menu"]) as Array
	if playlist.is_empty():
		return
	if music_cycle.is_empty():
		music_cycle = playlist.duplicate()
		music_cycle.shuffle()
		if music_cycle.size() > 1 and int(music_cycle[0]) == music_recent_track:
			var temp = music_cycle[0]
			music_cycle[0] = music_cycle[1]
			music_cycle[1] = temp
	var index = int(music_cycle.pop_front())
	music_recent_track = index
	soundtrack_cursor += 1
	var path = "res://assets/music/v3/track_%02d.ogg" % (index + 1)
	if not ResourceLoader.exists(path):
		push_warning("Soundtrack missing: " + path)
		return
	var outgoing: AudioStreamPlayer = current_music_player
	var incoming: AudioStreamPlayer = music if current_music_player != music else music_b
	if incoming == outgoing and not force:
		return
	if music_fade != null and music_fade.is_running():
		music_fade.kill()
	incoming.stop()
	incoming.stream = load(path)
	incoming.volume_db = -80.0
	current_music_player = incoming
	incoming.play()
	music_fade = create_tween().set_parallel(true)
	music_fade.tween_property(incoming, "volume_db", music_gain(), 1.25)
	if outgoing != null and outgoing != incoming and outgoing.playing:
		music_fade.tween_property(outgoing, "volume_db", -80.0, 1.25)
		music_fade.chain().tween_callback(func():
			if is_instance_valid(outgoing) and outgoing != current_music_player:
				outgoing.stop()
		)

func switch_music(name: String) -> void:
	# No restarts when visiting profile / shop / levels in the same universe.
	if soundtrack_scene == name:
		return
	soundtrack_scene = name
	music_cycle.clear()
	play_next_music()

func switch_ambience(scene: String) -> void:
	var scene_sounds = {"menu":"fire", "manor":"rain", "laboratory":"wind", "prison":"clock", "museum":"rain", "clocktower":"clock", "corridors":"wind", "glasscity":"rain", "missing":"clock", "witnesses":"rain", "finalarchive":"fire"}
	var ambience_name = str(scene_sounds.get(scene,"wind"))
	if ambience_name == active_ambience_name:
		return
	active_ambience_name = ambience_name
	if ambience_fade != null and ambience_fade.is_running():
		ambience_fade.kill()
	ambience.stop()
	var path = "res://assets/ambience/" + ambience_name + ".wav"
	if ResourceLoader.exists(path):
		ambience.stream = load(path)
		ambience.volume_db = -80.0
		if music_enabled:
			ambience.play()
			ambience_fade = create_tween()
			ambience_fade.tween_property(ambience,"volume_db",music_gain()-21.0,1.5)

func set_audio_scene(scene: String) -> void:
	if music == null or music_b == null:
		return
	# Only starting an actual case changes the soundtrack. A shop/profile/map
	# navigation must NEVER restart the track nor trigger a crossfade.
	var target = scene if screen == "game" else "menu"
	if screen == "result":
		target = soundtrack_scene if soundtrack_scene != "" else "menu"
	switch_music(target)
	switch_ambience(target)

func set_tension(active: bool) -> void:
	if tension_active == active:
		return
	tension_active = active
	if active and music_enabled and int(save.get("music_volume",25)) > 0 and not tension_player.playing:
		tension_player.play()
	var tween = create_tween()
	tween.tween_property(tension_player,"volume_db",music_gain()-16.0 if active and music_enabled else -80.0, .8)

func apply_audio_settings() -> void:
	if music == null:
		return
	var can_play = music_enabled and int(save.get("music_volume",25)) > 0
	if not can_play:
		music.stop()
		music_b.stop()
		ambience.stop()
		tension_player.stop()
		return
	if soundtrack_scene != "" and (current_music_player == null or not current_music_player.playing):
		play_next_music(true)
	if current_music_player != null:
		current_music_player.volume_db = music_gain()
	if ambience.stream != null:
		ambience.volume_db = music_gain() - 21.0
		if not ambience.playing:
			ambience.play()
	if tension_player.stream != null:
		tension_player.volume_db = music_gain()-16.0 if tension_active else -80.0


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
	touch_scrolls.clear()
	dragged_scroll = null
	kinetic_scroll = null
	kinetic_velocity = 0.0
	# Keep the old frame until it is replaced synchronously in this call.
	# page renders opaque background before next frame is presented.
	for child in content.get_children():
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
	briefing_label = null
	inspector_portrait = null
	set_tension(false)
	seq_reveal_end = 0 if screen != "game" else seq_reveal_end

func configure_touch_scroll(scroll: ScrollContainer) -> void:
	# Never require dragging the tiny right-hand scrollbar.
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.scroll_deadzone = 100000  # Gestures are handled centrally below.
	scroll.get_v_scroll_bar().modulate.a = 0.0
	scroll.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	touch_scrolls.append(scroll)

func begin_scroll_gesture(pos: Vector2) -> void:
	if modal_layer != null and modal_layer.get_child_count() > 0:
		return
	dragged_scroll = null
	scroll_drag_total = 0.0
	scroll_last_velocity = 0.0
	kinetic_scroll = null
	kinetic_velocity = 0.0
	for i in range(touch_scrolls.size() - 1, -1, -1):
		var scroller = touch_scrolls[i] as ScrollContainer
		if is_instance_valid(scroller) and scroller.is_visible_in_tree() and scroller.get_global_rect().has_point(pos):
			dragged_scroll = scroller
			break

func move_scroll_gesture(dy: float) -> void:
	if dragged_scroll == null or not is_instance_valid(dragged_scroll):
		return
	scroll_drag_total += absf(dy)
	if scroll_drag_total <= 9.0:
		return
	# Scrolling must win over a button click after a gesture.
	scroll_block_click_until = Time.get_ticks_msec() + 320
	dragged_scroll.scroll_vertical -= int(round(dy))
	scroll_last_velocity = -dy * 60.0

func finish_scroll_gesture() -> void:
	if dragged_scroll != null and is_instance_valid(dragged_scroll) and scroll_drag_total > 9.0:
		scroll_block_click_until = Time.get_ticks_msec() + 320
		kinetic_scroll = dragged_scroll
		kinetic_velocity = clampf(scroll_last_velocity, -1800.0, 1800.0)
	dragged_scroll = null
	scroll_drag_total = 0.0

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
	node.add_theme_font_size_override("font_size",int(round(sz*ui_scale)))
	node.add_theme_color_override("font_shadow_color", Color(0,0,0,0.4))
	node.add_theme_constant_override("shadow_offset_x",1)
	node.add_theme_constant_override("shadow_offset_y",2)
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centered else HORIZONTAL_ALIGNMENT_LEFT
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.clip_text = true
	# Approximate wrapped line count before rendering; protect narrow iPhone panels.
	var glyphs_per_line = maxf(7.0, w / maxf(8.0, float(sz) * 0.58 * ui_scale))
	var estimated_lines = maxf(1.0, ceil(float(t.length()) / glyphs_per_line))
	if estimated_lines * float(sz) * 1.38 > h and t.length() > 18:
		var fitting = maxi(14, int(floor(h / (1.4 * estimated_lines))))
		node.add_theme_font_size_override("font_size",mini(int(round(sz * ui_scale)),fitting))
	if t.length() > 105 and h <= 110:
		node.add_theme_font_size_override("font_size", int(round(mini(sz, 18) * ui_scale)))
	elif t.length() > 75 and h <= 105:
		node.add_theme_font_size_override("font_size", int(round(mini(sz, 20) * ui_scale)))
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent != null else page).add_child(node)
	return node

func btn(t: String, x: float,y: float,w: float,h: float, pressed: Callable, primary: bool=false, parent: Control=null, small: bool=false) -> Button:
	var node = Button.new()
	node.text = t
	node.position = Vector2(x,y)
	node.size = Vector2(w,h)
	node.focus_mode = Control.FOCUS_NONE
	node.add_theme_font_size_override("font_size", int(round((19 if small else 23)*ui_scale)))
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
	node.pivot_offset = node.size / 2.0
	node.button_down.connect(func():
		if not motion_reduced:
			create_tween().bind_node(node).tween_property(node,"scale",Vector2(.975,.975),.07)
	)
	node.button_up.connect(func():
		if not motion_reduced:
			create_tween().bind_node(node).tween_property(node,"scale",Vector2.ONE,.10)
	)
	node.pressed.connect(func():
		if Time.get_ticks_msec() < scroll_block_click_until:
			return
		play_sound("click")
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
	set_audio_scene(bg)
	current_bg = image("res://assets/backgrounds/"+bg+".png",-9,-13,738,1306)
	if not motion_reduced:
		current_bg.pivot_offset=current_bg.size/2
		var drift=create_tween().bind_node(current_bg).set_loops()
		drift.tween_property(current_bg,"scale",Vector2(1.026,1.026),7.0).set_trans(Tween.TRANS_SINE)
		drift.tween_property(current_bg,"scale",Vector2.ONE,7.0).set_trans(Tween.TRANS_SINE)
	var shade = ColorRect.new()
	shade.color = Color(0.018,0.035,0.055,darkness)
	shade.position=Vector2.ZERO
	shade.size=Vector2(720,1280)
	shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	page.add_child(shade)
	if not motion_reduced:
		var a=load("res://scripts/atmosphere_fx.gd").new()
		a.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		a.size=Vector2(720,1280)
		page.add_child(a)

func fade_in() -> void:
	# The V2 fade to alpha 0 exposed the black viewport on scene changes.
	# V3 presents the finished UI on the same frame, with no black interstitial.
	if page != null:
		page.modulate.a = 1.0
		page.position = Vector2.ZERO

func small_header(subtitle: String="") -> void:
	box(15,17,690,102,Color("#0c1a27f5"),18,Color("#b28c5b88"))
	image("res://assets/ui/icons/profile_badge.png",31,39,47,47)
	label(str(save.get("name","Détective")),85,28,333,41,25,PAPER)
	label(loc("NIVEAU ","LEVEL ")+str(user_level())+"  •  "+subtitle,86,70,344,30,16,QUIET)
	image("res://assets/ui/icons/gem_v6.png",455,47,43,43)
	label(str(save.get("gems",0)),499,39,66,55,22,Color("#8de6ff"),true)
	image("res://assets/ui/icons/coin_v6.png",569,47,43,43)
	label(str(save.get("coins",0)),613,39,76,55,22,GOLD_BRIGHT,true)

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
	active_mode = "classic"
	screen = "home"
	wipe()
	backdrop("menu", .40)  # Preserve the V5 detective desk background.
	small_header(loc("AGENT ACTIF", "ACTIVE AGENT"))
	label("MYSTERY ESCAPE'S",50,160,607,70,43,GOLD_BRIGHT,true)
	label(loc("BUREAU D'ENQUÊTES", "DETECTIVE BUREAU"),75,224,567,43,20,QUIET,true)
	# A real gear PNG, instead of a square emoji missing from some iOS fonts.
	btn("",635,143,64,67,show_settings,false,page,true)
	image("res://assets/ui/icons/settings_gear_v6.png",647,155,40,40)
	var ongoing = save.get("session",{}) as Dictionary
	var next_id = clampi(int(ongoing.get("level",solved_count())),0,main_level_count-1)
	box(34,324,651,391,Color("#102331f2"),24,Color("#d7ac70cc"))
	label(loc("JOUER LE DOSSIER", "PLAY CASE"),60,352,602,52,29,GOLD_BRIGHT,true)
	label("N° %02d" % (next_id+1),70,414,575,53,34,PAPER,true)
	label(property_text(levels[next_id],"title"),60,480,600,93,29,PAPER,true)
	label(loc("RECORD : ","BEST: ")+str((save.get("best",{}) as Dictionary).get(str(next_id+1),0))+" PTS",81,576,560,37,19,QUIET,true)
	if not ongoing.is_empty():
		btn(loc("REPRENDRE  ›", "RESUME  ›"),85,631,550,68,resume_session,true)
	else:
		btn(loc("JOUER MAINTENANT  ›", "PLAY NOW  ›"),85,631,550,68,Callable(self,"start_case").bind(next_id),true)
	# Two clear destinations; achievements remain in the Profile tab.
	box(35,744,651,152,Color("#183140ee"),19,Color("#d0a878a9"))
	label(loc("MODES DE JEU", "GAME MODES"),70,754,577,55,27,PAPER,true)
	btn(loc("CHOISIR UN MODE  ›", "CHOOSE A MODE  ›"),88,818,540,65,show_modes,true)
	box(35,925,651,169,Color("#183140ee"),19,Color("#d0a878a9"))
	label(loc("DÉFI DU JOUR", "DAILY CHALLENGE"),70,937,577,54,27,PAPER,true)
	btn(loc("LANCER LE DÉFI  ›", "PLAY DAILY CASE  ›"),88,1004,540,66,show_daily,false)
	navigation("home")
	fade_in()

func show_levels() -> void:
	active_mode = "classic"
	screen="levels"
	wipe()
	backdrop(BG_NAMES[chapter_filter % BG_NAMES.size()],.57)
	topbar(loc("DOSSIERS D'ENQUÊTE","INVESTIGATION FILES"),show_home)
	label(loc("100 ENQUÊTES • FAIS GLISSER LA LISTE", "100 CASES • SWIPE THE LIST"),35,135,650,55,22,PAPER,true)
	for i in range(10):
		btn(str(i+1),27+(i%5)*138,203+int(i/5)*61,125,53,Callable(self,"set_chapter").bind(i),chapter_filter==i,page,true)
	label(CHAPTERS_EN[chapter_filter] if str(save["language"])=="en" else CHAPTERS_FR[chapter_filter],30,331,655,51,25,theme_color,true)
	# ScrollContainer with separately editable card structure created from level data.
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(34,400)
	scroll.size=Vector2(650,738)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	configure_touch_scroll(scroll)
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
		if (save.get("solved",[]) as Array).has(i+1):
			label("✦",355,76,46,41,30,GREEN,true,holder)
		var b=btn(loc("OUVRIR","OPEN") if available else loc("FERMÉ","LOCKED"),410,77,188,50,Callable(self,"show_case_preview").bind(i),available,holder,true)
		if not available:
			b.disabled=true
	navigation("levels")
	fade_in()

func set_chapter(index: int) -> void:
	chapter_filter=index
	show_levels()

func show_case_preview(n: int) -> void:
	var c = levels[n] as Dictionary
	var description = property_text(c, "story") + "\n\n" + loc("Difficulté : ", "Difficulty: ") + str(c.get("difficulty", 1)) + "/10  •  " + str((c["stages"] as Array).size()) + loc(" énigmes", " puzzles")
	popup(property_text(c,"title"), description, Callable(self,"start_case").bind(n), loc("COMMENCER  ›", "START  ›"))

func start_case(n: int, is_daily: bool=false) -> void:
	if n<0 or n>=levels.size():
		return
	if not is_daily and active_mode == "classic" and not unlocked(n):
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
	if not bool(save.get("tutorial_seen",false)):
		show_tutorial_step(0)

func snapshot_session() -> void:
	if selected_level>=0 and selected_level<levels.size():
		save["session"]={"level":selected_level,"stage":stage_index,"elapsed":elapsed,"mistakes":mistakes,"hints":hints_used,"daily":daily_mode,"mode":active_mode,"chain":mode_chain.duplicate(),"chain_pos":mode_chain_pos,"mode_score":mode_total_score,"impossible_time":impossible_seconds_left,"impossible_overtime":impossible_overtime,"state":puzzle_state.duplicate(true),"started":stage_started}
		persist()

func resume_session() -> void:
	var session=save.get("session",{}) as Dictionary
	if session.is_empty():
		show_home()
		return
	selected_level=clampi(int(session.get("level",0)),0,levels.size()-1)
	active_mode=str(session.get("mode","classic"))
	mode_chain=(session.get("chain",[]) as Array).duplicate()
	mode_chain_pos=int(session.get("chain_pos",0))
	mode_total_score=int(session.get("mode_score",0))
	impossible_seconds_left=float(session.get("impossible_time",900.0))
	impossible_overtime=bool(session.get("impossible_overtime",false))
	impossible_save_checkpoint=-1
	stage_index=clampi(int(session.get("stage",0)),0,(levels[selected_level]["stages"] as Array).size()-1)
	elapsed=float(session.get("elapsed",0))
	mistakes=int(session.get("mistakes",0))
	hints_used=int(session.get("hints",0))
	daily_mode=bool(session.get("daily",false))
	puzzle_state=session.get("state",{}) as Dictionary
	stage_started=float(session.get("started",elapsed))
	seq_reveal_end=0
	stage_time_limit=mode_stage_limit()
	last_briefing_id=""
	render_game()

func reset_puzzle() -> void:
	puzzle_state={"typed":"", "wheels":[], "entered":[], "choice":-1,"maze":[0,0],"guessed":[],"wrong":0,"selected":[],"hour":0,"minute":0,"gears":[0,0,0],"hint_count":0}
	stage_started=elapsed
	stage_time_limit=mode_stage_limit()
	seq_reveal_end=0
	seq_played=false
	last_tick_second=-1
	stage_transitioning=false
	var stage=current_stage()
	var kind=str(stage["type"])
	if kind in ["lock","cipher"]:
		var solution=str(stage.get("answer",""))
		for ch in solution:
			puzzle_state["wheels"].append(0)
	if kind in ["memory","sound"]:
		seq_reveal_end=Time.get_ticks_msec()+3700 if kind=="memory" else 0
	if kind == "sliding":
		puzzle_state["tiles"] = (stage.get("start",[]) as Array).duplicate()

func render_game() -> void:
	screen="game"
	wipe()
	backdrop(BG_NAMES[int(levels[selected_level]["chapter"]) % BG_NAMES.size()],.66)
	topbar(loc("ENQUÊTE ","CASE ")+"%02d"%(selected_level+1),show_levels)
	box(27,135,666,76,Color("#112536ee"))
	label(loc("ÉTAPE ","STEP ")+str(stage_index+1)+" / "+str((levels[selected_level]["stages"] as Array).size()),47,151,350,43,23,theme_color)
	timer_text=label(time_display(int(elapsed)),452,151,222,43,23,PAPER,true)
	box(28,228,664,174,Color("#13212def"))
	var portrait=image("res://assets/ui/agent_morgan.png",42,249,91,108,page,.95)
	inspector_portrait=portrait
	portrait.pivot_offset=portrait.size/2
	var portrait_motion=create_tween().bind_node(portrait)
	portrait_motion.tween_property(portrait,"scale",Vector2(1.05,1.05),.4)
	portrait_motion.tween_property(portrait,"scale",Vector2.ONE,.4)
	label(loc("AGENT MORGAN  •  BRIEFING","AGENT MORGAN  •  BRIEFING"),143,247,522,34,19,theme_color)
	var briefing=label(property_text(current_stage(),"question"),142,283,521,100,22,PAPER)
	briefing_label=briefing
	# Touch the briefing to reveal all text immediately (also works with mouse).
	briefing.mouse_filter=Control.MOUSE_FILTER_STOP
	briefing.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			briefing.visible_characters = -1
	)
	var key=str(selected_level)+":"+str(stage_index)
	if last_briefing_id!=key:
		last_briefing_id=key
		briefing.visible_characters=0
		create_tween().bind_node(briefing).tween_property(briefing,"visible_characters",briefing.get_total_character_count(),1.55 if not motion_reduced else .15)
	box(26,418,669,620,Color("#0f1e2bec"),24,Color("#c39b64cc"))
	label(type_name(str(current_stage()["type"])),51,438,620,52,29,theme_color,true)
	render_puzzle()
	snapshot_session()
	box(27,1053,667,78,Color("#102331e9"))
	var hint_cost = 90 if int(puzzle_state.get("hint_count", 0)) == 0 else 150
	var hint_name=loc("INDICE","HINT")+(" ×"+str(save.get("hints_stock",0)) if int(save.get("hints_stock",0))>0 else " ●"+str(hint_cost))
	btn(hint_name,39,1064,202,57,show_hint_options,false,page,true)
	btn(loc("CARNET","NOTES"),258,1064,202,57,show_notepad,false,page,true)
	btn(loc("PAUSE","PAUSE"),475,1064,202,57,show_pause,false,page,true)
	var footer = loc("DÉFI IMPOSSIBLE • 15 MIN • ", "IMPOSSIBLE • 15 MIN • ") if active_mode == "impossible" else loc("MODE : ", "MODE: ") + active_mode.to_upper() + " • "
	label(footer + loc("Sauvegarde auto", "Autosave"),31,1132,659,28,17,QUIET,true)
	fade_in()

func type_name(kind: String) -> String:
	var fr={"code":"CADENAS À CODE", "cipher":"MESSAGE CHIFFRÉ", "memory":"MÉMOIRE VISUELLE", "wires":"CIRCUIT ÉLECTRIQUE", "deduction":"DÉDUCTION", "lock":"SERRURE À MOLETTES", "hidden":"INDICES CACHÉS", "logic":"LOGIQUE", "time":"HORLOGE", "hangman":"LE MOT SECRET", "mechanism":"MÉCANISME", "maze":"LABYRINTHE", "inventory":"INVENTAIRE", "sound":"ÉCHO MUSICAL", "sliding":"TAQUIN COULISSANT"}
	var en={"code":"KEYPAD LOCK", "cipher":"SECRET CIPHER", "memory":"VISUAL MEMORY", "wires":"ELECTRIC CIRCUIT", "deduction":"DEDUCTION", "lock":"COMBINATION DIAL", "hidden":"HIDDEN EVIDENCE", "logic":"LOGIC", "time":"CLOCK", "hangman":"SECRET WORD", "mechanism":"MECHANICAL DIALS", "maze":"MAZE", "inventory":"INVENTORY", "sound":"SOUND PATTERN", "sliding":"SLIDING PUZZLE"}
	return (en if str(save["language"])=="en" else fr).get(kind,kind)

func popup(title_text: String, body: String, confirm: Callable=Callable(), action_text: String="") -> void:
	for c in modal_layer.get_children():
		c.queue_free()
	var shade=ColorRect.new()
	shade.color=Color(0,0,0,.58)
	shade.size=Vector2(720,1280)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)
	var card=box(47,403,625,410,Color("#1a2b39"),28,theme_color,modal_layer)
	var stamp=label("✦",299,424,126,69,46,theme_color,true,modal_layer)
	stamp.pivot_offset=stamp.size/2.0
	if not motion_reduced:
		stamp.scale=Vector2(.5,.5)
		var stamp_anim=create_tween().bind_node(stamp)
		stamp_anim.tween_property(stamp,"scale",Vector2(1.2,1.2),.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		stamp_anim.tween_property(stamp,"scale",Vector2.ONE,.18)
	label(title_text,74,501,568,69,32,theme_color,true,modal_layer)
	label(body,80,582,559,104,22,PAPER,true,modal_layer)
	btn(action_text if action_text!="" else loc("CONTINUER","CONTINUE"),98,713,525,70,Callable(self,"close_popup").bind(confirm),true,modal_layer)
	card.pivot_offset=card.size/2
	card.scale=Vector2(.9,.9)
	var tween=create_tween()
	tween.tween_property(card,"scale",Vector2.ONE,.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func mistake(msg: String="") -> void:
	mistakes+=1
	play_sound("wrong_soft")
	popup(loc("MAUVAISE PISTE","WRONG LEAD"),msg if msg!="" else loc("Examine les indices et réessaie.","Study the evidence and try again."))

func stage_complete() -> void:
	if stage_transitioning: return
	stage_transitioning=true
	if str(current_stage()["type"]) in ["code","lock","cipher","mechanism"]:
		play_sound("lock_click")
		play_sound("solved")
	else:
		play_sound("solved")
	if not motion_reduced:
		var badge=label("✦",254,593,212,150,95,theme_color,true)
		badge.pivot_offset=badge.size/2
		badge.scale=Vector2(.45,.45)
		var celebration=create_tween().bind_node(badge)
		celebration.tween_property(badge,"scale",Vector2(1.34,1.34),.22).set_trans(Tween.TRANS_BACK)
		celebration.tween_property(badge,"modulate:a",0.0,.21)

	if stage_index+1 < (levels[selected_level]["stages"] as Array).size():
		popup(loc("ÉNIGME RÉSOLUE","PUZZLE SOLVED"),loc("Le mécanisme est déverrouillé. La prochaine pièce du dossier t'attend.","The mechanism is unlocked. Another clue awaits."),Callable(self,"complete_next_stage"),loc("PROCHAINE ÉTAPE  ›","NEXT STEP  ›"))
	else:
		case_complete()

func case_complete() -> void:
	play_sound("coins")
	var victory_player=AudioStreamPlayer.new()
	victory_player.stream=load("res://assets/music/victory.wav")
	victory_player.volume_db=music_gain() if music_enabled else -65.0
	add_child(victory_player)
	victory_player.finished.connect(func(): victory_player.queue_free())
	if music_enabled: victory_player.play()
	else: victory_player.queue_free()
	var seconds=int(elapsed)
	var score=max(250, 2500 + int(levels[selected_level]["chapter"])*350 - seconds*4 - mistakes*95 - hints_used*300)
	if active_mode != "classic":
		complete_mode_case(score)
		return
	var key=str(selected_level+1)
	var best=save.get("best",{}) as Dictionary
	var previous=int(best.get(key,0))
	var first=previous==0
	if first: play_sound("unlock")
	if score>previous:
		best[key]=score
	var earned=100+max(0,int(score/30)) if first else 20
	if daily_mode and str(save.get("daily_claim",""))!=str(Time.get_date_string_from_system()):
		earned+=180
		save["daily_claim"]=Time.get_date_string_from_system()
	save["coins"]=int(save.get("coins",0))+earned
	play_sound("coins")
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
	backdrop(BG_NAMES[int(levels[selected_level]["chapter"]) % BG_NAMES.size()],.62)
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
	if selected_level < main_level_count-1:
		btn(loc("DOSSIER SUIVANT  ›","NEXT CASE  ›"),59,1004,606,76,func(): start_case(selected_level+1),false)
	else:
		btn(loc("LES 100 DOSSIERS RÉSOLUS !","ALL 100 CASES COMPLETED!"),59,1004,606,76,show_levels,false)
	btn(loc("RETOUR AU MENU","BACK TO HOME"),60,1090,602,74,show_home,true)
	fade_in()

func add_achievements(seconds: int) -> void:
	var achievements=save.get("achievements",[]) as Array
	var count=solved_count()
	for item in ["FIRST" if count>=1 else "", "TEN" if count>=10 else "", "HALF" if count>=25 else "", "ALL" if count>=100 else "", "FAST" if seconds<50 else "", "PERFECT" if mistakes==0 and hints_used==0 else ""]:
		if item!="" and not achievements.has(item):achievements.append(item)

func show_hint_options() -> void:
	if active_mode == "expert":
		popup(loc("MODE EXPERT","EXPERT MODE"),loc("Les indices sont désactivés dans ce défi.","Hints are disabled in this challenge."))
		return
	var cost = 90 if int(puzzle_state.get("hint_count", 0)) == 0 else 150
	var message=loc("Utilise un indice de ton stock.","Use a hint from your inventory.") if int(save.get("hints_stock",0))>0 else loc("Indice payant : %d pièces. Il réduit le score final." % cost,"Paid hint: %d coins. It reduces your score." % cost)
	popup(loc("UN INDICE ?","NEED A HINT?"),message,Callable(self,"buy_hint"),loc("OBTENIR L'INDICE","GET HINT"))

func buy_hint() -> void:
	if int(save.get("hints_stock",0))>0:
		save["hints_stock"]=int(save["hints_stock"])-1
	else:
		var cost = 90 if int(puzzle_state.get("hint_count", 0)) == 0 else 150
		if int(save["coins"]) < cost:
			popup(loc("PIÈCES INSUFFISANTES","NOT ENOUGH COINS"),loc("Termine des enquêtes pour gagner des pièces.","Complete cases to earn coins."))
			return
		save["coins"]=int(save["coins"])-cost
	var hint_step = int(puzzle_state.get("hint_count", 0))
	puzzle_state["hint_count"] = hint_step + 1
	hints_used+=1
	persist()
	play_sound("paper")
	var partial = loc("Observe les éléments, vérifie l'ordre et élimine les possibilités impossibles.", "Review the evidence, check the order and eliminate impossible options.")
	popup(loc("INDICE DÉBLOQUÉ","HINT UNLOCKED"),partial if hint_step == 0 else property_text(current_stage(),"hint"))

func mode_stage_limit() -> float:
	if active_mode in ["zen", "kids", "impossible"]:
		return 0.0
	if active_mode == "speed":
		return 75.0
	if active_mode == "expert":
		return 105.0
	if selected_level >= 50 and selected_level < main_level_count and str(current_stage()["type"]) in ["wires", "memory", "sliding", "sound", "maze"]:
		return 180.0
	return 95.0 if selected_level >= 20 and str(current_stage()["type"]) in ["wires", "time"] else 0.0

func show_modes() -> void:
	screen = "modes"
	wipe()
	backdrop("menu", 0.59)
	topbar(loc("MODES DE JEU", "GAME MODES"), show_home)
	label(loc("GLISSE TON DOIGT POUR EXPLORER", "SWIPE TO EXPLORE"),25,134,666,63,24,theme_color,true)
	var mode_info = [
		["classic",loc("CLASSIQUE", "CLASSIC"),loc("100 enquêtes progressives", "100 progressive cases")],
		["detective",loc("DÉTECTIVE", "DETECTIVE"),loc("5 pièces d'une affaire confidentielle", "5 clues from one classified case")],
		["speed",loc("CONTRE-LA-MONTRE", "TIME ATTACK"),loc("75 secondes par énigme", "75 seconds per puzzle")],
		["zen",loc("ZEN", "ZEN"),loc("Aucune limite de temps", "No timer or pressure")],
		["expert",loc("EXPERT", "EXPERT"),loc("Sans indice, avec chronomètre", "No hints, with countdown")],
		["impossible",loc("DÉFI IMPOSSIBLE", "IMPOSSIBLE CHALLENGE"),loc("15 minutes globales • 5 dossiers extrêmes", "15 minutes total • 5 extreme cases")],
		["marathon",loc("MARATHON", "MARATHON"),loc("Enchaîne cinq dossiers", "Solve five cases in a row")],
		["endless",loc("INFINI", "ENDLESS"),loc("Nouveaux dossiers jusqu'à l'arrêt", "Cases until you stop")],
		["daily",loc("DÉFI QUOTIDIEN", "DAILY CASE"),loc("Une mission chaque jour", "A fresh challenge every day")],
		["kids",loc("MODE ENFANT", "JUNIOR DETECTIVE"),loc("20 enquêtes simples, sans pression", "20 gentle cases, no timer")]
	]
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(30,221)
	scroll.size=Vector2(661,909)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	page.add_child(scroll)
	configure_touch_scroll(scroll)
	var list=VBoxContainer.new()
	list.add_theme_constant_override("separation",13)
	list.custom_minimum_size=Vector2(626,0)
	scroll.add_child(list)
	for info in mode_info:
		var holder=Control.new()
		holder.custom_minimum_size=Vector2(627,136)
		list.add_child(holder)
		box(1,2,611,130,Color("#172c3bec"),18,theme_color,holder)
		image("res://assets/ui/icons/"+str(info[0])+".png",18,29,74,74,holder)
		label(str(info[1]),102,11,278,47,24,theme_color,false,holder)
		label(str(info[2]),102,57,288,50,17,PAPER,false,holder)
		btn(loc("JOUER  ›","PLAY  ›"),405,34,184,67,Callable(self,"launch_mode").bind(str(info[0])),true,holder,true)
	label(loc("Scores enregistrés localement. Aucun compte requis.","Scores stored locally. No account required."),30,1132,665,25,17,QUIET,true)
	navigation("home")
	fade_in()

func launch_mode(kind: String) -> void:
	if kind == "classic":
		show_levels()
		return
	if kind == "daily":
		active_mode = "classic"
		show_daily()
		return
	active_mode = kind
	if kind == "impossible":
		impossible_seconds_left = 900.0
		impossible_overtime = false
		impossible_save_checkpoint = -1
	mode_total_score=0
	mode_chain_pos=0
	match kind:
		"detective": mode_chain = [0,10,20,30,40]
		"impossible": mode_chain = [120, 95, 121, 99, 122]
		"kids": mode_chain = range(child_level_offset, child_level_offset + child_level_count)
		"marathon": mode_chain = [0,1,2,3,4]
		"endless": mode_chain = [randi_range(0,main_level_count-1)]
		_: mode_chain = [clampi(solved_count(),0,main_level_count-1)]
	start_case(int(mode_chain[0]))
	if kind == "impossible" and bool(save.get("tutorial_seen",false)) and not bool(save.get("impossible_tutorial_seen",false)):
		show_impossible_tutorial(0)
	if kind == "detective":
		popup(loc("AFFAIRE CONFIDENTIELLE", "CLASSIFIED CASE"),loc("Morgan : cinq dossiers sont liés. Observe les indices et découvre le fil rouge.","Morgan: five files are linked. Follow their clues."))

func show_impossible_tutorial(step: int) -> void:
	if step == 0:
		popup(loc("01 • CINQ DOSSIERS", "01 • FIVE CASES"),loc("Trois enquêtes inédites et deux dossiers avancés. Les réponses des étapes précédentes pourront servir ensuite.","Three new cases and two advanced files. Earlier answers may help later."),func():show_impossible_tutorial(1),loc("SUIVANT", "NEXT"))
	elif step == 1:
		popup(loc("02 • 15 MINUTES", "02 • 15 MINUTES"),loc("Le chronomètre est global et se met en pause pendant les explications. La musique accélère à la fin.","One shared timer. It pauses during instructions. Music intensifies near the end."),func():show_impossible_tutorial(2),loc("SUIVANT", "NEXT"))	
	else:
		save["impossible_tutorial_seen"] = true
		persist()
		popup(loc("03 • APRÈS LE TEMPS", "03 • AFTER TIME"),loc("Tu peux continuer, mais les points sont réduits de 45 %. Les indices coûtent toujours des pièces.","Keep playing after the timer, with 45 % fewer points. Hints still cost coins."))

func complete_mode_case(score: int) -> void:
	if active_mode == "impossible" and impossible_overtime:
		score = maxi(100, int(round(float(score) * 0.55)))
	mode_total_score += score
	var record_key=active_mode
	var records=save.get("mode_records",{}) as Dictionary
	records[record_key]=maxi(int(records.get(record_key,0)),mode_total_score)
	save["mode_records"]=records
	save["coins"]=int(save.get("coins",0))+60
	save["xp"]=int(save.get("xp",0))+85
	save["runs"].append({"level":selected_level+1,"mode":active_mode,"score":score,"time":int(elapsed),"date":Time.get_date_string_from_system(),"name":str(save.get("name","Détective"))})
	var runs=save.get("runs",[]) as Array
	if runs.size()>200:
		save["runs"]=runs.slice(runs.size()-200,runs.size())
	save["session"]={}
	persist()
	play_sound("coins")
	if active_mode == "endless":
		mode_chain.append(randi_range(0,main_level_count-1))
	if mode_chain_pos+1 < mode_chain.size():
		mode_chain_pos+=1
		var target=int(mode_chain[mode_chain_pos])
		popup(loc("PISTE SUIVANTE", "NEXT CLUE"),loc("Score cumulé : ","Total score: ")+str(mode_total_score)+loc(" points. Poursuis l'enquête !", " points. Keep going!"),func(): start_case(target),loc("CONTINUER  ›", "CONTINUE  ›"))
	else:
		if active_mode == "impossible":
			save["impossible_clears"] = int(save.get("impossible_clears",0)) + 1
			save["coins"] = int(save.get("coins",0)) + (350 if not impossible_overtime else 120)
			save["gems"] = int(save.get("gems",0)) + (5 if not impossible_overtime else 1)
			persist()
		screen="mode_result"
		wipe()
		backdrop("museum",.57)
		label(loc("DÉFI TERMINÉ", "CHALLENGE COMPLETE"),35,260,650,110,48,theme_color,true)
		label(active_mode.to_upper(),35,402,650,75,37,PAPER,true)
		label(str(mode_total_score)+" PTS",30,530,660,112,65,theme_color,true)
		label(loc("Ton record est conservé dans le classement local.","Your best score is saved to local records."),42,686,640,101,23,PAPER,true)
		btn(loc("REJOUER", "PLAY AGAIN"),76,907,570,77,Callable(self,"launch_mode").bind(active_mode),true)
		btn(loc("TOUS LES MODES", "ALL MODES"),76,1011,570,77,show_modes,false)
		fade_in()

func show_daily() -> void:
	play_sound("paper")
	var today=str(Time.get_date_string_from_system())
	var n=abs(today.hash())%main_level_count
	popup(loc("DÉFI QUOTIDIEN","DAILY CHALLENGE"),loc("Une enquête spéciale du jour ! Termine-la pour gagner 180 pièces supplémentaires (une fois par jour).","Today's special case! Solve it for 180 extra coins (once a day)."),func():start_case(n,true),loc("COMMENCER","START"))

# -------------------------------------------------------------
# Fourteen interactive puzzle mechanisms. Every case uses 2–4
# authored, deterministic stages stored in data/levels.json.
# -------------------------------------------------------------
func render_puzzle() -> void:
	var kind=str(current_stage()["type"])
	image("res://assets/ui/apparatus_"+kind+".png",49,509,623,367,page,.34)
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
		"sliding":draw_sliding()
		_:label("Puzzle",80,600,560,60,32,PAPER,true)

func puzzle_tip(text_fr: String,text_en: String) -> void:
	label(loc(text_fr,text_en),75,928,568,69,19,QUIET,true)

func draw_sliding() -> void:
	var tiles = puzzle_state.get("tiles", [1,2,3,4,5,6,7,8,0]) as Array
	label(loc("FAIS GLISSER LES TUILES VERS LE VIDE", "SLIDE TILES INTO THE EMPTY SPACE"),66,513,580,51,21,PAPER,true)
	for i in range(9):
		var x = 119 + (i%3)*166
		var y = 574 + int(i/3)*137
		if int(tiles[i]) == 0:
			box(x,y,156,124,Color("#0a1926"),12,Color("#4b6474"))
		else:
			btn(str(tiles[i]),x,y,156,124,Callable(self,"slide_tile").bind(i),true)
	label(loc("RECONSTITUE 1-2-3 / 4-5-6 / 7-8-VIDE", "SOLVE 1-2-3 / 4-5-6 / 7-8-EMPTY"),73,991,574,35,19,QUIET,true)

func slide_tile(index: int) -> void:
	var tiles = puzzle_state.get("tiles",[]) as Array
	if tiles.size() != 9: return
	var empty = tiles.find(0)
	if not (absi(int(index/3) - int(empty/3)) + absi(index%3 - empty%3) == 1):
		play_sound("wrong_soft")
		return
	var n = tiles[index]
	tiles[index] = 0
	tiles[empty] = n
	play_sound("gear")
	if tiles == (current_stage()["answer"] as Array):
		stage_complete()
	else:
		render_game()

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
		var touch_dial=box(x,743,wid,109,Color("#080f18"),12,theme_color)
		touch_dial.mouse_filter=Control.MOUSE_FILTER_STOP
		touch_dial.gui_input.connect(Callable(self,"wheel_gesture").bind(i,alphabet.length()))
		label(alphabet.substr(int(wheels[i]),1),x+4,760,wid-8,76,43,theme_color,true)
		btn("▼",x,862,wid,65,Callable(self,"turn_wheel").bind(i,-1,alphabet.length()))
	btn(loc("VALIDER","CONFIRM"),180,947,360,72,func():validate_wheels(alphabet),true)

func turn_wheel(i: int, step: int, base: int) -> void:
	var wheels=puzzle_state["wheels"] as Array
	wheels[i]=(int(wheels[i])+step+base)%base
	play_sound("gear")
	render_game()

func wheel_gesture(event: InputEvent, index: int, base: int) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		turn_wheel(index,1,base)
	elif event is InputEventScreenTouch and event.pressed:
		turn_wheel(index,1,base)
	elif event is InputEventScreenDrag and absf(event.relative.y)>20.0:
		turn_wheel(index,1 if event.relative.y<0 else -1,base)

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
	label(loc("RELIE LES BORNES DANS LE BON ORDRE","CONNECT TERMINALS IN ORDER"),81,520,560,53,22,PAPER,true)
	var board=load("res://scripts/wire_board.gd").new()
	board.position=Vector2(72,575)
	board.size=Vector2(574,358)
	board.connected=(puzzle_state["entered"] as Array).duplicate()
	board.wire_dropped.connect(Callable(self,"connect_wire"))
	board.drag_rejected.connect(func():play_sound("wrong_soft"))
	page.add_child(board)
	var entered=puzzle_state["entered"] as Array
	label(loc("CONNEXIONS : ","WIRES: ")+str(entered.size())+" / "+str((current_stage()["answer"] as Array).size()),76,939,571,36,22,theme_color,true)
	# The buttons are keyboard-friendly alternatives to touch drag.
	for i in range(4):
		var b=btn(str(i+1),80+i*144,983,130,50,Callable(self,"connect_wire").bind(i),false,page,true)
		b.add_theme_color_override("font_color",TONES[i])

func connect_wire(index: int) -> void:
	if stage_transitioning:return
	var entered=puzzle_state["entered"] as Array
	var answer=current_stage()["answer"] as Array
	if entered.size()>=answer.size():return
	if index==int(answer[entered.size()]):
		entered.append(index)
		play_sound("gear")
		if entered.size()==answer.size():stage_complete()
		else:render_game()
	else:
		mistake(loc("Cette couleur n'est pas la suivante.","That's not the next color."))

func draw_choices(as_suspects: bool) -> void:
	var stage=current_stage()
	var options: Array=[]
	if as_suspects:
		options=stage["options_en"] if str(save["language"])=="en" else stage["options_fr"]
	else:
		options=stage["options"]
	var compact = options.size() > 3
	for i in range(options.size()):
		var y = 527 + i*(113 if compact else 130)
		box(60,y,600,99 if compact else 107,Color("#182d3c"),18,theme_color)
		label(str(i+1)+".",83,y+22,55,55,30,theme_color,true)
		btn(str(options[i]),151,y+15,487,68 if compact else 73,Callable(self,"choose_option").bind(i),false)
	if not compact:
		puzzle_tip("Une seule réponse est correcte.","Only one answer is correct.")

func choose_option(i: int) -> void:
	if i==int(current_stage()["answer"]):
		stage_complete()
	elif str(current_stage()["type"])=="deduction":
		mistake(loc("L'agent Morgan secoue la tête : cette déposition ne correspond pas aux preuves.","Agent Morgan shakes their head: this statement doesn't match the evidence."))
	else:
		mistake()

func draw_hidden() -> void:
	var stage=current_stage()
	var objects: Array=stage["objects_en"] if str(save["language"])=="en" else stage["objects_fr"]
	label(loc("TOUCHE LA LOUPE POUR EXAMINER UNE PIÈCE","TAP THE MAGNIFIER TO INSPECT EVIDENCE"),60,508,602,42,18,QUIET,true)
	for i in range(objects.size()):
		var x=66+(i%3)*209
		var y=555+int(i/3)*106
		box(x,y,192,97,Color("#253745"),12,Color("#b79b65"))
		btn("⌕  "+str(objects[i]),x+7,y+9,178,79,Callable(self,"inspect_evidence").bind(i),false,page,true)

func inspect_evidence(index: int) -> void:
	var stage=current_stage()
	var items: Array=stage["objects_en"] if str(save["language"])=="en" else stage["objects_fr"]
	play_sound("paper")
	popup(loc("EXAMEN DE L'INDICE","EVIDENCE INSPECTION"),str(items[index])+"\n"+loc("Cet objet est-il celui que tu recherches ?","Is this the item you are looking for?"),Callable(self,"choose_option").bind(index),loc("CONFIRMER CET OBJET","SELECT THIS ITEM"))

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
	play_sound("gear")
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
	label(loc("GLISSE UN OBJET VERS LA ZONE COMBINER","DRAG AN ITEM TO THE COMBINE AREA"),63,508,593,49,19,theme_color,true)
	var board=load("res://scripts/inventory_board.gd").new()
	board.position=Vector2(64,563)
	board.size=Vector2(588,382)
	board.items=items
	board.selected=selected.duplicate()
	board.item_chosen.connect(Callable(self,"pick_item"))
	page.add_child(board)
	label(loc("OBJETS UTILISÉS : ","USED ITEMS: ")+str(selected.size())+" / 2",94,945,521,38,22,QUIET,true)
	btn(loc("VIDER LE SAC","RESET BAG"),187,987,348,43,clear_inventory,false,page,true)

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
func change_avatar(step: int) -> void:
	save["avatar"]=(int(save.get("avatar",0))+step+2)%2
	persist()
	play_sound("paper")
	show_profile()

func show_tutorial_step(index: int) -> void:
	var titles_fr = ["BIENVENUE, DÉTECTIVE", "LIRE LES CONSIGNES", "MANIPULER LES OBJETS", "INDICES ET PIÈCES", "VOTRE PROGRESSION"]
	var titles_en = ["WELCOME, DETECTIVE", "READ THE CLUES", "TOUCH AND DRAG", "HINTS AND COINS", "YOUR PROGRESS"]
	var tips_fr = [
		"Chaque dossier cache un mystère. Touchez les éléments, observez les indices et trouvez la solution.",
		"L'inspecteur Morgan donne la consigne au-dessus du puzzle. Touchez son texte pour l'afficher en entier.",
		"Touchez les boutons d'un cadenas. Faites glisser les fils ou les objets. Prenez le temps de bien observer.",
		"Les indices sont payants en pièces : le premier coûte 90 pièces, le suivant 150. Rien n'est acheté avec de l'argent réel.",
		"Le jeu enregistre automatiquement vos dossiers, records et notes. Vous pouvez rejouer ce tutoriel depuis les paramètres."
	]
	var tips_en = [
		"Each case hides a mystery. Tap objects, study clues and find a solution.",
		"Inspector Morgan gives instructions above the puzzle. Tap the text to reveal it at once.",
		"Tap lock buttons. Drag wires or inventory objects. Take time to observe.",
		"Hints cost in-game coins: the first costs 90, the next costs 150. No real-money purchase is needed.",
		"The game autosaves cases, records and notes. Replay this tutorial from Settings whenever you wish."
	]
	index = clampi(index,0,4)
	for node in modal_layer.get_children():
		node.queue_free()
	var shade = ColorRect.new()
	shade.color = Color(0.012,0.023,0.034,0.90)
	shade.size = Vector2(720,1280)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)
	box(38,254,644,750,Color("#182c3aeF"),26,theme_color,modal_layer)
	label("◈  " + loc("GUIDE D'ENQUÊTE", "INVESTIGATION GUIDE") + "  ◈",62,274,599,67,25,theme_color,true,modal_layer)
	label(str(index+1) + " / 5",270,347,183,40,21,QUIET,true,modal_layer)
	image("res://assets/ui/agent_morgan.png",262,396,195,225,modal_layer,0.95)
	var titles = titles_en if str(save.get("language","fr")) == "en" else titles_fr
	var tips = tips_en if str(save.get("language","fr")) == "en" else tips_fr
	label(titles[index],70,621,581,61,27,theme_color,true,modal_layer)
	var paragraph = label(tips[index],77,682,568,170,19,PAPER,true,modal_layer)
	paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	paragraph.clip_text = false
	paragraph.add_theme_font_size_override("font_size",int(round(19 * ui_scale)))
	paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	btn(loc("PASSER", "SKIP"),68,887,218,74,end_tutorial,false,modal_layer,true)
	var next_action = Callable(self,"show_tutorial_step").bind(index+1) if index < 4 else Callable(self,"end_tutorial")
	btn(loc("SUIVANT  ›", "NEXT  ›") if index < 4 else loc("C'EST PARTI !", "LET'S GO!"),299,887,347,74,next_action,true,modal_layer,true)

func end_tutorial() -> void:
	for node in modal_layer.get_children():
		node.queue_free()
	save["tutorial_seen"] = true
	persist()
	play_sound("unlock")

func show_notepad() -> void:
	play_sound("paper")
	for c in modal_layer.get_children(): c.queue_free()
	var shade=ColorRect.new()
	shade.color=Color(0,0,0,.82)
	shade.size=Vector2(720,1280)
	shade.mouse_filter=Control.MOUSE_FILTER_STOP
	modal_layer.add_child(shade)
	box(40,254,640,750,Color("#192b39"),28,theme_color,modal_layer)
	label(loc("CARNET DU DÉTECTIVE","DETECTIVE NOTEBOOK"),68,293,589,67,30,theme_color,true,modal_layer)
	label(loc("Retiens les codes, suspects et détails importants.","Note codes, suspects and important details."),66,373,593,52,19,QUIET,true,modal_layer)
	note_editor=TextEdit.new()
	note_editor.position=Vector2(79,441)
	note_editor.size=Vector2(565,405)
	note_editor.wrap_mode=TextEdit.LINE_WRAPPING_BOUNDARY
	note_editor.add_theme_font_size_override("font_size",int(round(24*ui_scale)))
	note_editor.add_theme_color_override("font_color",Color("#f0dfbd"))
	note_editor.add_theme_color_override("background_color",Color("#0b1825"))
	note_editor.text=str((save.get("notebook",{}) as Dictionary).get(str(selected_level+1),""))
	modal_layer.add_child(note_editor)
	btn(loc("SAUVEGARDER ET FERMER","SAVE & CLOSE"),88,886,544,75,save_notepad,true,modal_layer)

func save_notepad() -> void:
	if note_editor != null and is_instance_valid(note_editor):
		var notes=save.get("notebook",{}) as Dictionary
		notes[str(selected_level+1)]=note_editor.text.substr(0,4000)
		persist()
	for c in modal_layer.get_children():c.queue_free()
	play_sound("paper")

func show_pause() -> void:
	popup(loc("ENQUÊTE EN PAUSE","CASE PAUSED"),loc("La progression est sauvegardée. Tu peux fermer le jeu ou continuer.","Your progress has been saved. You can close the game or continue."),Callable(),loc("REPRENDRE","RESUME"))

func show_profile() -> void:
	screen="profile"
	wipe()
	backdrop("menu",.59)
	small_header(loc("IDENTITÉ","IDENTITY"))
	label(loc("MON DOSSIER","MY DETECTIVE FILE"),40,143,643,65,43,theme_color,true)
	box(39,236,641,398,Color("#182c3bef"))
	var avatar_id=int(save.get("avatar",0))
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
	var statistics=[loc("NIVEAU JOUEUR","PLAYER LEVEL"),str(user_level()),loc("DOSSIERS RÉSOLUS","CASES SOLVED"),str(solved_count())+" / 100",loc("EXPÉRIENCE","EXPERIENCE"),str(save.get("xp",0))+" XP",loc("RECORD CUMULÉ","TOTAL BEST SCORE"),str(total_score())+" PTS"]
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
	label(loc("POINTS CUMULÉS SUR 100 DOSSIERS","TOTAL BEST SCORE ACROSS 100 CASES"),78,319,556,35,18,QUIET,true)
	var mode_records=save.get("mode_records",{}) as Dictionary
	if mode_records.size()>0:
		var records_text=loc("RECORDS MODES : ","MODE RECORDS: ")
		for name in mode_records.keys():
			records_text+=str(name).to_upper()+" "+str(mode_records[name])+"  •  "
		label(records_text,32,374,650,40,16,GREEN,true)
	var records=[]
	for run in (save.get("runs",[]) as Array):records.append(run)
	records.sort_custom(func(a,b):return int(a.get("score",0))>int(b.get("score",0)))
	var scroll=ScrollContainer.new()
	scroll.position=Vector2(40,430)
	scroll.size=Vector2(640,684)
	page.add_child(scroll)
	configure_touch_scroll(scroll)
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
	play_sound("coins")
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
		["ALL",loc("LÉGENDE","LEGEND"),loc("Terminer 100 enquêtes","Finish 100 cases")],
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
	configure_touch_scroll(scroll)
	var list=VBoxContainer.new()
	list.custom_minimum_size=Vector2(613,0)
	list.add_theme_constant_override("separation",14)
	scroll.add_child(list)
	for i in range(main_level_count):
		var holder=Control.new()
		holder.custom_minimum_size=Vector2(610,119)
		list.add_child(holder)
		box(0,1,609,116,Color("#203343ed"),12,theme_color if (save.get("solved",[]) as Array).has(i+1) else QUIET,holder)
		label("%02d"%(i+1),11,20,85,65,37,theme_color,true,holder)
		label(property_text(levels[i],"title"),103,13,477,42,23,PAPER,false,holder)
		label(loc("RÉSOLU • DOSSIER CLASSÉ","SOLVED • CASE CLOSED") if (save.get("solved",[]) as Array).has(i+1) else loc("NON RÉSOLU","UNSOLVED"),104,63,466,37,17,GREEN if (save.get("solved",[]) as Array).has(i+1) else QUIET,false,holder)
	navigation("profile")
	fade_in()

func settings_row(parent: VBoxContainer, height: int) -> Control:
	var holder=Control.new()
	holder.custom_minimum_size=Vector2(634,height)
	parent.add_child(holder)
	box(2,0,614,height-5,Color("#172b39f2"),18,Color("#b8986b99"),holder)
	return holder

func make_volume_slider(holder: Control, text_fr: String, text_en: String, which: String) -> void:
	label(loc(text_fr,text_en),25,16,425,44,22,PAPER,false,holder)
	var current=int(save.get(which,25 if which=="music_volume" else 70))
	var readout=label(str(current)+" %",475,16,105,44,24,theme_color,true,holder)
	var slider=HSlider.new()
	slider.position=Vector2(32,70)
	slider.size=Vector2(535,55)
	slider.min_value=0
	slider.max_value=100
	slider.step=5
	slider.value=current
	slider.mouse_filter=Control.MOUSE_FILTER_STOP
	slider.value_changed.connect(Callable(self,"set_volume").bind(which,readout))
	holder.add_child(slider)

func set_volume(value: float, which: String, readout: Label) -> void:
	save[which]=clampi(int(round(value)),0,100)
	if is_instance_valid(readout): readout.text=str(save[which])+" %"
	persist()
	apply_audio_settings()

func show_settings() -> void:
	screen="settings"
	wipe()
	backdrop("menu",.65)
	topbar(loc("PARAMÈTRES","SETTINGS"),show_home)
	label(loc("GLISSEZ VERS LE HAUT POUR DÉFILER", "SWIPE UP TO SCROLL"),31,140,656,58,23,theme_color,true)
	var scroller=ScrollContainer.new()
	scroller.position=Vector2(37,218)
	scroller.size=Vector2(648,915)
	scroller.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	scroller.follow_focus = true
	scroller.scroll_deadzone = 4
	page.add_child(scroller)
	configure_touch_scroll(scroller)
	settings_scroll=scroller
	scroller.get_v_scroll_bar().modulate.a = 0.0
	scroller.get_v_scroll_bar().mouse_filter = Control.MOUSE_FILTER_IGNORE
	var list=VBoxContainer.new()
	list.custom_minimum_size=Vector2(627,0)
	list.add_theme_constant_override("separation",15)
	scroller.add_child(list)
	var h=settings_row(list,120)
	label(loc("LANGUE DU JEU","GAME LANGUAGE"),19,11,576,38,23,theme_color,true,h)
	btn("FRANÇAIS",27,52,271,55,func():set_language("fr"),str(save["language"])=="fr",h,true)
	btn("ENGLISH",318,52,271,55,func():set_language("en"),str(save["language"])=="en",h,true)
	h=settings_row(list,144)
	make_volume_slider(h,"MUSIQUE DE FOND","BACKGROUND MUSIC","music_volume")
	h=settings_row(list,144)
	make_volume_slider(h,"EFFETS SONORES","SOUND EFFECTS","sfx_volume")
	h=settings_row(list,117)
	btn(loc("TESTER LA MUSIQUE", "TEST MUSIC"),27,23,269,63,preview_music,true,h,true)
	btn(loc("TESTER UN SON", "TEST SOUND"),312,23,273,63,func():play_sound("click"),false,h,true)
	h=settings_row(list,118)
	btn(loc("MUSIQUE : ","MUSIC: ")+("ON" if music_enabled else "OFF"),26,26,269,65,toggle_music,music_enabled,h,true)
	btn(loc("SONS : ","SOUNDS: ")+("ON" if sound_enabled else "OFF"),312,26,273,65,toggle_sound,sound_enabled,h,true)
	h=settings_row(list,145)
	label(loc("THÈME VISUEL","VISUAL THEME"),23,12,565,45,23,theme_color,true,h)
	for i in range(3):
		var theme_name=[loc("OR","GOLD"),loc("AZUR","AZURE"),loc("VIOLET","VIOLET")][i]
		var b=btn(theme_name,25+i*192,66,177,59,Callable(self,"select_visual_theme").bind(i),int(save.get("theme",0))==i,h,true)
		if i>0 and not (save.get("purchases",[]) as Array).has(i): b.disabled=true
	h=settings_row(list,145)
	label(loc("TAILLE DU TEXTE","TEXT SIZE"),24,12,558,42,23,theme_color,true,h)
	for i in range(3):
		var pct=[90,100,110][i]
		btn(str(pct)+" %",27+i*193,66,175,59,Callable(self,"set_text_scale").bind(pct),int(save.get("text_scale",100))==pct,h,true)
	h=settings_row(list,106)
	btn(loc("VIBRATIONS : ","HAPTICS: ")+("ON" if haptics_enabled else "OFF"),27,19,560,63,toggle_haptics,haptics_enabled,h,true)
	h=settings_row(list,110)
	btn(loc("ANIMATIONS RÉDUITES : ","REDUCED MOTION: ")+("ON" if motion_reduced else "OFF"),27,23,560,65,toggle_reduced_motion,motion_reduced,h,true)
	h=settings_row(list,118)
	btn(loc("REVOIR LE TUTORIEL","REPLAY THE TUTORIAL"),25,22,563,66,replay_tutorial,false,h,true)
	h=settings_row(list,108)
	btn(loc("SIGNALER UN PROBLÈME", "REPORT AN ISSUE"),27,21,560,63,show_bug_report,false,h,true)
	h=settings_row(list,132)
	label(loc("SAUVEGARDE AUTOMATIQUE  •  HORS LIGNE","AUTOSAVE  •  OFFLINE"),22,15,570,47,22,theme_color,true,h)
	label(loc("Tes records, carnets et progrès restent sur cet appareil.","Your records, notes and progress stay on this device."),27,61,563,58,19,QUIET,true,h)
	btn(loc("RETOUR AU MENU","BACK TO HOME"),93,1150,534,72,show_home,true)
	fade_in()

func show_bug_report() -> void:
	popup(loc("RAPPORT DE TEST", "TEST REPORT"),loc("Copier le résumé technique et le coller dans le chat avec une capture. Aucune donnée n'est envoyée automatiquement.","Copy the technical summary and paste it with a screenshot. No data is sent automatically."),copy_bug_report,loc("COPIER LE RAPPORT", "COPY REPORT"))

func copy_bug_report() -> void:
	var details = "Mystery Escapes V6 | Platform: " + OS.get_name() + " | Mode: " + active_mode + " | Screen: " + screen + " | Case: " + str(selected_level + 1) + " | Step: " + str(stage_index + 1) + " | Locale: " + str(save.get("language","fr"))
	DisplayServer.clipboard_set(details)
	popup(loc("RAPPORT COPIÉ", "REPORT COPIED"),loc("Colle-le dans ton message et décris le problème rencontré.","Paste it into your message and describe the issue."))

func set_text_scale(percent: int) -> void:
	save["text_scale"]=percent
	ui_scale=float(percent)/100.0
	persist()
	show_settings()

func toggle_reduced_motion() -> void:
	motion_reduced=not motion_reduced
	save["reduced_motion"]=motion_reduced
	persist()
	show_settings()

func replay_tutorial() -> void:
	show_tutorial_step(0)

func set_language(code: String) -> void:
	save["language"]=code
	persist()
	show_settings()

func preview_music() -> void:
	if int(save.get("music_volume",25)) == 0:
		save["music_volume"] = 25
	music_enabled = true
	save["music"] = true
	persist()
	if soundtrack_scene == "":
		soundtrack_scene = "menu"
	play_next_music(true)
	apply_audio_settings()

func toggle_haptics() -> void:
	haptics_enabled=not haptics_enabled
	save["haptics"]=haptics_enabled
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
	persist()
	apply_audio_settings()
	show_settings()

func select_visual_theme(which: int) -> void:
	save["theme"]=which
	change_theme(which)
	persist()
	show_settings()

func _input(event: InputEvent) -> void:
	# Direct touch events are reliable even when the ScrollContainer contains buttons.
	if event is InputEventScreenTouch:
		touch_event_ms = Time.get_ticks_msec()
		if event.pressed:
			begin_scroll_gesture(event.position)
		else:
			finish_scroll_gesture()
	elif event is InputEventScreenDrag:
		touch_event_ms = Time.get_ticks_msec()
		move_scroll_gesture(event.relative.y)
	# Windows mouse drag also simulates a finger; ignore synthetic mouse after touch.
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Time.get_ticks_msec() - touch_event_ms < 400:
			return
		if event.pressed:
			begin_scroll_gesture(event.position)
		else:
			finish_scroll_gesture()
	elif event is InputEventMouseMotion:
		if Time.get_ticks_msec() - touch_event_ms >= 400 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			move_scroll_gesture(event.relative.y)

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


# V5: cinematic opening appears above the ready home UI; there is no fake progress bar.
# Automatically closes after the short introduction; never interrupts the music.
func show_opening() -> void:
	if opening_layer != null and is_instance_valid(opening_layer):
		return
	opening_completed = false
	opening_layer = Control.new()
	opening_layer.name = "V5CinematicOpening"
	opening_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	opening_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(opening_layer)
	var image_bg = TextureRect.new()
	image_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	image_bg.texture = load("res://assets/ui/loading_background.png")
	image_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image_bg.stretch_mode = TextureRect.STRETCH_SCALE
	opening_layer.add_child(image_bg)
	var emblem = TextureRect.new()
	emblem.position = Vector2(177,225)
	emblem.size = Vector2(366,366)
	emblem.texture = load("res://assets/ui/seal_v5.png")
	emblem.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	emblem.pivot_offset = emblem.size * 0.5
	opening_layer.add_child(emblem)
	var heading = Label.new()
	heading.text = "MYSTERY ESCAPE'S"
	heading.position = Vector2(45,622)
	heading.size = Vector2(630,100)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", GOLD_BRIGHT)
	heading.add_theme_font_size_override("font_size",43)
	opening_layer.add_child(heading)
	var sub = Label.new()
	sub.text = loc("LES ARCHIVES S'OUVRENT...", "THE ARCHIVES ARE OPENING...")
	sub.position = Vector2(38,746)
	sub.size = Vector2(644,57)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", QUIET)
	sub.add_theme_font_size_override("font_size",21)
	opening_layer.add_child(sub)
	var tips_fr = ["Observez les documents : les détails comptent.", "Chaque indice peut cacher une seconde lecture.", "Écoutez les témoins avant de choisir.", "Les indices coûtent des pièces du jeu.", "Vos enquêtes sont sauvegardées automatiquement."]
	var tips_en = ["Study documents: details matter.", "Every clue can have a second meaning.", "Listen to witnesses before choosing.", "Hints cost in-game coins.", "Your investigations are saved automatically."]
	var tip = Label.new()
	var tips = tips_en if str(save.get("language","fr")) == "en" else tips_fr
	tip.text = tips[randi() % tips.size()]
	tip.position = Vector2(76,1055)
	tip.size = Vector2(568,110)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tip.add_theme_font_size_override("font_size",21)
	tip.add_theme_color_override("font_color",PAPER)
	opening_layer.add_child(tip)
	var skip = Button.new()
	skip.text = loc("PASSER  ›", "SKIP  ›")
	skip.position = Vector2(262,1175)
	skip.size = Vector2(196,59)
	skip.add_theme_font_size_override("font_size",22)
	skip.pressed.connect(close_opening)
	opening_layer.add_child(skip)
	if not motion_reduced:
		emblem.modulate.a = 0.0
		emblem.scale = Vector2(.89,.89)
		var intro = create_tween().set_parallel(true)
		intro.tween_property(emblem,"modulate:a",1.0,1.0)
		intro.tween_property(emblem,"scale",Vector2.ONE,1.3).set_trans(Tween.TRANS_SINE)
	get_tree().create_timer(3.8).timeout.connect(close_opening)

func close_opening() -> void:
	if opening_completed:
		return
	opening_completed = true
	if opening_layer == null or not is_instance_valid(opening_layer):
		return
	var old = opening_layer
	opening_layer = null
	if motion_reduced:
		old.queue_free()
	else:
		var t = create_tween()
		t.tween_property(old,"modulate:a",0.0,.28)
		t.tween_callback(func():
			if is_instance_valid(old):
				old.queue_free()
		)
