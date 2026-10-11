extends Node
# Real AdMob events only; when the plugin is unavailable ads fail closed.
signal rewarded_ad_completed(reward_type: String)
signal ad_unavailable(message: String)
var settings: Dictionary = {}
var native_adapter: Node
var completed_cases: int = 0
var last_interstitial_ms: int = -10000000

func _ready() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string("res://config/online_services.json"))
	if typeof(raw) == TYPE_DICTIONARY:
		settings = raw.get("ads", {})
	# Native adapter is loaded only on iOS/Android when the third-party SDK is actually present.
	if OS.get_name() not in ["iOS", "Android"]:
		return
	if not bool(settings.get("enabled", false)):
		return
	if not get_tree().root.has_node("MobileAds"):
		return
	var resource: Script = load("res://scripts/online/admob_native_adapter.gd")
	if resource == null:
		return
	native_adapter = Node.new()
	native_adapter.set_script(resource)
	add_child(native_adapter)
	native_adapter.reward_confirmed.connect(func(kind: String): rewarded_ad_completed.emit(kind))
	native_adapter.ad_failed.connect(func(message: String): ad_unavailable.emit(message))

func show_rewarded(kind: String) -> void:
	if kind not in ["coins", "hint", "double"]:
		return
	if native_adapter == null:
		ad_unavailable.emit("SDK AdMob iOS indisponible : annonce non lancée")
		return
	native_adapter.show_rewarded(kind)

func case_finished() -> void:
	completed_cases += 1
	if completed_cases % maxi(1, int(settings.get("interstitial_after_cases", 3))) != 0:
		return
	if native_adapter == null:
		return
	if Time.get_ticks_msec() - last_interstitial_ms < 1000 * int(settings.get("min_seconds_between_interstitials", 300)):
		return
	last_interstitial_ms = Time.get_ticks_msec()
	native_adapter.show_interstitial()
