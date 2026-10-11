extends Node
## AdMob integration adapter: intentionally safe/inactive until native SDK exists.
signal rewarded_ad_completed(reward_type: String)
signal ad_unavailable(message: String)
var test_mode := true
var ads_enabled := false
var last_interstitial_at := -100000.0

func _ready() -> void:
    var obj = JSON.parse_string(FileAccess.get_file_as_string("res://config/online_services.json"))
    if typeof(obj) == TYPE_DICTIONARY:
        var ads: Dictionary = obj.get("ads", {})
        test_mode = bool(ads.get("test_mode", true))
        ads_enabled = bool(ads.get("enabled", false))

func show_rewarded(_reward_type: String) -> void:
    # Never grant a reward unless an actual SDK completion callback validates it.
    ad_unavailable.emit("Publicité non disponible : module natif AdMob non installé")

func show_interstitial() -> void:
    ad_unavailable.emit("Annonce non disponible dans cette version de test")
