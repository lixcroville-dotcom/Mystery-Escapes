extends Node
# Poing Studios AdMob 5.x adapter. Only loaded when native plugin is installed.
# The iOS test IDs are official Google test units, not the publisher's live units.
signal reward_confirmed(kind: String)
signal ad_failed(message: String)
const IOS_TEST_REWARDED = "ca-app-pub-3940256099942544/1712485313"
const IOS_TEST_INTERSTITIAL = "ca-app-pub-3940256099942544/4411468910"
const ANDROID_TEST_REWARDED = "ca-app-pub-3940256099942544/5224354917"
const ANDROID_TEST_INTERSTITIAL = "ca-app-pub-3940256099942544/1033173712"
var ads: Dictionary = {}
var active_ad: RewardedAd
var interstitial_ad: InterstitialAd
var pending_kind: String = ""
var busy: bool = false

func _ready() -> void:
	var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://config/online_services.json"))
	if typeof(cfg) == TYPE_DICTIONARY:
		ads = cfg.get("ads", {})
	MobileAds.initialize()

func _production_ready() -> bool:
	return bool(ads.get("production_approved", false)) and bool(ads.get("consent_ready", false)) and bool(ads.get("store_listing_linked", false)) and bool(ads.get("publisher_payment_profile_complete", false))

func _reward_unit(kind: String) -> String:
	if bool(ads.get("test_mode", true)):
		return IOS_TEST_REWARDED if OS.get_name() == "iOS" else ANDROID_TEST_REWARDED
	var key = "ios_rewarded_coins_unit_id" if kind != "hint" else "ios_rewarded_hint_unit_id"
	return str(ads.get(key, ""))

func show_rewarded(kind: String) -> void:
	if busy or kind not in ["coins", "hint", "double"]:
		return
	if not bool(ads.get("test_mode", true)) and not _production_ready():
		ad_failed.emit("Publicités commerciales désactivées : validation AdMob et consentement requis")
		return
	busy = true
	pending_kind = kind
	var cb := RewardedAdLoadCallback.new()
	cb.on_ad_failed_to_load = func(_err: LoadAdError) -> void:
		busy = false
		pending_kind = ""
		ad_failed.emit("Impossible de charger la vidéo publicitaire")
	cb.on_ad_loaded = func(ad: RewardedAd) -> void:
		active_ad = ad
		var fullscreen := FullScreenContentCallback.new()
		fullscreen.on_ad_failed_to_show_full_screen_content = func(_err: AdError) -> void:
			_cleanup()
			ad_failed.emit("Impossible d'afficher la vidéo")
		fullscreen.on_ad_dismissed_full_screen_content = func() -> void:
			_cleanup()
		active_ad.full_screen_content_callback = fullscreen
		var earned := OnUserEarnedRewardListener.new()
		earned.on_user_earned_reward = func(_reward: RewardedItem) -> void:
			if pending_kind != "":
				reward_confirmed.emit(pending_kind)
				pending_kind = ""  # prevent a double grant from duplicate callbacks
		active_ad.show(earned)
	RewardedAdLoader.new().load(_reward_unit(kind), AdRequest.new(), cb)

func _cleanup() -> void:
	if active_ad != null:
		active_ad.destroy()
		active_ad = null
	busy = false
	pending_kind = ""

func show_interstitial() -> void:
	if busy:
		return
	if not bool(ads.get("test_mode", true)) and not _production_ready():
		return
	var cb := InterstitialAdLoadCallback.new()
	cb.on_ad_failed_to_load = func(_err: LoadAdError) -> void: pass
	cb.on_ad_loaded = func(ad: InterstitialAd) -> void:
		interstitial_ad = ad
		var fullscreen := FullScreenContentCallback.new()
		fullscreen.on_ad_dismissed_full_screen_content = func() -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
				interstitial_ad = null
		fullscreen.on_ad_failed_to_show_full_screen_content = func(_err: AdError) -> void:
			if interstitial_ad != null:
				interstitial_ad.destroy()
				interstitial_ad = null
		interstitial_ad.full_screen_content_callback = fullscreen
		interstitial_ad.show()
	var unit = (IOS_TEST_INTERSTITIAL if OS.get_name() == "iOS" else ANDROID_TEST_INTERSTITIAL) if bool(ads.get("test_mode", true)) else str(ads.get("ios_interstitial_unit_id", ""))
	InterstitialAdLoader.new().load(unit, AdRequest.new(), cb)
